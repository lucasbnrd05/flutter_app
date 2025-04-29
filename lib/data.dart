// lib/data.dart
import 'package:flutter/material.dart';
import 'ux_unit/custom_drawer.dart'; // Assure-toi du chemin
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

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
  // Plus besoin de _isLoadingData car ValueListenableBuilder gère
  // Plus besoin de _savedEntries et _savedEntryKeys car lus depuis la box

  // Référence à la box Hive (doit être ouverte dans main.dart)
  late Box<Map> _precipitationBox;

  final List<String> _precipitationTypes = [ 'Flood', 'Drought', 'Fallen Trees', 'Heavy Hail', 'Heavy Rain', 'Heavy Snow', 'Other (specify in position)' ];

  @override
  void initState() {
    super.initState();
    // Récupère la référence à la box déjà ouverte
    if (Hive.isBoxOpen('precipitationBox')) {
      _precipitationBox = Hive.box<Map>('precipitationBox');
    } else {
      print("[ERROR DataPage initState] Hive box 'precipitationBox' is not open!");
      // Que faire ici ? L'appli risque de planter si on essaie d'utiliser la box.
      // Il est crucial que l'ouverture dans main() réussisse.
      // On pourrait essayer de l'ouvrir ici mais c'est moins propre :
      // WidgetsBinding.instance.addPostFrameCallback((_) async {
      //   _precipitationBox = await Hive.openBox<Map>('precipitationBox');
      //   setState((){}); // Force rebuild
      // });
    }
    // Pas besoin de _loadSavedData() ici si on utilise ValueListenableBuilder
  }

  @override
  void dispose() {
    _positionController.dispose();
    super.dispose();
  }

  // --- Gestion des Données Hive ---
  Future<void> _saveData() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final String type = _selectedPrecipitation!;
      final String position = _positionController.text;
      // Stocke en UTC, affiche en local
      final String timestamp = DateTime.now().toUtc().toIso8601String();

      final Map<String, dynamic> newEntry = {
        'type': type,
        'position': position,
        'timestamp': timestamp,
      };

      try {
        // Ajoute à la box (Hive gère la clé)
        await _precipitationBox.add(newEntry);
        print('Data added to Hive box.');

        if (!mounted) return;
        _formKey.currentState!.reset();
        _positionController.clear();
        setState(() { _selectedPrecipitation = null; }); // Réinitialise le dropdown visuellement

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data saved successfully!')),
        );
        // Pas besoin de recharger explicitement, ValueListenableBuilder le fera

      } catch (e) {
        print('Error saving data to Hive: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving data: ${e.toString()}')),
        );
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar( content: Text('Please fill all required fields (*) correctly.'), backgroundColor: Colors.orange, ),
      );
    }
  }

  Future<void> _confirmDeleteEntry(dynamic key) async {
    if (!mounted) return;
    final confirm = await showDialog<bool>( context: context, builder: (BuildContext context) {
      return AlertDialog( title: const Text('Confirm Deletion'), content: const Text('Do you really want to delete this entry?'), actions: <Widget>[ TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))), ], ); }, );

    if (confirm == true) {
      try {
        await _precipitationBox.delete(key); // Supprime par clé
        print('Entry deleted from Hive with key: $key');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content: Text('Entry deleted.')), );
        // Pas besoin de recharger, ValueListenableBuilder s'en charge
      } catch (e) {
        print('Error deleting entry from Hive: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('Error deleting entry: $e')), );
      }
    }
  }

  // --- Gestion de la Localisation ---
  Future<void> _getCurrentLocation() async {
    if (kIsWeb) { if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar( content: Text('Automatic location not fully supported on web.'))); return; }
    if (!mounted) return;
    setState(() { _isLoadingLocation = true; });

    bool serviceEnabled; LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled(); if (!serviceEnabled) { if (!mounted) return; ScaffoldMessenger.of(context).showSnackBar(const SnackBar( content: Text('Location services are disabled.'))); setState(() => _isLoadingLocation = false); return; }
    permission = await Geolocator.checkPermission(); if (permission == LocationPermission.denied) { permission = await Geolocator.requestPermission(); if (permission == LocationPermission.denied) { if (!mounted) return; ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content: Text('Location permissions are denied.'))); setState(() => _isLoadingLocation = false); return; } }
    if (permission == LocationPermission.deniedForever) { if (!mounted) return; ScaffoldMessenger.of(context).showSnackBar(const SnackBar( content: Text('Location permissions permanently denied...'))); await openAppSettings(); setState(() => _isLoadingLocation = false); return; }
    try { Position position = await Geolocator.getCurrentPosition( desiredAccuracy: LocationAccuracy.high); if (!mounted) return; setState(() { _positionController.text = 'Lat: ${position.latitude.toStringAsFixed(5)}, Lon: ${position.longitude.toStringAsFixed(5)}'; _isLoadingLocation = false; }); }
    catch (e) { print("Error getting location: $e"); if (!mounted) return; ScaffoldMessenger.of(context).showSnackBar(SnackBar( content: Text('Could not get current location: ${e.toString()}'))); setState(() => _isLoadingLocation = false); }
  }

  // --- Build UI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( title: const Text('Report Environmental Event'), ), // Titre plus spécifique
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
            Text('Recorded Events:', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            _buildSavedDataList(), // Utilise ValueListenableBuilder
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
            hint: const Text('Event type *'), // Label mis à jour
            isExpanded: true,
            items: _precipitationTypes.map<DropdownMenuItem<String>>((String value) =>
                DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
            onChanged: (String? newValue) { setState(() { _selectedPrecipitation = newValue!; }); },
            validator: (value) => value == null ? 'Please select a type' : null,
            decoration: const InputDecoration( border: OutlineInputBorder(), ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _positionController,
            decoration: const InputDecoration(labelText: 'Position / Description *', hintText: 'E.g., Park entrance, or Lat/Lon', border: OutlineInputBorder()),
            validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter a position or description' : null,
            maxLines: 2,
          ),
          const SizedBox(height: 10),
          _isLoadingLocation
              ? const Center(child: Padding( padding: EdgeInsets.symmetric(vertical: 8.0), child: CircularProgressIndicator(), ))
              : ElevatedButton.icon(
            icon: const Icon(Icons.my_location),
            label: const Text('Use Current Location'),
            onPressed: _getCurrentLocation,
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(40)), // Prend toute la largeur
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saveData,
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50), backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Theme.of(context).colorScheme.onPrimary),
            child: const Text('Save Event', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  // Utilise ValueListenableBuilder pour afficher les données Hive
  Widget _buildSavedDataList() {
    // Vérifie si la box est initialisée (sécurité)
    if (!Hive.isBoxOpen('precipitationBox')) {
      return const Center(child: Text("Error: Data box not available.", style: TextStyle(color: Colors.red)));
    }

    return ValueListenableBuilder<Box<Map>>(
        valueListenable: _precipitationBox.listenable(),
        builder: (context, box, _) {
          // Les clés et valeurs sont lues à chaque notification de la box
          final keys = box.keys.toList().reversed.toList(); // Récupère les clés pour suppression
          final entries = box.values.toList().reversed.toList(); // Récupère les valeurs

          if (entries.isEmpty) {
            return const Center(child: Padding( padding: EdgeInsets.all(20.0), child: Text('No events recorded yet.'), ));
          }

          return ListView.builder(
            shrinkWrap: true, // Important dans un SingleChildScrollView
            physics: const NeverScrollableScrollPhysics(), // Empêche le scroll interne
            itemCount: entries.length,
            itemBuilder: (context, index) {
              // Récupère la Map et la clé pour cet item
              final entryMap = Map<String, dynamic>.from(entries[index]);
              final entryKey = keys[index];

              // Formatage de la date/heure
              DateTime dateTimeLocal = DateTime.now(); // Default
              if (entryMap['timestamp'] != null) {
                dateTimeLocal = DateTime.tryParse(entryMap['timestamp'] as String? ?? '')?.toLocal() ?? DateTime.now();
              }
              final formattedDate = DateFormat.yMd().add_Hms().format(dateTimeLocal);

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: Icon(_getIconForType(entryMap['type'] as String?)), // Ajoute une icône basée sur le type
                  title: Text(entryMap['type'] ?? 'Unknown Type', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      '${entryMap['position'] ?? 'Not defined'}\n' // Position en premier
                          '$formattedDate', // Date en dessous
                      maxLines: 3, overflow: TextOverflow.ellipsis), // Gère texte long
                  trailing: IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red[300]),
                    tooltip: 'Delete Entry',
                    onPressed: () => _confirmDeleteEntry(entryKey), // Passe la clé Hive
                  ),
                  isThreeLine: true,
                  dense: true, // Rend la liste un peu plus compacte
                ),
              );
            },
          );
        }
    );
  }

  // Helper pour obtenir une icône basée sur le type d'événement
  IconData _getIconForType(String? type) {
    switch (type) { case 'Flood': return Icons.water_drop; case 'Drought': return Icons.local_fire_department_outlined; case 'Fallen Trees': return Icons.park_outlined; case 'Heavy Hail': return Icons.grain; case 'Heavy Rain': return Icons.water_drop_outlined; case 'Heavy Snow': return Icons.ac_unit; case 'Other (specify in position)': return Icons.help_outline; default: return Icons.report_problem_outlined; }
  }

}