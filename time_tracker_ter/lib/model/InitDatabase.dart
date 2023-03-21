import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'Categorie.dart';
import 'Tache.dart';

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
    await db.execute("CREATE TABLE IF NOT EXISTS categories ("
        "id	INTEGER PRIMARY KEY AUTOINCREMENT,"
        "nom TEXT NOT NULL,"
        /* couleur stockée en string
           si Color blue = Color(0xFF000000)
           alors on stocke black.value.toRadixString(16) = "ff000000"
         */
        "couleur TEXT NOT NULL,"
        "id_categorie_sup	INTEGER,"
        "FOREIGN KEY(id_categorie_sup) REFERENCES categories(id))");

    await db.execute("CREATE TABLE IF NOT EXISTS taches ("
        "id	INTEGER PRIMARY KEY AUTOINCREMENT,"
        "nom TEXT NOT NULL,"
        /* couleur stockée en string
           si Color black = Color(0xFF000000)
           alors on stocke black.value.toRadixString(16) = "ff000000"
         */
        "couleur TEXT NOT NULL,"
        // temps ecoulé : string au format XX:XX:XX (heures:minutes:secondes)
        "temps_ecoule	TEXT NOT NULL,"
        "id_categorie	INTEGER,"
        "FOREIGN KEY(id_categorie) REFERENCES categories(id))");

    await db.execute("CREATE TABLE IF NOT EXISTS deroulement_tache ("
        "id	INTEGER PRIMARY KEY AUTOINCREMENT,"
        "id_tache	INTEGER NOT NULL,"
        // date+heure stocké en string (iso8601 : 2023-03-09T16:30:00Z)
        "date_debut	TEXT NOT NULL,"
        "date_fin	TEXT,"
        "Longitude REAL NOT NULL,"
        "Latitude	REAL NOT NULL,"
        "FOREIGN KEY(id_tache) REFERENCES taches(id))");

    // table à update seulement, un seul insert à l'initialisation (car on a qu'un seul utilisateur pour l'instant)
    await db.execute(" CREATE TABLE parametres ("
        // utilisé pour l'autocomplétion du champ email lors de l'export, par défaut le string est vide
        "email_export TEXT DEFAULT '',"
        // theme préféré : 0 = rouge, 1 = bleu, 2 = orange, défaut = 1
        "theme_prefere INTEGER DEFAULT 1,"
        // settings time filter, 0 = jour par jour, 1 = semaine par semaine, 2 = mois par mois
        "time_filter_preference INTEGER DEFAULT 0)");

    // insertion de valeurs

    // parametres
    await db.execute("INSERT INTO parametres DEFAULT VALUES;");

    // categories
    var categorie1 = Categorie(nom: "Axari Graphics", couleur: "ff2b8713");
    var categorie2 = Categorie(nom: "Website Ions Inc.", couleur: "ff6c1387");
    var categorie3 = Categorie(nom: "Categorie3", couleur: "ff453bec");
    var categorie4 = Categorie(nom: "Categorie4", couleur: "ffec9e3b");
    var categorie5 = Categorie(nom: "Categorie5", couleur: "ff3b4eec");
    var categorie6 = Categorie(nom: "Categorie6", couleur: "ffdc3bec");
    var batch = db.batch();
    batch.insert('categories', categorie1.toMap());
    batch.insert('categories', categorie2.toMap());
    batch.insert('categories', categorie3.toMap());
    batch.insert('categories', categorie4.toMap());
    batch.insert('categories', categorie5.toMap());
    batch.insert('categories', categorie6.toMap());
    await batch.commit();

    // taches
    var tache1 = Tache(
        nom: "Communication", couleur: "ff000000", temps_ecoule: "00:00:00");
    var tache2 =
        Tache(nom: "Invoicing", couleur: "ff000000", temps_ecoule: "00:00:00");
    var tache3 = Tache(
        nom: "Logo design",
        couleur: "ff000000",
        id_categorie: 1,
        temps_ecoule: "00:00:00");
    var tache4 = Tache(
        nom: "Brochure",
        couleur: "ff000000",
        id_categorie: 1,
        temps_ecoule: "00:00:00");
    var tache5 = Tache(
        nom: "Webdesign",
        couleur: "ff000000",
        id_categorie: 1,
        temps_ecoule: "00:00:00");
    var tache6 = Tache(
        nom: "Concept",
        couleur: "ff000000",
        id_categorie: 2,
        temps_ecoule: "00:00:00");
    var tache7 = Tache(
        nom: "Screendesign",
        couleur: "ff000000",
        id_categorie: 2,
        temps_ecoule: "00:00:00");
    var tache8 = Tache(
        nom: "Tache 8",
        couleur: "ff000000",
        id_categorie: 3,
        temps_ecoule: "00:00:00");
    var tache9 = Tache(
        nom: "Tache 9",
        couleur: "ff000000",
        id_categorie: 3,
        temps_ecoule: "00:00:00");
    var tache10 = Tache(
        nom: "Tache 10",
        couleur: "ff000000",
        id_categorie: 4,
        temps_ecoule: "00:00:00");
    var tache11 = Tache(
        nom: "Tache 11",
        couleur: "ff000000",
        id_categorie: 5,
        temps_ecoule: "00:00:00");
    var tache12 = Tache(
        nom: "Tache 12",
        couleur: "ff000000",
        id_categorie: 5,
        temps_ecoule: "00:00:00");
    var tache13 = Tache(
        nom: "Tache 13",
        couleur: "ff000000",
        id_categorie: 6,
        temps_ecoule: "00:00:00");
    var tache14 = Tache(
        nom: "Tache 14",
        couleur: "ff000000",
        id_categorie: 6,
        temps_ecoule: "00:00:00");
    batch = db.batch();
    batch.insert('taches', tache1.toMap());
    batch.insert('taches', tache2.toMap());
    batch.insert('taches', tache3.toMap());
    batch.insert('taches', tache4.toMap());
    batch.insert('taches', tache5.toMap());
    batch.insert('taches', tache6.toMap());
    batch.insert('taches', tache7.toMap());
    batch.insert('taches', tache8.toMap());
    batch.insert('taches', tache9.toMap());
    batch.insert('taches', tache10.toMap());
    batch.insert('taches', tache11.toMap());
    batch.insert('taches', tache12.toMap());
    batch.insert('taches', tache13.toMap());
    batch.insert('taches', tache14.toMap());
    await batch.commit();
  }
}
