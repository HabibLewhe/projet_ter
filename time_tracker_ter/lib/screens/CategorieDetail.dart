import 'dart:async';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:page_transition/page_transition.dart';
import 'package:sqflite/sqflite.dart';
import '../model/Categorie.dart';
import '../model/DeroulementTache.dart';
import '../model/InitDatabase.dart';
import '../model/Tache.dart';
import '../services/DatabaseService.dart';
import '../services/exportService.dart';
import '../utilities/constants.dart';
import 'AddTache.dart';
import 'EditTask.dart';
import 'History_main.dart';
import 'package:intl/intl.dart';

import 'PieChart.dart';
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
  List<DeroulementTache> deroulementTaches = [];
  Categorie categorie;
  List<Categorie> categories = [];

  bool _isTimeFilterVisible = false;
  int timeFilterPreference;
  String timeFilterText = '';
  String timeFilterDate = '';
  int localTimeFilterCounter;

  Map<Tache, Map<String, dynamic>> _mapTimer = {};
  List<Timer> listeTimers = [];

  @override
  void initState() {
    super.initState();
    categorie = widget.categorie;
    fetchData();
    getTimeFilterPreference();
    localTimeFilterCounter = widget.timeFilterCounter;
  }

  @override
  void dispose() {
    super.dispose();
    if (listeTimers.isNotEmpty) {
      for (int i = 0; i < listeTimers.length; i++) {
        listeTimers[i].cancel();
      }
      listeTimers.clear();
    }
    _mapTimer.clear();
  }

  Future<void> refreshData() async {
    // on arrête tous les timers, ils seront relancés si besoin plus tard
    if (listeTimers.isNotEmpty) {
      for (int i = 0; i < listeTimers.length; i++) {
        listeTimers[i].cancel();
      }
      listeTimers.clear();
    }
    _mapTimer.clear();
    await fetchData();
  }

  Future<void> fetchData() async {
    getCategories();
    if (_isTimeFilterVisible) {
      await getTachesByFilter();
    } else {
      await getTaches();
      await getDeroulements();
    }
  }

  void getCategories() async {
    Database database = await InitDatabase().database;
    var cats = await database.query('categories');
    List<Categorie> liste = cats.map((e) => Categorie.fromMap(e)).toList();
    if (mounted) {
      setState(() {
        categories = liste;
      });
    }
  }

  int durationStringToSeconds(String durationString) {
    List<String> parts = durationString.split(':');
    int hours = int.parse(parts[0]);
    int minutes = int.parse(parts[1]);
    int seconds = int.parse(parts[2]);

    return hours * 3600 + minutes * 60 + seconds;
  }

  String timerText(int sec) {
    int hours = sec ~/ 3600;
    int minutes = (sec % 3600) ~/ 60;
    int seconds = sec % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void getTaches() async {
    Database database = await InitDatabase().database;
    //get all taches of the categorie
    var tachesOfCategorie = await database.query('taches',
        //where categorie id is equal to the categorie id
        where: 'id_categorie = ?',
        whereArgs: [categorie.id]);

    List<Tache> liste = tachesOfCategorie.map((e) => Tache.fromMap(e)).toList();
    Map<Tache, Map<String, dynamic>> newMapTimer = {};
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
          newMapTimer[liste[i]] = {
            'secValue': tempsEcouleSec,
            'isActive': true
          };
        }
        // cas où le timer de la tâche ne tourne pas
        else {
          newMapTimer[liste[i]] = {
            'secValue': durationStringToSeconds(liste[i].temps_ecoule),
            'isActive': false
          };
        }
      }
    }
    if (mounted) {
      setState(() {
        taches = liste;
        if (_mapTimer.isEmpty) {
          // si la map est vide, on ajoute toutes les nouvelles
          // valeurs depuis la base de donnée
          _mapTimer = newMapTimer;
          for (final entry in _mapTimer.entries) {
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
          for (final entry2 in newMapTimer.entries) {
            final tache2 = entry2.key;
            final value = entry2.value;
            bool hasMatchingId = false;
            for (final entry1 in _mapTimer.entries) {
              final tache1 = entry1.key;
              if (tache1.id == tache2.id) {
                // met à jour le temps écoulé des tâches déjà instanciées
                tache1.temps_ecoule = tache2.temps_ecoule;
                _mapTimer[tache1] = value;
                hasMatchingId = true;
                break;
              }
            }
            if (!hasMatchingId) {
              // ajoute les nouvelles tâches
              _mapTimer[tache2] = value;
            }
          }
        }

        // initialisation
        tachesFiltre = taches;
      });
    }
  }

  Future<void> getTachesByFilter() async {
    await getDeroulements();
    List<DeroulementTache> deroulementFiltre = getDeroulementsByFilter();
    List<Tache> l = [];
    for (int i = 0; i < deroulementFiltre.length; i++) {
      Tache tache;
      for (int j = 0; j < taches.length; j++) {
        if (taches[j].id == deroulementFiltre[i].id_tache) {
          tache = taches[j];
          if (!l.contains(tache)) {
            l.add(tache);
          }
          break;
        }
      }
    }
    for (int i = 0; i < l.length; i++) {
      Tache tache = l[i];
      String date_debut = await repriseTimer(tache);
      // cas où le timer de la tâche tourne
      if (date_debut != null) {
        // on calcule le temps écoulé à partir de la date_debut et de DateTime.now()
        DateTime debut = DateTime.parse(date_debut);
        final now = DateTime.now().toUtc();
        int lastTempsEcouleSec =
            durationStringToSeconds(calculerTempsFiltre(tache));
        Duration tempsEcouleLastDeroulement = now.difference(debut);
        int tempsEcouleSec =
            lastTempsEcouleSec + tempsEcouleLastDeroulement.inSeconds;
        _mapTimer[tache] = {'secValue': tempsEcouleSec, 'isActive': true};
      } else {
        _mapTimer[tache]['secValue'] =
            durationStringToSeconds(calculerTempsFiltre(tache));
      }
    }
    setState(() {
      tachesFiltre = l;
    });
  }

  void toggleStartStop(Tache tache) {
    setState(() {
      // cas où la tâche est en cours
      if (_mapTimer[tache]['isActive']) {
        // on arrête la tâche
        _mapTimer[tache]['isActive'] = false;
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
        _mapTimer[tache]['isActive'] = true;
        _startTimer(tache);
        // Ajouter une nouvelle ligne dans la table deroulement_tache
        final now = DateTime.now().toUtc();
        final DateFormat formatter = DateFormat('yyyy-MM-ddTHH:mm:ss');
        String formattedDate = formatter.format(now) + 'Z';
        insertDeroulementTache(tache.id, formattedDate);
      }
    });
  }

  void _startTimer(Tache tache) {
    Timer timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!_mapTimer[tache]['isActive']) {
        timer.cancel(); // stop the timer if _isRunning is false
        return;
      }
      setState(() {
        Map<String, dynamic> myMap = _mapTimer[tache];
        int sec = myMap['secValue']++;
        _mapTimer.putIfAbsent(tache, () => {'secValue': sec});
      });
    });
    listeTimers.add(timer);
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
    print(
        'updateLastDeroulementTache: $id'); // ajouter cette ligne pour afficher l'ID de la tâche
    final db = await database;
    print(
        'formattedDate: $formattedDate'); // ajouter cette ligne pour afficher la date formatée
    int result = await db.update(
        'deroulement_tache', {'date_fin': formattedDate},
        where: 'id_tache = ? AND date_fin = ?', whereArgs: [id, '']);
    print(
        'update result: $result'); // ajouter cette ligne pour afficher le résultat de l'opération de mise à jour
    // pour mettre à jour le temps ecoule total
    await getTempsEcouleCategorie();
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

  void _addTacheItem() {
    //supprimer toutes les taches
    taches.clear();
    //ajouter les taches
    getTaches();
  }

  void deleteTache(int id) async {
    Database database = await InitDatabase().database;
    await database.delete('taches', where: 'id = ?', whereArgs: [id]);
    taches.clear();
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
    if (mounted) {
      setState(() {
        deroulementTaches = t.map((e) => DeroulementTache.fromMap(e)).toList();
      });
    }
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
        // on cherche à comparer seulement l'année, le mois et le jour
        dateDebut = DateTime(dateDebut.year, dateDebut.month, dateDebut.day);
        if (deroulement.date_fin != "") {
          DateTime dateFin = DateTime.parse(deroulement.date_fin);
          dateFin = DateTime(dateFin.year, dateFin.month, dateFin.day);
          return dateDebut.isAtSameMomentAs(jourFiltre) &&
              dateFin.isAtSameMomentAs(jourFiltre);
        } else {
          // cas où la date de fin du deroulement est vide
          return dateDebut.isAtSameMomentAs(jourFiltre);
        }
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
        // on cherche à comparer seulement l'année, le mois et le jour
        dateDebut = DateTime(dateDebut.year, dateDebut.month, dateDebut.day);
        if (deroulement.date_fin != "") {
          DateTime dateFin = DateTime.parse(deroulement.date_fin);
          dateFin = DateTime(dateFin.year, dateFin.month, dateFin.day);
          return ((dateDebut.isAfter(premierJourFiltre) ||
                  dateDebut == premierJourFiltre) &&
              (dateFin.isBefore(dernierJourFiltre) ||
                  dateFin == dernierJourFiltre));
        } else {
          // cas où la date de fin du deroulement est vide
          return (dateDebut.isAfter(premierJourFiltre) ||
              dateDebut == premierJourFiltre);
        }
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
        // on cherche à comparer seulement l'année, le mois et le jour
        dateDebut = DateTime(dateDebut.year, dateDebut.month, dateDebut.day);
        if (deroulement.date_fin != "") {
          DateTime dateFin = DateTime.parse(deroulement.date_fin);
          dateFin = DateTime(dateFin.year, dateFin.month, dateFin.day);
          return ((dateDebut.isAfter(premierJourFiltre) ||
                  dateDebut == premierJourFiltre) &&
              (dateFin.isBefore(dernierJourFiltre) ||
                  dateFin == dernierJourFiltre));
        } else {
          // cas où la date de fin du deroulement est vide
          return (dateDebut.isAfter(premierJourFiltre) ||
              dateDebut == premierJourFiltre);
        }
      }).toList();
      return deroulementsFiltre;
    } else {
      return [];
    }
  }

  // calcule le temps écoulé pour une tache donnée avec le filtre du moment
  String calculerTempsFiltre(Tache tache) {
    List<DeroulementTache> deroulementsFiltre = getDeroulementsByFilter();
    Duration tempsEcoule = Duration();
    for (int i = 0; i < deroulementsFiltre.length; i++) {
      if (deroulementsFiltre[i].id_tache == tache.id) {
        if (deroulementsFiltre[i].date_fin != "") {
          DateTime dateDebut = DateTime.parse(deroulementsFiltre[i].date_debut);
          DateTime dateFin = DateTime.parse(deroulementsFiltre[i].date_fin);
          tempsEcoule = tempsEcoule + dateFin.difference(dateDebut);
        }
      }
    }
    String tempsEcouleTxt = timerText(tempsEcoule.inSeconds);
    return tempsEcouleTxt;
  }

  void getTempsEcouleCategorie() async {
    Database database = await InitDatabase().database;
    var cat = await database.query(
      'categories',
      where: 'id = ?',
      whereArgs: [categorie.id],
    );

    setState(() {
      categorie.temps_ecoule = cat[0]['temps_ecoule'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: backgroundColor1,
        appBar: AppBar(
          title: Text(categorie.nom),
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
          leading: IconButton(
            color: Colors.white,
            onPressed: () {
              // appuie sur le bouton retour
              Navigator.of(context).pop(true);
            },
            icon: Icon(Icons.backspace),
          ),
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
                          DateTime now = DateTime.now().toUtc();
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
                            DateTime dateDernierJour = DateTime(now.year,
                                now.month - localTimeFilterCounter, 0);
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
                                      timeFilterPreference:
                                          timeFilterPreference,
                                      timeFilterCounter: localTimeFilterCounter,
                                      colorIndex: widget.colorIndex),
                                  childCurrent: this.widget,
                                  duration: Duration(milliseconds: 500)));
                          if (t != null) {
                            String text = '';
                            String date = '';
                            DateTime now = DateTime.now().toUtc();
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
                                DateTime datePremierJour = now
                                    .subtract(Duration(days: now.weekday - 1));
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
                              getTachesByFilter();
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
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            // Ajustement horizontal des éléments
            children: [
              IconButton(
                icon: Icon(
                  Icons.add_circle,
                  color: allColors[widget.colorIndex][1],
                  size: 36,
                ),
                onPressed: () {
                  // appuie sur le bouton +
                  Navigator.push(
                    context,
                    PageTransition(
                      type: PageTransitionType.bottomToTop,
                      child: AddTache(
                        onDataAdded: _addTacheItem,
                        colorIndex: widget.colorIndex,
                        categorie: categorie,
                      ),
                      childCurrent: this.widget,
                      duration: Duration(milliseconds: 500),
                    ),
                  );
                },
              ),
              IconButton(
                icon: SvgPicture.asset(
                  'assets/icons/pie_chart.svg',
                  color: allColors[widget.colorIndex][1],
                ),
                onPressed: () {
                  // appuie sur le bouton pie chart

                  // créer la data map qui associe à chaque catégorie son temps en secondes
                  Map<String, double> dataMap = {};
                  List<Color> colorList = [];
                  for (int i = 0; i < tachesFiltre.length; i++) {
                    List<String> parts =
                        tachesFiltre[i].temps_ecoule.split(':');
                    int hours = int.parse(parts[0]);
                    int minutes = int.parse(parts[1]);
                    int seconds = int.parse(parts[2]);
                    Duration duration = Duration(
                        hours: hours, minutes: minutes, seconds: seconds);
                    double tempsEcouleEnSec = duration.inSeconds.toDouble();
                    dataMap[tachesFiltre[i].nom] = tempsEcouleEnSec;
                    colorList.add(
                      Color(int.parse(tachesFiltre[i].couleur, radix: 16)),
                    );
                  }
                  // l'envoyer à PieChartPage pour l'afficher
                  Navigator.push(
                    context,
                    PageTransition(
                      type: PageTransitionType.bottomToTop,
                      child: PieChartPage(
                        dataMap: dataMap,
                        colorList: colorList,
                        colorIndex: widget.colorIndex,
                      ),
                      childCurrent: this.widget,
                      duration: Duration(milliseconds: 500),
                    ),
                  );
                },
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 15),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Total ",
                      overflow: TextOverflow.visible,
                      style: TextStyle(
                        fontSize: 19,
                        color: allColors[widget.colorIndex][1],
                      ),
                    ),
                    Text(
                      categorie.temps_ecoule,
                      overflow: TextOverflow.visible,
                      style: TextStyle(
                        fontSize: 19,
                        color: allColors[widget.colorIndex][1],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: SvgPicture.asset(
                  'assets/icons/mail.svg',
                  color: allColors[widget.colorIndex][1],
                ),
                onPressed: () {
                  // appuie sur le bouton export
                  _export(context);
                },
              ),
              IconButton(
                  icon: SvgPicture.asset(
                    'assets/icons/calendar.svg',
                    color: allColors[widget.colorIndex][1],
                  ),
                  onPressed: () async {
                    // appuie sur le bouton time filter

                    // appuie quand le filtre n'est pas visible
                    if (_isTimeFilterVisible == false) {
                      String text = '';
                      String date = '';
                      DateTime now = DateTime.now().toUtc();
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
                        _isTimeFilterVisible = true;
                        localTimeFilterCounter = 0;
                      });
                      await getTachesByFilter();
                    }
                    // appuie quand le filtre est visible
                    else {
                      await getTaches();
                      setState(() {
                        _isTimeFilterVisible = false;
                      });
                    }
                  }),
            ],
          ),
        ));
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
                  child: _mapTimer[tache] != null &&
                          _mapTimer[tache]['isActive'] == true
                      ? SvgPicture.asset('assets/icons/pause.svg')
                      : SvgPicture.asset('assets/icons/play_arrow.svg'),
                ),
              ),
            ),
          ),
          Container(
            height: 50,
            width: 150.3,
            alignment: Alignment.centerLeft,
            child: Text(
              tache.nom,
              style: TextStyle(fontSize: 20.0, color: Colors.black87),
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
                    timerText(_mapTimer[tache]['secValue']),
                    style: TextStyle(
                        fontSize: 20.0,
                        color: _mapTimer[tache]['isActive']
                            ? colorTime2
                            : Colors.black),
                  ),
                ),
                Container(
                  height: 30,
                  width: 30,
                  child: GestureDetector(
                    onTap: () async {
                      await Navigator.push(
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
                      await refreshData();
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
        child: SlidableAutoCloseBehavior(
          closeWhenOpened: true,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: tachesFiltre.length,
            itemBuilder: (context, index) {
              return Slidable(
                  endActionPane: ActionPane(
                    motion: BehindMotion(),
                    children: [
                      SlidableAction(
                        flex: 2,
                        onPressed: (context) {
                          //TODO EDIT
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => EditTask(
                                  tachesFiltre[index], categories, refreshData),
                            ),
                          );
                        },
                        backgroundColor: allColors[1][1],
                        foregroundColor: Colors.white,
                        icon: Icons.edit,
                        label: edit,
                      ),
                      SlidableAction(
                        flex: 2,
                        onPressed: (context) {
                          showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text('Supprimer ?'),
                                  content: Text(
                                      'Voulez-vous vraiment supprimer cette tâche: ${tachesFiltre[index].nom} ?'),
                                  actions: [
                                    TextButton(
                                      child: const Text('Annuler'),
                                      onPressed: () {
                                        // quand l'utilisateur annule la suppression
                                        Navigator.of(context)
                                            .pop(); //Dismiss Dialog
                                      },
                                    ),
                                    ElevatedButton(
                                      onPressed: () async {
                                        // quand l'utilisateur confirme la suppression
                                        await DeleteTache(
                                            tachesFiltre[index].id);
                                        Navigator.of(context).pop();
                                        await refreshData();
                                      },
                                      child: const Text('Supprimer'),
                                    ),
                                  ],
                                );
                              });
                        },
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        icon: Icons.delete,
                        label: delete,
                      ),
                    ],
                  ),
                  child: buildRowTache(tachesFiltre[index]));
            },
          ),
        ),
      ),
    );
  }

  _export(BuildContext context) async {
    ExportService service = ExportService();
    await service.promptEmail(context);
  }
}
