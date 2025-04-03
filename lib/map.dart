import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_app/ux_unit/custom_drawer.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Risk Map 🌍"),
      ),
      drawer: const CustomDrawer(),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(40.389683644051864, -3.627825356970311),
          initialZoom: 15.0,  // Niveau de zoom initial
        ),
        children: [
          TileLayer(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: ['a', 'b', 'c'],
          ),
          PolygonLayer(
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
        ],
      ),
    );
  }
}
