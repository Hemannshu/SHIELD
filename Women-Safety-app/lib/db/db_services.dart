import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:title_proj/model/contactsm.dart';

class DatabaseHelper {
  static DatabaseHelper? _databaseHelper;
  static Database? _database;

  String contactTable = 'contact_table';
  String colId = 'id';
  String colContactName = 'name';
  String colContactNumber = 'number';

  DatabaseHelper._createInstance();

  factory DatabaseHelper() {
    _databaseHelper ??= DatabaseHelper._createInstance();
    return _databaseHelper!;
  }

  Future<Database> get database async {
    _database ??= await initializeDatabase();
    return _database!;
  }

  Future<Database> initializeDatabase() async {
    String path = join(await getDatabasesPath(), 'contact.db');
    return await openDatabase(path, version: 1, onCreate: _createDbTable);
  }

  void _createDbTable(Database db, int newVersion) async {
    await db.execute(
      'CREATE TABLE $contactTable($colId INTEGER PRIMARY KEY AUTOINCREMENT, $colContactName TEXT, $colContactNumber TEXT)'
    );
  }

  Future<List<Map<String, dynamic>>> getContactMapList() async {
    Database db = await this.database;
    return await db.query(contactTable, orderBy: '$colId ASC');
  }

  Future<int> insertContact(TContact contact) async {
    Database db = await this.database;
    return await db.insert(contactTable, contact.toMap());
  }

  Future<int> deleteContact(int id) async {
    Database db = await this.database;
    return await db.delete(contactTable, where: '$colId = ?', whereArgs: [id]);
  }

  Future<int> getCount() async {
    Database db = await this.database;
    List<Map<String, dynamic>> x = await db.rawQuery('SELECT COUNT(*) from $contactTable');
    return Sqflite.firstIntValue(x) ?? 0;
  }

  Future<List<TContact>> getContactList() async {
    var contactMapList = await getContactMapList();
    return contactMapList.map((contact) => TContact.fromMapObject(contact)).toList();
  }

  Future<bool> contactExists(String number) async {
    Database db = await this.database;
    List<Map<String, dynamic>> result = await db.query(contactTable, where: '$colContactNumber = ?', whereArgs: [number]);
    return result.isNotEmpty;
  }
}
