import 'package:flutter/material.dart';
import 'package:flutter_login_ui/model/DeroulementTache.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/svg.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:intl/intl.dart';
import 'package:page_transition/page_transition.dart';
import 'package:sqflite/sqflite.dart';
import '../model/InitDatabase.dart';
import '../utilities/constants.dart';
import 'AddCreneau.dart';
import 'timeDetails.dart';

class HistoryPage extends StatefulWidget {
  final String title;
  final int id;
  final int colorIndex;

  const HistoryPage({this.title, this.id, this.colorIndex});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<DeroulementTache> deroulement_taches = [];

  static const Color _mainColor = Color.fromRGBO(0, 93, 164, 1);
  static const Color _sndColor = Color.fromRGBO(0, 93, 164, .25);
  static const Color _trdColor = Color.fromRGBO(150, 178, 200, 0.75);

  int hours;
  int minutes;
  String tempsEcouleTotal = "00:00:00";
  bool _isTimeFilterVisible = false;
  int timeFilterPreference;
  String timeFilterText = '';
  String timeFilterDate = '';
  int localTimeFilterCounter;
  DateTime currentStartingDate;
  DateTime currentEndingDate;
  double currentLatitude;
  double currentLongitude;

  @override
  void initState() {
    super.initState();
    getCreneau();
    currentStartingDate = DateTime.now();
    currentEndingDate = currentStartingDate.add(const Duration(hours: 6));
    currentLatitude = 47.8430441;
    currentLongitude = 1.9365067;
  }

  void getCreneau() async {
    Database database = await InitDatabase().database;
    var t = await database.query('deroulement_tache',
        where: 'id_tache = ?', whereArgs: [widget.id]);

    setState(() {
      deroulement_taches = t.map((e) => DeroulementTache.fromMap(e)).toList();
    });

    Duration duration = Duration();
    String tempsEcoule = "00:00:00";
    for (int i = 0; i < deroulement_taches.length; i++) {
      duration += (DateTime.parse(deroulement_taches[i].date_fin))
          .difference(DateTime.parse(deroulement_taches[i].date_debut));
    }

    tempsEcoule =
        "${duration.inHours}:${duration.inMinutes.remainder(60).toString().padLeft(2, '0')}:"
        "${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}";

    setState(() {
      tempsEcouleTotal = tempsEcoule;
    });
  }

  Future showConfirmDialog(BuildContext context, int idCreneau) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(confirmerSuppression),
          content: Text(supprimerCreneau),
          actions: <Widget>[
            TextButton(
              child: Text(annuler),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(supprimer),
              onPressed: () {
                deleteCreneau(idCreneau);
              },
            ),
          ],
        );
      },
    );
  }

  Future showConfirmDialogdeleteAll(BuildContext context) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(confirmerSuppression),
          content: Text(viderHistorique),
          actions: <Widget>[
            TextButton(
              child: Text(annuler),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(supprimer),
              onPressed: () {
                deleteAllCreneau();
              },
            ),
          ],
        );
      },
    );
  }

  void deleteCreneau(int idCreneau) async {
    Database database = await InitDatabase().database;
    //supprimer un créneau
    await database
        .delete('deroulement_tache', where: 'id = ?', whereArgs: [idCreneau]);

    //afficher un message de succès
    showSuccessMessage("Créneau supprimé");
    //notifier le widget parent que les données ont été mise à jour
    _addCreneauItem();

    Navigator.of(context).pop();
  }

  void deleteAllCreneau() async {
    Database database = await InitDatabase().database;
    //supprimer un créneau
    await database.delete('deroulement_tache',
        where: 'id_tache = ?', whereArgs: [widget.id]);

    //afficher un message de succès
    showSuccessMessage("Historique vidé");
    //notifier le widget parent que les données ont été mise à jour
    _addCreneauItem();

    Navigator.of(context).pop();
  }

  Duration showDuration(var datedebut, var datefin) {
    Duration intervalDuration = const Duration();

    if (datefin != null) {
      intervalDuration =
          DateTime.parse(datefin).difference(DateTime.parse(datedebut));
    }

    return intervalDuration;
  }

  Duration sumDuration(String group) {
    String date = "";
    int totalMicroseconds = 0;
    Duration duration;

    for (final elt in deroulement_taches) {
      date = DateFormat('yMd').format(DateTime.parse(elt.date_debut));
      if (date == group && elt.date_fin != null) {
        duration = (DateTime.parse(elt.date_fin))
            .difference(DateTime.parse(elt.date_debut));
        totalMicroseconds += duration.inMicroseconds;
      }
    }
    return Duration(microseconds: totalMicroseconds);
  }

  bool dateFinChecker(var date) {
    return (date == null);
  }

  void _addCreneauItem() {
    //supprimer tous les créneaux
    deroulement_taches.clear();
    //ajouter les créneaux
    getCreneau();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          centerTitle: true,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_mainColor, _sndColor]),
            ),
          ),
        ),
        body: GroupedListView<DeroulementTache, String>(
          elements: deroulement_taches,
          groupBy: (element) =>
              DateFormat('yMd').format(DateTime.parse(element.date_debut)),
          groupSeparatorBuilder: (String groupByValue) => Container(
            width: double.infinity,
            padding: const EdgeInsets.all(7),
            color: _trdColor,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    groupByValue,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.start,
                  ),
                ),
                Expanded(
                  child: Text(
                    "${(sumDuration(groupByValue).inHours).toString()}:"
                    "${(sumDuration(groupByValue).inMinutes % 60).toString().padLeft(2, '0')}:"
                    "${(sumDuration(groupByValue).inSeconds % 60).toString().padLeft(2, '0')}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
          itemBuilder: (context, DeroulementTache element) {
            return Slidable(
              endActionPane: ActionPane(
                motion: ScrollMotion(),
                children: [
                  SlidableAction(
                    // An action can be bigger than the others.
                    flex: 2,
                    onPressed: (context) {
                      showConfirmDialog(context, element.id);
                    },
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    icon: Icons.archive,
                    label: delete,
                  ),
                ],
              ),
              child: Card(
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                  title: Text(
                    dateFinChecker(element.date_fin)
                        ? "${DateFormat('Hm').format(DateTime.parse(element.date_debut))} - ${now}"
                        : "${DateFormat('Hm').format(DateTime.parse(element.date_debut))} - "
                            "${DateFormat('Hm').format(DateTime.parse(element.date_fin))}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: Text(
                    "${showDuration(element.date_debut, element.date_fin).inHours}:"
                    "${(showDuration(element.date_debut, element.date_fin).inMinutes % 60).toString().padLeft(2, '0')}:"
                    "${(showDuration(element.date_debut, element.date_fin).inSeconds % 60).toString().padLeft(2, '0')}",
                    style: const TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      PageTransition(
                          type: PageTransitionType.bottomToTop,
                          child: TimeDetailsPage(
                            onDataAdded: _addCreneauItem,
                            deroulementTache: element,
                            title: widget.title,
                            start: DateTime.parse(element.date_debut),
                            end: DateTime.parse(element.date_fin),
                            duration: showDuration(
                                element.date_debut, element.date_fin),
                            latitude: element.latitude,
                            longitude: element.longitude,
                          ),
                          childCurrent: this.widget,
                          duration: Duration(milliseconds: 300)),
                    );
                  },
                ),
              ),
            );
          },
          itemComparator: (item1, item2) {
            return (DateTime.parse(item1.date_fin))
                .compareTo(DateTime.parse(item2.date_debut));
          },
          // optional
          useStickyGroupSeparators: true,
          // optional
          floatingHeader: true,
          // optional
          order: GroupedListOrder.DESC, // optional
        ),
        bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            onTap: (value) {
              // cas où appuie sur le bouton +
              if (value == 0) {
                // afficher la page pour ajouter un créneau
                Navigator.push(
                    context,
                    PageTransition(
                        type: PageTransitionType.bottomToTop,
                        child: AddCreneauPage(
                          onDataAdded: _addCreneauItem,
                          id_tache: widget.id,
                          title: widget.title,
                          start: currentStartingDate,
                          end: currentEndingDate,
                          duration:
                              currentEndingDate.difference(currentStartingDate),
                          longitude: currentLongitude,
                          latitude: currentLatitude,
                        ),
                        childCurrent: this.widget,
                        duration: Duration(milliseconds: 300)));
              }
              // cas où appuie sur le bouton balai
              else if (value == 1) {
                // TODO : traitement appuie bouton balai
                showConfirmDialogdeleteAll(context);
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
                  text = today;
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
                  text = thisWeek;
                }
                // mois
                else if (timeFilterPreference == 2) {
                  DateTime datePremierJour = DateTime(now.year, now.month, 1);
                  DateTime dateDernierJour =
                      DateTime(now.year, now.month + 1, 0);
                  date = formatter.format(datePremierJour) +
                      " - " +
                      formatter.format(dateDernierJour);
                  text = thisMonth;
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
                      total,
                      overflow: TextOverflow.visible,
                      style: TextStyle(
                          fontSize: 19, color: allColors[widget.colorIndex][1]),
                    ),
                    Text(
                      tempsEcouleTotal,
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
                  'assets/icons/calendar.svg',
                  color: allColors[widget.colorIndex][1],
                ),
                label: '',
              ),
            ],
            iconSize: 40,
            elevation: 5));
  }
}
