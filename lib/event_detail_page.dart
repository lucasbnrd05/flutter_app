// lib/event_detail_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event.dart';


class EventDetailPage extends StatelessWidget {
  final Event event;

  const EventDetailPage({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    DateTime dateTimeLocal = DateTime.now();
    try {
      dateTimeLocal = DateTime.parse(event.timestamp).toLocal();
    } catch (e) {
      print("Error parsing timestamp on detail page: ${event.timestamp}");
    }
    final formattedDate = DateFormat.yMMMMEEEEd()
        .add_jms()
        .format(dateTimeLocal);

    return Scaffold(
      appBar: AppBar(
        title: Text('Event Details: ${event.type}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            _buildDetailItem(
              context: context,
              icon: _getIconForType(
                  event.type),
              label: 'Event Type',
              value: event.type,
              iconColor: _getColorForType(
                  event.type, theme),
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
              value: formattedDate,
            ),
            const Divider(height: 20),
            _buildDetailItem(
              context: context,
              icon: Icons.location_on_outlined,
              label: 'Coordinates',
              value: (event.latitude != 0.0 || event.longitude != 0.0)
                  ? 'Lat: ${event.latitude.toStringAsFixed(5)}, Lon: ${event.longitude.toStringAsFixed(5)}'
                  : 'Coordinates not available from description.',
            ),
            const SizedBox(height: 24),

          ],
        ),
      ),
    );
  }

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
                      ?.color,
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
        return theme.colorScheme.secondary;
    }
  }
}