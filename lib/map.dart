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

  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); // Get location on startup
  }

  // Function to get the current location
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are disabled. Show a message.
      if (!mounted) return; // Check if the widget is still mounted
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location services are disabled. Please enable them.'))); // English Text
      return; // Don't continue if disabled
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied. Show a message.
        if (!mounted) return; // Check if the widget is still mounted
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Location permissions are denied.'))); // English Text
        return; // Don't continue if denied
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever. Show a message.
      if (!mounted) return; // Check if the widget is still mounted
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location permissions are permanently denied. Please enable them in app settings.'))); // English Text
      return; // Don't continue
    }

    // If permissions are granted, get the position
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      if (!mounted) return; // Check if the widget is still mounted

      setState(() {
        _currentPosition = position;
      });
      // Optional: Center the map on the new position
      _mapController.move(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        15.0, // Keep the same zoom or adjust
      );
    } catch (e) {
      print("Error getting location: $e");
      if (!mounted) return; // Check if the widget is still mounted
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not get current location.'))); // English Text
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define a default initial center or use the current position if available
    LatLng initialCenter = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : const LatLng(40.389683644051864, -3.627825356970311); // Your default center

    return Scaffold(
      appBar: AppBar(
        title: const Text("Risk Map 🌍"), // Title (already mostly English)
      ),
      drawer: const CustomDrawer(), // Make sure CustomDrawer exists
      body: FlutterMap(
        mapController: _mapController, // Link controller to the map
        options: MapOptions(
          initialCenter: initialCenter, // Use the defined center
          initialZoom: 15.0,
        ),
        children: [
          TileLayer(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: const ['a', 'b', 'c'],
          ),
          PolygonLayer( // Your existing polygons
            polygons: [
              Polygon(
                points: [
                  LatLng(48.9, 2.3),
                  LatLng(49.0, 2.4),
                  LatLng(48.8, 2.5),
                ],
                color: Colors.orange.withOpacity(0.3),
                borderStrokeWidth: 2,
                borderColor: Colors.orange,
              ),
              Polygon(
                points: [
                  LatLng(48.5, 2.2),
                  LatLng(48.6, 2.3),
                  LatLng(48.4, 2.4),
                ],
                color: Colors.blue.withOpacity(0.3),
                borderStrokeWidth: 2,
                borderColor: Colors.blue,
              ),
            ],
          ),
          // --- USER LOCATION MARKER ---
          if (_currentPosition != null) // Only display if position is known
            MarkerLayer(
              markers: [
                Marker(
                  // Adjust width and height to match your image asset's desired size
                  // Or make it slightly larger for easier tapping
                  width: 40.0,
                  height: 40.0,
                  point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                  // --- CHANGE MARKER HERE ---
                  child: Image.asset(
                    'assets/user_marker.png', // <<< Path to your image asset
                    // Optionally set width/height for the image itself if needed
                    // width: 35.0,
                    // height: 35.0,
                    // Add error builder for robustness
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback icon if image fails to load
                      print("Error loading marker image: $error");
                      return Icon(Icons.location_pin, color: Colors.red, size: 30);
                    },
                  ),
                  // You might need to adjust the alignment depending on your image.
                  // If the 'point' of your marker image is at the bottom center,
                  // use Alignment.topCenter so the map knows where the coordinate is.
                  alignment: Alignment.topCenter,
                ),
              ],
            ),
        ],
      ),
      // Optional: Button to re-center on location
      floatingActionButton: FloatingActionButton(
        onPressed: _getCurrentLocation, // Calls the function to get and center
        tooltip: 'My Location', // English Tooltip
        child: const Icon(Icons.my_location), // FAB icon can remain the same or change
      ),
    );
  }
}