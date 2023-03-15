import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

Database _database;
Future<Database> get database async {
  if (_database != null) {
    return _database;
  }

  // If the database doesn't exist yet, create it.
  _database = await openDatabase(
    join(await getDatabasesPath(), 'data.db'),
  );

  // Perform any necessary migrations or other initialization here.
  // ...

  return _database;
}

void ModifierNomTache(int idTache, String newName) async {
  final db = await database;
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
