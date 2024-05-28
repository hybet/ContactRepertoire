import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'contacts.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute(
      'CREATE TABLE contacts (id INTEGER PRIMARY KEY, name TEXT, firstName TEXT, number TEXT)',
    );
  }

  Future<int> insertContact(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('contacts', row);
  }

  Future<List<Map<String, dynamic>>> queryAllContacts() async {
    Database db = await database;
    return await db.query('contacts', orderBy: 'name ASC');
  }

  Future<int> updateContact(Map<String, dynamic> row) async {
    Database db = await database;
    int id = row['id'];
    return await db.update('contacts', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteContact(int id) async {
    Database db = await database;
    return await db.delete('contacts', where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> contactExists(String name, String firstName, String number) async {
    Database db = await database;
    var result = await db.query(
      'contacts',
      where: ' number = ?',
      whereArgs: [number],
    );
    return result.isNotEmpty;
  }
}