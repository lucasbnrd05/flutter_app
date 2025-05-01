// lib/services/database_helper.dart

import 'dart:async';
import 'dart:io'; // Pour Directory

import 'package:path/path.dart'; // Importe le package path
import 'package:path_provider/path_provider.dart'; // Pour trouver le chemin
import 'package:sqflite/sqflite.dart'; // Importe sqflite
import '../models/event.dart'; // Importe notre modèle Event

class DatabaseHelper {
  // --- Singleton Pattern ---
  // Rend cette classe un singleton pour qu'il n'y ait qu'une seule instance
  // de la connexion à la base de données dans toute l'application.
  DatabaseHelper._privateConstructor(); // Constructeur privé
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor(); // Instance unique

  // Référence privée à la base de données (peut être null si pas initialisée)
  static Database? _database;

  // Getter pour la base de données. Initialise si elle n'existe pas.
  Future<Database> get database async {
    if (_database != null) return _database!; // Si déjà initialisée, la retourne
    // Sinon, initialise la base de données
    _database = await _initDatabase();
    return _database!;
  }

  // --- Initialisation de la Base de Données ---
  Future<Database> _initDatabase() async {
    // 1. Obtenir le chemin du répertoire où stocker la BDD
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    // 2. Créer le chemin complet vers le fichier de la BDD
    //    Utilise join du package 'path' pour créer un chemin multiplateforme correct
    String path = join(documentsDirectory.path, 'events.db');
    print("[DatabaseHelper] Database path: $path"); // Log du chemin

    // 3. Ouvrir la base de données à ce chemin
    return await openDatabase(
      path,
      version: 1, // Version de la BDD (pour les migrations futures)
      onCreate: _onCreate, // Fonction à exécuter lors de la création initiale
    );
  }

  // --- Création de la Table (onCreate) ---
  // Cette fonction est appelée seulement la première fois que la BDD est créée.
  Future _onCreate(Database db, int version) async {
    print("[DatabaseHelper] Creating 'events' table...");
    await db.execute('''
      CREATE TABLE events (
        id INTEGER PRIMARY KEY AUTOINCREMENT, -- Clé primaire auto-générée
        type TEXT NOT NULL,                   -- Type d'événement (non null)
        latitude REAL NOT NULL,               -- Latitude (nombre réel non null)
        longitude REAL NOT NULL,              -- Longitude (nombre réel non null)
        description TEXT NOT NULL,            -- Description/Position texte (non null)
        timestamp TEXT NOT NULL               -- Timestamp ISO 8601 UTC (non null)
      )
      ''');
    print("[DatabaseHelper] 'events' table created.");
  }

  // --- Opérations CRUD ---

  // 1. CREATE (Insérer un événement)
  Future<int> insertEvent(Event event) async {
    Database db = await instance.database;
    // La méthode insert retourne l'ID de la nouvelle ligne insérée.
    print("[DatabaseHelper] Inserting event: ${event.toMap()}");
    int id = await db.insert(
      'events',       // Nom de la table
      event.toMap(),  // Données de l'événement converties en Map
      conflictAlgorithm: ConflictAlgorithm.replace, // Si un conflit (ex: même ID), remplace la ligne existante (moins probable avec AUTOINCREMENT)
    );
    print("[DatabaseHelper] Event inserted with id: $id");
    return id;
  }

  // 2. READ (Récupérer tous les événements)
  Future<List<Event>> getAllEvents() async {
    Database db = await instance.database;
    // query retourne une List<Map<String, dynamic>>.
    final List<Map<String, dynamic>> maps = await db.query(
        'events',
        orderBy: 'id DESC' // Optionnel: Ordonne par ID décroissant (les plus récents d'abord)
    );
    print("[DatabaseHelper] Found ${maps.length} events in DB.");

    // Convertit la List<Map<String, dynamic>> en List<Event>.
    if (maps.isEmpty) {
      return [];
    }
    return List.generate(maps.length, (i) {
      return Event.fromMap(maps[i]);
    });
  }

  // 3. READ (Récupérer un événement par ID) - Utile pour la page détail
  Future<Event?> getEventById(int id) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'events',
      where: 'id = ?', // Clause WHERE pour filtrer par ID
      whereArgs: [id], // Argument pour la clause WHERE
      limit: 1,        // On ne s'attend qu'à un seul résultat
    );

    if (maps.isNotEmpty) {
      print("[DatabaseHelper] Found event with id $id: ${maps.first}");
      return Event.fromMap(maps.first);
    } else {
      print("[DatabaseHelper] Event with id $id not found.");
      return null; // Retourne null si aucun événement avec cet ID n'est trouvé
    }
  }

  // 4. DELETE (Supprimer un événement par ID)
  Future<int> deleteEvent(int id) async {
    Database db = await instance.database;
    // La méthode delete retourne le nombre de lignes supprimées.
    print("[DatabaseHelper] Deleting event with id: $id");
    int count = await db.delete(
      'events',       // Nom de la table
      where: 'id = ?', // Clause WHERE pour trouver la bonne ligne
      whereArgs: [id], // Argument pour la clause WHERE
    );
    print("[DatabaseHelper] Deleted $count event(s).");
    return count;
  }

  // 5. UPDATE (Non utilisé pour l'instant, mais voici un exemple)
  // Future<int> updateEvent(Event event) async {
  //   Database db = await instance.database;
  //   // Nécessite que l'objet Event ait un ID non null
  //   if (event.id == null) return 0;
  //   return await db.update(
  //     'events',
  //     event.toMap(),
  //     where: 'id = ?',
  //     whereArgs: [event.id],
  //   );
  // }

  // --- Fermeture de la base de données (Optionnel mais bonne pratique si besoin) ---
  Future close() async {
    Database db = await instance.database;
    _database = null; // Réinitialise la référence
    await db.close();
    print("[DatabaseHelper] Database closed.");
  }
}