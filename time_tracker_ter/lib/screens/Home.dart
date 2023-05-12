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
import 'History_main.dart';
import 'PieChart.dart';


class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int colorIndex = 1;
  String tempsEcouleTotal = "00:00:00";

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
    futureTaches = get_quick_taches();
    _idTacheEnCours = null;
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

  //Quick start button
  bool _isPressed = false;
  Timer _timer;
  Tache lastQuickStart;
  int _idTacheEnCours;
  Map<Tache, Map<String, dynamic>> _mapQuickStart = {};

  void _startTimer(Tache tache) {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!_mapQuickStart[tache]['isActive']) {
        timer.cancel(); // stop the timer if _isRunning is false
        return;
      }
      setState(() {
        Map<String, dynamic> myMap = _mapQuickStart[tache];
        int sec = myMap['secValue']++;
        _mapQuickStart.putIfAbsent(tache, () => {'secValue': sec});
      });
    });
  }

  void toggleStartStop(Tache tache) {
    setState(() {
      // cas où la tâche est en cours
      if(_mapQuickStart[tache]['isActive']){
        // on arrête la tâche
        _mapQuickStart[tache]['isActive'] = false;
        // on update le champ date_fin en base de donnée
        // de "" à DateTime.now()
        final now = DateTime.now().add(Duration(hours: 2));
        final DateFormat formatter = DateFormat('yyyy-MM-ddTHH:mm:ss');
        String formattedDate = formatter.format(now.toUtc());
        updateLastDeroulementTache(tache.id, formattedDate);

        _idTacheEnCours = null;
      }
      // cas où la tâche n'est pas en cours
      else{
        // on lance le chrono de la tâche
        _mapQuickStart[tache]['isActive'] = true;
        _startTimer(tache);
        // Ajouter une nouvelle ligne dans la table deroulement_tache
        final now = DateTime.now().add(Duration(hours: 2));
        final DateFormat formatter = DateFormat('yyyy-MM-ddTHH:mm:ss');
        String formattedDate = formatter.format(now.toUtc());
        insertDeroulementTache(tache.id, formattedDate);
        _idTacheEnCours = tache.id;
      }
    });
  }


  String timerText(int sec) {
    int hours = sec ~/ 3600;
    int minutes = (sec % 3600) ~/ 60;
    int seconds = sec % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  //list de quick tâches
  Future<List<Tache>> futureTaches;
  List<Tache> taches = [];

  Future<List<Tache>> get_quick_taches() async {
    Database database = await InitDatabase().database;
    var t = await database.query('taches', where: "nom LIKE '%Quick task%'", orderBy: "id DESC");
    List<Tache> liste = t.map((e) => Tache.fromMap(e)).toList();
    Map<Tache, Map<String, dynamic>> newMapQuickStart = {};
    if(liste.isNotEmpty){
      for(int i = 0; i < liste.length; i++){
        String date_debut = await repriseTimerQuickTask(liste[i]);
        // cas où le timer de la tâche tourne
        if(date_debut != null){
          // on calcule le temps écoulé à partir de la date_debut et de DateTime.now()
          DateTime debut = DateTime.parse(date_debut);
          final now = DateTime.now().add(Duration(hours: 2)).toUtc();
          Duration tempsEcoule = now.difference(debut);
          int tempsEcouleSec = tempsEcoule.inSeconds;
          newMapQuickStart[liste[i]] = {'secValue': tempsEcouleSec, 'isActive': true};
        }
        // cas où le timer de la tâche ne tourne pas
        else{
          newMapQuickStart[liste[i]] = {'secValue': durationStringToSeconds(liste[i].temps_ecoule), 'isActive': false};
        }
      }

    }
    setState(() {
      taches = liste;
      if(_mapQuickStart.isEmpty){
        // si la map est vide, on ajoute toutes les nouvelles
        // valeurs depuis la base de donnée
        _mapQuickStart = newMapQuickStart;
        for(final entry in _mapQuickStart.entries){
          final tache = entry.key;
          final value = entry.value;
          if(value['isActive'] == true){
            // on relance le timer des taches en cours
            _startTimer(tache);
          }
        }
      }
      else{
        // sinon, on parcours les valeurs de la base de donnée
        // pour mettre à jour le temps écoulé des tâches
        // déjà instanciées et ajouter les nouvelles
        for(final entry2 in newMapQuickStart.entries){
          final tache2 = entry2.key;
          final value = entry2.value;
          bool hasMatchingId = false;
          for(final entry1 in _mapQuickStart.entries){
            final tache1 = entry1.key;
            if(tache1.id == tache2.id){
              // met à jour le temps écoulé des tâches déjà instanciées
              tache1.temps_ecoule = tache2.temps_ecoule;
              _mapQuickStart[tache1] = value;
              hasMatchingId = true;
              break;
            }
          }
          if(!hasMatchingId){
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

    return taches;
  }

  Future<String> repriseTimerQuickTask(Tache tache) async {
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
    print('updateLastDeroulementTache: $id'); // ajouter cette ligne pour afficher l'ID de la tâche
    final db = await database;
    print('formattedDate: $formattedDate'); // ajouter cette ligne pour afficher la date formatée
    int result = await db.update('deroulement_tache', {'date_fin': formattedDate},
        where: 'id_tache = ? AND date_fin = ?', whereArgs: [id, '']);
    print('update result: $result'); // ajouter cette ligne pour afficher le résultat de l'opération de mise à jour
  }

  // Insertion d'une nouvelle ligne dans la table `deroulement_tache`
  Future<int> insertDeroulementTache(int idTache, String dateDebut) async {
    final db = await database;
    final id = await db.insert('deroulement_tache', {
      'id_tache': idTache,
      'date_debut': dateDebut,
      'date_fin': '',
      'latitude': 48.8566,
      'longitude': 2.3382,
    });
    return id;
  }

  Color selectedColor = Colors.blue;

  void add_quick_tache() async{
    Database database = await InitDatabase().database;
    // compter le nombre de tâches "Quick task"
    int quickTaskCount = Sqflite.firstIntValue(await database.rawQuery("SELECT COUNT(*) FROM taches WHERE nom LIKE 'Quick task %'")) ?? 0;

    final now = DateTime.now().add(Duration(hours: 2));
    final DateFormat formatter = DateFormat('yyyy-MM-ddTHH:mm:ss');

    int id = await database.insert('taches', {
      'nom': "Quick task ${quickTaskCount + 1}",
      'couleur':selectedColor.value.toRadixString(16),
      'temps_ecoule': "00:00:00",
      'id_categorie': 1,
    });

    //inserer une nouvelle deroulement de tache
    await database.insert('deroulement_tache', {
      'id_tache': id,
      'date_debut':'${formatter.format(now.toUtc())}',
      'date_fin': '',
      'latitude': 48.8566,
      'longitude': 2.3382,
    });

    // Récupérer la dernière tâche insérée
    List<Map<String, dynamic>> maps = await database.rawQuery('SELECT * FROM taches ORDER BY id DESC LIMIT 1');
    lastQuickStart = Tache.fromMap(maps.first);

    // Récupérer les nouvelles tâches depuis la base de données
    List<Tache> nouvellesTaches =  await get_quick_taches();

    // Actualiser la liste de tâches dans l'état et redessiner l'interface utilisateur
    setState(() {
      taches = nouvellesTaches;
      _isPressed = true;
      _startTimer(taches[0]);
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
                icon: Icon(Icons.color_lens_rounded, color: Colors.white,),
                iconSize: 36,
                onPressed: () {
                  // appuie sur le bouton palette de couleur
                  // on affiche le popup pour choisir le theme de l'app
                  showColorPickerDialog(context);
                },
              )
          ),
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
                future: futureTaches,
                builder: (BuildContext context,
                    AsyncSnapshot<List<Tache>> snapshot2) {
                  if (snapshot2.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  } else if (snapshot2.hasError) {
                    return BottomAppBar(
                      child: Center(
                        child: Text('Error loading categories'),
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
                                margin: const EdgeInsets.only(left: 20.0, right: 20.0),
                                height: 50,
                                child: MaterialButton(
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(50.0),
                                  ),
                                  onPressed: () async {
                                    await add_quick_tache();
                                  },
                                  child: Text(
                                    "Quick Start",
                                    style: TextStyle(
                                        fontSize: 20.0,
                                        color: allColors[colorIndex][1]),
                                  ),
                                )
                            ),
                          ),
                          // Container of my task create with button Quick Start
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
                                    color: allColors[colorIndex][0], width: 1),
                                color: allColors[colorIndex][1],
                              ),
                              margin: const EdgeInsets.only(left: 20.0, right: 20.0),
                              child: Column(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      // sur un appuie sur la ligne "All Tasks"
                                      // Naviguer vers la page All Tasks
                                      Navigator.push(
                                          context,
                                          PageTransition(
                                              type: PageTransitionType.rightToLeftWithFade,
                                              child: AllTasksPage(
                                                  timeFilterCounter: 0,
                                                  colorIndex: colorIndex
                                              ),
                                              childCurrent: this.widget,
                                              duration: Duration(milliseconds: 500)
                                          )
                                      );
                                    },
                                    child: Container(
                                      color: Colors.transparent,
                                      width: double.infinity,
                                      child: buildRow("papers", "All Tasks"),
                                    ),
                                  ),
                                  Divider(
                                    color: backgroundColor2,
                                    thickness: 0.6,
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      // sur un appuie sur la ligne "Single Tasks"
                                      // Naviguer vers la page Single Tasks
                                      Navigator.push(
                                          context,
                                          PageTransition(
                                              type: PageTransitionType.rightToLeftWithFade,
                                              child: CategorieDetail(
                                                categorie: categories[0], colorIndex: colorIndex, timeFilterCounter: 0,),
                                              childCurrent: this.widget,
                                              duration: Duration(milliseconds: 500)
                                          )
                                      );
                                    },
                                    child: Container(
                                      color: Colors.transparent,
                                      width: double.infinity,
                                      child: buildRow("paper", "Single Tasks"),
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
              for(int i=0; i<categories.length; i++){
                List<String> parts = categories[i].temps_ecoule.split(':');
                int hours = int.parse(parts[0]);
                int minutes = int.parse(parts[1]);
                int seconds = int.parse(parts[2]);
                Duration duration = Duration(hours: hours, minutes: minutes, seconds: seconds);
                double tempsEcouleEnSec = duration.inSeconds.toDouble();
                dataMap[categories[i].nom] = tempsEcouleEnSec;
                colorList.add(Color(int.parse(categories[i].couleur, radix: 16)));
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
                    "Total ",
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
    } else if (titre == "Single Tasks") {
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
            style: TextStyle(fontSize: 20.0, color: Colors.white),
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

  Widget buildRowTaches( Tache tache) {
    return GestureDetector(
      onLongPress: () {
        // Afficher le popup pour supprimer ou éditer la tache
        showDelModDialog(context, tache.id);
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
            child: IconButton(
              icon: _mapQuickStart[tache]['isActive'] ?
              Icon(Icons.pause_circle) : Icon(Icons.play_circle),
              onPressed: () {
                toggleStartStop(tache);
              },
              color: Colors.blue,
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
  }

  Widget buildRowCategorie(IconData icons, Categorie categorie) {
    // id != 1 pour ne pas afficher la categorie "Single Tasks"
    if (categorie.id != 1) {
      return GestureDetector(
        onLongPress: () {
          // sur un appuie long :
          // afficher le popup pour supprimer ou éditer la catégorie
          showDelModDialog(context, categorie.id);
        },
        onTap: () {
          // sur un appuie court :
          // naviguer vers la page de détail de la catégorie
          Navigator.push(
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
              )
            ),
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
    if (_mapQuickStart.length==0) {
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
        child: ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _mapQuickStart.length,
            itemBuilder: (context, index) {
              List<Tache> keysList=_mapQuickStart.keys.toList();
              IconData iconButton;
              bool b =_mapQuickStart[keysList[index]]['isActive'];
              b? iconButton= Icons.pause_circle:iconButton= Icons.play_circle;
              return buildRowTaches(
                   keysList[index]);
            }),
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

  showAlertDialog(BuildContext context) {
    // set up the buttons

    Widget continueButton = TextButton(
      child: Icon(Icons.add),
      onPressed: () {
        // do something
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("AlertDialog"),
      content: Text("Would you like to continue?"),
      actions: [
        continueButton,
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

  showDelModDialog(BuildContext context, int id) {
    // set up the buttons
    Widget deletBtn = TextButton(
      child: Row(
        children: [
          Icon(Icons.delete, color: Colors.red),
          Text("Delete", style: TextStyle(color: Colors.red)),
        ],
      ),
      onPressed: () {
        // appuie bouton delete
        // on supprime la catégorie
        deleteCategorie(id);
        // on ferme le popup
        Navigator.of(context).pop();
      },
    );
    Widget editBtn = TextButton(
      child: Row(
        children: [
          Icon(Icons.edit, color: Colors.blue),
          Text("Edit", style: TextStyle(color: Colors.blue)),
        ],
      ),
      onPressed: () {
        // TODO : traitement bouton edit categorie
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

  getColorFromName(String name) {
    switch (name) {
      case "blue":
        return Colors.blue;
      case "red":
        return Colors.red;
      case "orange":
        return Colors.orange;
    }
  }

  int selectedValue = 0;

  showColorPickerDialog(BuildContext context) {
    //save button
    Widget backBtn = TextButton(
      child: Row(
        //center the text
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Back",
            style: TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      onPressed: () {
        //save the categorie
        //get the color from the dropdown
        var colorIndex_ = colorIndex;
        updatePreferedTheme(colorIndex_);
        //saveCategorie(dropdownValue);
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
              Text("Red", style: TextStyle(color: Colors.white)),
            ],
          ),
          onPressed: () {
            //get the color from the dropdown
            updatePreferedTheme(0);
            //saveCategorie(dropdownValue);
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
              Text("Blue", style: TextStyle(color: Colors.white)),
            ],
          ),
          onPressed: () {
            //get the color from the dropdown
            updatePreferedTheme(1);
            //saveCategorie(dropdownValue);
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
            //get the color from the dropdown
            updatePreferedTheme(2);
            //saveCategorie(dropdownValue);
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
                  "Prefered theme",
                  style: TextStyle(fontSize: 24.0),
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
