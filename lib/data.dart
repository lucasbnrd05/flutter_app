import 'package:flutter/material.dart';
import 'package:flutter_app/ux_unit/custom_drawer.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:geolocator/geolocator.dart'; // For geolocation
import 'package:permission_handler/permission_handler.dart'; // For permissions
import 'package:hive_flutter/hive_flutter.dart'; // Import Hive Flutter
import 'package:flutter/foundation.dart' show kIsWeb; // For platform checks if needed


// Note: No need to import database_helper.dart anymore

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
  bool _isLoadingData = true;
  // Store list of Maps directly from Hive Box values
  List<Map> _savedEntries = [];
  // Keep track of Hive keys corresponding to the entries for deletion
  List<dynamic> _savedEntryKeys = [];

  // Reference the opened Hive Box
  late Box<Map> _precipitationBox;

  // Dropdown options (unchanged)
  final List<String> _precipitationTypes = [
    'Flood', 'Drought', 'Fallen Trees', 'Heavy Hail', 'Heavy Rain',
    'Heavy Snow', 'Other (specify in position)'
  ];

  @override
  void initState() {
    super.initState();
    _precipitationBox = Hive.box<Map>('precipitationBox'); // Get reference to the box
    _loadSavedData();
  }

  @override
  void dispose() {
    _positionController.dispose();
    // Hive boxes are usually kept open for the app's lifetime,
    // but you could close them here if needed:
    // _precipitationBox.close();
    super.dispose();
  }

  // --- Data Management using Hive ---

  Future<void> _loadSavedData() async {
    if (!mounted) return;
    setState(() { _isLoadingData = true; });

    try {
      // Read all values and keys from the Hive box
      final entries = _precipitationBox.values.toList();
      final keys = _precipitationBox.keys.toList();

      if (!mounted) return;
      setState(() {
        // Store data in descending order (newest first) - assuming keys are sequential
        _savedEntries = List<Map>.from(entries.reversed);
        _savedEntryKeys = List<dynamic>.from(keys.reversed);
        _isLoadingData = false;
      });
    } catch (e) {
      print("Error loading data from Hive: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
      setState(() { _isLoadingData = false; });
    }
  }

  Future<void> _saveData() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final String type = _selectedPrecipitation!;
      final String position = _positionController.text;
      final String timestamp = DateTime.now().toUtc().toIso8601String();

      // Create the data Map - IMPORTANT: Hive prefers basic types or registered adapters
      // Using Map<String, dynamic> is generally okay here.
      final Map<String, dynamic> newEntry = {
        // Use distinct keys for Hive Map storage
        'type': type,
        'position': position,
        'timestamp': timestamp,
      };

      try {
        // Add the Map to the box. Hive assigns an auto-incrementing integer key.
        await _precipitationBox.add(newEntry);
        print('Data added to Hive box.');

        // Reload data to display the new entry
        await _loadSavedData();

        if (!mounted) return;
        _formKey.currentState!.reset();
        _positionController.clear();
        setState(() { _selectedPrecipitation = null; });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data saved successfully!')),
        );

      } catch (e) {
        print('Error saving data to Hive: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving data: ${e.toString()}')),
        );
      }
    } else {
      print('Form validation failed.');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields (*) correctly.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  // Function to confirm and delete an entry using Hive key
  Future<void> _confirmDeleteEntry(dynamic key) async { // Key can be int or String
    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) { /* ... AlertDialog code (unchanged) ... */
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Do you really want to delete this entry?'),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        // Delete the entry from Hive using its key
        await _precipitationBox.delete(key);
        print('Entry deleted from Hive with key: $key');

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entry deleted.')),
        );
        await _loadSavedData(); // Reload the list

      } catch (e) {
        print('Error deleting entry from Hive: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting entry: $e')),
        );
      }
    }
  }


  // --- Location Management (Refactored based on MapPage example) ---
  // NOTE: Geolocation might have limited functionality or require different
  // setup/permissions on Web compared to Mobile. This code focuses on mobile.
  Future<void> _getCurrentLocation() async {
    // Basic web check: Geolocation might not work reliably or easily on web
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Automatic location fetching is not fully supported on web in this example.')));
      return;
    }

    if (!mounted) return;
    setState(() { _isLoadingLocation = true; });

    // ... (rest of the location permission and fetching logic remains the same) ...
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Location services are disabled. Please enable them.')));
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
          content: Text('Location permissions are permanently denied...')));
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
      print("Error getting location: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not get current location: ${e.toString()}')));
      setState(() => _isLoadingLocation = false);
    }
  }

  // --- UI Build ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( title: const Text('Report an Event'), ),
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
            Text('Saved Data:', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            _buildSavedDataList(), // Updated to use Hive data
          ],
        ),
      ),
    );
  }

  // Widget for the input form (Unchanged, still uses _formKey, controllers etc.)
  Widget _buildInputForm() {
    // ... (Form UI code remains exactly the same) ...
    return Form(
      key: _formKey,
      child: Column( /* ... Dropdown, TextFormField, Buttons ... */
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          DropdownButtonFormField<String>( /* ... */
            value: _selectedPrecipitation,
            hint: const Text('Precipitation type *'),
            isExpanded: true,
            onChanged: (String? newValue) { setState(() { _selectedPrecipitation = newValue!; }); },
            items: _precipitationTypes.map<DropdownMenuItem<String>>((String value) =>
                DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
            validator: (value) => value == null ? 'Please select a type' : null,
          ),
          const SizedBox(height: 16),
          TextFormField( /* ... */
            controller: _positionController,
            decoration: const InputDecoration(labelText: 'Position / Description *', hintText: 'E.g., Main Street near the bridge, or Lat/Lon', border: OutlineInputBorder()),
            validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter a position or description' : null,
            maxLines: 2,
          ),
          const SizedBox(height: 10),
          _isLoadingLocation
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton.icon( /* ... Location Button ... */
            icon: const Icon(Icons.my_location),
            label: const Text('Use my current location'),
            onPressed: _getCurrentLocation, // Check inside function for web limitation
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(40)),
          ),
          const SizedBox(height: 20),
          ElevatedButton( /* ... Save Button ... */
            onPressed: _saveData,
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50), backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
            child: const Text('Save', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  // Widget to display the list of saved data from Hive
  Widget _buildSavedDataList() {
    if (_isLoadingData) {
      return const Center(child: CircularProgressIndicator());
    }
    // Watch the box for changes to automatically rebuild the list
    return ValueListenableBuilder(
        valueListenable: _precipitationBox.listenable(),
        builder: (context, Box<Map> box, _) {
          // Re-fetch data inside the builder when the box changes
          // Note: This re-fetches on every change, which is simple but might
          // not be the most efficient for very large datasets.
          // Consider using the lists updated in _loadSavedData if preferred.
          final entries = box.values.toList().reversed.toList();
          final keys = box.keys.toList().reversed.toList();

          if (entries.isEmpty) {
            return const Center(child: Text('No data recorded yet.'));
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entryMap = Map<String, dynamic>.from(entries[index]); // Ensure it's the right type
              final entryKey = keys[index]; // Get the corresponding key

              final dateTimeUtc = DateTime.parse(entryMap['timestamp'] ?? DateTime.now().toUtc().toIso8601String());
              final dateTimeLocal = dateTimeUtc.toLocal();
              final formattedDate = DateFormat.yMd().add_Hms().format(dateTimeLocal);

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 5),
                child: ListTile(
                  title: Text(entryMap['type'] ?? 'Unknown Type',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      'Position: ${entryMap['position'] ?? 'Not defined'}\n'
                          'Time: $formattedDate'),
                  trailing: IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red[300]),
                    // Pass the specific Hive key to the delete function
                    onPressed: () => _confirmDeleteEntry(entryKey),
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        }
    );
  }
}