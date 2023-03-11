import 'dart:io';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'Categorie.dart';
import 'User.dart';

class InitDatabase {
  static final InitDatabase _initDatabase_ = InitDatabase._internal();

  factory InitDatabase() {
    return _initDatabase_;
  }

  InitDatabase._internal();

  static Database _database;

  Future<Database> get database async {
    if (_database != null) return _database;

    _database = await _initDatabase();
    return _database;
  }

  _initDatabase() async {
    String path = await getDatabasesPath();
    path = join(path, 'base.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  _onCreate(Database db, int version) async {
    await db.execute(" CREATE TABLE users ("
                        "id	INTEGER NOT NULL,"
                        "username	VARCHAR(255) NOT NULL,"
                        "email	VARCHAR(255) NOT NULL UNIQUE,"
                        "password	VARCHAR(255) NOT NULL,"
                        "color integer NOT NULL DEFAULT 0,"
                        "registered_on	DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,"
                        "PRIMARY KEY(id))"
                    );

    await db.execute("CREATE TABLE categories ("
                        "id	INTEGER NOT NULL,"
                        "nom VARCHAR(255) NOT NULL,"
                        "couleur VARCHAR(16) NOT NULL,"
                        "id_categorie_sup	INTEGER NOT NULL,"
                        "id_user	INTEGER NOT NULL,"
                        "FOREIGN KEY(id_user) REFERENCES users(id),"
                        "FOREIGN KEY(id_categorie_sup) REFERENCES categorie(id),"
                        "PRIMARY KEY(id))"
                    );

    await db.execute("CREATE TABLE taches ("
                        "id	INTEGER NOT NULL,"
                        "nom	VARCHAR(255) NOT NULL,"
                        "couleur	VARCHAR(16) NOT NULL,"
                        "temps_ecoule	INTEGER NOT NULL DEFAULT 0,"
                        "id_categorie	INTEGER NOT NULL,"
                        "FOREIGN KEY(id_categorie) REFERENCES categories(id),"
                        "PRIMARY KEY(id))"
                    );

    await db.execute("CREATE TABLE deroulement_tache ("
                        "id	INTEGER NOT NULL,"
                        "id_tache	INTEGER NOT NULL,"
                        "date_debut	DATETIME NOT NULL,"
                        "date_fin	DATETIME NOT NULL,"
                        "Longitude	FLOAT NOT NULL,"
                        "Latitude	FLOAT NOT NULL,"
                        "PRIMARY KEY(id),"
                        "FOREIGN KEY(id_tache) REFERENCES taches(id))"
                    );

    //insertion default user
    var user = User(username: 'default', email: 'default@default.com', password: 'default', color: 0);
    //insert user to database
    await db.insert('users', user.toMap());
    //insertion default categorie
    var categorie = Categorie(nom: 'default', couleur: 'default', id_categorie_sup: 1, id_user: 1);
    //insert categorie to database
    await db.insert('categories', categorie.toMap());
  }
}