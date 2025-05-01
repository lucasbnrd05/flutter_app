// lib/services/database_helper.dart

import 'dart:async';
import 'dart:io'; // Pour Directory

import 'package:path/path.dart'; // Importe le package path
import 'package:path_provider/path_provider.dart'; // Pour trouver le chemin
import 'package:sqflite/sqflite.dart'; // Importe sqflite
import '../models/event.dart'; // Importe notre modèle Event

class DatabaseHelper {
  // --- Singleton Pattern ---
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance =
  DatabaseHelper._privateConstructor();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // --- Initialisation ---
  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'events.db');
    print("[DatabaseHelper] Database path: $path");
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  // --- Création Table ---
  Future _onCreate(Database db, int version) async {
    print("[DatabaseHelper] Creating 'events' table...");
    await db.execute('''
      CREATE TABLE events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        description TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
      ''');
    print("[DatabaseHelper] 'events' table created.");
  }

  // --- Opérations CRUD ---

  // CREATE
  Future<int> insertEvent(Event event) async {
    Database db = await instance.database;
    print("[DatabaseHelper] Inserting event: ${event.toMap()}");
    int id = await db.insert(
      'events',
      event.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print("[DatabaseHelper] Event inserted with id: $id");
    return id;
  }

  // READ ALL
  Future<List<Event>> getAllEvents() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('events',
        orderBy: 'id DESC'); // Tri par ID pour avoir les plus récents en premier
    print("[DatabaseHelper] Found ${maps.length} events in DB.");
    if (maps.isEmpty) {
      return [];
    }
    return List.generate(maps.length, (i) {
      return Event.fromMap(maps[i]);
    });
  }

  // READ ONE BY ID
  Future<Event?> getEventById(int id) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'events',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      print("[DatabaseHelper] Found event with id $id: ${maps.first}");
      return Event.fromMap(maps.first);
    } else {
      print("[DatabaseHelper] Event with id $id not found.");
      return null;
    }
  }

  // **** NOUVELLE MÉTHODE : READ LAST EVENT ****
  Future<Event?> getLastEvent() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'events',
      orderBy: 'id DESC', // Ordonne par ID décroissant
      limit: 1, // Ne prend que le premier (le plus récent)
    );
    if (maps.isNotEmpty) {
      final lastEvent = Event.fromMap(maps.first);
      print("[DatabaseHelper] Found last event (ID ${lastEvent.id}): ${maps.first}");
      // Vérifie si les coordonnées sont valides avant de retourner
      if ((lastEvent.latitude != 0.0 || lastEvent.longitude != 0.0) &&
          lastEvent.latitude.abs() <= 90 && lastEvent.longitude.abs() <= 180) {
        return lastEvent;
      } else {
        print("[DatabaseHelper] Last event (ID ${lastEvent.id}) has invalid coordinates, returning null.");
        return null; // Retourne null si les coordonnées ne sont pas valides
      }
    } else {
      print("[DatabaseHelper] No events found in the database.");
      return null; // Retourne null si la table est vide
    }
  }
  // **** FIN NOUVELLE MÉTHODE ****

  // DELETE
  Future<int> deleteEvent(int id) async {
    Database db = await instance.database;
    print("[DatabaseHelper] Deleting event with id: $id");
    int count = await db.delete(
      'events',
      where: 'id = ?',
      whereArgs: [id],
    );
    print("[DatabaseHelper] Deleted $count event(s).");
    return count;
  }

  // --- Fermeture ---
  Future close() async {
    Database db = await instance.database;
    _database = null;
    await db.close();
    print("[DatabaseHelper] Database closed.");
  }
}