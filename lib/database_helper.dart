import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DB {
  static Future<Database> init() async {
    return openDatabase(
      join(await getDatabasesPath(), 'todo_pro_final_v15.db'),
      onCreate: (db, version) => db.execute(
          'CREATE TABLE tasks(id INTEGER PRIMARY KEY, title TEXT, date TEXT, priority TEXT, category TEXT, status TEXT)'),
      version: 1,
    );
  }
}