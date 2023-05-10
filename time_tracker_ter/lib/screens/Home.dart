import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:page_transition/page_transition.dart';
import 'package:sqflite/sqflite.dart';
import 'package:time_tracker_ter/model/DeroulementTache.dart';
import 'package:time_tracker_ter/services/DatabaseService.dart';
import '../model/Categorie.dart';
import '../model/InitDatabase.dart';
import '../model/Tache.dart';
import '../utilities/constants.dart';
import 'AddCategorie.dart';
import 'AllTasks.dart';
import 'CategorieDetail.dart';


class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var colorIndex = 1;
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
    fetchQuickTache();

  }
  void fetchQuickTache()  async{
    List<Tache> nouvellesTaches= await get_quick_taches();
    setState(() {
      for(int i = 0; i < nouvellesTaches.length; i++ ){
        _mapQuickStart[taches[i]] = {'secValue': 0, 'isActive': false};
      }
    });
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
  int _idTacheEnCours = null;
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

  void toggleStartStop(Tache tache){
    setState(() {
      bool b= ! _mapQuickStart[tache]['isActive'];
      _mapQuickStart[tache]['isActive'] = b;

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
    setState(() {
      taches = liste;
    });
    return taches;
  }

  // Insertion d'une nouvelle ligne dans la table `deroulement_tache`
  /*Future<int> insertDeroulementTache(int idTache, String dateDebut) async {
    final db = await database;
    final id = await db.insert('deroulement_tache', {
      'id_tache': idTache,
      'date_debut': dateDebut,
      'date_fin': '',
      'latitude': 48.8566,
      'longitude': 2.3382,
    });
    return id;
  }*/

// Mise à jour de la colonne `date_fin` pour une ligne spécifique de la table `deroulement_tache`
  Future<void> updateDeroulementTache(int id, String dateFin) async {
    final db = await database;
    await db.update('deroulement_tache', {'date_fin': dateFin},
        where: 'id_tache = ?', whereArgs: [id]);
  }

  Color selectedColor = Colors.blue;

  void add_quick_tache() async{
    Database database = await InitDatabase().database;
    // compter le nombre de tâches "Quick task"
    int quickTaskCount = Sqflite.firstIntValue(await database.rawQuery("SELECT COUNT(*) FROM taches WHERE nom LIKE 'Quick task %'")) ?? 0;

    final now = DateTime.now().add(Duration(hours: 2));
    final DateFormat formatter = DateFormat('yyyy-MM-ddTHH:mm:ss');

//inserer une nouvelle tache
    int id = await database.insert('taches', {
      'nom': "Quick task ${quickTaskCount + 1}",
      'couleur':selectedColor.value.toRadixString(16),
      'temps_ecoule': '00:00:00',
      'id_categorie': 1,
    });
//inserer une nouvelle deroulement de tache
    await database.insert('deroulement_tache', {
      'id_tache': id,
      'date_debut':'${formatter.format(now.toUtc())}Z',
      'date_fin': '',
      'latitude': 48.8566,
      'longitude': 2.3382,
    });

    // Récupérer la dernière tâche insérée
    List<Map<String, dynamic>> maps = await database.rawQuery('SELECT * FROM taches ORDER BY id DESC LIMIT 1');
    lastQuickStart = Tache.fromMap(maps.first);
    //print('lastQuickStart after adding new task: $lastQuickStart');

    // Récupérer les nouvelles tâches depuis la base de données
    List<Tache> nouvellesTaches =  await get_quick_taches();
    //print("nouvelleTaches ${nouvellesTaches.toString()}");
    print('nouvellesTache ${nouvellesTaches.toString()}');
    // Actualiser la liste de tâches dans l'état et redessiner l'interface utilisateur
    setState(() {
      taches = nouvellesTaches;
      _isPressed = true;
      //print("last tache: ${taches[taches.length-1]}");
      _mapQuickStart[taches[0]] = {'secValue': 0, 'isActive': true};
      //print(_mapQuickStart.toString());
      //print("_mapQuickStart ${_mapQuickStart.length}");
    });
  }

  void delete_quick_start() async {
    Database database = await InitDatabase().database;
    await database.delete(
      'taches',
      where: 'id_categorie = 1',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: backgroundColor1,
        appBar: AppBar(
          title: Text("Overview"),
          centerTitle: true,
          flexibleSpace: GestureDetector(
            onLongPress: () {
              // TODO : faire en sorte que le choix se fasse plus explicitement (bouton paramètres)
              // sur un appuie long sur la barre du haut
              // on affiche le popup pour choisir le theme de l'app
              showColorPickerDialog(context);
            },
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: allColors[colorIndex],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          leading: Padding(
            padding: const EdgeInsets.only(left: 25.0),
            child: GestureDetector(
              onTap: () {
                // TODO : traiter appuie sur bouton info
              },
              child: SvgPicture.asset(
                'assets/icons/info.svg',
              ),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 25.0),
              child: GestureDetector(
                onTap: () {
                  // TODO : traiter appuie sur bouton edit
                },
                child: SvgPicture.asset(
                  'assets/icons/edit.svg',
                ),
              ),
            ),
          ],
        ),
        body: FutureBuilder<List<Categorie>>(
          future: futureCategories,
          builder: (BuildContext context, AsyncSnapshot<List<Categorie>> snapshot1) {
            if (snapshot1.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot1.hasError) {
              return BottomAppBar(
                child: Text('Error loading categories'),
              );
            } else {
              return FutureBuilder<List<Tache>>(
                future: futureTaches,
                builder: (BuildContext context, AsyncSnapshot<List<Tache>> snapshot2) {
                  if (snapshot2.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snapshot2.hasError) {
                    return BottomAppBar(
                      child: Text('Error loading tasks'),
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
                                    // TODO : traiter appuie sur le bouton Quick Start
                                    await add_quick_tache();
                                    //print("size map : ${_mapQuickStart.length}");
                                    _startTimer(_mapQuickStart.keys.last);
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
                                    child: buildRow("papers", "All Tasks"),
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
                                    child: buildRow("paper", "Single Tasks"),
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
                      duration: Duration(milliseconds: 500)
                  )
              );
            }
            // cas où on appuie sur le bouton export
            else if (value == 2) {
              // TODO : traitement appuie bouton export
            }
          },
          backgroundColor: Colors.white,
          selectedItemColor: allColors[colorIndex][1],
          unselectedItemColor: allColors[colorIndex][1],
          selectedFontSize: 15,
          unselectedFontSize: 15,
          showSelectedLabels: false,
          showUnselectedLabels: false,
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
                'assets/icons/mail.svg',
                color: allColors[colorIndex][1],
              ),
              label: '',
            ),
          ],
          iconSize: 40,
          elevation: 5,
        )
    );
  }

  Row buildRow(String icon, String titre) {
    String tempsEcoule = "00:00:00";
    if (titre == "All Tasks") {
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
          child: (icon == "paper")
              ? Image.asset(
            'assets/icons/paper.png',
          )
              : ((icon == "papers")
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
        // Naviguer vers la page de détail de la tache
        /*Navigator.push(
            context,
            PageTransition(
                type: PageTransitionType.rightToLeftWithFade,
                child: TacheDetail(tache: tache, colorIndex: colorIndex),
                childCurrent: this.widget,if (_isTimerActive || _isPressed ) {

                duration: Duration(milliseconds: 500)
            )
        );*/
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
              Icon(Icons.pause_circle):Icon(Icons.play_circle),
              onPressed: () async {
                toggleStartStop(tache);
                _startTimer(tache);
                if(!_mapQuickStart[tache]['isActive']){
                  final now = DateTime.now().add(Duration(hours: 2));
                  final formatter = DateFormat('yyyy-MM-ddTHH:mm:ss');
                  String formattedDateFin = formatter.format(DateTime.now().toUtc()) + 'Z';
                  if (_idTacheEnCours != null) {
                    // Mettre à jour la colonne date_fin dans la base de données
                    await updateDeroulementTache(_idTacheEnCours, formattedDateFin);
                  }
                  // Ajouter une nouvelle ligne dans la table deroulement_tache
                  //_idTacheEnCours = await insertDeroulementTache(tache.id, formattedDateFin);
                }
              },
              color: Colors.blue,
            ),
          ),
          Container(
            height: 50,
            width: 150,
            alignment: Alignment.centerLeft,
            child: Text(
              tache.nom, // Utilisation de l'opérateur null-aware pour fournir une chaîne vide si tache.nom est nul,
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
                    categorie: categorie, colorIndex: colorIndex, timeFilterCounter: 0,),
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
              child: Image.asset('assets/icons/dossier.png'),
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
    var quickTaches = taches;
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
}
