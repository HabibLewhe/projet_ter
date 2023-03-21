import 'package:flutter/material.dart';
import 'package:flutter_login_ui/model/DeroulementTache.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import '../model/InitDatabase.dart';
import 'timeDetails.dart';

class HistoryPage extends StatefulWidget {
  final String title;
  final int id;

  const HistoryPage({this.title, this.id});

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

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getTaches();
  }

  void getTaches() async {
    Database database = await InitDatabase().database;
    var t = await database.query('deroulement_tache',
        where: 'id_tache = ?',
        whereArgs: [widget.id]);

    setState(() {
      deroulement_taches = t.map((e) => DeroulementTache.fromMap(e)).toList();
      for(var elt in deroulement_taches){
        print(elt.id);
      }
    });
  }

  Duration showDuration(var datedebut, var datefin) {
    Duration intervalDuration = const Duration();

    if (datefin != null) {
      intervalDuration = DateTime.parse(datefin).difference(DateTime.parse(datedebut));
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
        duration = (DateTime.parse(elt.date_fin)).difference(DateTime.parse(elt.date_debut));
        totalMicroseconds += duration.inMicroseconds;
      }
    }
    return Duration(microseconds: totalMicroseconds);
  }

  bool dateFinChecker(var date) {
    return (date == null);
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
        groupBy: (element) => DateFormat('yMd').format(DateTime.parse(element.date_debut)),
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
            endActionPane: const ActionPane(
              motion: ScrollMotion(),
              children: [
                SlidableAction(
                  // An action can be bigger than the others.
                  flex: 2,
                  onPressed: null,
                  backgroundColor: Color(0xFF7BC043),
                  foregroundColor: Colors.white,
                  icon: Icons.archive,
                  label: 'Supprimer',
                ),
              ],
            ),
            child: Card(
              elevation: 2,
              child: ListTile(
                contentPadding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                title: Text(
                  dateFinChecker(element.date_fin)
                      ? "${DateFormat('Hm').format(DateTime.parse(element.date_debut))} - Now"
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
                      MaterialPageRoute(
                          builder: (context) => TimeDetailsPage(
                            title: widget.title,
                            start: DateTime.parse(element.date_debut),
                            end: DateTime.parse(element.date_fin),
                            //DateFormat('Hm').format(element['date_fin']),
                            duration: showDuration(
                                element.date_debut, element.date_fin),
                          )));
                },
              ),
            ),
          );
        },
        itemComparator: (item1, item2) =>
            (DateTime.parse(item1.date_fin)).compareTo(DateTime.parse(item2.date_debut)),
        // optional
        useStickyGroupSeparators: true,
        // optional
        floatingHeader: true,
        // optional
        order: GroupedListOrder.DESC, // optional
      ),
    );
  }
}
