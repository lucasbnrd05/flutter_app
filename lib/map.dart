import 'package:flutter/material.dart';
import 'package:flutter_app/ux_unit/custom_drawer.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';

import 'about.dart';
import 'settings.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final Completer<GoogleMapController> _controller = Completer();

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(48.8566, 2.3522), // Coordinates of Paris
    zoom: 6.0,
  );

  final Set<Marker> _markers = {};
  final Set<Polygon> _polygons = {};

  @override
  void initState() {
    super.initState();
    _loadRiskZones();
  }

  void _loadRiskZones() {
    setState(() {
      // Example of a drought zone
      _polygons.add(
        Polygon(
          polygonId: const PolygonId("drought_zone"),
          points: [
            const LatLng(48.9, 2.3),
            const LatLng(49.0, 2.4),
            const LatLng(48.8, 2.5),
          ],
          strokeWidth: 2,
          strokeColor: Colors.orange,
          fillColor: Colors.orange.withOpacity(0.3),
        ),
      );

      // Example of a flood zone
      _polygons.add(
        Polygon(
          polygonId: const PolygonId("flood_zone"),
          points: [
            const LatLng(48.5, 2.2),
            const LatLng(48.6, 2.3),
            const LatLng(48.4, 2.4),
          ],
          strokeWidth: 2,
          strokeColor: Colors.blue,
          fillColor: Colors.blue.withOpacity(0.3),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Risk Map 🌍"),
      ),
      drawer: const CustomDrawer(),
      body: GoogleMap(
        mapType: MapType.hybrid,
        initialCameraPosition: _initialPosition,
        markers: _markers,
        polygons: _polygons,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
      ),
    );
  }
}
