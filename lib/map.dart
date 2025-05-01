// lib/map.dart
import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

// Services et Modèles
import '../models/event.dart';
import '../models/latest_measurement.dart';
import '../services/air_quality_service.dart';
import '../services/database_helper.dart';
import '../services/settings_service.dart';
import '../ux_unit/custom_drawer.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});
  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  Position? _currentPosition;
  final MapController _mapController = MapController();
  final double _minZoom = 2.0;
  final double _maxZoom = 18.0;
  final LatLng _defaultCenter = const LatLng(46.6, 2.2); // Centre France/Europe
  final double _defaultZoom = 5.0;

  final AirQualityService _aqService = AirQualityService();
  List<LatestMeasurementResult> _allLatestMeasurements = [];
  bool _isLoadingAQ = false;
  String? _aqError;
  bool _isApiKeyMissing = false;

  String _selectedParameterId = '3'; // O3 par défaut
  String _selectedParameterName = 'O3';
  String _selectedParameterDescription = '';

  final Map<String, String> _availableParameters = {
    '3': 'O₃ (µg/m³)', // Ozone par défaut
    '2': 'PM2.5 (µg/m³)',
    '1': 'PM10 (µg/m³)',
    '4': 'CO (µg/m³)',
    '5': 'NO₂ (µg/m³)',
    '6': 'SO₂ (µg/m³)',
    '19': 'PM1 (µg/m³)',
    '98': 'Relative Humidity (%)',
    '100': 'Temperature (°C)',
    '125': 'UM003 (particles/cm³)',
    '19843': 'NO (µg/m³)',
    '11': 'BC (µg/m³)',
    '7': 'NO₂ (ppm)',
    '8': 'CO (ppm)',
    '9': 'SO₂ (ppm)',
    '10': 'O₃ (ppm)',
  };

  LatLng? _mapInitialCenter;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // --- NOUVEAU: Variable d'état pour la polyline ---
  Polyline? _userToLastEventPolyline;
  // --- FIN NOUVEAU ---

  @override
  void initState() {
    super.initState();
    _updateSelectedParameterInfo(_selectedParameterId);
    _initializeMapAndFetchData();
  }

  void _updateSelectedParameterInfo(String id) {
    // Identique
    final info = PARAMETER_ID_TO_INFO[int.tryParse(id)];
    setState(() {
      _selectedParameterId = id;
      _selectedParameterName = info?['name']?.toUpperCase() ??
          _availableParameters[id]?.split(' ')[0] ??
          'Unknown';
      _selectedParameterDescription =
          info?['description'] ?? 'No description available.';
    });
  }

  Future<void> _initializeMapAndFetchData() async {
    // Récupère la position initiale MAIS ne centre pas encore
    bool locationObtained = await _getCurrentLocation(centerMap: false);
    LatLng initialCenter = _defaultCenter;
    double initialZoom = _defaultZoom;

    if (locationObtained && _currentPosition != null) {
      initialCenter = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
      initialZoom = 11.5; // Zoom plus proche si on a la loc
    }

    if (mounted) {
      // Définit le centre initial pour FlutterMap
      setState(() {
        _mapInitialCenter = initialCenter;
      });
      // Attend que la carte soit construite avant de la déplacer
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _mapController.move(initialCenter, initialZoom);
        }
      });
    }

    // Met à jour la polyline APRÈS avoir potentiellement obtenu la position
    await _updateUserToLastEventPolyline();

    // Attend un peu pour la visibilité et lance le fetch AQI
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) {
      await _fetchDataForSelectedParameter();
      setState(() {}); // Rebuild pour les marqueurs SQFlite
    }
  }


  Future<bool> _getCurrentLocation({bool centerMap = true}) async {
    if (!mounted) return false;
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled.')));
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied.')));
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Location permissions permanently denied.')));
      return false;
    }
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      if (!mounted) return false;

      final bool positionChanged = _currentPosition?.latitude != position.latitude ||
          _currentPosition?.longitude != position.longitude;

      setState(() {
        _currentPosition = position;
      });
      print(
          "[INFO MapPage] User location obtained: (${position.latitude}, ${position.longitude})");

      // Met à jour la polyline SI la position a changé ou si c'est le premier appel
      if (positionChanged || _userToLastEventPolyline == null) {
        await _updateUserToLastEventPolyline();
      }

      if (centerMap && _currentPosition != null) {
        _mapController.move(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          15.0, // Zoom plus proche si centré sur l'utilisateur
        );
      }
      return true;
    } catch (e) {
      print("[ERROR MapPage] Error getting location: $e");
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get current location.')));
      // Si erreur de localisation, on essaie quand même de mettre à jour la polyline
      // (au cas où on aurait déjà une position précédente et un nouvel événement)
      await _updateUserToLastEventPolyline();
      return false;
    }
  }

  // --- NOUVEAU: Fonction pour mettre à jour la polyline ---
  Future<void> _updateUserToLastEventPolyline() async {
    print("[MapPage] Attempting to update User-to-Last-Event polyline...");
    if (_currentPosition == null) {
      print("[MapPage] No current user position available.");
      if (_userToLastEventPolyline != null && mounted) {
        setState(() => _userToLastEventPolyline = null); // Efface si elle existait
      }
      return;
    }

    try {
      final Event? lastEvent = await _dbHelper.getLastEvent();
      if (lastEvent == null) {
        print("[MapPage] No valid last event found in DB.");
        if (_userToLastEventPolyline != null && mounted) {
          setState(() => _userToLastEventPolyline = null); // Efface si elle existait
        }
        return;
      }

      final LatLng userPos = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
      final LatLng eventPos = LatLng(lastEvent.latitude, lastEvent.longitude);

      // Crée la nouvelle polyline
      final newPolyline = Polyline(
        points: [userPos, eventPos],
        color: Colors.teal.withOpacity(0.8), // Couleur différente
        strokeWidth: 3.0,
        isDotted: true, // Pointillés pour la distinguer
      );

      print("[MapPage] Polyline created between $userPos and $eventPos");

      if (mounted) {
        // Met à jour l'état pour afficher la nouvelle polyline
        setState(() {
          _userToLastEventPolyline = newPolyline;
        });
      }
    } catch (e) {
      print("[ERROR MapPage] Failed to update user-to-last-event polyline: $e");
      if (_userToLastEventPolyline != null && mounted) {
        setState(() => _userToLastEventPolyline = null); // Efface en cas d'erreur
      }
    }
  }
  // --- FIN NOUVEAU ---


  Future<void> _fetchDataForSelectedParameter() async {
    // Identique
    final openAqKey = await SettingsService.getOpenAqApiKey();
    bool keyIsMissing = (openAqKey == null || openAqKey.isEmpty);
    if (mounted) {
      setState(() {
        _isApiKeyMissing = keyIsMissing;
        _isLoadingAQ = !keyIsMissing;
        _aqError = null;
        _allLatestMeasurements = [];
      });
    }
    if (keyIsMissing) {
      print(
          "[INFO MapPage] OpenAQ Key missing for current user, API call skipped.");
      return;
    }
    try {
      final globalMeasurements = await _aqService.fetchGlobalLatestMeasurements(
          parameterId: _selectedParameterId);
      if (!mounted) return;
      setState(() {
        _allLatestMeasurements = globalMeasurements;
        _isLoadingAQ = false;
      });
    } catch (e) {
      print("[ERROR MapPage] Fetch Fail for param $_selectedParameterId: $e");
      if (!mounted) return;
      setState(() {
        _aqError = e.toString().replaceFirst('Exception: ', '');
        _isLoadingAQ = false;
      });
    }
  }

  void _zoomIn() {
    // Identique
    double currentZoom = _mapController.camera.zoom;
    double targetZoom = currentZoom + 1;
    if (targetZoom > _maxZoom) targetZoom = _maxZoom;
    _mapController.move(_mapController.camera.center, targetZoom);
  }

  void _zoomOut() {
    // Identique
    double currentZoom = _mapController.camera.zoom;
    double targetZoom = currentZoom - 1;
    if (targetZoom < _minZoom) targetZoom = _minZoom;
    _mapController.move(_mapController.camera.center, targetZoom);
  }

  List<Marker> _buildAirQualityMarkers() {
    // Identique (avec les améliorations précédentes)
    List<Marker> markers = [];
    int knownParamCount = 0;
    int validValueCount = 0;

    final paramInfoSelected = PARAMETER_ID_TO_INFO[int.tryParse(_selectedParameterId)];
    if (paramInfoSelected == null) {
      print("[WARN MapPage] No info found for selected parameter ID: $_selectedParameterId");
      return markers;
    }
    final String selectedParamNameLower = paramInfoSelected['name']!;
    final String selectedParamUnit = paramInfoSelected['unit']!;

    for (var measurement in _allLatestMeasurements) {
      if (measurement.parameterId.toString() != _selectedParameterId) continue;
      knownParamCount++;
      final double value = measurement.value;
      final String description = paramInfoSelected['description'] ?? 'No description available.';

      if (value >= 0) {
        validValueCount++;
        Color markerColor = Colors.grey[400]!;
        String aqiCategory = "N/A";

        switch (selectedParamNameLower) {
          case 'pm25':
            if (value <= 12.0) { markerColor = Colors.green.shade400; aqiCategory = "Good"; }
            else if (value <= 35.4) { markerColor = Colors.yellow.shade600; aqiCategory = "Moderate"; }
            else if (value <= 55.4) { markerColor = Colors.orange.shade700; aqiCategory = "Unhealthy (Sensitive)"; }
            else if (value <= 150.4) { markerColor = Colors.red.shade400; aqiCategory = "Unhealthy"; }
            else if (value <= 250.4) { markerColor = Colors.purple.shade300; aqiCategory = "Very Unhealthy"; }
            else { markerColor = Colors.brown.shade400; aqiCategory = "Hazardous"; }
            break;
          case 'pm10':
            if (value <= 54) { markerColor = Colors.green.shade400; aqiCategory = "Good"; }
            else if (value <= 154) { markerColor = Colors.yellow.shade600; aqiCategory = "Moderate"; }
            else if (value <= 254) { markerColor = Colors.orange.shade700; aqiCategory = "Unhealthy (Sensitive)"; }
            else if (value <= 354) { markerColor = Colors.red.shade400; aqiCategory = "Unhealthy"; }
            else if (value <= 424) { markerColor = Colors.purple.shade300; aqiCategory = "Very Unhealthy"; }
            else { markerColor = Colors.brown.shade400; aqiCategory = "Hazardous"; }
            break;
          case 'o3':
            if (selectedParamUnit == 'µg/m³') {
              if (value <= 100) { markerColor = Colors.green.shade400; aqiCategory = "Good"; }
              else if (value <= 140) { markerColor = Colors.yellow.shade600; aqiCategory = "Moderate"; }
              else if (value <= 170) { markerColor = Colors.orange.shade700; aqiCategory = "Unhealthy (Sensitive)"; }
              else if (value <= 210) { markerColor = Colors.red.shade400; aqiCategory = "Unhealthy"; }
              else { markerColor = Colors.purple.shade300; aqiCategory = "Very Unhealthy"; }
            } else if (selectedParamUnit == 'ppm') {
              if (value <= 0.054) { markerColor = Colors.green.shade400; aqiCategory = "Good"; }
              else if (value <= 0.070) { markerColor = Colors.yellow.shade600; aqiCategory = "Moderate"; }
              else if (value <= 0.085) { markerColor = Colors.orange.shade700; aqiCategory = "Unhealthy (Sensitive)"; }
              else if (value <= 0.105) { markerColor = Colors.red.shade400; aqiCategory = "Unhealthy"; }
              else if (value <= 0.200) { markerColor = Colors.purple.shade300; aqiCategory = "Very Unhealthy"; }
              else { markerColor = Colors.brown.shade400; aqiCategory = "Hazardous"; }
            } else { markerColor = Colors.blueGrey.shade300; aqiCategory = "Info (Unknown Unit)"; }
            break;
          case 'no2':
            if (selectedParamUnit == 'µg/m³') {
              if (value <= 50) { markerColor = Colors.green.shade400; aqiCategory = "Good"; }
              else if (value <= 100) { markerColor = Colors.yellow.shade600; aqiCategory = "Moderate"; }
              else if (value <= 200) { markerColor = Colors.orange.shade700; aqiCategory = "Unhealthy (Sensitive)"; }
              else if (value <= 400) { markerColor = Colors.red.shade400; aqiCategory = "Unhealthy"; }
              else { markerColor = Colors.purple.shade300; aqiCategory = "Very Unhealthy"; }
            } else if (selectedParamUnit == 'ppm') {
              if (value <= 0.053) { markerColor = Colors.green.shade400; aqiCategory = "Good"; }
              else if (value <= 0.100) { markerColor = Colors.yellow.shade600; aqiCategory = "Moderate"; }
              else if (value <= 0.360) { markerColor = Colors.orange.shade700; aqiCategory = "Unhealthy (Sensitive)"; }
              else if (value <= 0.649) { markerColor = Colors.red.shade400; aqiCategory = "Unhealthy"; }
              else if (value <= 1.249) { markerColor = Colors.purple.shade300; aqiCategory = "Very Unhealthy"; }
              else { markerColor = Colors.brown.shade400; aqiCategory = "Hazardous"; }
            } else { markerColor = Colors.blueGrey.shade300; aqiCategory = "Info (Unknown Unit)"; }
            break;
          case 'co': markerColor = Colors.teal.shade300; aqiCategory = "Info"; break;
          case 'so2': markerColor = Colors.indigo.shade200; aqiCategory = "Info"; break;
          case 'bc': markerColor = Colors.black54; aqiCategory = "Info"; break;
          case 'pm1': markerColor = Colors.lime.shade600; aqiCategory = "Info"; break;
          case 'relativehumidity': case 'temperature': case 'um003': case 'nox': case 'no':
          markerColor = Colors.cyan.shade300; aqiCategory = "Info"; break;
          default: markerColor = Colors.grey.shade400; aqiCategory = "Info"; break;
        }

        markers.add(Marker(
          width: 38.0, height: 38.0, point: measurement.coordinates,
          child: GestureDetector(
            onTap: () { /* ... AlertDialog identique ... */
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text("Location ID: ${measurement.locationId}",
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold)),
                  content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              "${_selectedParameterName.toUpperCase()}: ${value.toStringAsFixed(1)} $selectedParamUnit",
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          Text("Status: $aqiCategory",
                              style: TextStyle(
                                  color: markerColor, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(description,
                              style: Theme.of(ctx).textTheme.bodySmall),
                          const Divider(height: 15, thickness: 1),
                          Text("Sensor ID: ${measurement.sensorId}"),
                          Text(
                              "Updated: ${DateFormat.yMd().add_jm().format(measurement.datetimeUtc.toLocal())}"),
                        ],
                      )),
                  actions: [ TextButton( child: const Text("Close"), onPressed: () => Navigator.of(ctx).pop()) ],
                  shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(15)),
                ),
              );
            },
            child: Tooltip(
              message: "Loc: ${measurement.locationId}\n${_selectedParameterName.toUpperCase()}: ${value.toStringAsFixed(1)} $selectedParamUnit ($aqiCategory)",
              child: Container( /* ... Container identique ... */
                decoration: BoxDecoration(
                    color: markerColor.withOpacity(0.8),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black54, width: 1),
                    boxShadow: const [ BoxShadow( color: Colors.black26, blurRadius: 3, offset: Offset(1, 1)) ]
                ),
                child: Center( child: Text( value.round().toString(),
                  style: TextStyle(
                      color: markerColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white,
                      fontSize: 11, fontWeight: FontWeight.bold),
                )),
              ),
            ),
          ),
        ));
      }
    }
    print( "[DEBUG MapPage] Built ${markers.length} AQI markers for $_selectedParameterName ($knownParamCount matched ID, $validValueCount with valid value >= 0). Total fetched: ${_allLatestMeasurements.length}.");
    return markers;
  }


  Future<List<Marker>> _buildSqliteEventMarkers() async {
    // Identique (avec les améliorations précédentes)
    List<Marker> markers = [];
    try {
      final List<Event> events = await _dbHelper.getAllEvents();
      print("[MapPage] Found ${events.length} events in SQFlite DB.");
      for (var event in events) {
        if ((event.latitude != 0.0 || event.longitude != 0.0) &&
            event.latitude.abs() <= 90 && event.longitude.abs() <= 180)
        {
          final LatLng point = LatLng(event.latitude, event.longitude);
          final IconData eventIcon = _getIconForType(event.type);
          final Color iconColor = _getColorForType(event.type, Theme.of(context));
          markers.add(Marker(
            width: 30.0, height: 30.0, point: point,
            child: Tooltip(
              message: "${event.type}\n${event.description.substring(0, (event.description.length > 30 ? 30 : event.description.length))}...",
              child: GestureDetector(
                onTap: () { /* ... AlertDialog identique ... */
                  DateTime dt = DateTime.now().toLocal();
                  try { dt = DateTime.parse(event.timestamp).toLocal(); } catch (e) { print("Error parsing event timestamp for dialog: ${event.timestamp}"); }
                  final formattedDate = DateFormat.yMd().add_jm().format(dt);
                  showDialog( context: context, builder: (ctx) => AlertDialog(
                    title: Row( children: [ Icon(eventIcon, color: iconColor), const SizedBox(width: 10), Text(event.type), ], ),
                    content: Text( "Reported: $formattedDate\nDetails: ${event.description}"),
                    actions: [ TextButton( onPressed: () => Navigator.of(ctx).pop(), child: const Text("OK")) ],
                    shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(15)),
                  ));
                },
                child: Container( /* ... Container identique ... */
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.75),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black38, width: 1),
                      boxShadow: const [ BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(1,1)) ]
                  ),
                  child: Icon(eventIcon, color: iconColor, size: 22.0, ),
                ),
              ),
            ),
          ));
        } else {
          print("[MapPage] Skipping event ID ${event.id} due to invalid/default coordinates (${event.latitude}, ${event.longitude}).");
        }
      }
    } catch (e) {
      print("[ERROR MapPage] Failed to build SQLite markers: $e");
      ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('Error loading reported events: $e'), backgroundColor: Colors.red));
    }
    print("[MapPage] Built ${markers.length} markers from SQFlite.");
    return markers;
  }

  Future<void> _launchUrl(String urlString) async {
    // Identique
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $urlString';
      }
    } catch (e) {
      print('[ERROR MapPage] Could not launch URL: $urlString. Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open link: $urlString')));
      }
    }
  }

  IconData _getIconForType(String? type) {
    // Identique
    switch (type) {
      case 'Flood': return Icons.water_drop;
      case 'Drought': return Icons.local_fire_department_outlined;
      case 'Fallen Trees': return Icons.park_outlined;
      case 'Heavy Hail': return Icons.grain;
      case 'Heavy Rain': return Icons.water_drop_outlined;
      case 'Heavy Snow': return Icons.ac_unit;
      case 'Other (specify in position)': return Icons.help_outline;
      default: return Icons.report_problem_outlined;
    }
  }

  Color _getColorForType(String? type, ThemeData theme) {
    // Identique
    switch (type) {
      case 'Flood': return Colors.blue.shade700;
      case 'Drought': return Colors.orange.shade800;
      case 'Fallen Trees': return Colors.green.shade800;
      case 'Heavy Hail': return Colors.lightBlue.shade300;
      case 'Heavy Rain': return Colors.blue.shade400;
      case 'Heavy Snow': return Colors.cyan.shade200;
      case 'Other (specify in position)': return Colors.grey.shade600;
      default: return theme.colorScheme.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final LatLng centerForMapOptions = _mapInitialCenter ?? _defaultCenter;
    final double zoomForMapOptions = (_mapInitialCenter != null && _mapInitialCenter != _defaultCenter)
        ? 11.5 : _defaultZoom;

    return Scaffold(
      appBar: AppBar( /* ... AppBar identique ... */
        title: Text("AQ Map - $_selectedParameterName"),
        actions: [
          PopupMenuButton<String>( icon: const Icon(Icons.filter_list), tooltip: "Select Pollutant / Parameter",
            onSelected: (String result) { if (_selectedParameterId != result) { _updateSelectedParameterInfo(result); _fetchDataForSelectedParameter(); } },
            itemBuilder: (BuildContext context) => _availableParameters.entries .map((entry) => PopupMenuItem<String>( value: entry.key, child: Text(entry.value), )).toList(),
          ),
          IconButton( icon: const Icon(Icons.refresh), tooltip: 'Refresh Data for $_selectedParameterName', onPressed: _isLoadingAQ ? null : _fetchDataForSelectedParameter, ),
        ],
      ),
      drawer: const CustomDrawer(),
      body: Stack(
        children: [
          // Carte
          if (_mapInitialCenter != null)
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: centerForMapOptions, initialZoom: zoomForMapOptions,
                minZoom: _minZoom, maxZoom: _maxZoom, initialRotation: 0.0,
                interactionOptions: const InteractionOptions( flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom | InteractiveFlag.doubleTapZoom, ),
              ),
              children: [
                // Fond de carte
                TileLayer( urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png", userAgentPackageName: 'com.example.greenwatch', ),

                // --- NOUVEAU: Polyline Dynamique ---
                // Affiche la polyline seulement si elle a été calculée
                if (_userToLastEventPolyline != null)
                  PolylineLayer(
                    polylines: [_userToLastEventPolyline!], // Utilise la variable d'état
                  ),
                // --- FIN NOUVEAU ---

                // Marqueur Utilisateur
                if (_currentPosition != null)
                  MarkerLayer( markers: [
                    Marker( width: 40.0, height: 40.0, point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                      child: Tooltip( message: "Your Location",
                        child: Icon( Icons.person_pin_circle, color: Theme.of(context).colorScheme.primary, size: 35.0,
                          shadows: const [ Shadow( color: Colors.black54, blurRadius: 5, offset: Offset(1, 2)) ],
                        ),
                      ),
                      alignment: Alignment.topCenter,
                    ),
                  ],
                  ),

                // Marqueurs Qualité de l'Air
                if (!_isApiKeyMissing && _aqError == null)
                  MarkerLayer(markers: _buildAirQualityMarkers()),

                // Marqueurs SQFlite
                FutureBuilder<List<Marker>>(
                  future: _buildSqliteEventMarkers(),
                  builder: (context, snapshot) { /* ... FutureBuilder identique ... */
                    if (snapshot.connectionState == ConnectionState.waiting) { return const SizedBox.shrink(); }
                    else if (snapshot.hasError) { print("[MapPage] Error in FutureBuilder for SQLite markers: ${snapshot.error}"); return const SizedBox.shrink(); }
                    else if (snapshot.hasData && snapshot.data!.isNotEmpty) { print("[MapPage] FutureBuilder displaying ${snapshot.data!.length} SQFlite markers."); return MarkerLayer(markers: snapshot.data!); }
                    else { print("[MapPage] FutureBuilder for SQFlite: No data or empty list."); return const SizedBox.shrink(); }
                  },
                ),
              ],
            )
          else // Indicateur pendant chargement initial
            const Center(child: CircularProgressIndicator()),

          // Panneau description polluant (Gradient en haut)
          // Identique
          Positioned( top: 0, left: 0, right: 0,
            child: IgnorePointer( child: Container(
              decoration: BoxDecoration( gradient: LinearGradient( begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [ theme.colorScheme.surface.withOpacity(0.95), theme.colorScheme.surface.withOpacity(0.75), theme.colorScheme.surface.withOpacity(0.0), ],
                  stops: const [ 0.0, 0.7, 1.0 ])),
              padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 16.0),
              child: Text( _selectedParameterDescription, style: theme.textTheme.bodySmall?.copyWith( color: theme.colorScheme.onSurface.withOpacity(0.9)),
                textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
              ),
            )),
          ),

          // Indicateurs & Erreurs (en bas)
          // Identique (avec les améliorations précédentes)
          if (_mapInitialCenter != null) ...[
            if (_isLoadingAQ) Positioned( bottom: 80, left: 0, right: 0, child: Center( child: Container( padding: const EdgeInsets.symmetric( horizontal: 15, vertical: 8), decoration: BoxDecoration( color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(20)), child: const Row( mainAxisSize: MainAxisSize.min, children: [ SizedBox( height: 15, width: 15, child: CircularProgressIndicator( strokeWidth: 2, color: Colors.white)), SizedBox(width: 10), Text('Loading Air Quality Data...', style: TextStyle(color: Colors.white, fontSize: 12)) ])))),
            if (_aqError != null && !_isApiKeyMissing) Positioned( bottom: 80, left: 10, right: 10, child: Container( padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration( color: Colors.redAccent.withOpacity(0.9), borderRadius: BorderRadius.circular(8), boxShadow: const [ BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0,2)) ] ), child: Text( "Air Quality Data Error: $_aqError", style: const TextStyle(color: Colors.white, fontSize: 12), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, ))),
            if (_isApiKeyMissing) Positioned( bottom: 80, left: 10, right: 10, child: Container( padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10), decoration: BoxDecoration( color: Colors.orange.shade800.withOpacity(0.9), borderRadius: BorderRadius.circular(8), boxShadow: const [ BoxShadow( color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)) ]), child: RichText( textAlign: TextAlign.center, text: TextSpan( style: TextStyle( color: Colors.white, fontSize: 13, fontFamily: Theme.of(context) .textTheme .bodyMedium ?.fontFamily), children: [ const TextSpan(text: 'OpenAQ API Key needed in '), TextSpan( text: 'Settings', style: const TextStyle( fontWeight: FontWeight.bold, decoration: TextDecoration.underline), recognizer: TapGestureRecognizer() ..onTap = () => Navigator.pushNamed( context, '/settings') .then((_) => _fetchDataForSelectedParameter()), ), const TextSpan(text: ' to show Air Quality data.'), ]), ), ), ),
          ],

          // Boutons de contrôle (Zoom et MyLocation)
          // Identique
          Positioned( bottom: 20, right: 10,
            child: Column( mainAxisSize: MainAxisSize.min, children: <Widget>[
              FloatingActionButton.small( heroTag: "btnZoomIn", onPressed: _zoomIn, tooltip: 'Zoom In', child: const Icon(Icons.add)),
              const SizedBox(height: 8),
              FloatingActionButton.small( heroTag: "btnZoomOut", onPressed: _zoomOut, tooltip: 'Zoom Out', child: const Icon(Icons.remove)),
            ],
            ),
          ),
          Positioned( bottom: 20, left: 10,
            child: FloatingActionButton( heroTag: "btnMyLocation", onPressed: () { _getCurrentLocation(centerMap: true); }, tooltip: 'My Location', child: const Icon(Icons.my_location), ),
          ),
        ],
      ),
    );
  }
}