import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';

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
    return await openDatabase(path,
        version: 1, onCreate: _onCreate, onConfigure: onConfigure);
  }

  Future onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
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
        // temps ecoulé : string au format XX:XX:XX (heures:minutes:secondes)
        // temps total des taches de la catégorie, calculé automatiquement
        "temps_ecoule	TEXT DEFAULT '00:00:00',"
        "id_categorie_sup	INTEGER,"
        "FOREIGN KEY(id_categorie_sup) REFERENCES categories(id) ON DELETE CASCADE)");

    await db.execute("CREATE TABLE IF NOT EXISTS taches ("
        "id	INTEGER PRIMARY KEY AUTOINCREMENT,"
        "nom TEXT NOT NULL,"
        /* couleur stockée en string
           si Color black = Color(0xFF000000)
           alors on stocke black.value.toRadixString(16) = "ff000000"
         */
        "couleur TEXT NOT NULL,"
        // temps ecoulé : string au format XX:XX:XX (heures:minutes:secondes)
        // calculé automatiquement
        "temps_ecoule	TEXT DEFAULT '00:00:00',"
        // id_categorie = 1 si la tache est une single task
        "id_categorie	INTEGER NOT NULL,"
        "FOREIGN KEY(id_categorie) REFERENCES categories(id) ON DELETE CASCADE)");

    await db.execute("CREATE TABLE IF NOT EXISTS deroulement_tache ("
        "id	INTEGER PRIMARY KEY AUTOINCREMENT,"
        "id_tache	INTEGER NOT NULL,"
        // date+heure stocké en string (iso8601 : 2023-03-09T16:30:00Z)
        "date_debut	TEXT NOT NULL,"
        "date_fin	TEXT,"
        "Longitude REAL NOT NULL,"
        "Latitude	REAL NOT NULL,"
        "FOREIGN KEY(id_tache) REFERENCES taches(id) ON DELETE CASCADE)");

    // table à update seulement, un seul insert à l'initialisation (car on a qu'un seul utilisateur pour l'instant)
    await db.execute(" CREATE TABLE parametres ("
        // theme préféré : 0 = rouge, 1 = bleu, 2 = orange, défaut = 1
        "theme_prefere INTEGER DEFAULT 1,"
        // settings time filter, 0 = jour par jour, 1 = semaine par semaine, 2 = mois par mois
        "time_filter_preference INTEGER DEFAULT 0)");

    // insertion de valeurs

    // parametres
    await db.execute("INSERT INTO parametres DEFAULT VALUES;");

    // categories
    await db.execute('''
      INSERT INTO categories (nom, couleur) VALUES 
        ('Single Tasks', 'ff000000'),
        ('Axari Graphics', 'ff2b8713'),
        ('Website Ions Inc.', 'ff6c1387'), 
        ('Categorie3', 'ff453bec'), 
        ('Categorie4', 'ffec9e3b'), 
        ('Categorie5', 'ff3b4eec'), 
        ('Categorie6', 'ffdc3bec')
    ''');

    // taches
    await db.execute('''
      INSERT INTO taches (nom, couleur, id_categorie) VALUES 
        ('Communication', 'ffff0000', 1),
        ('Invoicing', 'ff00ff00', 1),
        ('Logo design', 'ff0000ff', 2),
        ('Brochure', 'ffff7000', 2),
        ('Webdesign', 'ffff00ff', 2),
        ('Concept', 'ff00ffff', 3),
        ('Screendesign', 'ff000000', 3),
        ('Tache 8', 'ff800000', 4),
        ('Tache 9', 'ff008000', 4),
        ('Tache 10', 'ff000080', 5),
        ('Tache 11', 'ff808080', 6),
        ('Tache 12', 'ffff0000', 6),
        ('Tache 13', 'ff00ff00', 7),
        ('Tache 14', 'ff0000ff', 7)
    ''');

    // procédure pour mettre à jour automatiquement les champs temp_ecoule
    // dans la table taches et dans la table categories à chaque fois que
    // l'on insert une nouvelle ligne dans la table deroulement_tache
    await db.execute('''
    CREATE TRIGGER update_temps_ecoule AFTER INSERT ON deroulement_tache
    BEGIN
      UPDATE taches SET temps_ecoule = (
        SELECT COALESCE(
          time(SUM(CASE WHEN date_fin != '' THEN strftime('%s', datetime(date_fin)) - strftime('%s', datetime(date_debut)) ELSE 0 END), 'unixepoch'),
          '00:00:00'
        )
        FROM deroulement_tache
        WHERE deroulement_tache.id_tache = taches.id
      )
      WHERE id = NEW.id_tache;

      UPDATE categories SET temps_ecoule = (
        SELECT COALESCE(
          time(SUM(CASE WHEN deroulement_tache.date_fin != '' THEN strftime('%s', datetime(deroulement_tache.date_fin)) - strftime('%s', datetime(deroulement_tache.date_debut)) ELSE 0 END), 'unixepoch'),
          '00:00:00'
        )
        FROM deroulement_tache
        INNER JOIN taches ON deroulement_tache.id_tache = taches.id
        WHERE taches.id_categorie = categories.id
      )
      WHERE id = (
        SELECT id_categorie
        FROM taches
        WHERE id = NEW.id_tache
      );
    END;
    ''');

    // procédure pour mettre à jour automatiquement les champs temp_ecoule
    // dans la table taches et dans la table categories à chaque fois que
    // l'on update une ligne dans la table deroulement_tache
    await db.execute('''
    CREATE TRIGGER update_temps_ecoule_update AFTER UPDATE ON deroulement_tache
    BEGIN
      UPDATE taches SET temps_ecoule = (
        SELECT COALESCE(
          time(SUM(CASE WHEN date_fin != '' THEN strftime('%s', datetime(date_fin)) - strftime('%s', datetime(date_debut)) ELSE 0 END), 'unixepoch'),
          '00:00:00'
        )
        FROM deroulement_tache
        WHERE deroulement_tache.id_tache = taches.id
      )
      WHERE id = NEW.id_tache;
    
      UPDATE categories SET temps_ecoule = (
        SELECT COALESCE(
          time(SUM(CASE WHEN deroulement_tache.date_fin != '' THEN strftime('%s', datetime(deroulement_tache.date_fin)) - strftime('%s', datetime(deroulement_tache.date_debut)) ELSE 0 END), 'unixepoch'),
          '00:00:00'
        )
        FROM deroulement_tache
        INNER JOIN taches ON deroulement_tache.id_tache = taches.id
        WHERE taches.id_categorie = categories.id
      )
      WHERE id IN (
        SELECT id_categorie
        FROM taches
        WHERE id = NEW.id_tache
      );
    END;
    ''');

    // procédure pour mettre à jour automatiquement les champs temp_ecoule
    // dans la table taches et dans la table categories à chaque fois que
    // l'on supprime une ligne dans la table deroulement_tache
    await db.execute('''
    CREATE TRIGGER update_temps_ecoule_delete AFTER DELETE ON deroulement_tache
    BEGIN
      UPDATE taches SET temps_ecoule = COALESCE(
        (SELECT time(SUM(strftime('%s', datetime(date_fin)) - strftime('%s', datetime(date_debut))), 'unixepoch')
        FROM deroulement_tache
        WHERE deroulement_tache.id_tache = taches.id), '00:00:00')
      WHERE id = OLD.id_tache;
    
      UPDATE categories SET temps_ecoule = COALESCE(
        (SELECT time(SUM(strftime('%s', datetime(date_fin)) - strftime('%s', datetime(date_debut))), 'unixepoch')
        FROM deroulement_tache
        INNER JOIN taches ON deroulement_tache.id_tache = taches.id
        WHERE taches.id_categorie = categories.id), '00:00:00')
      WHERE id = (
        SELECT id_categorie
        FROM taches
        WHERE id = OLD.id_tache
      );
    END;
    ''');

    // procédure pour mettre à jour automatiquement le champ temp_ecoule
    // dans la table categories à chaque fois que l'on supprime une ligne dans la table taches
    await db.execute('''
    CREATE TRIGGER update_temps_ecoule_delete_task AFTER DELETE ON taches
    BEGIN
      UPDATE categories SET temps_ecoule = COALESCE(
        (SELECT time(SUM(strftime('%s', datetime(date_fin)) - strftime('%s', datetime(date_debut))), 'unixepoch')
        FROM deroulement_tache
        INNER JOIN taches ON deroulement_tache.id_tache = taches.id
        WHERE taches.id_categorie = categories.id), '00:00:00')
      WHERE id = OLD.id_categorie;
    END;
    ''');

    // déroulement tache
    final now = DateTime.now().toUtc();
    final yesterday = now.subtract(Duration(days: 1));
    final oneWeekAgo = now.subtract(Duration(days: 7));
    final oneMonthAgo = now.subtract(Duration(days: 30));
    final formatter = DateFormat('yyyy-MM-ddTHH:mm:ss');

    await db.execute(
        "INSERT INTO deroulement_tache (id_tache, date_debut, date_fin, latitude, longitude) VALUES "
        "(1, '${formatter.format(now) + 'Z'}', '${formatter.format(now.add(Duration(hours: 2))) + 'Z'}', 48.8566, 2.3522),"
        "(1, '${formatter.format(yesterday) + 'Z'}', '${formatter.format(yesterday.add(Duration(minutes: 45))) + 'Z'}', 48.8647, 2.3490),"
        "(2, '${formatter.format(oneWeekAgo) + 'Z'}', '${formatter.format(oneWeekAgo.add(Duration(hours: 1, minutes: 30))) + 'Z'}', 48.8534, 2.3488),"
        "(3, '${formatter.format(oneMonthAgo) + 'Z'}', '${formatter.format(oneMonthAgo.add(Duration(hours: 2, minutes: 12))) + 'Z'}', 48.8606, 2.3522),"
        "(4, '2023-03-13T14:00:00Z', '2023-03-13T15:00:00Z', 48.8566, 2.3382),"
        "(4, '2023-03-14T11:00:00Z', '2023-03-14T12:00:00Z', 48.8599, 2.3414),"
        "(4, '2023-03-15T15:30:00Z', '2023-03-15T17:00:00Z', 48.8631, 2.3455),"
        "(5, '2023-03-16T08:30:00Z', '2023-03-16T10:00:00Z', 48.8566, 2.3522),"
        "(6, '2023-03-17T14:30:00Z', '2023-03-17T15:10:00Z', 48.8566, 2.3522),"
        "(6, '2023-03-18T08:30:00Z', '2023-03-18T10:00:00Z', 48.8566, 2.3522),"
        "(7, '2023-03-18T10:30:00Z', '2023-03-18T12:00:00Z', 48.8566, 2.3522);");
  }
}
