import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';


Database _database;
Future<Database> get database async {
  if (_database != null) {
    return _database;
  }

  // Get a location using getDatabasesPath
  var databasesPath = await getDatabasesPath();
  var path = join(databasesPath, 'base.db');

  // Check if the database file exists
  var exists = await databaseExists(path);

  if (!exists) {
    // If the database doesn't exist, create a new one
    // Perform any necessary migrations or other initialization here.
    // ...

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        // create your database tables here
      },
    );
  } else {
    // If the database exists, open it
    _database = await openDatabase(path);
  }

  return _database;
}

void ModifierNomTache(int idTache, String newName) async {
  var databasesPath = await getDatabasesPath();
  var path = join(databasesPath, "base.db");
  Database db = await openDatabase(path);
  print("this is my db $db");
  await db.update(
    'taches',
    {'nom': newName},
    where: 'id = ?',
    whereArgs: [idTache],
  );
}

//modifier id_categorie du tache
void ModifierGroupeCategorie(int idTache, int newId) async {
  final db = await database;
  await db.update(
    'taches',
    {'id_categorie': newId},
    where: 'id = ?',
    whereArgs: [idTache],
  );
}

void DeleteTache(int idTache) async {
  final db = await database;
  await db.delete(
    'taches',
    where: 'id = ?',
    whereArgs: [idTache],
  );
}
