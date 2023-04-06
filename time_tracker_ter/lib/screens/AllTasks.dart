import 'package:flutter/material.dart';
import 'package:flutter_login_ui/model/Categorie.dart';
import 'package:flutter_login_ui/screens/AddCategorie.dart';
import 'package:flutter_login_ui/screens/SettingsTimeFilter.dart';
import 'package:page_transition/page_transition.dart';
import 'package:flutter_login_ui/model/DeroulementTache.dart';

import 'package:sqflite/sqflite.dart';
import '../model/InitDatabase.dart';
import '../model/Tache.dart';
import '../utilities/constants.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';

import 'package:flutter_login_ui/screens/AllTasksEdit.dart';
import 'EditTask.dart';
import 'History_main.dart';
import '../services/DatabaseService.dart';

import 'History_main.dart';

class AllTasksPage extends StatefulWidget {
  final int colorIndex;
  final int timeFilterCounter;

  AllTasksPage({this.colorIndex, this.timeFilterCounter});

  @override
  _AllTasksPageState createState() => _AllTasksPageState();
}

class _AllTasksPageState extends State<AllTasksPage> {
  bool _isEditMode = false;
  bool _isDragging = false;
  Future<List<Categorie>> futureCategories;
  List<Categorie> categories = [];
  String tempsEcouleTotal = "00:00:00";
  List<Tache> taches = [];
  List<Tache> tachesFiltre = [];
  List<DeroulementTache> deroulementTaches = [];
  bool _isTimeFilterVisible = false;
  int timeFilterPreference;
  String timeFilterText = '';
  String timeFilterDate = '';
  int localTimeFilterCounter;

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
    });
  }

  void refreshData() {
    setState(() {
      fetchData();
    });
  }

  Future<void> fetchData() async {
    await getTaches();
    await getDeroulements();
  }

  @override
  void initState() {
    super.initState();
    futureCategories = getCategories();
    fetchData();
    getTimeFilterPreference();
    localTimeFilterCounter = widget.timeFilterCounter;
  }

  void getTimeFilterPreference() async {
    Database database = await InitDatabase().database;
    final Map<String, dynamic> queryResult =
        (await database.query('parametres')).first;
    setState(() {
      timeFilterPreference = queryResult['time_filter_preference'] as int;
    });
  }

  void getTaches() async {
    Database database = await InitDatabase().database;
    var t = await database.query('taches');
    setState(() {
      taches = t.map((e) => Tache.fromMap(e)).toList();
      // initialisation
      tachesFiltre = taches;
    });
  }

  void getTachesByFilter() {
    List<DeroulementTache> deroulementFiltre = getDeroulementsByFilter();
    List<Tache> l = [];
    for (int i = 0; i < deroulementFiltre.length; i++) {
      l.add(taches[deroulementFiltre[i].id_tache - 1]);
    }
    setState(() {
      tachesFiltre = l;
    });
  }

  void deleteTache(int id) async {
    Database database = await InitDatabase().database;
    await database.delete('taches', where: 'id = ?', whereArgs: [id]);
    taches.clear();
    getTaches();
  }

  void getDeroulements() async {
    Database database = await InitDatabase().database;
    var t = await database.query('deroulement_tache');
    setState(() {
      deroulementTaches = t.map((e) => DeroulementTache.fromMap(e)).toList();
    });
  }

  List<DeroulementTache> getDeroulementsByFilter() {
    List<DeroulementTache> deroulementsFiltre = [];
    // jour
    if (timeFilterPreference == 0) {
      // convertir la date du time filter
      DateTime jourFiltre =
          DateTime.parse(timeFilterDate.split('/').reversed.join('-'));
      // on cherche à comparer seulement l'année, le mois et le jour
      jourFiltre = DateTime(jourFiltre.year, jourFiltre.month, jourFiltre.day);

      deroulementsFiltre = deroulementTaches.where((deroulement) {
        // convertir les dates de l'objet DeroulementTache
        DateTime dateDebut = DateTime.parse(deroulement.date_debut);
        DateTime dateFin = DateTime.parse(deroulement.date_fin);
        // on cherche à comparer seulement l'année, le mois et le jour
        dateDebut = DateTime(dateDebut.year, dateDebut.month, dateDebut.day);
        dateFin = DateTime(dateFin.year, dateFin.month, dateFin.day);
        return dateDebut.isAtSameMomentAs(jourFiltre) &&
            dateFin.isAtSameMomentAs(jourFiltre);
      }).toList();
      return deroulementsFiltre;
    }
    // semaine
    else if (timeFilterPreference == 1) {
      // convertir les dates de début et de fin de semaine du time filter
      DateFormat formatter = DateFormat('dd/MM/yyyy');
      DateTime premierJourFiltre =
          formatter.parse(timeFilterDate.split("-")[0]);
      DateTime dernierJourFiltre =
          formatter.parse(timeFilterDate.split("-")[1].replaceAll(' ', ''));
      // on cherche à comparer seulement l'année, le mois et le jour
      premierJourFiltre = DateTime(premierJourFiltre.year,
          premierJourFiltre.month, premierJourFiltre.day);
      dernierJourFiltre = DateTime(dernierJourFiltre.year,
          dernierJourFiltre.month, dernierJourFiltre.day);

      deroulementsFiltre = deroulementTaches.where((deroulement) {
        // convertir les dates de l'objet DeroulementTache
        DateTime dateDebut = DateTime.parse(deroulement.date_debut);
        DateTime dateFin = DateTime.parse(deroulement.date_fin);
        // on cherche à comparer seulement l'année, le mois et le jour
        dateDebut = DateTime(dateDebut.year, dateDebut.month, dateDebut.day);
        dateFin = DateTime(dateFin.year, dateFin.month, dateFin.day);
        return ((dateDebut.isAfter(premierJourFiltre) ||
                dateDebut == premierJourFiltre) &&
            (dateFin.isBefore(dernierJourFiltre) ||
                dateFin == dernierJourFiltre));
      }).toList();
      return deroulementsFiltre;
    }
    // mois
    else if (timeFilterPreference == 2) {
      // convertir les dates de début et de fin de mois du time filter
      DateFormat formatter = DateFormat('dd/MM/yyyy');
      DateTime premierJourFiltre =
          formatter.parse(timeFilterDate.split("-")[0]);
      DateTime dernierJourFiltre =
          formatter.parse(timeFilterDate.split("-")[1].replaceAll(' ', ''));
      // on cherche à comparer seulement l'année, le mois et le jour
      premierJourFiltre = DateTime(premierJourFiltre.year,
          premierJourFiltre.month, premierJourFiltre.day);
      dernierJourFiltre = DateTime(dernierJourFiltre.year,
          dernierJourFiltre.month, dernierJourFiltre.day);

      deroulementsFiltre = deroulementTaches.where((deroulement) {
        // convertir les dates de l'objet DeroulementTache
        DateTime dateDebut = DateTime.parse(deroulement.date_debut);
        DateTime dateFin = DateTime.parse(deroulement.date_fin);
        // on cherche à comparer seulement l'année, le mois et le jour
        dateDebut = DateTime(dateDebut.year, dateDebut.month, dateDebut.day);
        dateFin = DateTime(dateFin.year, dateFin.month, dateFin.day);
        return ((dateDebut.isAfter(premierJourFiltre) ||
                dateDebut == premierJourFiltre) &&
            (dateFin.isBefore(dernierJourFiltre) ||
                dateFin == dernierJourFiltre));
      }).toList();
      return deroulementsFiltre;
    } else {
      return [];
    }
  }

  Future<List<Categorie>> getCategories() async {
    Database database = await InitDatabase().database;
    var cats = await database.query('categories');
    List<Categorie> liste = cats.map((e) => Categorie.fromMap(e)).toList();
    setState(() {
      categories = liste;
    });
    // calcule le temps ecoule pour la categorie
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

  void deleteTache(int id) async {
    Database database = await InitDatabase().database;
    await database.delete('taches', where: 'id = ?', whereArgs: [id]);
    taches.clear();
    getTaches();
  }

  List<Tache> getTachesCategorie(Categorie categorie) {
    List<Tache> t = [];
    for (int i = 0; i < tachesFiltre.length; i++) {
      if (tachesFiltre[i].id_categorie == categorie.id) {
        if (!t.contains(tachesFiltre[i])) t.add(tachesFiltre[i]);
      }
    }
    return t;
  }

  void deleteCategorie(int id) async {
    Database database = await InitDatabase().database;
    await database.delete('categories', where: 'id = ?', whereArgs: [id]);
    categories.clear();
    getCategories();
  }

  void _addCategorieItem() {
    //clear all categories
    categories.clear();
    getCategories();
  }

  // calcule le temps écoulé pour une tache donnée avec le filtre du moment
  String calculerTempsFiltre(Tache tache) {
    List<DeroulementTache> deroulementsFiltre = getDeroulementsByFilter();
    Duration tempsEcoule = Duration();
    for (int i = 0; i < deroulementsFiltre.length; i++) {
      if (deroulementsFiltre[i].id_tache == tache.id) {
        DateTime dateDebut = DateTime.parse(deroulementsFiltre[i].date_debut);
        DateTime dateFin = DateTime.parse(deroulementsFiltre[i].date_fin);
        tempsEcoule = tempsEcoule + dateFin.difference(dateDebut);
      }
    }
    String tempsEcouleTxt = '${tempsEcoule.inHours.toString().padLeft(2, '0')}:'
        '${(tempsEcoule.inMinutes % 60).toString().padLeft(2, '0')}:'
        '${(tempsEcoule.inSeconds % 60).toString().padLeft(2, '0')}';
    return tempsEcouleTxt;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: backgroundColor1,
        appBar: AppBar(
          title: Text("All Tasks"),
          centerTitle: true,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: allColors[widget.colorIndex],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
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
                  _toggleEditMode();
                },
                child: _isEditMode
                    ? Icon(
                        Icons.done,
                        size: 30,
                      )
                    : SvgPicture.asset(
                        'assets/icons/edit.svg',
                      ),
              ),
            ),
          ],
        ),
        body: _isEditMode ? _buildEditMode() : _buildViewMode(),
        bottomNavigationBar: FutureBuilder<List<Categorie>>(
          future: futureCategories,
          builder:
              (BuildContext context, AsyncSnapshot<List<Categorie>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(),
              );
            } else if (snapshot.hasError) {
              return BottomAppBar(
                child: Text('Error loading categories'),
              );
            } else {
              return BottomNavigationBar(
                  type: BottomNavigationBarType.fixed,
                  onTap: (value) {
                    // cas où appuie sur le bouton +
                    if (value == 0) {
                      // afficher la page pour ajouter une catégorie
                      Navigator.push(
                          context,
                          PageTransition(
                              type: PageTransitionType.bottomToTop,
                              child: AddCatePage(
                                onDataAdded: _addCategorieItem,
                                colorIndex: widget.colorIndex,
                              ),
                              childCurrent: this.widget,
                              duration: Duration(milliseconds: 500)));
                    }
                    // cas où appuie sur le bouton balai
                    else if (value == 1) {
                      // TODO : traitement appuie bouton balai
                    }
                    // cas où appuie sur le bouton export
                    else if (value == 3) {
                      // TODO : traitement appuie bouton export
                    }
                    // cas où appuie sur le bouton time filter
                    else if (value == 4) {
                      String text = '';
                      String date = '';
                      DateTime now = DateTime.now();
                      DateFormat formatter = DateFormat('dd/MM/yyyy');
                      // jour
                      if (timeFilterPreference == 0) {
                        date = formatter.format(now);
                        text = "Today";
                      }
                      // semaine
                      else if (timeFilterPreference == 1) {
                        DateTime datePremierJour =
                            now.subtract(Duration(days: now.weekday - 1));
                        DateTime dateDernierJour =
                            datePremierJour.add(Duration(days: 6));
                        date = formatter.format(datePremierJour) +
                            " - " +
                            formatter.format(dateDernierJour);
                        text = "This Week";
                      }
                      // mois
                      else if (timeFilterPreference == 2) {
                        DateTime datePremierJour =
                            DateTime(now.year, now.month, 1);
                        DateTime dateDernierJour =
                            DateTime(now.year, now.month + 1, 0);
                        date = formatter.format(datePremierJour) +
                            " - " +
                            formatter.format(dateDernierJour);
                        text = "This Month";
                      }
                      setState(() {
                        timeFilterDate = date;
                        timeFilterText = text;
                        // si le bandeau de filtre est affiché on le retire, sinon on l'affiche
                        _isTimeFilterVisible = !_isTimeFilterVisible;
                        localTimeFilterCounter = 0;
                      });
                    }
                  },
                  backgroundColor: backgroundColor2,
                  selectedItemColor: allColors[widget.colorIndex][1],
                  unselectedItemColor: allColors[widget.colorIndex][1],
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
                      icon: SvgPicture.asset(
                        'assets/icons/broom.svg',
                        color: allColors[widget.colorIndex][1],
                      ),
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
                                fontSize: 19,
                                color: allColors[widget.colorIndex][1]),
                          ),
                          Text(
                            tempsEcouleTotal,
                            overflow: TextOverflow.visible,
                            style: TextStyle(
                                fontSize: 19,
                                color: allColors[widget.colorIndex][1]),
                          ),
                        ],
                      ),
                      label: '',
                    ),
                    BottomNavigationBarItem(
                      icon: SvgPicture.asset(
                        'assets/icons/mail.svg',
                        color: allColors[widget.colorIndex][1],
                      ),
                      label: '',
                    ),
                    BottomNavigationBarItem(
                      icon: SvgPicture.asset(
                        'assets/icons/calendar.svg',
                        color: allColors[widget.colorIndex][1],
                      ),
                      label: '',
                    ),
                  ],
                  iconSize: 40,
                  elevation: 5);
            }
          },
        ));
  }

  Widget getPageContainer() {
    return SingleChildScrollView(
      child: Column(
        children: [
          ...categories.map((categorie) {
            final tachesCategorie = getTachesCategorie(categorie);
            return buildRowCategorie(categorie, categorie.id, tachesCategorie);
          }).toList(),
        ],
      ),
    );
  }

  Container buildRowCategorie(
      Categorie categorie, int id, List<Tache> listeTachesCat) {
    if (listeTachesCat.isEmpty) return Container();
    return Container(
        width: double.infinity,
        alignment: Alignment.centerLeft,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: EdgeInsets.only(left: 16.0, top: 10.0),
            child: Text(
              categorie.nom,
              style: TextStyle(
                  fontSize: 20,
                  color: allColors[widget.colorIndex][1],
                  fontFamily: 'Montserrat'),
            ),
          ),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: 1),
              color: backgroundColor2,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DragTarget<Tache>(
                  onWillAccept: (data) {
                    setState(() {
                      _isDragging = true;
                    });
                    return true;
                  },
                  onAccept: (data) {
                    setState(() {
                      _isDragging = false;
                      ModifierGroupeCategorie(data.id, categorie.id);
                      refreshData();
                    });
                  },
                  builder: (context, candidateData, rejectedData) {
                    if (listeTachesCat.isEmpty && _isDragging) {
                      // Placeholder widget for empty category when dragging a task
                      return Container(
                        height: 30,
                        width: double.infinity,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white,
                        ),
                      );
                    } else if (listeTachesCat.isEmpty && !_isDragging) {
                      // Placeholder widget for empty category
                      return SizedBox.shrink();
                    } else {
                      // Task list for non-empty category
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: listeTachesCat.length,
                        itemBuilder: (context, index) {
                          return _isEditMode
                              ? buildRowTacheEdit(listeTachesCat[index],
                                  listeTachesCat[index].id)
                              : buildRowTache(listeTachesCat[index].nom,
                                  listeTachesCat[index].id);
                        },
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ]));
  }

  Draggable buildRowTacheEdit(Tache tache, int id) {
    return Draggable<Tache>(
      data: tache,
      feedback: buildFeedBackDraggable(tache, id),
      childWhenDragging: Container(),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: 1),
          color: backgroundColor2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 20,
              width: 20,
              child: GestureDetector(
                onTap: () {
                  showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Delete Confirmation'),
                          content: Text(
                              'Are you sure you want to delete task: ${tache.nom} ?'),
                          actions: [
                            TextButton(
                              child: const Text('Cancel'),
                              onPressed: () {
                                Navigator.of(context).pop(); //Dismiss Dialog
                              },
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                Navigator.of(context).pop(); //Dismiss Dialog
                                setState(() {
                                  DeleteTache(id);
                                  refreshData();
                                });
                              },
                              child: const Text('Delete'),
                            ),
                          ],
                        );
                        ;
                      });
                  // TODO : lancer chronomètre pour la tache
                },
                child: SvgPicture.asset(
                  'assets/icons/delete3.svg',
                ),
              ),
            ),
            GestureDetector(
              child: Container(
                height: 50,
                width: 190,
                alignment: Alignment.centerLeft,
                child: Text(
                  tache.nom,
                  style: TextStyle(fontSize: 20.0, color: Colors.black),
                ),
              ),
            ),
            SizedBox(
              height: 30,
              width: 10,
            ),
            Container(
                height: 50,
                width: 38,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                EditTask(tache, categories, refreshData),
                          ),
                        );
                      },
                      child: Icon(
                        Icons.keyboard_arrow_right_rounded,
                        color: allColors[widget.colorIndex][1],
                        size: 38.0,
                      ),
                    ),
                  ],
                )),
          ],
        ),
      ),
    );
  }

  //        ------------- back up buildRowTacheEdit------------------
  Container buildRowTacheEdit1(Tache tache, int id) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 1),
        color: backgroundColor2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 20,
            width: 20,
            child: GestureDetector(
              onTap: () {
                showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Delete Confirmation'),
                        content: Text(
                            'Are you sure you want to delete task: ${tache.nom} ?'),
                        actions: [
                          TextButton(
                            child: const Text('Cancel'),
                            onPressed: () {
                              Navigator.of(context).pop(); //Dismiss Dialog
                            },
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              Navigator.of(context).pop(); //Dismiss Dialog
                              setState(() {
                                DeleteTache(id);
                                refreshData();
                              });
                            },
                            child: const Text('Delete'),
                          ),
                        ],
                      );
                      ;
                    });
                // TODO : lancer chronomètre pour la tache
              },
              child: SvgPicture.asset(
                'assets/icons/delete3.svg',
              ),
            ),
          ),
          GestureDetector(
            child: Container(
              height: 50,
              width: 150,
              alignment: Alignment.centerLeft,
              child: Text(
                tache.nom,
                style: TextStyle(fontSize: 20.0, color: Colors.black),
              ),
            ),
          ),
          Container(
            height: 30,
            width: 30,
            child: GestureDetector(
              onTap: () {
                // TODO : naviguer vers l'historique de la tache
                Navigator.push(
                    context,
                    PageTransition(
                        type: PageTransitionType.rightToLeftWithFade,
                        child: HistoryPage(
                          title: tache.nom,
                          id: id,
                        ),
                        childCurrent: this.widget,
                        duration: Duration(milliseconds: 500)));
              },
            ),
          ),
          Container(
              height: 50,
              width: 58,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              EditTask(tache, categories, refreshData),
                        ),
                      );
                    },
                    child: Icon(Icons.keyboard_arrow_right_rounded,
                        color: allColors[widget.colorIndex][1], size: 29.0),
                  ),
                  GestureDetector(
                      onTap: () {
                        //TODO
                        //bouton 3 slash (move group)
                      },
                      child: Icon(
                        Icons.menu_rounded,
                        color: allColors[widget.colorIndex][1],
                        size: 29.0,
                      ))
                ],
              )),
        ],
      ),
    );
  }

  Container buildRowTache(String titre, int id) {
    Tache tache = null;
    for (int i = 0; i < tachesFiltre.length; i++) {
      if (tachesFiltre[i].id == id) {
        tache = tachesFiltre[i];
      }
    }
    if (tache == null) return Container();
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 1),
        color: backgroundColor2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 20,
            width: 20,
            child: GestureDetector(
              onTap: () {
                // TODO : lancer chronomètre pour la tache
              },
              child: SvgPicture.asset(
                'assets/icons/play_arrow.svg',
              ),
            ),
          ),
          GestureDetector(
            // sur un appuie long :
            // afficher le popup pour supprimer ou éditer la tache
            onLongPress: () {
              showDelModDialog(context, id);
              print(titre);
            },
            child: Container(
              height: 50,
              width: 150.3,
              alignment: Alignment.centerLeft,
              child: Text(
                titre,
                style: TextStyle(fontSize: 20.0, color: Colors.black),
              ),
            ),
          ),
          Container(
            height: 50,
            width: 125,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  height: 50,
                  width: 80,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    (_isTimeFilterVisible == true)
                        ? calculerTempsFiltre(tache)
                        : tache.temps_ecoule,
                    style: TextStyle(fontSize: 20.0, color: Colors.black),
                  ),
                ),
                Container(
                  height: 30,
                  width: 30,
                  child: GestureDetector(
                    onTap: () {
                      // TODO : naviguer vers l'historique de la tache
                      Navigator.push(
                          context,
                          PageTransition(
                              type: PageTransitionType.rightToLeftWithFade,
                              child: HistoryPage(
                                title: titre,
                                id: id,
                                colorIndex: widget.colorIndex,
                              ),
                              childCurrent: this.widget,
                              duration: Duration(milliseconds: 500)));
                    },
                    child: Stack(
                      children: [
                        SvgPicture.asset(
                          'assets/icons/circle.svg',
                          color: allColors[widget.colorIndex][1],
                        ),
                        Padding(
                          padding: EdgeInsets.all(10),
                          child: SvgPicture.asset(
                            'assets/icons/arrow_right_in_circle.svg',
                            color: Colors.white,
                          ),
                        ),
                      ],
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
        // appuie sur le bouton delete
        // on supprime la tache
        deleteTache(id);
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
        // TODO : traitement bouton edit tache
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

  // VIEWMODE
  Widget _buildViewMode() {
    return FutureBuilder<List<Categorie>>(
        future: futureCategories,
        builder:
            (BuildContext context, AsyncSnapshot<List<Categorie>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return BottomAppBar(
              child: Text('Error loading categories'),
            );
          } else {
            return Stack(
              children: [
                Container(
                  height: _isTimeFilterVisible ? 65 : 0,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [timeFilterColor1, timeFilterColor2],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(left: 30.0),
                          child: GestureDetector(
                            onTap: (() {
                              String text = '';
                              String date = '';
                              DateTime now = DateTime.now();
                              DateFormat formatter = DateFormat('dd/MM/yyyy');
                              // jour par jour
                              if (timeFilterPreference == 0) {
                                DateTime before = now.subtract(
                                    Duration(days: localTimeFilterCounter + 1));
                                date = formatter.format(before);
                                if (localTimeFilterCounter + 1 == 1) {
                                  text = "Yesterday";
                                } else {
                                  text =
                                      (localTimeFilterCounter + 1).toString() +
                                          " days ago";
                                }
                              }
                              // semaine par semaine
                              else if (timeFilterPreference == 1) {
                                DateTime datePremierJour = now
                                    .subtract(Duration(days: now.weekday - 1))
                                    .subtract(Duration(
                                        days: 7 * (localTimeFilterCounter + 1)));
                                DateTime dateDernierJour = now
                                    .subtract(Duration(days: now.weekday - 1))
                                    .subtract(Duration(
                                        days: 7 * localTimeFilterCounter + 1));
                                date = formatter.format(datePremierJour) +
                                    " - " +
                                    formatter.format(dateDernierJour);
                                if (localTimeFilterCounter + 1 == 1) {
                                  text = "Last Week";
                                } else {
                                  text =
                                      (localTimeFilterCounter + 1).toString() +
                                          " weeks ago";
                                }
                              }
                              // mois par mois
                              else if (timeFilterPreference == 2) {
                                DateTime datePremierJour = DateTime(now.year,
                                    now.month - localTimeFilterCounter - 1, 1);
                                DateTime dateDernierJour = DateTime(now.year,
                                    now.month - localTimeFilterCounter, 0);
                                date = formatter.format(datePremierJour) +
                                    " - " +
                                    formatter.format(dateDernierJour);
                                if (localTimeFilterCounter + 1 == 1) {
                                  text = "Last Month";
                                } else {
                                  text =
                                      (localTimeFilterCounter + 1).toString() +
                                          " months ago";
                                }
                              }
                              setState(() {
                                timeFilterText = text;
                                timeFilterDate = date;
                                localTimeFilterCounter++;
                              });
                              getTachesByFilter();
                            }),
                            child: SvgPicture.asset('assets/icons/left.svg'),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              // appuie sur le texte du time filter
                              int t = await Navigator.push(
                                  context,
                                  PageTransition(
                                      type: PageTransitionType
                                          .rightToLeftWithFade,
                                      child: SettingsTimeFilter(
                                          timeFilterPreference:
                                              timeFilterPreference,
                                          timeFilterCounter:
                                              localTimeFilterCounter,
                                          colorIndex: widget.colorIndex),
                                      childCurrent: this.widget,
                                      duration: Duration(milliseconds: 500)));
                              if (t != null) {
                                String text = '';
                                String date = '';
                                DateTime now = DateTime.now();
                                DateFormat formatter = DateFormat('dd/MM/yyyy');
                                await getTimeFilterPreference();
                                // jour par jour
                                if (timeFilterPreference == 0) {
                                  if (t == 0) {
                                    // today
                                    date = formatter.format(now);
                                    text = "Today";
                                  } else if (t == 1) {
                                    date = formatter.format(
                                        now.subtract(Duration(days: 1)));
                                    text = "Yesterday";
                                  }
                                }
                                // semaine par semaine
                                else if (timeFilterPreference == 1) {
                                  // this week
                                  if (t == 0) {
                                    DateTime datePremierJour = now.subtract(
                                        Duration(days: now.weekday - 1));
                                    DateTime dateDernierJour =
                                        datePremierJour.add(Duration(days: 6));
                                    date = formatter.format(datePremierJour) +
                                        " - " +
                                        formatter.format(dateDernierJour);
                                    text = "This Week";
                                  }
                                  // last week
                                  else if (t == 1) {
                                    DateTime datePremierJour = now
                                        .subtract(
                                        Duration(days: now.weekday - 1))
                                        .subtract(Duration(days: 7));
                                    DateTime dateDernierJour = now
                                        .subtract(
                                        Duration(days: now.weekday - 1))
                                        .subtract(Duration(days: 1));
                                    date = formatter.format(datePremierJour) +
                                        " - " +
                                        formatter.format(dateDernierJour);
                                    text = "Last Week";
                                  }
                                }
                                // mois par mois
                                else if (timeFilterPreference == 2) {
                                  // this month
                                  if (t == 0) {
                                    DateTime datePremierJour =
                                        DateTime(now.year, now.month, 1);
                                    DateTime dateDernierJour =
                                        DateTime(now.year, now.month + 1, 0);
                                    date = formatter.format(datePremierJour) +
                                        " - " +
                                        formatter.format(dateDernierJour);
                                    text = "This Month";
                                  }
                                  // last month
                                  else if (t == 1) {
                                    DateTime datePremierJour =
                                        DateTime(now.year, now.month - 1, 1);
                                    DateTime dateDernierJour =
                                        DateTime(now.year, now.month, 0);
                                    date = formatter.format(datePremierJour) +
                                        " - " +
                                        formatter.format(dateDernierJour);
                                    text = "Last Month";
                                  }
                                }
                                setState(() {
                                  timeFilterDate = date;
                                  timeFilterText = text;
                                  localTimeFilterCounter = t;
                                });
                              }
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  timeFilterText,
                                  style: kLabelStyle,
                                ),
                                Text(
                                  timeFilterDate,
                                  style: kLabelStyle,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Visibility(
                          visible: localTimeFilterCounter == 0 ? false : true,
                          maintainSize: true,
                          maintainAnimation: true,
                          maintainState: true,
                          child: Padding(
                            padding: EdgeInsets.only(right: 30.0),
                            child: GestureDetector(
                              onTap: (() {
                                // appuie sur le bouton droite du time filter
                                String text = '';
                                String date = '';
                                DateFormat formatter = DateFormat('dd/MM/yyyy');
                                // jour par jour
                                if (timeFilterPreference == 0) {
                                  DateTime before = DateTime.parse(
                                      timeFilterDate
                                          .split('/')
                                          .reversed
                                          .join('-'));
                                  DateTime after =
                                      before.add(Duration(days: 1));
                                  date = formatter.format(after);
                                  if (localTimeFilterCounter - 1 == 1) {
                                    text = "Yesterday";
                                  } else if (localTimeFilterCounter - 1 == 0) {
                                    text = "Today";
                                  } else {
                                    text = (localTimeFilterCounter - 1)
                                            .toString() +
                                        " days ago";
                                  }
                                }
                                // semaine par semaine
                                else if (timeFilterPreference == 1) {
                                  DateTime beforePremierJour = formatter
                                      .parse(timeFilterDate.split("-")[0]);
                                  DateTime beforeDernierJour = formatter.parse(
                                      timeFilterDate
                                          .split("-")[1]
                                          .replaceAll(' ', ''));
                                  DateTime datePremierJour =
                                      beforePremierJour.add(Duration(days: 7));
                                  DateTime dateDernierJour =
                                      beforeDernierJour.add(Duration(days: 7));
                                  date = formatter.format(datePremierJour) +
                                      " - " +
                                      formatter.format(dateDernierJour);
                                  if (localTimeFilterCounter - 1 == 1) {
                                    text = "Last Week";
                                  } else if (localTimeFilterCounter - 1 == 0) {
                                    text = "This Week";
                                  } else {
                                    text = (localTimeFilterCounter - 1)
                                            .toString() +
                                        " weeks ago";
                                  }
                                }
                                // mois par mois
                                else if (timeFilterPreference == 2) {
                                  DateTime beforePremierJour = formatter
                                      .parse(timeFilterDate.split("-")[0]);
                                  DateTime beforeDernierJour = formatter.parse(
                                      timeFilterDate
                                          .split("-")[1]
                                          .replaceAll(' ', ''));
                                  DateTime datePremierJour = DateTime(
                                      beforePremierJour.year,
                                      beforePremierJour.month + 1,
                                      1);
                                  DateTime dateDernierJour = DateTime(
                                      beforeDernierJour.year,
                                      beforeDernierJour.month + 2,
                                      0);
                                  date = formatter.format(datePremierJour) +
                                      " - " +
                                      formatter.format(dateDernierJour);
                                  if (localTimeFilterCounter - 1 == 1) {
                                    text = "Last Month";
                                  } else if (localTimeFilterCounter - 1 == 0) {
                                    text = "This Month";
                                  } else {
                                    text = (localTimeFilterCounter - 1)
                                            .toString() +
                                        " months ago";
                                  }
                                }
                                setState(() {
                                  timeFilterText = text;
                                  timeFilterDate = date;
                                  localTimeFilterCounter--;
                                });
                              }),
                              child: SvgPicture.asset('assets/icons/right.svg'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                    padding: _isTimeFilterVisible
                        ? EdgeInsets.only(top: 75.0)
                        : EdgeInsets.only(top: 10.0),
                    child:
                        //affiche la page dynamiquement
                        getPageContainer()),
              ],
            );
          }
        });
  }

  Widget _buildEditMode() {
    return FutureBuilder<List<Categorie>>(
        future: futureCategories,
        builder:
            (BuildContext context, AsyncSnapshot<List<Categorie>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child : CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return BottomAppBar(
              child: Text('Error loading categories'),
            );
          } else {
            return Container(
              child: Padding(
                  padding: _isTimeFilterVisible
                      ? EdgeInsets.only(top: 75.0)
                      : EdgeInsets.only(top: 10.0),
                  child:
                      //affiche la page dynamiquement
                      getPageContainer()),
            );
          }
        });
  }
}
