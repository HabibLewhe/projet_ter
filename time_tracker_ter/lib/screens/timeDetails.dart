import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TimeDetailsPage extends StatefulWidget {
  final String title;
  final DateTime start;
  final DateTime end;
  final Duration duration;

  TimeDetailsPage({
    this.title,
    this.start,
    this.end,
    this.duration,
  });

  @override
  State<TimeDetailsPage> createState() => _TimeDetailsPageState();
}

class _TimeDetailsPageState extends State<TimeDetailsPage> {
  static const Color _mainColor = Color.fromRGBO(0, 93, 164, 1);
  static const Color _sndColor = Color.fromRGBO(0, 93, 164, .25);
  static const Color _trdColor = Color.fromRGBO(150, 178, 200, 0.75);

  bool clickStart = false;
  bool clickEnd = false;
  bool clickDuration = false;
  bool startDateChanged = false;
  bool endDateChanged = false;
  bool durationChanged = false;

  DateTime newStartDate;
  DateTime newEndDate;
  Duration newDuration;

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
        actions: [IconButton(icon: const Icon(Icons.save), onPressed: () {})],
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
                    "Start",
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
                      clickStart = true;
                      showCupertinoModalPopup(
                          context: context,
                          builder: (BuildContext context) => SizedBox(
                                height: 250,
                                child: CupertinoDatePicker(
                                  backgroundColor: Colors.white,
                                  initialDateTime: widget.start,
                                  onDateTimeChanged: (DateTime newTime) {
                                    setState(() {
                                      startDateChanged = true;
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
                    "End",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color:
                            (clickEnd == true) ? Colors.white : Colors.black),
                  ),
                  trailing: Text(
                      (endDateChanged == true)
                          ? DateFormat('Hm').format(newEndDate)
                          : DateFormat('Hm').format(widget.end),
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color:
                              (clickEnd == true) ? Colors.white : Colors.grey)),
                  onTap: () {
                    setState(() {
                      clickStart = false;
                      clickDuration = false;
                      clickEnd = true;
                      showCupertinoModalPopup(
                          context: context,
                          builder: (BuildContext context) => SizedBox(
                                height: 250,
                                child: CupertinoDatePicker(
                                  backgroundColor: Colors.white,
                                  initialDateTime: widget.end,
                                  onDateTimeChanged: (DateTime newTime) {
                                    setState(() {
                                      endDateChanged = true;
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
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(10.0),
                    bottomRight: Radius.circular(10.0),
                  ),
                  color: (clickDuration == true) ? Colors.blue : Colors.white,
                ),
                child: ListTile(
                  title: Text(
                    "Duration",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: (clickDuration == true)
                            ? Colors.white
                            : Colors.black),
                  ),
                  trailing: Text(
                      (durationChanged == true)
                          ? "${newDuration.inHours}:"
                              "${(newDuration.inMinutes % 60).toString().padLeft(2, '0')}:"
                              "${(newDuration.inSeconds % 60).toString().padLeft(2, '0')}"
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
                      clickDuration = true;
                      showCupertinoModalPopup(
                          context: context,
                          builder: (BuildContext context) => SizedBox(
                              height: 250,
                              child: CupertinoTimerPicker(
                                  backgroundColor: Colors.white,
                                  initialTimerDuration: widget.duration,
                                  mode: CupertinoTimerPickerMode.hms,
                                  onTimerDurationChanged: (Duration duration) =>
                                      setState(() {
                                        durationChanged = true;
                                        newDuration = duration;
                                      }))));
                    });
                  },
                ),
              ),
            ],
          )),
    );
  }
}
