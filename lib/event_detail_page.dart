// lib/event_detail_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event.dart'; // Importe le modèle Event

// Optionnel: Pour afficher une mini-carte statique plus tard
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';

class EventDetailPage extends StatelessWidget {
  final Event event; // Reçoit l'objet Event complet

  const EventDetailPage({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Formatte la date/heure pour l'affichage
    DateTime dateTimeLocal = DateTime.now(); // Default
    try {
      dateTimeLocal = DateTime.parse(event.timestamp).toLocal();
    } catch (e) {
      print("Error parsing timestamp on detail page: ${event.timestamp}");
    }
    final formattedDate = DateFormat.yMMMMEEEEd()
        .add_jms()
        .format(dateTimeLocal); // Format plus complet

    return Scaffold(
      appBar: AppBar(
        title: Text('Event Details: ${event.type}'), // Titre avec le type
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start, // Aligne le texte à gauche
          children: [
            _buildDetailItem(
              context: context,
              icon: _getIconForType(
                  event.type), // Utilise le même helper que DataPage
              label: 'Event Type',
              value: event.type,
              iconColor: _getColorForType(
                  event.type, theme), // Optionnel: couleur icône
            ),
            const Divider(height: 20),
            _buildDetailItem(
              context: context,
              icon: Icons.description_outlined,
              label: 'Description / Position Notes',
              value: event.description,
            ),
            const Divider(height: 20),
            _buildDetailItem(
              context: context,
              icon: Icons.calendar_today_outlined,
              label: 'Reported Time',
              value: formattedDate, // Date/heure formatée
            ),
            const Divider(height: 20),
            _buildDetailItem(
              context: context,
              icon: Icons.location_on_outlined,
              label: 'Coordinates',
              // Affiche les coordonnées si elles sont valides (non 0.0), sinon un message
              value: (event.latitude != 0.0 || event.longitude != 0.0)
                  ? 'Lat: ${event.latitude.toStringAsFixed(5)}, Lon: ${event.longitude.toStringAsFixed(5)}'
                  : 'Coordinates not available from description.',
            ),
            const SizedBox(height: 24),

            // --- Optionnel: Mini-carte statique ---
            // if (event.latitude != 0.0 || event.longitude != 0.0)
            //   _buildMiniMap(context),
            // --- Fin Optionnel ---
          ],
        ),
      ),
    );
  }

  // Widget helper pour afficher une ligne de détail (Icône, Label, Valeur)
  Widget _buildDetailItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    Color? iconColor,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor ?? theme.colorScheme.primary, size: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.textTheme.bodySmall
                      ?.color, // Couleur plus discrète pour le label
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(value, style: theme.textTheme.bodyLarge),
            ],
          ),
        ),
      ],
    );
  }

  // --- Optionnel: Construction de la mini-carte ---
  // Widget _buildMiniMap(BuildContext context) {
  //   return Container(
  //     height: 200,
  //     clipBehavior: Clip.hardEdge, // Empêche le débordement
  //     decoration: BoxDecoration(
  //       borderRadius: BorderRadius.circular(12),
  //       border: Border.all(color: Theme.of(context).dividerColor),
  //     ),
  //     child: FlutterMap(
  //       options: MapOptions(
  //         initialCenter: LatLng(event.latitude, event.longitude),
  //         initialZoom: 15.0, // Zoom plus rapproché
  //         interactionOptions: const InteractionOptions(flags: InteractiveFlag.none), // Non interactive
  //       ),
  //       children: [
  //         TileLayer(
  //           urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
  //           userAgentPackageName: 'com.example.greenwatch',
  //         ),
  //         MarkerLayer(
  //           markers: [
  //             Marker(
  //               width: 40.0, height: 40.0,
  //               point: LatLng(event.latitude, event.longitude),
  //               child: Icon(
  //                 _getIconForType(event.type),
  //                 color: _getColorForType(event.type, Theme.of(context)),
  //                 size: 30.0,
  //                 shadows: const [Shadow(color: Colors.black54, blurRadius: 4)]
  //               ),
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }
  // --- Fin Optionnel ---

  // Helper pour obtenir l'icône (copié/collé depuis DataPage)
  IconData _getIconForType(String? type) {
    switch (type) {
      case 'Flood':
        return Icons.water_drop;
      case 'Drought':
        return Icons.local_fire_department_outlined;
      case 'Fallen Trees':
        return Icons.park_outlined;
      case 'Heavy Hail':
        return Icons.grain;
      case 'Heavy Rain':
        return Icons.water_drop_outlined;
      case 'Heavy Snow':
        return Icons.ac_unit;
      case 'Other (specify in position)':
        return Icons.help_outline;
      default:
        return Icons.report_problem_outlined;
    }
  }

  // Optionnel: Helper pour obtenir la couleur associée au type
  Color _getColorForType(String? type, ThemeData theme) {
    switch (type) {
      case 'Flood':
        return Colors.blue.shade700;
      case 'Drought':
        return Colors.orange.shade800;
      case 'Fallen Trees':
        return Colors.green.shade800;
      case 'Heavy Hail':
        return Colors.lightBlue.shade300;
      case 'Heavy Rain':
        return Colors.blue.shade400;
      case 'Heavy Snow':
        return Colors.cyan.shade200;
      case 'Other (specify in position)':
        return Colors.grey.shade600;
      default:
        return theme.colorScheme.secondary; // Couleur par défaut
    }
  }
}
