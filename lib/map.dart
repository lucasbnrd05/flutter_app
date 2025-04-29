// lib/map.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;

// Services et Modèles
import '../services/air_quality_service.dart';
import '../models/latest_measurement.dart'; // Utilise le modèle simple
import '../services/settings_service.dart';
import '../ux_unit/custom_drawer.dart'; // Vérifie le chemin

// Classe pour calculer la distance (optionnelle)
// class DistanceCalculator { static const Distance _distance = Distance(); static double distanceInKm(LatLng pos1, LatLng pos2) => _distance.as(LengthUnit.Kilometer, pos1, pos2); }

class MapPage extends StatefulWidget { const MapPage({super.key}); @override State<MapPage> createState() => _MapPageState(); }

class _MapPageState extends State<MapPage> {
  Position? _currentPosition;
  final MapController _mapController = MapController();
  final double _minZoom = 2.0; final double _maxZoom = 18.0;
  final LatLng _defaultCenter = const LatLng(20, -20); // Centre global
  final double _defaultZoom = 3.0; // Zoom global

  // Centre et Rayon pour le FILTRE GEOGRAPHIQUE côté client (Optionnel, décommenter si besoin)
  // final LatLng _aqiFilterCenter = const LatLng(40.4168, -3.7038); // Madrid
  // final double _filterRadiusKm = 500; // Rayon large

  final AirQualityService _aqService = AirQualityService();
  List<LatestMeasurementResult> _allLatestMeasurements = []; // Stocke les mesures globales
  bool _isLoadingAQ = false;
  String? _aqError;
  bool _isApiKeyMissing = false;

  // Pas besoin de _selectedMeasurement pour AlertDialog

  // *** CHANGEMENT : ID par défaut = PM10 (ID 1) ***
  String _selectedParameterId = '1';
  String _selectedParameterName = 'PM10'; // Sera mis à jour dans initState

  // *** Liste filtrée SANS PM2.5, O3 µg/m³ pour le menu ***
  final Map<String, String> _availableParameters = {
    '1': 'PM10 (µg/m³)',       // ID 1 - DEFAUT
    // '3': 'O₃ (µg/m³)',      // Exclu
    '4': 'CO (µg/m³)',         // ID 4
    '5': 'NO₂ (µg/m³)',        // ID 5
    '6': 'SO₂ (µg/m³)',        // ID 6
    '19': 'PM1 (µg/m³)',       // ID 19
    '98': 'Relative Humidity (%)', // ID 98
    '100': 'Temperature (°C)',   // ID 100
    '125': 'UM003 (particles/cm³)', // ID 125
    '19843': 'NO (µg/m³)',      // ID 19843
    // Exclus : '2': 'PM2.5 (µg/m³)',
  };

  LatLng? _mapInitialCenter;
  String _selectedParameterDescription = ''; // Pour le popup

  @override
  void initState() {
    super.initState();
    _updateSelectedParameterInfo(_selectedParameterId);
    _initializeMapAndFetchData();
  }

  // Helper pour obtenir le nom court ET la description à partir de l'ID
  void _updateSelectedParameterInfo(String id) {
    final info = PARAMETER_ID_TO_INFO[int.tryParse(id)];
    setState(() {
      _selectedParameterId = id;
      _selectedParameterName = info?['name']?.toUpperCase() ?? 'Unknown';
      _selectedParameterDescription = info?['description'] ?? 'No description available.';
    });
  }

  Future<void> _initializeMapAndFetchData() async {
    bool locationObtained = await _getCurrentLocation(centerMap: false);
    LatLng initialCenter = _defaultCenter;
    double initialZoom = _defaultZoom;
    if (locationObtained && _currentPosition != null) { initialCenter = LatLng(_currentPosition!.latitude, _currentPosition!.longitude); initialZoom = 11.5; }
    if (mounted) { WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) { setState(() { _mapInitialCenter = initialCenter; }); } }); }
    await Future.delayed(const Duration(milliseconds: 150));
    if (mounted) { await _fetchDataForSelectedParameter(); }
  }

  Future<bool> _getCurrentLocation({bool centerMap = true}) async {
    if (!mounted) return false; bool serviceEnabled; LocationPermission permission; serviceEnabled = await Geolocator.isLocationServiceEnabled(); if (!serviceEnabled) { if (!mounted) return false; ScaffoldMessenger.of(context).showSnackBar(const SnackBar( content: Text('Location services are disabled.'))); return false; } permission = await Geolocator.checkPermission(); if (permission == LocationPermission.denied) { permission = await Geolocator.requestPermission(); if (permission == LocationPermission.denied) { if (!mounted) return false; ScaffoldMessenger.of(context).showSnackBar(const SnackBar( content: Text('Location permissions are denied.'))); return false; } } if (permission == LocationPermission.deniedForever) { if (!mounted) return false; ScaffoldMessenger.of(context).showSnackBar(const SnackBar( content: Text( 'Location permissions permanently denied.'))); return false; } try { Position position = await Geolocator.getCurrentPosition( desiredAccuracy: LocationAccuracy.high); if (!mounted) return false; setState(() { _currentPosition = position; }); print("[INFO MapPage] User location obtained: (${position.latitude}, ${position.longitude})");
    if (centerMap && _currentPosition != null) { _mapController.move( LatLng(_currentPosition!.latitude, _currentPosition!.longitude), 15.0, ); } return true;
    } catch (e) { print("[ERROR MapPage] Error getting location: $e"); if (!mounted) return false; ScaffoldMessenger.of(context).showSnackBar(const SnackBar( content: Text('Could not get current location.'))); return false; }
  }

  // Fonction qui appelle le service pour le paramètre sélectionné
  Future<void> _fetchDataForSelectedParameter() async {
    final openAqKey = await SettingsService.getOpenAqApiKey(); bool keyIsMissing = (openAqKey == null || openAqKey.isEmpty);
    if (mounted) { setState(() { _isApiKeyMissing = keyIsMissing; _isLoadingAQ = !keyIsMissing; _aqError = null; _allLatestMeasurements = []; }); }
    if (keyIsMissing) { print("[INFO MapPage] OpenAQ Key missing, API call skipped."); return; }
    try { final globalMeasurements = await _aqService.fetchGlobalLatestMeasurements(parameterId: _selectedParameterId); if (!mounted) return; setState(() { _allLatestMeasurements = globalMeasurements; _isLoadingAQ = false; }); }
    catch (e) { print("[ERROR MapPage] Fetch Fail for param $_selectedParameterId: $e"); if (!mounted) return; setState(() { _aqError = e.toString().replaceFirst('Exception: ', ''); _isLoadingAQ = false; }); }
  }

  void _zoomIn() { double currentZoom = _mapController.camera.zoom; double targetZoom = currentZoom + 1; if (targetZoom > _maxZoom) targetZoom = _maxZoom; _mapController.move(_mapController.camera.center, targetZoom); }
  void _zoomOut() { double currentZoom = _mapController.camera.zoom; double targetZoom = currentZoom - 1; if (targetZoom < _minZoom) targetZoom = _minZoom; _mapController.move(_mapController.camera.center, targetZoom); }

  // Construit les marqueurs SANS filtre géographique client
  List<Marker> _buildAirQualityMarkers() {
    List<Marker> markers = [];
    int knownParamCount = 0;
    int validValueCount = 0;

    for (var measurement in _allLatestMeasurements) {
      // Déduire le paramètre et l'unité
      final paramInfo = PARAMETER_ID_TO_INFO[measurement.parameterId];
      if (paramInfo == null) { continue; }
      // Vérifie si le paramètre correspond
      if (measurement.parameterId.toString() != _selectedParameterId) continue;
      knownParamCount++;

      final String param = paramInfo['name']!;
      final String unit = paramInfo['unit']!;
      final double value = measurement.value;
      final String description = paramInfo['description'] ?? 'No description available.'; // Récupère la description

      if (value >= 0) {
        validValueCount++;
        Color markerColor = Colors.grey[400]!; String aqiCategory = "N/A";
        /* ... logique couleur ... */ if (param == 'pm25') { if (value <= 12.0) { markerColor = Colors.green.shade400; aqiCategory = "Good"; } else if (value <= 35.4) { markerColor = Colors.yellow.shade600; aqiCategory = "Moderate"; } else if (value <= 55.4) { markerColor = Colors.orange.shade700; aqiCategory = "Unhealthy (Sensitive)"; } else if (value <= 150.4) { markerColor = Colors.red.shade400; aqiCategory = "Unhealthy"; } else if (value <= 250.4) { markerColor = Colors.purple.shade300; aqiCategory = "Very Unhealthy"; } else { markerColor = Colors.brown.shade400; aqiCategory = "Hazardous"; } } else if (param == 'pm10') { if (value <= 54) { markerColor = Colors.green.shade400; aqiCategory = "Good"; } else if (value <= 154) { markerColor = Colors.yellow.shade600; aqiCategory = "Moderate"; } else if (value <= 254) { markerColor = Colors.orange.shade700; aqiCategory = "Unhealthy (Sensitive)"; } else if (value <= 354) { markerColor = Colors.red.shade400; aqiCategory = "Unhealthy"; } else if (value <= 424) { markerColor = Colors.purple.shade300; aqiCategory = "Very Unhealthy"; } else { markerColor = Colors.brown.shade400; aqiCategory = "Hazardous"; } } else if (param == 'o3') { if (unit == 'µg/m³') { if (value <= 100) { markerColor = Colors.green.shade400; aqiCategory = "Good"; } else if (value <= 160) { markerColor = Colors.yellow.shade600; aqiCategory = "Moderate"; } else if (value <= 214) { markerColor = Colors.orange.shade700; aqiCategory = "Unhealthy (Sensitive)"; } else if (value <= 267) { markerColor = Colors.red.shade400; aqiCategory = "Unhealthy"; } else { markerColor = Colors.purple.shade300; aqiCategory = "Very Unhealthy"; } } else { markerColor = Colors.blueGrey.shade300; aqiCategory = "Info (ppm)";} } else if (param == 'no2') { if (unit == 'µg/m³') { if (value <= 100) { markerColor = Colors.green.shade400; aqiCategory = "Good"; } else if (value <= 200) { markerColor = Colors.yellow.shade600; aqiCategory = "Moderate"; } else if (value <= 400) { markerColor = Colors.orange.shade700; aqiCategory = "Unhealthy (Sensitive)"; } else { markerColor = Colors.red.shade400; aqiCategory = "Unhealthy"; } } else { markerColor = Colors.blueGrey.shade300; aqiCategory = "Info (ppm)";} } else { markerColor = Colors.cyan.shade300; aqiCategory = "Info"; }

        markers.add(Marker( width: 38.0, height: 38.0, point: measurement.coordinates,
          child: GestureDetector(
            // *** Rétablit showDialog AVEC description ***
            onTap: () {
              showDialog( context: context, builder: (ctx) => AlertDialog(
                title: Text("Location ID: ${measurement.locationId}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                content: SingleChildScrollView( child: Column( mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("${param.toUpperCase()}: ${value.toStringAsFixed(1)} $unit", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text("Status: $aqiCategory", style: TextStyle(color: markerColor, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  // *** AFFICHE LA DESCRIPTION ICI ***
                  Text(description, style: Theme.of(ctx).textTheme.bodySmall),
                  const Divider(height: 15, thickness: 1),
                  Text("Sensor ID: ${measurement.sensorId}"),
                  Text("Updated: ${DateFormat.yMd().add_jm().format(measurement.datetimeUtc.toLocal())}"),
                ], ) ),
                actions: [TextButton(child: const Text("Close"), onPressed: () => Navigator.of(ctx).pop())],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              );
            }, // Fin onTap
            child: Tooltip( message: "Loc: ${measurement.locationId}\n${param.toUpperCase()}: ${value.toStringAsFixed(1)} $unit ($aqiCategory)",
              child: Container( decoration: BoxDecoration( color: markerColor.withOpacity(0.8), shape: BoxShape.circle, border: Border.all(color: Colors.black54, width: 1), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(1,1))] ), child: Center( child: Text( value.round().toString(), style: TextStyle( color: markerColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white, fontSize: 11, fontWeight: FontWeight.bold), ) ), ),
            ),
          ),
        ));
      } // Fin if value >= 0
    }
    print("[DEBUG MapPage] Built ${markers.length} markers for $_selectedParameterName ($knownParamCount known params, $validValueCount with valid value). Total fetched: ${_allLatestMeasurements.length}.");
    return markers;
  }

  // Fonction pour parser Lat/Lon depuis DataPage
  LatLng? _parseLatLngFromString(String positionString) { try { final regex = RegExp(r"Lat:\s*(-?\d+\.?\d*),\s*Lon:\s*(-?\d+\.?\d*)"); final match = regex.firstMatch(positionString); if (match != null && match.groupCount == 2) { final lat = double.tryParse(match.group(1)!); final lon = double.tryParse(match.group(2)!); if (lat != null && lon != null) { return LatLng(lat, lon); } } } catch (e) { print("[ERROR MapPage] Error parsing position string '$positionString': $e"); } return null; }

  // Fonction pour construire les marqueurs Hive
  List<Marker> _buildHiveEventMarkers(List<Map> eventData) { List<Marker> markers = []; for (var eventMap in eventData) { final event = Map<String, dynamic>.from(eventMap); final positionString = event['position'] as String? ?? ''; final type = event['type'] as String? ?? 'Unknown'; final timestamp = event['timestamp'] as String? ?? ''; LatLng? point = _parseLatLngFromString(positionString); if (point != null) { IconData eventIcon = Icons.report_problem_outlined; Color iconColor = Colors.teal; switch (type) { case 'Flood': eventIcon = Icons.water_drop; iconColor = Colors.blue.shade700; break; case 'Drought': eventIcon = Icons.local_fire_department_outlined; iconColor = Colors.orange.shade800; break; case 'Fallen Trees': eventIcon = Icons.park_outlined; iconColor = Colors.green.shade800; break; case 'Heavy Hail': eventIcon = Icons.grain; iconColor = Colors.lightBlue.shade300; break; case 'Heavy Rain': eventIcon = Icons.water_drop_outlined; iconColor = Colors.blue.shade400; break; case 'Heavy Snow': eventIcon = Icons.ac_unit; iconColor = Colors.cyan.shade200; break; case 'Other (specify in position)': eventIcon = Icons.help_outline; iconColor = Colors.grey.shade600; break; } markers.add(Marker( width: 30.0, height: 30.0, point: point, child: Tooltip( message: "$type\n${positionString.split(',').first}...", child: GestureDetector( onTap: () { final dt = DateTime.tryParse(timestamp)?.toLocal() ?? DateTime.now(); showDialog(context: context, builder: (ctx) => AlertDialog( title: Text(type), content: Text("Reported: ${DateFormat.yMd().add_jm().format(dt)}\nDetails: $positionString"), actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("OK"))], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), )); }, child: Container( padding: const EdgeInsets.all(2), decoration: BoxDecoration(color: Colors.white.withOpacity(0.7), shape: BoxShape.circle), child: Icon(eventIcon, color: iconColor, size: 24.0, shadows: const [Shadow(color: Colors.black26, blurRadius: 2)]), ), ), ), )); } } return markers; }

  // Helper pour ouvrir les URL
  Future<void> _launchUrl(String urlString) async { final Uri url = Uri.parse(urlString); try { if (!await launchUrl(url, mode: LaunchMode.externalApplication)) throw 'Could not launch $urlString'; } catch (e) { print('[ERROR MapPage] Could not launch URL: $urlString. Error: $e'); if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open link: $urlString'))); } }

  // *** SUPPRESSION de _buildInfoPanel() ***

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final LatLng centerForMapOptions = _mapInitialCenter ?? _defaultCenter;
    final double zoomForMapOptions = (_mapInitialCenter == _defaultCenter || _mapInitialCenter == null) ? _defaultZoom : 11.5;

    return Scaffold(
      appBar: AppBar(
        title: Text("AQ Map - $_selectedParameterName"), // Titre dynamique
        actions: [
          // *** Menu utilise la map _availableParameters filtrée ***
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list), tooltip: "Select Pollutant",
            onSelected: (String result) {
              if (_selectedParameterId != result) {
                _updateSelectedParameterInfo(result); // Met à jour ID, nom et description
                setState(() { _aqError = null; _allLatestMeasurements = []; _isLoadingAQ = true; });
                _fetchDataForSelectedParameter(); // Appelle la bonne fonction
              }
            },
            itemBuilder: (BuildContext context) => _availableParameters.entries // Utilise la map filtrée
                .map((entry) => PopupMenuItem<String>( value: entry.key, child: Text(entry.value), )).toList(),
          ),
          IconButton( icon: const Icon(Icons.refresh), tooltip: 'Refresh Data for $_selectedParameterName', onPressed: _fetchDataForSelectedParameter ),
        ],
      ),
      drawer: const CustomDrawer(),
      body: Stack(
        children: [
          // Carte affichée si centre initial prêt
          if (_mapInitialCenter != null)
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: centerForMapOptions, initialZoom: zoomForMapOptions,
                minZoom: _minZoom, maxZoom: _maxZoom,
                // Pas de maxBounds pour voir le monde
                initialRotation: 0.0,
                interactionOptions: const InteractionOptions( flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom | InteractiveFlag.doubleTapZoom, ),
                // Pas de onTap global pour fermer le panneau
              ),
              children: [
                TileLayer( urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", subdomains: const ['a', 'b', 'c'], ),
                // Marqueur Utilisateur
                if (_currentPosition != null) MarkerLayer( markers: [ Marker( width: 40.0, height: 40.0, point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude), child: Image.asset('assets/user_marker.png', errorBuilder: (c,e,s) => const Icon(Icons.person_pin_circle, color: Colors.red, size: 30)), alignment: Alignment.topCenter, ), ], ),
                // Marqueurs OpenAQ (sans filtre géo client)
                if (!_isApiKeyMissing && _aqError == null) MarkerLayer(markers: _buildAirQualityMarkers()),
                // Marqueurs Hive
                if (Hive.isBoxOpen('precipitationBox')) ValueListenableBuilder<Box<Map>>( valueListenable: Hive.box<Map>('precipitationBox').listenable(), builder: (context, box, _) { final events = List<Map>.from(box.values.toList()); return MarkerLayer(markers: _buildHiveEventMarkers(events)); } ) else Padding( padding: const EdgeInsets.all(20.0), child: Center(child: Text("Event data unavailable (Box not open)", style: TextStyle(color: Colors.orange.shade800))),),
              ],
            )
          // Indicateur de chargement initial
          else if (!_isApiKeyMissing)
            const Center(child: CircularProgressIndicator()),

          // *** Panneau de description du polluant en HAUT ***
          Positioned(
            top: 0, left: 0, right: 0,
            child: IgnorePointer( // Pour ne pas bloquer la carte
                child: Container(
                  decoration: BoxDecoration( gradient: LinearGradient( begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [ theme.colorScheme.surface.withOpacity(0.9), theme.colorScheme.surface.withOpacity(0.7), theme.colorScheme.surface.withOpacity(0.0), ], stops: const [0.0, 0.8, 1.0] ) ),
                  padding: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 12.0),
                  child: Text( _selectedParameterDescription, style: theme.textTheme.bodySmall?.copyWith( color: theme.colorScheme.onSurface.withOpacity(0.9) ), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, ),
                )
            ),
          ),
          // *** FIN Panneau Description ***


          // Indicateurs & Erreurs/Info Clé Manquante (Positionnés en BAS)
          if (_mapInitialCenter != null) ...[
            if (_isLoadingAQ) Positioned(bottom: 80, left: 10, right: 10, child: Center(child: Container( padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)), child: const Row(mainAxisSize: MainAxisSize.min, children: [SizedBox(height: 15, width: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)), SizedBox(width: 10), Text('Loading AQ Data...', style: TextStyle(color: Colors.white))])))),
            if (_aqError != null && !_isApiKeyMissing) Positioned(bottom: 80, left: 10, right: 10, child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.red.withOpacity(0.85), borderRadius: BorderRadius.circular(8)), child: Text("Data Error: $_aqError", style: const TextStyle(color: Colors.white), textAlign: TextAlign.center,))),
            if (_isApiKeyMissing) Positioned( bottom: 80, left: 10, right: 10, child: Container( padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10), decoration: BoxDecoration( color: Colors.orange.shade700.withOpacity(0.9), borderRadius: BorderRadius.circular(8), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))] ), child: RichText( textAlign: TextAlign.center, text: TextSpan( style: TextStyle(color: Colors.white, fontSize: 13, fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily), children: [ const TextSpan(text: 'OpenAQ API Key needed in '), TextSpan( text: 'Settings', style: const TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline), recognizer: TapGestureRecognizer()..onTap = () => Navigator.pushNamed(context, '/settings').then((_) => _fetchDataForSelectedParameter()), ), const TextSpan(text: ' to show Air Quality data.'), ] ), ), ), ),
          ],
          // Positionnement des Boutons
          Positioned( bottom: 20, right: 10, child: Column( mainAxisSize: MainAxisSize.min, children: <Widget>[ FloatingActionButton.small( heroTag: "btnZoomIn", onPressed: _zoomIn, tooltip: 'Zoom In', child: const Icon(Icons.add)), const SizedBox(height: 8), FloatingActionButton.small( heroTag: "btnZoomOut", onPressed: _zoomOut, tooltip: 'Zoom Out', child: const Icon(Icons.remove)), ], ), ),
          Positioned( bottom: 20, left: 10, child: FloatingActionButton( heroTag: "btnMyLocation", onPressed: () { _getCurrentLocation(centerMap: true); }, tooltip: 'My Location', child: const Icon(Icons.my_location), ), ),
        ],
      ),
    );
  }
}