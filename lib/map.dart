import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart'; // Import geolocator
import 'dart:async'; // For async operations

// Make sure this import path is correct for your project
import 'package:flutter_app/ux_unit/custom_drawer.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  Position? _currentPosition; // Variable to store the position
  final MapController _mapController = MapController(); // Controller for the map

  final double _minZoom = 5.0;
  final double _maxZoom = 18.0;
  // --- CENTRE PAR DÉFAUT (FALLBACK) ---
  // Reste défini ici pour être utilisé si la localisation échoue ou n'est pas prête
  final LatLng _defaultCenter = const LatLng(40.417, -3.657);
  final double _defaultZoom = 14.0;

  @override
  void initState() {
    super.initState();
    _initializeMapLocation(); // Nouvelle fonction d'initialisation
  }

  // Nouvelle fonction pour gérer la logique d'initialisation
  Future<void> _initializeMapLocation() async {
    // Tenter de récupérer la localisation
    await _getCurrentLocation();

    // À ce stade, _currentPosition peut être null ou avoir une valeur.
    // La carte sera initialement construite avec _defaultCenter.
    // Si _getCurrentLocation a réussi, elle aura appelé _mapController.move.
  }


  // Fonction pour obtenir la localisation actuelle ET CENTRER LA CARTE SI SUCCÈS
  Future<void> _getCurrentLocation({bool centerMap = true}) async { // Ajout de centerMap
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Location services are disabled. Please enable them.')));
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Location permissions are denied.')));
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location permissions are permanently denied. Please enable them in app settings.')));
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      if (!mounted) return;

      // Mettre à jour l'état d'abord
      setState(() {
        _currentPosition = position;
      });

      // --- CENTRAGE CONDITIONNEL ---
      // Si la localisation est obtenue avec succès ET que centerMap est true,
      // déplacer la carte vers la position de l'utilisateur.
      if (centerMap && _currentPosition != null) {
        _mapController.move(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          15.0, // Zoom approprié pour la vue utilisateur
        );
      }

    } catch (e) {
      print("Error getting location: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not get current location.')));
      // En cas d'erreur, on ne change pas _currentPosition et la carte reste
      // centrée sur _defaultCenter (ou là où elle était).
    }
  }

  // Fonctions pour le zoom (inchangées)
  void _zoomIn() {
    double currentZoom = _mapController.camera.zoom;
    double targetZoom = currentZoom + 1;
    if (targetZoom > _maxZoom) targetZoom = _maxZoom;
    _mapController.move(_mapController.camera.center, targetZoom);
  }

  void _zoomOut() {
    double currentZoom = _mapController.camera.zoom;
    double targetZoom = currentZoom - 1;
    if (targetZoom < _minZoom) targetZoom = _minZoom;
    _mapController.move(_mapController.camera.center, targetZoom);
  }

  @override
  Widget build(BuildContext context) {

    // NOTE : initialCenter et initialZoom dans MapOptions utiliseront TOUJOURS
    // les valeurs par défaut définies en haut (_defaultCenter, _defaultZoom).
    // Le centrage sur l'utilisateur se fait via _mapController.move APRES
    // que la localisation soit obtenue dans _getCurrentLocation.

    return Scaffold(
      appBar: AppBar(
        title: const Text("Risk Map 🌍"),
      ),
      drawer: const CustomDrawer(),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              // --- UTILISER LE CENTRE PAR DÉFAUT ICI ---
              initialCenter: _defaultCenter,
              initialZoom: _defaultZoom,
              minZoom: _minZoom,
              maxZoom: _maxZoom,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: const ['a', 'b', 'c'],
              ),
              PolygonLayer(
                polygons: [
                  Polygon( /* ... polygone orange ... */
                    points: [ LatLng(40.4152591,-3.6572069), LatLng(40.4136421,-3.6567349), LatLng(40.4144591,-3.6545029),],
                    color: Colors.orange.withOpacity(0.5), borderStrokeWidth: 3, borderColor: Colors.orange, isFilled: true,
                  ),
                  Polygon( /* ... polygone bleu ... */
                    points: [ LatLng(40.4211111,-3.6604129), LatLng(40.4179211,-3.6575389), LatLng(40.4203221,-3.6556079),],
                    color: Colors.blue.withOpacity(0.5), borderStrokeWidth: 3, borderColor: Colors.blue, isFilled: true,
                  ),
                ],
              ),
              if (_currentPosition != null)
                MarkerLayer(
                  markers: [
                    Marker( /* ... marqueur utilisateur ... */
                      width: 40.0, height: 40.0, point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                      child: Image.asset('assets/user_marker.png', errorBuilder: (context, error, stackTrace) {
                        print("Error loading marker image: $error");
                        return Icon(Icons.location_pin, color: Colors.red, size: 30);
                      },
                      ),
                      alignment: Alignment.topCenter,
                    ),
                  ],
                ),
            ],
          ),

          // --- Boutons de zoom (inchangés) ---
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 80.0, right: 10.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  FloatingActionButton.small(
                    heroTag: "btnZoomIn", onPressed: _zoomIn, tooltip: 'Zoom In',
                    backgroundColor: Colors.white.withOpacity(0.8), foregroundColor: Colors.black,
                    child: const Icon(Icons.add),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: "btnZoomOut", onPressed: _zoomOut, tooltip: 'Zoom Out',
                    backgroundColor: Colors.white.withOpacity(0.8), foregroundColor: Colors.black,
                    child: const Icon(Icons.remove),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      // --- Bouton de localisation (légèrement modifié) ---
      floatingActionButton: FloatingActionButton(
        heroTag: "btnMyLocation",
        onPressed: () {
          // Si la position est déjà connue, on centre dessus
          if (_currentPosition != null) {
            _mapController.move(
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
              15.0,
            );
          } else {
            // Sinon, on essaie de la récupérer (et de centrer si succès)
            _getCurrentLocation(centerMap: true);
            // Optionnel: informer l'utilisateur qu'on cherche la localisation
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Getting current location...')));
          }
        },
        tooltip: 'My Location',
        child: const Icon(Icons.my_location),
      ),
    );
  }
}