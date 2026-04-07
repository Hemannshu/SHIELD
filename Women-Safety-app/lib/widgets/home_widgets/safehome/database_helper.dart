import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = await getDatabasesPath();
    return openDatabase(
      join(path, 'emergency_locations.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE locations(id INTEGER PRIMARY KEY AUTOINCREMENT, latitude REAL, longitude REAL, timestamp INTEGER, sent INTEGER DEFAULT 0)',
        );
      },
      version: 1,
    );
  }

  Future<int> insertLocation(double latitude, double longitude) async {
    final db = await database;
    return await db.insert('locations', {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<Map<String, dynamic>>> getUnsentLocations() async {
    final db = await database;
    return await db.query(
      'locations',
      where: 'sent = ?',
      whereArgs: [0],
    );
  }

  Future<int> markAsSent(int id) async {
    final db = await database;
    return await db.update(
      'locations',
      {'sent': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}