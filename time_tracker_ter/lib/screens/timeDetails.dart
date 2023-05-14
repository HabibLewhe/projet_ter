import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import '../model/DeroulementTache.dart';
import '../model/InitDatabase.dart';
import '../utilities/constants.dart';

class TimeDetailsPage extends StatefulWidget {
  final Function() onDataAdded;
  final String title;
  final DateTime start;
  final DateTime end;
  final Duration duration;
  final double latitude;
  final double longitude;
  final DeroulementTache deroulementTache;

  const TimeDetailsPage(
      {this.deroulementTache,
      this.title,
      this.start,
      this.end,
      this.duration,
      this.latitude,
      this.longitude,
      this.onDataAdded});

  @override
  State<TimeDetailsPage> createState() => _TimeDetailsPageState();
}

class _TimeDetailsPageState extends State<TimeDetailsPage> {
  static const Color _mainColor = Color.fromRGBO(0, 93, 164, 1);
  static const Color _sndColor = Color.fromRGBO(0, 93, 164, .25);

  bool clickStart = false;
  bool clickEnd = false;
  bool clickDuration = false;
  bool clickLongitude = false;
  bool clickLatitude = false;
  bool startDateChanged = false;
  bool endDateChanged = false;
  bool durationChanged = false;
  bool fromTimerPicker = false;

  DateTime newStartDate;
  DateTime newEndDate;
  Duration newDuration;
  double newLatitude = 47.8430441;
  double newLongitude = 1.9365067;

  void updateCreneau() async {
    Database database = await InitDatabase().database;
    final DateFormat formatter = DateFormat('yyyy-MM-ddTHH:mm:ss');

    print("widget.deroulementTache : ${widget.deroulementTache}");
    //mettre à jour un créneau
    await database.update(
        'deroulement_tache',
        {
          'id_tache': widget.deroulementTache.id_tache,
          'date_debut': newStartDate == null
              ? formatter.format(widget.start.toUtc())+'Z'
              : formatter.format(newStartDate.toUtc())+'Z',
          'date_fin': newEndDate == null
              ? formatter.format(widget.end.toUtc())+'Z'
              : formatter.format(newEndDate.toUtc())+'Z',
          'latitude': newLatitude == null ? widget.latitude : newLatitude,
          'longitude': newLongitude == null ? widget.duration : newLongitude
        },
        where: 'id = ?',
        whereArgs: [widget.deroulementTache.id]);

    //afficher un message de succès
    showSuccessMessage("Créneau mis à jour");
    //notifier le widget parent que les données ont été mise à jour
    widget.onDataAdded();
    //go back to history page
    Navigator.of(context).pop();
  }

  Duration showDuration(var datedebut, var datefin) {
    Duration intervalDuration = const Duration();

    if (datefin != null) {
      intervalDuration = datefin.difference(datedebut);
    }
    return intervalDuration;
  }

  DateTime updateEndDateTime(DateTime datedebut, Duration duree) {
    DateTime datefin = DateTime.now().toUtc();
    datefin = datedebut.add(duree);
    return datefin;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(233, 233, 233, 1),
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
        actions: [
          IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                setState(() {
                  updateCreneau();
                });
              })
        ],
      ),
      body: Padding(
          padding: const EdgeInsets.all(50.0),
          child: ListView(
            children: <Widget>[
              Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10.0),
                    topRight: Radius.circular(10.0),
                  ),
                  color: (clickStart == true) ? Colors.blue : Colors.white,
                ),
                child: ListTile(
                  title: Text(
                    start,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: (clickStart == true) ? Colors.white : Colors.black,
                    ),
                  ),
                  trailing: Text(
                    (startDateChanged == true)
                        ? "${DateFormat('yMMMEd').format(newStartDate)} "
                            "${DateFormat('Hm').format(newStartDate)}"
                        : "${DateFormat('yMMMEd').format(widget.start)} "
                            "${DateFormat('Hm').format(widget.start)}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color:
                          (clickStart == true) ? Colors.white : Colors.black38,
                    ),
                    textAlign: TextAlign.end,
                  ),
                  onTap: () {
                    setState(() {
                      clickEnd = false;
                      clickDuration = false;
                      clickLongitude = false;
                      clickLatitude = false;
                      clickStart = true;
                      showCupertinoModalPopup(
                          context: context,
                          builder: (BuildContext context) => SizedBox(
                                height: 250,
                                child: CupertinoDatePicker(
                                  backgroundColor: Colors.white,
                                  maximumDate: endDateChanged == true
                                      ? newEndDate
                                      : widget.end,
                                  initialDateTime: startDateChanged == true
                                      ? newStartDate
                                      : widget.start,
                                  onDateTimeChanged: (DateTime newTime) {
                                    setState(() {
                                      startDateChanged = true;
                                      durationChanged = true;
                                      newStartDate = newTime;
                                    });
                                  },
                                ),
                              ));
                    });
                  },
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: const BorderDirectional(
                    top: BorderSide(color: Colors.black12, width: 1.0),
                    bottom: BorderSide(color: Colors.black12, width: 1.0),
                  ),
                  color: (clickEnd == true) ? Colors.blue : Colors.white,
                ),
                child: ListTile(
                  title: Text(
                    end,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color:
                            (clickEnd == true) ? Colors.white : Colors.black),
                  ),
                  trailing: Text(
                      (endDateChanged == true)
                          ? DateFormat('Hm').format(newEndDate)
                          : (fromTimerPicker == true)
                              ? (newStartDate == null)
                                  ? DateFormat('Hm').format(updateEndDateTime(
                                      widget.start, newDuration))
                                  : DateFormat('Hm').format(updateEndDateTime(
                                      newStartDate, newDuration))
                              : DateFormat('Hm').format(widget.end),
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color:
                              (clickEnd == true) ? Colors.white : Colors.grey)),
                  onTap: () {
                    setState(() {
                      clickStart = false;
                      clickDuration = false;
                      clickLongitude = false;
                      clickLatitude = false;
                      clickEnd = true;
                      showCupertinoModalPopup(
                          context: context,
                          builder: (BuildContext context) => SizedBox(
                                height: 250,
                                child: CupertinoDatePicker(
                                  backgroundColor: Colors.white,
                                  minimumDate: startDateChanged == true
                                      ? newStartDate
                                      : widget.start,
                                  initialDateTime: endDateChanged == true
                                      ? newEndDate
                                      : widget.end,
                                  onDateTimeChanged: (DateTime newTime) {
                                    setState(() {
                                      endDateChanged = true;
                                      durationChanged = true;
                                      newEndDate = newTime;
                                    });
                                  },
                                ),
                              ));
                    });
                  },
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: (clickDuration == true) ? Colors.blue : Colors.white,
                ),
                child: ListTile(
                  title: Text(
                    duration,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: (clickDuration == true)
                            ? Colors.white
                            : Colors.black),
                  ),
                  trailing: Text(
                      (durationChanged == true)
                          ? (fromTimerPicker == true)
                              ? "${newDuration.inHours}:"
                                  "${(newDuration.inMinutes % 60).toString().padLeft(2, '0')}:"
                                  "${(newDuration.inSeconds % 60).toString().padLeft(2, '0')}"
                              : newStartDate == null
                                  ? "${showDuration(widget.start, newEndDate).inHours}:"
                                      "${(showDuration(widget.start, newEndDate).inMinutes % 60).toString().padLeft(2, '0')}:"
                                      "${(showDuration(widget.start, newEndDate).inSeconds % 60).toString().padLeft(2, '0')}"
                                  : newEndDate == null
                                      ? "${showDuration(newStartDate, widget.end).inHours}:"
                                          "${(showDuration(newStartDate, widget.end).inMinutes % 60).toString().padLeft(2, '0')}:"
                                          "${(showDuration(newStartDate, widget.end).inSeconds % 60).toString().padLeft(2, '0')}"
                                      : "${showDuration(newStartDate, newEndDate).inHours}:"
                                          "${(showDuration(newStartDate, newEndDate).inMinutes % 60).toString().padLeft(2, '0')}:"
                                          "${(showDuration(newStartDate, newEndDate).inSeconds % 60).toString().padLeft(2, '0')}"
                          : "${widget.duration.inHours}:"
                              "${(widget.duration.inMinutes % 60).toString().padLeft(2, '0')}:"
                              "${(widget.duration.inSeconds % 60).toString().padLeft(2, '0')}",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: (clickDuration == true)
                              ? Colors.white
                              : Colors.grey)),
                  onTap: () {
                    setState(() {
                      clickStart = false;
                      clickEnd = false;
                      clickLongitude = false;
                      clickLatitude = false;
                      clickDuration = true;
                      showCupertinoModalPopup(
                          context: context,
                          builder: (BuildContext context) => SizedBox(
                              height: 250,
                              child: CupertinoTimerPicker(
                                  backgroundColor: Colors.white,
                                  initialTimerDuration: newDuration == null
                                      ? widget.duration
                                      : newDuration,
                                  mode: CupertinoTimerPickerMode.hms,
                                  onTimerDurationChanged: (Duration duration) {
                                    setState(() {
                                      fromTimerPicker = true;
                                      durationChanged = true;
                                      newDuration = duration;
                                    });
                                  })));
                    });
                  },
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: const BorderDirectional(
                    top: BorderSide(color: Colors.black12, width: 1.0),
                    bottom: BorderSide(color: Colors.black12, width: 1.0),
                  ),
                  color: (clickLongitude == true) ? Colors.blue : Colors.white,
                ),
                child: ListTile(
                  title: Text(
                    longitude,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: (clickLongitude == true)
                            ? Colors.white
                            : Colors.black),
                  ),
                  trailing: Text("${(widget.longitude)}",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: (clickLongitude == true)
                              ? Colors.white
                              : Colors.grey)),
                  onTap: () {
                    setState(() {
                      clickStart = false;
                      clickEnd = false;
                      clickDuration = false;
                      clickLatitude = false;
                      clickLongitude = true;
                    });
                  },
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(10.0),
                    bottomRight: Radius.circular(10.0),
                  ),
                  color: (clickLatitude == true) ? Colors.blue : Colors.white,
                ),
                child: ListTile(
                  title: Text(
                    latitude,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: (clickLatitude == true)
                            ? Colors.white
                            : Colors.black),
                  ),
                  trailing: Text("${(widget.latitude)}",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: (clickLatitude == true)
                              ? Colors.white
                              : Colors.grey)),
                  onTap: () {
                    setState(() {
                      clickStart = false;
                      clickEnd = false;
                      clickDuration = false;
                      clickLongitude = false;
                      clickLatitude = true;
                    });
                  },
                ),
              ),
            ],
          )),
    );
  }
}
