import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:page_transition/page_transition.dart';
import 'package:sqflite/sqflite.dart';
import 'package:time_tracker_ter/services/DatabaseService.dart';
import '../model/Categorie.dart';
import '../model/InitDatabase.dart';
import '../model/Tache.dart';
import '../services/exportService.dart';
import '../utilities/constants.dart';
import 'AddCategorie.dart';
import 'AllTasks.dart';
import 'CategorieDetail.dart';
import 'EditTask.dart';
import 'History_main.dart';
import 'PieChart.dart';

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int colorIndex = 1;
  String tempsEcouleTotal = "00:00:00";

  //Quick start button
  Tache lastQuickStart;
  Map<Tache, Map<String, dynamic>> _mapQuickStart = {};
  Map<Tache, Map<String, dynamic>> _mapTachesEnCours = {};
  // Liste des Quick Tasks
  Future<List<Tache>> futureQuickTasks;
  List<Tache> quickTasks = [];
  // Liste des autres tâches en cours
  Future<List<Tache>> futureTachesEnCours;
  List<Tache> tachesEnCours = [];
  Map<Tache, Timer> listeTimerTachesEnCours = {};

  _MyHomePageState() {
    getPreferedTheme();
  }

  //list of categories
  Future<List<Categorie>> futureCategories;
  List<Categorie> categories = [];

  @override
  void initState() {
    super.initState();
    futureCategories = getCategories();
    futureTachesEnCours = getTachesEnCours();
    futureQuickTasks = get_quick_taches();
  }

  Future<void> refreshData() async {
    // on arrête tous les timers, ils seront relancés si besoin plus tard
    if (listeTimerTachesEnCours.isNotEmpty) {
      for (Tache tache in listeTimerTachesEnCours.keys) {
        listeTimerTachesEnCours[tache].cancel();
      }
      listeTimerTachesEnCours.clear();
    }
    _mapTachesEnCours.clear();
    _mapQuickStart.clear();
    await getCategories();
    await getTachesEnCours();
    await get_quick_taches();
  }

  int durationStringToSeconds(String durationString) {
    List<String> parts = durationString.split(':');
    int hours = int.parse(parts[0]);
    int minutes = int.parse(parts[1]);
    int seconds = int.parse(parts[2]);

    return hours * 3600 + minutes * 60 + seconds;
  }

  Future<List<Categorie>> getCategories() async {
    Database database = await InitDatabase().database;
    var cats = await database.query('categories');
    List<Categorie> liste = cats.map((e) => Categorie.fromMap(e)).toList();
    setState(() {
      categories = liste;
    });
    String tempsEcoule = "00:00:00";
    for (int i = 0; i < categories.length; i++) {
      Duration duration1 = Duration(
        hours: int.parse(tempsEcoule.split(':')[0]),
        minutes: int.parse(tempsEcoule.split(':')[1]),
        seconds: int.parse(tempsEcoule.split(':')[2]),
      );
      Duration duration2 = Duration(
        hours: int.parse(categories[i].temps_ecoule.split(':')[0]),
        minutes: int.parse(categories[i].temps_ecoule.split(':')[1]),
        seconds: int.parse(categories[i].temps_ecoule.split(':')[2]),
      );
      Duration sum = duration1 + duration2;
      tempsEcoule =
          "${sum.inHours}:${sum.inMinutes.remainder(60).toString().padLeft(2, '0')}:${sum.inSeconds.remainder(60).toString().padLeft(2, '0')}";
    }
    setState(() {
      tempsEcouleTotal = tempsEcoule;
    });
    return liste;
  }

  void deleteCategorie(int id) async {
    Database database = await InitDatabase().database;
    await database.delete('categories', where: 'id = ?', whereArgs: [id]);
    categories = await futureCategories;
    categories.clear();
    getCategories();
  }

  void updateCategorieNom(int id, String nouveauNom) async {
    Database database = await InitDatabase().database;
    await database.update(
      'categories',
      {'nom': nouveauNom},
      where: 'id = ?',
      whereArgs: [id],
    );
    categories = await futureCategories;
    categories.clear();
    getCategories();
  }

  void _addCategorieItem() async {
    //clear all categories
    categories.clear();
    categories = await getCategories();
  }

  void getPreferedTheme() async {
    Database database = await InitDatabase().database;
    final Map<String, dynamic> queryResult =
        (await database.query('parametres')).first;
    setState(() {
      colorIndex = queryResult['theme_prefere'];
    });
  }

  void updatePreferedTheme(int index) async {
    Database database = await InitDatabase().database;
    await database.update('parametres', {'theme_prefere': index});
    setState(() {
      colorIndex = index;
    });
  }

  void _startTimerQuickTask(Tache tache) {
    Timer.periodic(Duration(seconds: 1), (timer) {
      if (_mapQuickStart[tache] != null && !_mapQuickStart[tache]['isActive']) {
        timer.cancel(); // stop the timer if _isRunning is false
        return;
      }
      if (_mapQuickStart[tache] != null) {
        setState(() {
          Map<String, dynamic> myMap = _mapQuickStart[tache];

          int sec = myMap['secValue']++;
          _mapQuickStart.putIfAbsent(tache, () => {'secValue': sec});
        });
      }
    });
  }

  void _startTimer(Tache tache) {
    Timer timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!_mapTachesEnCours[tache]['isActive']) {
        timer.cancel(); // stop the timer if _isRunning is false
        return;
      }
      setState(() {
        Map<String, dynamic> myMap = _mapTachesEnCours[tache];
        int sec = myMap['secValue']++;
        _mapTachesEnCours.putIfAbsent(tache, () => {'secValue': sec});
      });
    });
    listeTimerTachesEnCours[tache] = timer;
  }

  void toggleStartStopQuickTask(Tache tache) {
    setState(() {
      // cas où la tâche est en cours
      if (_mapQuickStart[tache]['isActive']) {
        // on arrête la tâche
        _mapQuickStart[tache]['isActive'] = false;
        // on update le champ date_fin en base de donnée
        // de "" à DateTime.now()
        final now = DateTime.now().toUtc();
        final DateFormat formatter = DateFormat('yyyy-MM-ddTHH:mm:ss');
        String formattedDate = formatter.format(now) + 'Z';
        updateLastDeroulementTache(tache.id, formattedDate);
      }
      // cas où la tâche n'est pas en cours
      else {
        // on lance le chrono de la tâche
        _mapQuickStart[tache]['isActive'] = true;
        _startTimerQuickTask(tache);
        // Ajouter une nouvelle ligne dans la table deroulement_tache
        final now = DateTime.now().toUtc();
        final DateFormat formatter = DateFormat('yyyy-MM-ddTHH:mm:ss');
        String formattedDate = formatter.format(now) + 'Z';
        insertDeroulementTache(tache.id, formattedDate);
      }
    });
  }

  void toggleStartStop(Tache tache) {
    setState(() {
      // cas où la tâche est en cours
      if (_mapTachesEnCours[tache]['isActive']) {
        // on arrête la tâche
        _mapTachesEnCours[tache]['isActive'] = false;
        // on update le champ date_fin en base de donnée
        // de "" à DateTime.now()
        final now = DateTime.now().toUtc();
        final DateFormat formatter = DateFormat('yyyy-MM-ddTHH:mm:ss');
        String formattedDate = formatter.format(now) + 'Z';
        updateLastDeroulementTache(tache.id, formattedDate);
        // on retire la tache des taches en cours
        _mapTachesEnCours.remove(tache);
        tachesEnCours.remove(tache);
        // on stop son timer
        listeTimerTachesEnCours[tache].cancel();
        listeTimerTachesEnCours.remove(tache);
      }
    });
  }

  String timerText(int sec) {
    int hours = sec ~/ 3600;
    int minutes = (sec % 3600) ~/ 60;
    int seconds = sec % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<List<Tache>> get_quick_taches() async {
    Database database = await InitDatabase().database;
    var t = await database.query('taches',
        where: "nom LIKE '%Quick task%'", orderBy: "id DESC");
    List<Tache> liste = t.map((e) => Tache.fromMap(e)).toList();
    Map<Tache, Map<String, dynamic>> newMapQuickStart = {};
    if (liste.isNotEmpty) {
      for (int i = 0; i < liste.length; i++) {
        String date_debut = await repriseTimer(liste[i]);
        // cas où le timer de la tâche tourne
        if (date_debut != null) {
          // on calcule le temps écoulé à partir de la date_debut et de DateTime.now()
          DateTime debut = DateTime.parse(date_debut);
          final now = DateTime.now().toUtc();
          int lastTempsEcouleSec =
              durationStringToSeconds(liste[i].temps_ecoule);
          Duration tempsEcouleLastDeroulement = now.difference(debut);
          int tempsEcouleSec =
              lastTempsEcouleSec + tempsEcouleLastDeroulement.inSeconds;
          newMapQuickStart[liste[i]] = {
            'secValue': tempsEcouleSec,
            'isActive': true
          };
        }
        // cas où le timer de la tâche ne tourne pas
        else {
          newMapQuickStart[liste[i]] = {
            'secValue': durationStringToSeconds(liste[i].temps_ecoule),
            'isActive': false
          };
        }
      }
    }
    setState(() {
      quickTasks = liste;
      if (_mapQuickStart.isEmpty) {
        // si la map est vide, on ajoute toutes les nouvelles
        // valeurs depuis la base de donnée
        _mapQuickStart = newMapQuickStart;
        for (final entry in _mapQuickStart.entries) {
          final tache = entry.key;
          final value = entry.value;
          if (value['isActive'] == true) {
            // on relance le timer des taches en cours
            _startTimerQuickTask(tache);
          }
        }
      } else {
        // sinon, on parcours les valeurs de la base de donnée
        // pour mettre à jour le temps écoulé des tâches
        // déjà instanciées et ajouter les nouvelles
        for (final entry2 in newMapQuickStart.entries) {
          final tache2 = entry2.key;
          final value = entry2.value;
          bool hasMatchingId = false;
          for (final entry1 in _mapQuickStart.entries) {
            final tache1 = entry1.key;
            if (tache1.id == tache2.id) {
              // met à jour le temps écoulé des tâches déjà instanciées
              tache1.temps_ecoule = tache2.temps_ecoule;
              _mapQuickStart[tache1] = value;
              hasMatchingId = true;
              break;
            }
          }
          if (!hasMatchingId) {
            // ajoute les nouvelles tâches
            _mapQuickStart[tache2] = value;
          }
        }
      }
      // pour trier par ordre décroissant
      final sortedEntries = _mapQuickStart.entries.toList()
        ..sort((a, b) => b.key.id.compareTo(a.key.id));
      _mapQuickStart = LinkedHashMap.fromEntries(sortedEntries);
    });

    return quickTasks;
  }

  Future<List<Tache>> getTachesEnCours() async {
    Database database = await InitDatabase().database;
    // récupère les taches (qui ne sont pas des Quick Tasks)
    // dont le dernier deroulement contient une date_fin vide
    var t = await database.query(
      'taches',
      where: '''
      id IN (
        SELECT t.id
        FROM taches AS t
        INNER JOIN deroulement_tache AS dt ON t.id = dt.id_tache
        WHERE dt.date_fin = ''
        AND t.nom NOT LIKE 'Quick task %'
        GROUP BY t.id
        HAVING MAX(dt.id) = (
          SELECT MAX(id)
          FROM deroulement_tache
          WHERE id_tache = t.id
        )
      )
    ''',
    );

    List<Tache> liste = t.map((e) => Tache.fromMap(e)).toList();
    Map<Tache, Map<String, dynamic>> newMapTachesEnCours = {};
    if (liste.isNotEmpty) {
      for (int i = 0; i < liste.length; i++) {
        String date_debut = await repriseTimer(liste[i]);
        // cas où le timer de la tâche tourne
        if (date_debut != null) {
          // on calcule le temps écoulé à partir de la date_debut et de DateTime.now()
          DateTime debut = DateTime.parse(date_debut);
          final now = DateTime.now().toUtc();
          int lastTempsEcouleSec =
              durationStringToSeconds(liste[i].temps_ecoule);
          Duration tempsEcouleLastDeroulement = now.difference(debut);
          int tempsEcouleSec =
              lastTempsEcouleSec + tempsEcouleLastDeroulement.inSeconds;
          newMapTachesEnCours[liste[i]] = {
            'secValue': tempsEcouleSec,
            'isActive': true
          };
        }
        // cas où le timer de la tâche ne tourne pas
        else {
          newMapTachesEnCours[liste[i]] = {
            'secValue': durationStringToSeconds(liste[i].temps_ecoule),
            'isActive': false
          };
        }
      }
    }
    setState(() {
      tachesEnCours = liste;
      if (_mapTachesEnCours.isEmpty) {
        // si la map est vide, on ajoute toutes les nouvelles
        // valeurs depuis la base de donnée
        _mapTachesEnCours = newMapTachesEnCours;
        for (final entry in _mapTachesEnCours.entries) {
          final tache = entry.key;
          final value = entry.value;
          if (value['isActive'] == true) {
            // on relance le timer des taches en cours
            _startTimer(tache);
          }
        }
      } else {
        // sinon, on parcours les valeurs de la base de donnée
        // pour mettre à jour le temps écoulé des tâches
        // déjà instanciées et ajouter les nouvelles
        for (final entry2 in newMapTachesEnCours.entries) {
          final tache2 = entry2.key;
          final value = entry2.value;
          bool hasMatchingId = false;
          for (final entry1 in _mapTachesEnCours.entries) {
            final tache1 = entry1.key;
            if (tache1.id == tache2.id) {
              // met à jour le temps écoulé des tâches déjà instanciées
              tache1.temps_ecoule = tache2.temps_ecoule;
              _mapTachesEnCours[tache1] = value;
              hasMatchingId = true;
              break;
            }
          }
          if (!hasMatchingId) {
            // ajoute les nouvelles tâches
            _mapTachesEnCours[tache2] = value;
          }
        }
      }
      // pour trier par ordre décroissant
      final sortedEntries = _mapTachesEnCours.entries.toList()
        ..sort((a, b) => b.key.id.compareTo(a.key.id));
      _mapTachesEnCours = LinkedHashMap.fromEntries(sortedEntries);
    });

    return tachesEnCours;
  }

  Future<String> repriseTimer(Tache tache) async {
    Database database = await InitDatabase().database;
    // on cherche si cette tâche a un champ dans deroulement_tache qui a
    // une date_fin vide
    var t = await database.query(
      'deroulement_tache',
      where: 'id_tache = ? AND date_fin = ?',
      whereArgs: [tache.id, ''],
      orderBy: 'id DESC',
      limit: 1,
    );
    // si il n'y a pas de résultat, on retourne null, le timer de cette
    // tâche ne tourne pas, sinon on retourne le String date_debut
    if (t.isNotEmpty) {
      final String dateDebut = t[0]['date_debut'];
      return dateDebut;
    } else {
      return null;
    }
  }

  Future<void> updateLastDeroulementTache(int id, String formattedDate) async {
    final db = await database;
    await db.update(
        'deroulement_tache', {'date_fin': formattedDate},
        where: 'id_tache = ? AND date_fin = ?', whereArgs: [id, '']);
  }

  // Insertion d'une nouvelle ligne dans la table `deroulement_tache`
  Future<int> insertDeroulementTache(int idTache, String formattedDate) async {
    final db = await database;
    final id = await db.insert('deroulement_tache', {
      'id_tache': idTache,
      'date_debut': formattedDate,
      'date_fin': '',
      'latitude': 48.8566,
      'longitude': 2.3382,
    });
    return id;
  }

  Color selectedColor = Colors.blue;

  void add_quick_tache() async {
    Database database = await InitDatabase().database;
    // compter le nombre de tâches "Quick task"
    int quickTaskCount = Sqflite.firstIntValue(await database.rawQuery(
            "SELECT COUNT(*) FROM taches WHERE nom LIKE 'Quick task %'")) ??
        0;

    final now = DateTime.now().toUtc();
    final DateFormat formatter = DateFormat('yyyy-MM-ddTHH:mm:ss');
    int id = await database.insert('taches', {
      'nom': "Quick task ${quickTaskCount + 1}",
      'couleur': selectedColor.value.toRadixString(16),
      'temps_ecoule': "00:00:00",
      'id_categorie': 1,
    });

    //inserer une nouvelle deroulement de tache
    await database.insert('deroulement_tache', {
      'id_tache': id,
      'date_debut': formatter.format(now) + 'Z',
      'date_fin': '',
      'latitude': 48.8566,
      'longitude': 2.3382,
    });

    // Récupérer la dernière tâche insérée
    List<Map<String, dynamic>> maps = await database
        .rawQuery('SELECT * FROM taches ORDER BY id DESC LIMIT 1');
    lastQuickStart = Tache.fromMap(maps.first);

    // Récupérer les nouvelles tâches depuis la base de données
    List<Tache> nouvellesTaches = await get_quick_taches();

    // Actualiser la liste de tâches dans l'état et redessiner l'interface utilisateur
    setState(() {
      quickTasks = nouvellesTaches;
      if (quickTasks.length > 1) {
        _startTimerQuickTask(quickTasks[0]);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: backgroundColor1,
        appBar: AppBar(
          title: Text("Overview"),
          centerTitle: true,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: allColors[colorIndex],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          leading: Padding(
              padding: const EdgeInsets.only(left: 25.0),
              child: IconButton(
                icon: Icon(
                  Icons.color_lens_rounded,
                  color: Colors.white,
                ),
                iconSize: 36,
                onPressed: () {
                  // appuie sur le bouton palette de couleur
                  // on affiche le popup pour choisir le theme de l'app
                  showColorPickerDialog(context);
                },
              )),
        ),
        body: FutureBuilder<List<Categorie>>(
          future: futureCategories,
          builder:
              (BuildContext context, AsyncSnapshot<List<Categorie>> snapshot1) {
            if (snapshot1.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(),
              );
            } else if (snapshot1.hasError) {
              return BottomAppBar(
                child: Center(
                  child: Text('Error loading categories'),
                ),
              );
            } else {
              return FutureBuilder<List<Tache>>(
                future: futureQuickTasks,
                builder: (BuildContext context,
                    AsyncSnapshot<List<Tache>> snapshot2) {
                  if (snapshot2.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  } else if (snapshot2.hasError) {
                    return BottomAppBar(
                      child: Center(
                        child: Text('Error loading Tasks'),
                      ),
                    );
                  } else {
                    return FutureBuilder<List<Tache>>(
                        future: futureTachesEnCours,
                        builder: (BuildContext context,
                            AsyncSnapshot<List<Tache>> snapshot3) {
                          if (snapshot3.connectionState ==
                              ConnectionState.waiting) {
                            return Center(
                              child: CircularProgressIndicator(),
                            );
                          } else if (snapshot3.hasError) {
                            return BottomAppBar(
                              child: Center(
                                child: Text('Error loading Tasks'),
                              ),
                            );
                          } else {
                            return SingleChildScrollView(
                              child: Column(
                                children: [
                                  Container(
                                    width: double.infinity,
                                    color: allColors[colorIndex][1],
                                    alignment: Alignment.center,
                                    height: 93,
                                    margin: const EdgeInsets.only(bottom: 35.0),
                                    child: Container(
                                        width: double.infinity,
                                        margin: const EdgeInsets.only(
                                            left: 20.0, right: 20.0),
                                        height: 50,
                                        child: MaterialButton(
                                          color: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(50.0),
                                          ),
                                          onPressed: () async {
                                            await add_quick_tache();
                                          },
                                          child: Text(
                                            "Quick Start",
                                            style: TextStyle(
                                                fontSize: 20.0,
                                                color: allColors[colorIndex]
                                                    [1]),
                                          ),
                                        )),
                                  ),
                                  // Affichage des taches en cours et des Quick Tasks
                                  getTachesContainer(),
                                  Container(
                                    width: double.infinity,
                                    alignment: Alignment.center,
                                    margin: const EdgeInsets.only(bottom: 20.0),
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: allColors[colorIndex][0],
                                            width: 1),
                                        color: allColors[colorIndex][1],
                                      ),
                                      margin: const EdgeInsets.only(
                                          left: 20.0, right: 20.0),
                                      child: Column(
                                        children: [
                                          GestureDetector(
                                            onTap: () async {
                                              // sur un appuie sur la ligne "All Tasks"
                                              // Naviguer vers la page All Tasks
                                              await Navigator.push(
                                                  context,
                                                  PageTransition(
                                                      type: PageTransitionType
                                                          .rightToLeftWithFade,
                                                      child: AllTasksPage(
                                                          timeFilterCounter: 0,
                                                          colorIndex:
                                                              colorIndex),
                                                      childCurrent: this.widget,
                                                      duration: Duration(
                                                          milliseconds: 500)));
                                              await refreshData();
                                            },
                                            child: Container(
                                              color: Colors.transparent,
                                              width: double.infinity,
                                              child: buildRow("papers",
                                                  "All Tasks"),
                                            ),
                                          ),
                                          Divider(
                                            color: backgroundColor2,
                                            thickness: 0.6,
                                          ),
                                          GestureDetector(
                                            onTap: () async {
                                              // sur un appuie sur la ligne "Single Tasks"
                                              // Naviguer vers la page Single Tasks
                                              await Navigator.push(
                                                  context,
                                                  PageTransition(
                                                      type: PageTransitionType
                                                          .rightToLeftWithFade,
                                                      child: CategorieDetail(
                                                        categorie:
                                                            categories[0],
                                                        colorIndex: colorIndex,
                                                        timeFilterCounter: 0,
                                                      ),
                                                      childCurrent: this.widget,
                                                      duration: Duration(
                                                          milliseconds: 500)));
                                              await refreshData();
                                            },
                                            child: Container(
                                              color: Colors.transparent,
                                              width: double.infinity,
                                              child: buildRow(
                                                  "paper", "Single Tasks"),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  //container of my categories
                                  getCategoriesContainer()
                                ],
                              ),
                            );
                          }
                        });
                  }
                },
              );
            }
          },
        ),
        bottomNavigationBar: BottomNavigationBar(
          onTap: (value) {
            // cas où on appuie sur le bouton "+"
            if (value == 0) {
              // on affiche la page pour créer une catégorie
              Navigator.push(
                  context,
                  PageTransition(
                      type: PageTransitionType.bottomToTop,
                      child: AddCatePage(
                        onDataAdded: _addCategorieItem,
                        colorIndex: colorIndex,
                      ),
                      childCurrent: this.widget,
                      duration: Duration(milliseconds: 500)));
            }
            // cas où on appuie sur le bouton pie chart
            else if (value == 2) {
              // créer la data map qui associe à chaque catégorie son temps en secondes
              Map<String, double> dataMap = {};
              List<Color> colorList = [];
              for (int i = 0; i < categories.length; i++) {
                List<String> parts = categories[i].temps_ecoule.split(':');
                int hours = int.parse(parts[0]);
                int minutes = int.parse(parts[1]);
                int seconds = int.parse(parts[2]);
                Duration duration =
                    Duration(hours: hours, minutes: minutes, seconds: seconds);
                double tempsEcouleEnSec = duration.inSeconds.toDouble();
                dataMap[categories[i].nom] = tempsEcouleEnSec;
                colorList
                    .add(Color(int.parse(categories[i].couleur, radix: 16)));
              }
              // l'envoyer à PieChartPage pour l'afficher
              Navigator.push(
                  context,
                  PageTransition(
                      type: PageTransitionType.bottomToTop,
                      child: PieChartPage(
                        dataMap: dataMap,
                        colorList: colorList,
                        colorIndex: colorIndex,
                      ),
                      childCurrent: this.widget,
                      duration: Duration(milliseconds: 500)));
            }
            // cas où on appuie sur le bouton export
            else if (value == 3) {
              _export(context);
            }
          },
          backgroundColor: Colors.white,
          selectedItemColor: allColors[colorIndex][1],
          unselectedItemColor: allColors[colorIndex][1],
          selectedFontSize: 15,
          unselectedFontSize: 15,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          iconSize: 40,
          elevation: 5,
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Total",
                    overflow: TextOverflow.visible,
                    style: TextStyle(
                        fontSize: 19, color: allColors[colorIndex][1]),
                  ),
                  Text(
                    tempsEcouleTotal,
                    overflow: TextOverflow.visible,
                    style: TextStyle(
                        fontSize: 19, color: allColors[colorIndex][1]),
                  ),
                ],
              ),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/icons/pie_chart.svg',
                color: allColors[colorIndex][1],
              ),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/icons/mail.svg',
                color: allColors[colorIndex][1],
              ),
              label: '',
            ),
          ],
        ));
  }

  Row buildRow(String icon, String titre) {
    String tempsEcoule = "00:00:00";
    if (titre == alltasks) {
      tempsEcoule = tempsEcouleTotal;
    } else if (titre == singleTask) {
      tempsEcoule = categories[0].temps_ecoule;
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          height: 50,
          width: 50,
          child: (icon == paper)
              ? Image.asset(
                  'assets/icons/paper.png',
                )
              : ((icon == papers)
                  ? Image.asset(
                      'assets/icons/papers.png',
                    )
                  : Container()),
        ),
        Container(
          height: 50,
          width: 150,
          alignment: Alignment.centerLeft,
          child: Text(
            titre,
            style: TextStyle(fontSize: 18.0, color: Colors.white),
          ),
        ),
        Container(
          height: 50,
          width: 115,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                height: 50,
                width: 80,
                alignment: Alignment.center,
                child: Text(
                  tempsEcoule,
                  style: TextStyle(fontSize: 20.0, color: Colors.white),
                ),
              ),
              Container(
                height: 35,
                width: 35,
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: SvgPicture.asset(
                    'assets/icons/arrow_right_in_circle.svg',
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildRowQuickTask(Tache tache) {
    return GestureDetector(
      onLongPress: () {
        // Afficher le popup pour supprimer ou éditer la tache
        showDelModDialog(context, tache);
      },
      onTap: () async {
        // Naviguer vers la page de history_main de la tache
        await Navigator.push(
            context,
            PageTransition(
                type: PageTransitionType.rightToLeftWithFade,
                child: HistoryPage(
                  title: tache.nom,
                  id: tache.id,
                  colorIndex: colorIndex,
                ),
                childCurrent: this.widget,
                duration: Duration(milliseconds: 500)));
        await refreshData();
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 50,
            width: 50,
            child: GestureDetector(
              onTap: () {
                toggleStartStopQuickTask(tache);
              },
              child: Align(
                alignment: Alignment.center,
                child: FractionallySizedBox(
                  widthFactor: 0.4,
                  heightFactor: 0.4,
                  child: _mapQuickStart[tache]['isActive']
                      ? SvgPicture.asset(
                          'assets/icons/pause.svg',
                        )
                      : SvgPicture.asset(
                          'assets/icons/play_arrow.svg',
                        ),
                ),
              ),
            ),
          ),
          Container(
            height: 50,
            width: 150,
            alignment: Alignment.centerLeft,
            child: Text(
              tache.nom,
              style: TextStyle(fontSize: 20.0, color: Colors.black87),
            ),
          ),
          Container(
            height: 50,
            width: 115,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  height: 50,
                  width: 80,
                  alignment: Alignment.center,
                  child: Text(
                    timerText(_mapQuickStart[tache]['secValue']),
                    style: TextStyle(
                        fontSize: 20.0,
                        color: _mapQuickStart[tache]['isActive']
                            ? colorTime2
                            : colorTime1),
                  ),
                ),
                Container(
                  height: 35,
                  width: 35,
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: SvgPicture.asset(
                      'assets/icons/arrow_right_in_circle.svg',
                      color: Color(0xff848484),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildRowTache(Tache tache) {
    return GestureDetector(
      onLongPress: () {
        // Afficher le popup pour supprimer ou éditer la tache
        showDelModDialog(context, tache);
      },
      onTap: () {
        // Naviguer vers la page de history_main de la tache
        Navigator.push(
            context,
            PageTransition(
                type: PageTransitionType.rightToLeftWithFade,
                child: HistoryPage(
                  title: tache.nom,
                  id: tache.id,
                  colorIndex: colorIndex,
                ),
                childCurrent: this.widget,
                duration: Duration(milliseconds: 500)));
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 50,
            width: 50,
            child: GestureDetector(
              onTap: () {
                toggleStartStop(tache);
              },
              child: Align(
                alignment: Alignment.center,
                child: FractionallySizedBox(
                  widthFactor: 0.4,
                  heightFactor: 0.4,
                  child: _mapTachesEnCours[tache]['isActive']
                      ? SvgPicture.asset(
                          'assets/icons/pause.svg',
                        )
                      : SvgPicture.asset(
                          'assets/icons/play_arrow.svg',
                        ),
                ),
              ),
            ),
          ),
          Container(
            height: 50,
            width: 150,
            alignment: Alignment.centerLeft,
            child: Text(
              tache.nom,
              style: TextStyle(fontSize: 20.0, color: Colors.black87),
            ),
          ),
          Container(
            height: 50,
            width: 115,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  height: 50,
                  width: 80,
                  alignment: Alignment.center,
                  child: Text(
                    timerText(_mapTachesEnCours[tache]['secValue']),
                    style: TextStyle(
                        fontSize: 20.0,
                        color: _mapTachesEnCours[tache]['isActive']
                            ? colorTime2
                            : colorTime1),
                  ),
                ),
                Container(
                  height: 35,
                  width: 35,
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: SvgPicture.asset(
                      'assets/icons/arrow_right_in_circle.svg',
                      color: Color(0xff848484),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildRowCategorie(IconData icons, Categorie categorie) {
    // id != 1 pour ne pas afficher la categorie "Single Tasks"
    if (categorie.id != 1) {
      return GestureDetector(
        onLongPress: () {
          // sur un appuie long :
          // afficher le popup pour supprimer ou éditer la catégorie
          showDelModDialog(context, categorie);
        },
        onTap: () async {
          // sur un appuie court :
          // naviguer vers la page de détail de la catégorie
          await Navigator.push(
              context,
              PageTransition(
                  type: PageTransitionType.rightToLeftWithFade,
                  child: CategorieDetail(
                    categorie: categorie,
                    colorIndex: colorIndex,
                    timeFilterCounter: 0,
                  ),
                  childCurrent: this.widget,
                  duration: Duration(milliseconds: 500)));
          await refreshData();
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
                height: 50,
                width: 50,
                child: Icon(
                  Icons.folder,
                  size: 30,
                  color: Color(int.parse(categorie.couleur, radix: 16)),
                )),
            Container(
              height: 50,
              width: 150,
              alignment: Alignment.centerLeft,
              child: Text(
                categorie.nom,
                style: TextStyle(fontSize: 20.0, color: Colors.black87),
              ),
            ),
            Container(
              height: 50,
              width: 115,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    height: 50,
                    width: 80,
                    alignment: Alignment.center,
                    child: Text(
                      categorie.temps_ecoule,
                      style: TextStyle(fontSize: 20.0, color: colorTime1),
                    ),
                  ),
                  Container(
                    height: 35,
                    width: 35,
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: SvgPicture.asset(
                        'assets/icons/arrow_right_in_circle.svg',
                        color: Color(0xff848484),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return Container();
    }
  }

  Container getTachesContainer() {
    if (_mapQuickStart.length == 0 && _mapTachesEnCours.length == 0) {
      return Container();
    }
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      margin: const EdgeInsets.only(bottom: 20.0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: backgroundColor2,
        ),
        margin: const EdgeInsets.only(left: 20.0, right: 20.0),
        child: Column(
          children: [
            (_mapTachesEnCours.length == 0)
                ? Container()
                : ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _mapTachesEnCours.length,
                    itemBuilder: (context, index) {
                      List<Tache> keysList = _mapTachesEnCours.keys.toList();
                      return buildRowTache(keysList[index]);
                    }),
            (_mapQuickStart.length == 0)
                ? Container()
                : ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _mapQuickStart.length,
                    itemBuilder: (context, index) {
                      List<Tache> keysList = _mapQuickStart.keys.toList();
                      return buildRowQuickTask(keysList[index]);
                    }),
          ],
        ),
      ),
    );
  }

  Container getCategoriesContainer() {
    if (categories == null || categories.length == 0) {
      return Container();
    }
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      margin: const EdgeInsets.only(bottom: 20.0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: backgroundColor2,
        ),
        margin: const EdgeInsets.only(left: 20.0, right: 20.0),
        //get the categories from the database
        child: ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            return buildRowCategorie(Icons.folder, categories[index]);
          },
        ),
      ),
    );
  }

  showDelModDialog(BuildContext context, var object) {
    // set up the buttons
    Widget deletBtn = TextButton(
      child: Row(
        children: [
          Icon(Icons.delete, color: Colors.red),
          Text("Supprimer", style: TextStyle(color: Colors.red)),
        ],
      ),
      onPressed: () async {
        // appuie bouton delete
        // on supprime la catégorie
        if (object.runtimeType.toString() == typeCategorie) {
          deleteCategorie(object.id);
          // on ferme le popup
          Navigator.of(context).pop();
        } else if (object.runtimeType.toString() == typeTache) {
          await DeleteTache(object.id);
          Navigator.of(context).pop();
          await refreshData();
        }
      },
    );
    Widget editBtn = TextButton(
      child: Row(
        children: [
          Icon(Icons.edit, color: Colors.blue),
          Text("Edit", style: TextStyle(color: Colors.blue)),
        ],
      ),
      onPressed: () async {
        if (object.runtimeType.toString() == typeCategorie) {
          Navigator.of(context).pop();
          String nom = await getCategoryNameById(object.id);
          showEditCategorieDialog(context, object.id, nom);
        } else if (object.runtimeType.toString() == typeTache) {
          //Edit single Task
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => EditTask(object, categories, refreshData),
            ),
          );
        }
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Confirmation"),
      content: Text("Que voulez vous faire?"),
      actions: [
        deletBtn,
        editBtn,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  Future<String> getCategoryNameById(int id) async {
    Database database = await InitDatabase().database;
    List<Map<String, dynamic>> results = await database.query(
      'categories',
      columns: ['nom'],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isNotEmpty) {
      // Assuming there is only one category with this ID
      return results.first['nom'];
    } else {
      throw Exception('No category found with ID: $id');
    }
  }

  void showEditCategorieDialog(BuildContext context, int id, String oldName) {
    TextEditingController textController = TextEditingController(text: oldName);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Modifier La Catégorie'),
          content: TextField(
            controller: textController,
            decoration: InputDecoration(
              labelText: 'Nom De La Catégorie',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Sauvegarder'),
              onPressed: () async {
                String newName = textController.text;
                // call your function to update the category name in the database
                await updateCategorieNom(id, newName);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  showColorPickerDialog(BuildContext context) {
    //save button
    Widget backBtn = TextButton(
      child: Row(
        //center the text
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Fermer",
            style: TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      onPressed: () {
        // appuie sur le bouton back
        Navigator.of(context).pop();
      },
    );

    var choixCouleur = Column(
      children: <Widget>[
        TextButton(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(allColors[0][1]),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text("Rouge", style: TextStyle(color: Colors.white)),
            ],
          ),
          onPressed: () {
            updatePreferedTheme(0);
          },
        ),
        TextButton(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(allColors[1][1]),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text("Bleu", style: TextStyle(color: Colors.white)),
            ],
          ),
          onPressed: () {
            updatePreferedTheme(1);
          },
        ),
        TextButton(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(allColors[2][1]),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text("Orange", style: TextStyle(color: Colors.white)),
            ],
          ),
          onPressed: () {
            updatePreferedTheme(2);
          },
        ),
      ],
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16.0))),
      contentPadding: EdgeInsets.only(top: 10.0),
      content: Container(
        width: 300.0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  "Thème De l'Application ",
                  style: TextStyle(fontSize: 20.0),
                ),
              ],
            ),
            SizedBox(
              height: 5.0,
            ),
            Divider(
              color: Colors.grey,
              height: 4.0,
            ),
            Padding(
              padding: EdgeInsets.only(left: 30.0, right: 30.0),
              child: choixCouleur,
            ),
            InkWell(
              child: Container(
                decoration: BoxDecoration(
                  color: allColors[colorIndex][1],
                  borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(16.0),
                      bottomRight: Radius.circular(16.0)),
                ),
                child: backBtn,
              ),
            ),
          ],
        ),
      ),
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return alert;
          },
        );
      },
    );
  }

  _export(BuildContext context) async {
    ExportService service = ExportService();
    await service.promptEmail(context);
  }
}
