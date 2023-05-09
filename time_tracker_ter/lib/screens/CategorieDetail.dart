import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:page_transition/page_transition.dart';
import 'package:sqflite/sqflite.dart';
import '../model/Categorie.dart';
import '../model/DeroulementTache.dart';
import '../model/InitDatabase.dart';
import '../model/Tache.dart';
import '../utilities/constants.dart';
import 'AddTache.dart';
import 'History_main.dart';
import 'package:intl/intl.dart';

import 'SettingsTimeFilter.dart';

class CategorieDetail extends StatefulWidget {
  final Categorie categorie;
  final int colorIndex;
  final int timeFilterCounter;

  CategorieDetail({this.categorie, this.colorIndex, this.timeFilterCounter});

  @override
  CategorieDetail_ createState() => CategorieDetail_();
}

class CategorieDetail_ extends State<CategorieDetail> {
  List<Tache> taches = [];
  List<Tache> tachesFiltre = [];
  bool _isTimeFilterVisible = false;
  int timeFilterPreference;
  String timeFilterText = '';
  String timeFilterDate = '';
  int localTimeFilterCounter;
  List<DeroulementTache> deroulementTaches = [];

  @override
  void initState() {
    super.initState();
    getTaches();
    getDeroulements();
    getTimeFilterPreference();
    localTimeFilterCounter = widget.timeFilterCounter;
  }

  void getTaches() async {
    Database database = await InitDatabase().database;
    //get all taches of the categorie
    var tachesOfCategorie = await database.query('taches',
        //where categorie id is equal to the categorie id
        where: 'id_categorie = ?',
        whereArgs: [widget.categorie.id]);

    //add all taches to the list
    setState(() {
      taches = tachesOfCategorie.map((e) => Tache.fromMap(e)).toList();
      // initialisation
      tachesFiltre = taches;
    });
  }

  void getTachesByFilter() {
    List<DeroulementTache> deroulementFiltre = getDeroulementsByFilter();
    List<Tache> l = [];
    for (int i = 0; i < deroulementFiltre.length; i++) {
      for(int j = 0; j < taches.length; j++){
        if(taches[j].id == deroulementFiltre[i].id_tache){
          l.add(taches[j]);
        }
      }
    }
    setState(() {
      tachesFiltre = l;
    });
  }

  void _addTacheItem() {
    //supprimer toutes les taches
    taches.clear();
    //ajouter les taches
    getTaches();
  }

  void getTimeFilterPreference() async {
    Database database = await InitDatabase().database;
    final Map<String, dynamic> queryResult =
        (await database.query('parametres')).first;
    setState(() {
      timeFilterPreference = queryResult['time_filter_preference'] as int;
    });
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
    }
    else{
      return [];
    }
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
        title: Text(widget.categorie.nom),
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
        leading: Container(
            child: IconButton(
          color: Colors.white,
          onPressed: () {
            // appuie sur le bouton retour
            Navigator.of(context).pop(true);
          },
          icon: Icon(Icons.backspace),
        )),
        actions: [
          Container(
              child: IconButton(
            color: Colors.white,
            onPressed: () {
              // TODO : traitement appuie sur le bouton edit
            },
            icon: Icon(Icons.edit_note),
          )),
        ],
      ),
      body: Stack(
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
                        // appuie sur le bouton gauche du time filter
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
                            text = (localTimeFilterCounter + 1).toString() +
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
                            text = (localTimeFilterCounter + 1).toString() +
                                " weeks ago";
                          }
                        }
                        // mois par mois
                        else if (timeFilterPreference == 2) {
                          DateTime datePremierJour = DateTime(now.year,
                              now.month - localTimeFilterCounter - 1, 1);
                          DateTime dateDernierJour = DateTime(
                              now.year, now.month - localTimeFilterCounter, 0);
                          date = formatter.format(datePremierJour) +
                              " - " +
                              formatter.format(dateDernierJour);
                          if (localTimeFilterCounter + 1 == 1) {
                            text = "Last Month";
                          } else {
                            text = (localTimeFilterCounter + 1).toString() +
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
                                type: PageTransitionType.rightToLeftWithFade,
                                child: SettingsTimeFilter(
                                    timeFilterPreference: timeFilterPreference,
                                    timeFilterCounter: localTimeFilterCounter,
                                    colorIndex: widget.colorIndex),
                                childCurrent: this.widget,
                                duration: Duration(milliseconds: 500)));
                        if (t != null) {
                          String text = '';
                          String date = '';
                          DateTime now = DateTime.now();
                          DateFormat formatter = DateFormat('dd/MM/yyyy');
                          await getTimeFilterPreference();
                          // jour
                          if (timeFilterPreference == 0) {
                            // today
                            if (t == 0) {
                              date = formatter.format(now);
                              text = "Today";
                            }
                            // yesterday
                            else if (t == 1) {
                              date = formatter
                                  .format(now.subtract(Duration(days: 1)));
                              text = "Yesterday";
                            }
                          }
                          // semaine
                          else if (timeFilterPreference == 1) {
                            // this week
                            if (t == 0) {
                              DateTime datePremierJour =
                                  now.subtract(Duration(days: now.weekday - 1));
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
                                  .subtract(Duration(days: now.weekday - 1))
                                  .subtract(Duration(days: 7));
                              DateTime dateDernierJour = now
                                  .subtract(Duration(days: now.weekday - 1))
                                  .subtract(Duration(days: 1));
                              date = formatter.format(datePremierJour) +
                                  " - " +
                                  formatter.format(dateDernierJour);
                              text = "Last Week";
                            }
                          }
                          // mois
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
                                timeFilterDate.split('/').reversed.join('-'));
                            DateTime after = before.add(Duration(days: 1));
                            date = formatter.format(after);
                            if (localTimeFilterCounter - 1 == 1) {
                              text = "Yesterday";
                            } else if (localTimeFilterCounter - 1 == 0) {
                              text = "Today";
                            } else {
                              text = (localTimeFilterCounter - 1).toString() +
                                  " days ago";
                            }
                          }
                          // semaine par semaine
                          else if (timeFilterPreference == 1) {
                            DateTime beforePremierJour =
                                formatter.parse(timeFilterDate.split("-")[0]);
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
                              text = (localTimeFilterCounter - 1).toString() +
                                  " weeks ago";
                            }
                          }
                          // mois par mois
                          else if (timeFilterPreference == 2) {
                            DateTime beforePremierJour =
                                formatter.parse(timeFilterDate.split("-")[0]);
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
                              text = (localTimeFilterCounter - 1).toString() +
                                  " months ago";
                            }
                          }
                          setState(() {
                            timeFilterText = text;
                            timeFilterDate = date;
                            localTimeFilterCounter--;
                          });
                          getTachesByFilter();
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
                  getCategorieContainer()),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
          onTap: (value) {
            // cas où appuie sur le bouton +
            if (value == 0) {
              Navigator.push(
                  context,
                  PageTransition(
                      type: PageTransitionType.bottomToTop,
                      child: AddTache(
                          onDataAdded: _addTacheItem,
                          colorIndex: widget.colorIndex,
                          categorie: widget.categorie),
                      childCurrent: this.widget,
                      duration: Duration(milliseconds: 500)));
            }
            // cas où appuie sur le bouton export
            else if (value == 2) {
              // TODO : traitement appuie sur le bouton export
            }
            // cas où appuie sur le bouton time filter
            else if (value == 3) {
              // appuie quand le filtre n'est pas visible
              if (_isTimeFilterVisible == false) {
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
                  DateTime datePremierJour = DateTime(now.year, now.month, 1);
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
                  _isTimeFilterVisible = true;
                  localTimeFilterCounter = 0;
                });
                getTachesByFilter();
              }
              // appuie quand le filtre est visible
              else {
                setState(() {
                  tachesFiltre = taches;
                  _isTimeFilterVisible = false;
                });
              }
            }
          },
          backgroundColor: Colors.white,
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
              icon: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Total ",
                    overflow: TextOverflow.visible,
                    style: TextStyle(
                        fontSize: 19, color: allColors[widget.colorIndex][1]),
                  ),
                  Text(
                    widget.categorie.temps_ecoule,
                    overflow: TextOverflow.visible,
                    style: TextStyle(
                        fontSize: 19, color: allColors[widget.colorIndex][1]),
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
          elevation: 5),
    );
  }

  Container buildRowTache(Tache tache) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 0.5),
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
            // get tap location
            // show the context menu
            onLongPress: () {},
            child: Container(
              height: 50,
              width: 150,
              alignment: Alignment.center,
              child: Text(
                tache.nom,
                style: TextStyle(fontSize: 20.0, color: Colors.black87),
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
                      Navigator.push(
                          context,
                          PageTransition(
                              type: PageTransitionType.rightToLeftWithFade,
                              child: HistoryPage(
                                title: tache.nom,
                                id: tache.id,
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

  Container getCategorieContainer() {
    if (tachesFiltre == null || tachesFiltre.length == 0) {
      return Container();
    }
    return Container(
      width: double.infinity,
      alignment: Alignment.topCenter,
      margin: const EdgeInsets.only(bottom: 20.0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: backgroundColor2,
        ),
        //get the categories from the database
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: tachesFiltre.length,
          itemBuilder: (context, index) {
            return buildRowTache(tachesFiltre[index]);
          },
        ),
      ),
    );
  }
}
