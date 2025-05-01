// lib/services/database_helper.dart

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/event.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance =
  DatabaseHelper._privateConstructor();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

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

  Future<List<Event>> getAllEvents() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('events',
        orderBy: 'id DESC');
    print("[DatabaseHelper] Found ${maps.length} events in DB.");
    if (maps.isEmpty) {
      return [];
    }
    return List.generate(maps.length, (i) {
      return Event.fromMap(maps[i]);
    });
  }

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

  Future<Event?> getLastEvent() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'events',
      orderBy: 'id DESC',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      final lastEvent = Event.fromMap(maps.first);
      print("[DatabaseHelper] Found last event (ID ${lastEvent.id}): ${maps.first}");
      if ((lastEvent.latitude != 0.0 || lastEvent.longitude != 0.0) &&
          lastEvent.latitude.abs() <= 90 && lastEvent.longitude.abs() <= 180) {
        return lastEvent;
      } else {
        print("[DatabaseHelper] Last event (ID ${lastEvent.id}) has invalid coordinates, returning null.");
        return null;
      }
    } else {
      print("[DatabaseHelper] No events found in the database.");
      return null;
    }
  }

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

  Future close() async {
    Database db = await instance.database;
    _database = null;
    await db.close();
    print("[DatabaseHelper] Database closed.");
  }
}