// lib/map.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:intl/intl.dart';
// Retire les imports Hive
// import 'package:hive/hive.dart';
// import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
// Retire import 'dart:math' car plus utilisé

// Services et Modèles
import '../services/air_quality_service.dart';
import '../models/latest_measurement.dart';
import '../services/settings_service.dart';
import '../ux_unit/custom_drawer.dart';
// Importe le helper SQFlite et le modèle Event
import '../services/database_helper.dart';
import '../models/event.dart';

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
  final LatLng _defaultCenter = const LatLng(20, -20);
  final double _defaultZoom = 3.0;

  final AirQualityService _aqService = AirQualityService();
  List<LatestMeasurementResult> _allLatestMeasurements = [];
  bool _isLoadingAQ = false;
  String? _aqError;
  bool _isApiKeyMissing = false;

  String _selectedParameterId = '1';
  String _selectedParameterName = 'PM10';
  String _selectedParameterDescription = '';

  final Map<String, String> _availableParameters = {
    '1': 'PM10 (µg/m³)', '4': 'CO (µg/m³)', '5': 'NO₂ (µg/m³)',
    '6': 'SO₂ (µg/m³)', '19': 'PM1 (µg/m³)', '98': 'Relative Humidity (%)',
    '100': 'Temperature (°C)', '125': 'UM003 (particles/cm³)', '19843': 'NO (µg/m³)',
  };

  LatLng? _mapInitialCenter;
  // Référence au helper de BDD
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _updateSelectedParameterInfo(_selectedParameterId);
    _initializeMapAndFetchData();
    // Pas besoin de charger les events ici, FutureBuilder s'en chargera
  }

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
    if (locationObtained && _currentPosition != null) {
      initialCenter = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
      initialZoom = 11.5;
    }
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() { _mapInitialCenter = initialCenter; });
        }
      });
    }
    await Future.delayed(const Duration(milliseconds: 150));
    if (mounted) {
      await _fetchDataForSelectedParameter();
      // On force un rafraîchissement pour lancer le FutureBuilder des marqueurs SQFlite
      setState(() {});
    }
  }

  Future<bool> _getCurrentLocation({bool centerMap = true}) async {
    if (!mounted) return false;
    bool serviceEnabled; LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar( content: Text('Location services are disabled.'))); return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar( content: Text('Location permissions are denied.'))); return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar( content: Text( 'Location permissions permanently denied.'))); return false;
    }
    try {
      Position position = await Geolocator.getCurrentPosition( desiredAccuracy: LocationAccuracy.high);
      if (!mounted) return false;
      setState(() { _currentPosition = position; });
      print("[INFO MapPage] User location obtained: (${position.latitude}, ${position.longitude})");
      if (centerMap && _currentPosition != null) {
        _mapController.move( LatLng(_currentPosition!.latitude, _currentPosition!.longitude), 15.0, );
      }
      return true;
    } catch (e) {
      print("[ERROR MapPage] Error getting location: $e");
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar( content: Text('Could not get current location.'))); return false;
    }
  }

  Future<void> _fetchDataForSelectedParameter() async {
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
      print("[INFO MapPage] OpenAQ Key missing, API call skipped.");
      return;
    }
    try {
      final globalMeasurements = await _aqService.fetchGlobalLatestMeasurements(parameterId: _selectedParameterId);
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

  void _zoomIn() { /* ... inchangé ... */ double currentZoom = _mapController.camera.zoom; double targetZoom = currentZoom + 1; if (targetZoom > _maxZoom) targetZoom = _maxZoom; _mapController.move(_mapController.camera.center, targetZoom); }
  void _zoomOut() { /* ... inchangé ... */ double currentZoom = _mapController.camera.zoom; double targetZoom = currentZoom - 1; if (targetZoom < _minZoom) targetZoom = _minZoom; _mapController.move(_mapController.camera.center, targetZoom); }

  List<Marker> _buildAirQualityMarkers() { /* ... inchangé ... */ List<Marker> markers = []; int knownParamCount = 0; int validValueCount = 0; for (var measurement in _allLatestMeasurements) { final paramInfo = PARAMETER_ID_TO_INFO[measurement.parameterId]; if (paramInfo == null) { continue; } if (measurement.parameterId.toString() != _selectedParameterId) continue; knownParamCount++; final String param = paramInfo['name']!; final String unit = paramInfo['unit']!; final double value = measurement.value; final String description = paramInfo['description'] ?? 'No description available.'; if (value >= 0) { validValueCount++; Color markerColor = Colors.grey[400]!; String aqiCategory = "N/A"; if (param == 'pm25') { if (value <= 12.0) { markerColor = Colors.green.shade400; aqiCategory = "Good"; } else if (value <= 35.4) { markerColor = Colors.yellow.shade600; aqiCategory = "Moderate"; } else if (value <= 55.4) { markerColor = Colors.orange.shade700; aqiCategory = "Unhealthy (Sensitive)"; } else if (value <= 150.4) { markerColor = Colors.red.shade400; aqiCategory = "Unhealthy"; } else if (value <= 250.4) { markerColor = Colors.purple.shade300; aqiCategory = "Very Unhealthy"; } else { markerColor = Colors.brown.shade400; aqiCategory = "Hazardous"; } } else if (param == 'pm10') { if (value <= 54) { markerColor = Colors.green.shade400; aqiCategory = "Good"; } else if (value <= 154) { markerColor = Colors.yellow.shade600; aqiCategory = "Moderate"; } else if (value <= 254) { markerColor = Colors.orange.shade700; aqiCategory = "Unhealthy (Sensitive)"; } else if (value <= 354) { markerColor = Colors.red.shade400; aqiCategory = "Unhealthy"; } else if (value <= 424) { markerColor = Colors.purple.shade300; aqiCategory = "Very Unhealthy"; } else { markerColor = Colors.brown.shade400; aqiCategory = "Hazardous"; } } else if (param == 'o3') { if (unit == 'µg/m³') { if (value <= 100) { markerColor = Colors.green.shade400; aqiCategory = "Good"; } else if (value <= 160) { markerColor = Colors.yellow.shade600; aqiCategory = "Moderate"; } else if (value <= 214) { markerColor = Colors.orange.shade700; aqiCategory = "Unhealthy (Sensitive)"; } else if (value <= 267) { markerColor = Colors.red.shade400; aqiCategory = "Unhealthy"; } else { markerColor = Colors.purple.shade300; aqiCategory = "Very Unhealthy"; } } else { markerColor = Colors.blueGrey.shade300; aqiCategory = "Info (ppm)";} } else if (param == 'no2') { if (unit == 'µg/m³') { if (value <= 100) { markerColor = Colors.green.shade400; aqiCategory = "Good"; } else if (value <= 200) { markerColor = Colors.yellow.shade600; aqiCategory = "Moderate"; } else if (value <= 680) { markerColor = Colors.orange.shade700; aqiCategory = "Unhealthy (Sensitive)"; } else { markerColor = Colors.red.shade400; aqiCategory = "Unhealthy"; } } else { markerColor = Colors.blueGrey.shade300; aqiCategory = "Info (ppm)";} } else { markerColor = Colors.cyan.shade300; aqiCategory = "Info"; } markers.add(Marker( width: 38.0, height: 38.0, point: measurement.coordinates, child: GestureDetector( onTap: () { showDialog( context: context, builder: (ctx) => AlertDialog( title: Text("Location ID: ${measurement.locationId}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)), content: SingleChildScrollView( child: Column( mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [ Text("${param.toUpperCase()}: ${value.toStringAsFixed(1)} $unit", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), Text("Status: $aqiCategory", style: TextStyle(color: markerColor, fontWeight: FontWeight.bold)), const SizedBox(height: 8), Text(description, style: Theme.of(ctx).textTheme.bodySmall), const Divider(height: 15, thickness: 1), Text("Sensor ID: ${measurement.sensorId}"), Text("Updated: ${DateFormat.yMd().add_jm().format(measurement.datetimeUtc.toLocal())}"), ], ) ), actions: [TextButton(child: const Text("Close"), onPressed: () => Navigator.of(ctx).pop())], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), ), ); }, child: Tooltip( message: "Loc: ${measurement.locationId}\n${param.toUpperCase()}: ${value.toStringAsFixed(1)} $unit ($aqiCategory)", child: Container( decoration: BoxDecoration( color: markerColor.withOpacity(0.8), shape: BoxShape.circle, border: Border.all(color: Colors.black54, width: 1), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(1,1))] ), child: Center( child: Text( value.round().toString(), style: TextStyle( color: markerColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white, fontSize: 11, fontWeight: FontWeight.bold), ) ), ), ), ), )); } } print("[DEBUG MapPage] Built ${markers.length} AQI markers for $_selectedParameterName ($knownParamCount known params, $validValueCount with valid value). Total fetched: ${_allLatestMeasurements.length}."); return markers; }

  // --- Fonction RETIRÉE car parsing fait dans DataPage ---
  // LatLng? _parseLatLngFromString(String positionString) { ... }

  // --- Fonction RETIRÉE car remplacée par _buildSqliteEventMarkers ---
  // List<Marker> _buildHiveEventMarkers(List<Map> eventData) { ... }

  // --- NOUVELLE Fonction pour construire les marqueurs depuis SQFlite ---
  Future<List<Marker>> _buildSqliteEventMarkers() async {
    List<Marker> markers = [];
    try {
      // 1. Récupérer les événements depuis DatabaseHelper
      final List<Event> events = await _dbHelper.getAllEvents();
      print("[MapPage] Found ${events.length} events in SQFlite DB.");

      // 2. Itérer sur les événements
      for (var event in events) {
        // 3. Vérifier si les coordonnées sont valides (non 0.0)
        if (event.latitude != 0.0 || event.longitude != 0.0) {
          final LatLng point = LatLng(event.latitude, event.longitude);
          final IconData eventIcon = _getIconForType(event.type); // Helper pour l'icône
          final Color iconColor = _getColorForType(event.type, Theme.of(context)); // Helper pour la couleur

          // 4. Créer le Marker
          markers.add(Marker(
            width: 30.0, height: 30.0,
            point: point,
            child: Tooltip(
              // Affiche type et début description
              message: "${event.type}\n${event.description.substring(0, (event.description.length > 20 ? 20 : event.description.length))}...",
              child: GestureDetector(
                onTap: () {
                  // Parse le timestamp pour l'afficher dans le dialogue
                  DateTime dt = DateTime.now().toLocal();
                  try { dt = DateTime.parse(event.timestamp).toLocal(); }
                  catch(e) { print("Error parsing event timestamp for dialog: ${event.timestamp}"); }
                  final formattedDate = DateFormat.yMd().add_jm().format(dt);

                  showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(event.type), // Titre avec le type
                        // Affiche la date et la description complète
                        content: Text("Reported: $formattedDate\nDetails: ${event.description}"),
                        actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("OK"))],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      )
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7), // Fond blanc semi-transparent
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black26, width: 0.5) // Petite bordure
                  ),
                  child: Icon(
                      eventIcon,
                      color: iconColor,
                      size: 24.0,
                      shadows: const [Shadow(color: Colors.black38, blurRadius: 3)] // Ombre légère
                  ),
                ),
              ),
            ),
          ));
        } else {
          print("[MapPage] Skipping event ID ${event.id} due to invalid coordinates (0,0).");
        }
      }
    } catch (e) {
      print("[ERROR MapPage] Failed to build SQLite markers: $e");
      // Retourne une liste vide en cas d'erreur pour ne pas planter l'UI
    }
    print("[MapPage] Built ${markers.length} markers from SQFlite.");
    return markers;
  }
  // --- FIN Nouvelle Fonction ---


  // Helper pour ouvrir les URL (inchangé)
  Future<void> _launchUrl(String urlString) async { /* ... inchangé ... */ final Uri url = Uri.parse(urlString); try { if (!await launchUrl(url, mode: LaunchMode.externalApplication)) throw 'Could not launch $urlString'; } catch (e) { print('[ERROR MapPage] Could not launch URL: $urlString. Error: $e'); if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open link: $urlString'))); } }

  // --- Helpers pour Icônes/Couleurs (copiés depuis EventDetailPage/DataPage) ---
  IconData _getIconForType(String? type) {
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
  // --- FIN Helpers Icônes/Couleurs ---


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final LatLng centerForMapOptions = _mapInitialCenter ?? _defaultCenter;
    final double zoomForMapOptions = (_mapInitialCenter == _defaultCenter || _mapInitialCenter == null)
        ? _defaultZoom
        : 11.5;

    return Scaffold(
      appBar: AppBar( /* ... inchangé ... */ title: Text("AQ Map - $_selectedParameterName"), actions: [ PopupMenuButton<String>( icon: const Icon(Icons.filter_list), tooltip: "Select Pollutant", onSelected: (String result) { if (_selectedParameterId != result) { _updateSelectedParameterInfo(result); setState(() { _aqError = null; _allLatestMeasurements = []; _isLoadingAQ = true; }); _fetchDataForSelectedParameter(); } }, itemBuilder: (BuildContext context) => _availableParameters.entries .map((entry) => PopupMenuItem<String>( value: entry.key, child: Text(entry.value), )).toList(), ), IconButton( icon: const Icon(Icons.refresh), tooltip: 'Refresh Data for $_selectedParameterName', onPressed: _isLoadingAQ ? null : _fetchDataForSelectedParameter ), ], ),
      drawer: const CustomDrawer(),
      body: Stack(
        children: [
          // Carte (inchangée)
          if (_mapInitialCenter != null)
            FlutterMap(
              mapController: _mapController,
              options: MapOptions( /* ... inchangé ... */ initialCenter: centerForMapOptions, initialZoom: zoomForMapOptions, minZoom: _minZoom, maxZoom: _maxZoom, initialRotation: 0.0, interactionOptions: const InteractionOptions( flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom | InteractiveFlag.doubleTapZoom, ), ),
              children: [
                TileLayer( /* ... inchangé ... */ urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png", userAgentPackageName: 'com.example.greenwatch', ),
                // Marqueur Utilisateur (inchangé)
                if (_currentPosition != null)
                  MarkerLayer( markers: [ Marker( width: 40.0, height: 40.0, point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude), child: Icon( Icons.person_pin_circle, color: Theme.of(context).colorScheme.primary, size: 35.0, shadows: const [Shadow(color: Colors.black38, blurRadius: 4, offset: Offset(1,1))], ), alignment: Alignment.center, ), ], ),
                // Marqueurs Qualité de l'Air (inchangé)
                if (!_isApiKeyMissing && _aqError == null)
                  MarkerLayer(markers: _buildAirQualityMarkers()),

                // --- NOUVEAU: FutureBuilder pour les marqueurs SQFlite ---
                FutureBuilder<List<Marker>>(
                  future: _buildSqliteEventMarkers(), // Appelle la fonction qui lit la BDD
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      // Optionnel: Indicateur pendant le chargement des marqueurs SQFlite
                      // return const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)));
                      return const SizedBox.shrink(); // Ne rien afficher pendant le chargement
                    } else if (snapshot.hasError) {
                      print("[MapPage] Error in FutureBuilder for SQLite markers: ${snapshot.error}");
                      // Optionnel: Afficher un message d'erreur discret si besoin
                      // return const Positioned(bottom: 5, left: 5, child: Text("Error loading events", style: TextStyle(color: Colors.red, fontSize: 10)));
                      return const SizedBox.shrink();
                    } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                      // Si on a des marqueurs, on les affiche
                      print("[MapPage] FutureBuilder displaying ${snapshot.data!.length} SQFlite markers.");
                      return MarkerLayer(markers: snapshot.data!);
                    } else {
                      // Si pas de données (liste vide) ou autre problème non géré
                      print("[MapPage] FutureBuilder for SQFlite: No data or empty list.");
                      return const SizedBox.shrink(); // Ne rien afficher
                    }
                  },
                ),
                // --- FIN NOUVEAU FutureBuilder ---

                // --- Ancienne partie Hive et message "unavailable" RETIRÉE ---
                // if (Hive.isBoxOpen('precipitationBox')) ...
                // else Padding(...)
                // --- FIN PARTIE RETIRÉE ---

              ],
            )
          // Indicateur de chargement initial (inchangé)
          else if (!_isApiKeyMissing)
            const Center(child: CircularProgressIndicator()),

          // Panneau de description du polluant (inchangé)
          Positioned( /* ... inchangé ... */ top: 0, left: 0, right: 0, child: IgnorePointer( child: Container( decoration: BoxDecoration( gradient: LinearGradient( begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [ theme.colorScheme.surface.withOpacity(0.9), theme.colorScheme.surface.withOpacity(0.7), theme.colorScheme.surface.withOpacity(0.0), ], stops: const [0.0, 0.7, 1.0] ) ), padding: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 12.0), child: Text( _selectedParameterDescription, style: theme.textTheme.bodySmall?.copyWith( color: theme.colorScheme.onSurface.withOpacity(0.9) ), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, ), ) ), ),

          // Indicateurs & Erreurs/Info Clé Manquante (inchangé)
          if (_mapInitialCenter != null) ...[ /* ... inchangé ... */ if (_isLoadingAQ) Positioned(bottom: 80, left: 10, right: 10, child: Center(child: Container( padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)), child: const Row(mainAxisSize: MainAxisSize.min, children: [SizedBox(height: 15, width: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)), SizedBox(width: 10), Text('Loading AQ Data...', style: TextStyle(color: Colors.white))])))), if (_aqError != null && !_isApiKeyMissing) Positioned(bottom: 80, left: 10, right: 10, child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.red.withOpacity(0.85), borderRadius: BorderRadius.circular(8)), child: Text("AQ Data Error: $_aqError", style: const TextStyle(color: Colors.white), textAlign: TextAlign.center,))), if (_isApiKeyMissing) Positioned( bottom: 80, left: 10, right: 10, child: Container( padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10), decoration: BoxDecoration( color: Colors.orange.shade700.withOpacity(0.9), borderRadius: BorderRadius.circular(8), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))] ), child: RichText( textAlign: TextAlign.center, text: TextSpan( style: TextStyle(color: Colors.white, fontSize: 13, fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily), children: [ const TextSpan(text: 'OpenAQ API Key needed in '), TextSpan( text: 'Settings', style: const TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline), recognizer: TapGestureRecognizer()..onTap = () => Navigator.pushNamed(context, '/settings').then((_) => _fetchDataForSelectedParameter()), ), const TextSpan(text: ' to show Air Quality data.'), ] ), ), ), ), ],

          // Boutons de contrôle (inchangé)
          Positioned( /* ... inchangé ... */ bottom: 20, right: 10, child: Column( mainAxisSize: MainAxisSize.min, children: <Widget>[ FloatingActionButton.small( heroTag: "btnZoomIn", onPressed: _zoomIn, tooltip: 'Zoom In', child: const Icon(Icons.add)), const SizedBox(height: 8), FloatingActionButton.small( heroTag: "btnZoomOut", onPressed: _zoomOut, tooltip: 'Zoom Out', child: const Icon(Icons.remove)), ], ), ),
          Positioned( /* ... inchangé ... */ bottom: 20, left: 10, child: FloatingActionButton( heroTag: "btnMyLocation", onPressed: () { _getCurrentLocation(centerMap: true); }, tooltip: 'My Location', child: const Icon(Icons.my_location), ), ),
        ],
      ),
    );
  }
} // Fin _MapPageState