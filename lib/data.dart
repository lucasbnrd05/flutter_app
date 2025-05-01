// lib/data.dart
import 'package:firebase_auth/firebase_auth.dart'; // Importe User
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart'; // Importe Provider

// Importe les éléments locaux
import '../models/event.dart';
import '../services/database_helper.dart';
import '../ux_unit/custom_drawer.dart';
import '../ux_unit/login_required_widget.dart';
import 'event_detail_page.dart';

class DataPage extends StatefulWidget {
  const DataPage({super.key});

  @override
  State<DataPage> createState() => _DataPageState();
}

class _DataPageState extends State<DataPage> {
  final _formKey = GlobalKey<FormState>();
  final _positionController = TextEditingController();
  String? _selectedPrecipitation;
  bool _isLoadingLocation = false;

  late Future<List<Event>> _eventsFuture;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  final List<String> _precipitationTypes = [
    'Flood',
    'Drought',
    'Fallen Trees',
    'Heavy Hail',
    'Heavy Rain',
    'Heavy Snow',
    'Other (specify in position)'
  ];

  @override
  void initState() {
    super.initState();
    _eventsFuture = _fetchEvents();
  }

  Future<List<Event>> _fetchEvents() async {
    // La vérification se fait dans build()
    return _dbHelper.getAllEvents();
  }

  void _refreshEventsList() {
    final user = Provider.of<User?>(context, listen: false);
    if (user != null && !user.isAnonymous) {
      setState(() {
        _eventsFuture = _fetchEvents();
      });
    }
  }

  @override
  void dispose() {
    _positionController.dispose();
    super.dispose();
  }

  ({double? latitude, double? longitude}) _parsePositionString(String text) {
    try {
      final regex = RegExp(r"Lat:\s*(-?\d+\.?\d*),\s*Lon:\s*(-?\d+\.?\d*)");
      final match = regex.firstMatch(text);
      if (match != null && match.groupCount == 2) {
        final lat = double.tryParse(match.group(1)!);
        final lon = double.tryParse(match.group(2)!);
        if (lat != null && lon != null) {
          return (latitude: lat, longitude: lon);
        }
      }
    } catch (e) {
      print("[DataPage] Error parsing position string '$text': $e");
    }
    return (latitude: null, longitude: null);
  }

  Future<void> _saveData() async {
    if (_formKey.currentState!.validate()) {
      final String type = _selectedPrecipitation!;
      final String descriptionOrPosition = _positionController.text.trim();
      final String timestamp = DateTime.now().toUtc().toIso8601String();
      final coords = _parsePositionString(descriptionOrPosition);
      double latitude = coords.latitude ?? 0.0;
      double longitude = coords.longitude ?? 0.0;
      final Event newEvent = Event(
        type: type,
        latitude: latitude,
        longitude: longitude,
        description: descriptionOrPosition,
        timestamp: timestamp,
      );
      try {
        await _dbHelper.insertEvent(newEvent);
        if (!mounted) return;
        _formKey.currentState!.reset();
        _positionController.clear();
        setState(() {
          _selectedPrecipitation = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event saved successfully!')));
        _refreshEventsList();
      } catch (e) {
        print('[DataPage] Error saving data to SQFlite: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving data: ${e.toString()}')),
        );
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields (*) correctly.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _confirmDeleteEntry(int eventId) async {
    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Do you really want to delete this entry?'),
          actions: <Widget>[
            TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child:
                    const Text('Delete', style: TextStyle(color: Colors.red))),
          ],
        );
      },
    );
    if (confirm == true) {
      try {
        await _dbHelper.deleteEvent(eventId);
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Entry deleted.')));
        _refreshEventsList();
      } catch (e) {
        print('[DataPage] Error deleting entry from SQFlite: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting entry: $e')),
        );
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    if (kIsWeb) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Automatic location not fully supported on web.')));
      return;
    }
    if (!mounted) return;
    setState(() {
      _isLoadingLocation = true;
    });
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled.')));
      setState(() => _isLoadingLocation = false);
      return;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied.')));
        setState(() => _isLoadingLocation = false);
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Location permissions permanently denied...')));
      await openAppSettings();
      setState(() => _isLoadingLocation = false);
      return;
    }
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      if (!mounted) return;
      setState(() {
        _positionController.text =
            'Lat: ${position.latitude.toStringAsFixed(5)}, Lon: ${position.longitude.toStringAsFixed(5)}';
        _isLoadingLocation = false;
      });
    } catch (e) {
      print("[DataPage] Error getting location: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not get current location: ${e.toString()}')));
      setState(() => _isLoadingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = Provider.of<User?>(context);
    final bool isTrulyLoggedIn = user != null && !user.isAnonymous;

    if (!isTrulyLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Report Environmental Event')),
        drawer: const CustomDrawer(),
        body: const LoginRequiredWidget(featureName: "Report Data"),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Environmental Event'),
      ),
      drawer: const CustomDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInputForm(),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Text('Recorded Events:',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            _buildSavedDataList(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          DropdownButtonFormField<String>(
            value: _selectedPrecipitation,
            hint: const Text('Event type *'),
            isExpanded: true,
            items: _precipitationTypes
                .map<DropdownMenuItem<String>>((String value) =>
                    DropdownMenuItem<String>(value: value, child: Text(value)))
                .toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedPrecipitation = newValue!;
              });
            },
            validator: (value) => value == null ? 'Please select a type' : null,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _positionController,
            decoration: const InputDecoration(
                labelText: 'Position / Description *',
                hintText: 'E.g., Park entrance, or Lat/Lon',
                border: OutlineInputBorder()),
            validator: (value) => (value == null || value.trim().isEmpty)
                ? 'Please enter a position or description'
                : null,
            maxLines: 2,
          ),
          const SizedBox(height: 10),
          _isLoadingLocation
              ? const Center(
                  child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: CircularProgressIndicator(),
                ))
              : ElevatedButton.icon(
                  icon: const Icon(Icons.my_location),
                  label: const Text('Use Current Location'),
                  onPressed: _getCurrentLocation,
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40)),
                ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saveData,
            style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary),
            child: const Text('Save Event', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedDataList() {
    return FutureBuilder<List<Event>>(
        future: _eventsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            print("[DataPage _buildSavedDataList] Error: ${snapshot.error}");
            return Center(
                child: Text("Error loading events: ${snapshot.error}",
                    style: const TextStyle(color: Colors.red)));
          } else if (snapshot.hasData) {
            final events = snapshot.data!;
            if (events.isEmpty) {
              return const Center(
                  child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text('No events recorded yet.'),
              ));
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                DateTime dateTimeLocal = DateTime.now();
                try {
                  dateTimeLocal = DateTime.parse(event.timestamp).toLocal();
                } catch (e) {
                  print("Error parsing timestamp: ${event.timestamp}");
                }
                final formattedDate =
                    DateFormat.yMd().add_Hms().format(dateTimeLocal);
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: Icon(_getIconForType(event.type)),
                    title: Text(event.type,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${event.description}\n$formattedDate',
                        maxLines: 3, overflow: TextOverflow.ellipsis),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.red[300]),
                      tooltip: 'Delete Entry',
                      onPressed: () => _confirmDeleteEntry(event.id!),
                    ),
                    isThreeLine: true,
                    dense: true,
                    onTap: () {
                      print(
                          "[DataPage] Navigating to detail for event ID: ${event.id}");
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EventDetailPage(event: event),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          } else {
            return const Center(child: Text("Something went wrong."));
          }
        });
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
}
