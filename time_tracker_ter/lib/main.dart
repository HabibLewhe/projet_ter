import 'package:flutter/material.dart';
import 'package:time_tracker_ter/timeDetails.dart';
import 'deroulementTache.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MyHomePage(title: 'History Page'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late List _elements;

  static const Color _mainColor = Color.fromRGBO(0, 93, 164, 1);
  static const Color _sndColor = Color.fromRGBO(0, 93, 164, .25);
  static const Color _trdColor = Color.fromRGBO(150, 178, 200, 0.75);

  late int hours;
  late int minutes;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _elements = [
      {
        'date_debut': DateTime(2009, 8, 30, 19, 54),
        'date_fin': null,
        'latitude': 0.0,
        'longitude': 0.0
      },
      {
        'date_debut': DateTime(2009, 8, 30, 16, 19),
        'date_fin': DateTime(2009, 8, 30, 18, 51),
        'latitude': 0.0,
        'longitude': 0.0
      },
      {
        'date_debut': DateTime(2009, 8, 30, 08, 05),
        'date_fin': DateTime(2009, 8, 30, 11, 44),
        'latitude': 0.0,
        'longitude': 0.0
      },
      {
        'date_debut': DateTime(2009, 8, 27, 14, 13),
        'date_fin': DateTime(2009, 8, 27, 19, 05),
        'latitude': 0.0,
        'longitude': 0.0
      },
      {
        'date_debut': DateTime(2009, 8, 27, 09, 04),
        'date_fin': DateTime(2009, 8, 27, 11, 29),
        'latitude': 0.0,
        'longitude': 0.0
      },
      {
        'date_debut': DateTime(2009, 8, 26, 08, 08),
        'date_fin': DateTime(2009, 8, 26, 16, 18),
        'latitude': 0.0,
        'longitude': 0.0
      },
    ];
  }

  String shwoTimeInterval(var datedebut, var datefin) {
    Duration intervalDuration = const Duration();
    String strResult = "";

    if (datefin != null) {
      intervalDuration = datefin.difference(datedebut);
    }
    strResult +=
    "${intervalDuration.inHours}:${(intervalDuration.inMinutes % 60).toString().padLeft(2, '0')}:${(intervalDuration.inSeconds % 60).toString().padLeft(2, '0')}";
    return strResult;
  }

  Duration sumDuration(String group) {
    String date = "";
    int totalMicroseconds = 0;
    late Duration duration;

    for (final elt in _elements) {
      date = DateFormat('yMd').format(elt['date_debut']);
      if (date == group && elt['date_fin'] != null) {
        duration = elt['date_fin'].difference(elt['date_debut']);
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
      body: GroupedListView<dynamic, String>(
        elements: _elements,
        groupBy: (element) =>
            DateFormat('yMd').format(element['date_debut']),
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
        itemBuilder: (context, dynamic element) => Card(
          elevation: 2,
          child: ListTile(
            contentPadding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
            title: Text(
              dateFinChecker(element['date_fin'])
              //Hm
              //'kk:mm'
                  ? "${DateFormat('Hm').format(element['date_debut'])} - Now"
                  : "${DateFormat('Hm').format(element['date_debut'])} - "
                  "${DateFormat('Hm').format(element['date_fin'])}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: Text(
              shwoTimeInterval(element['date_debut'], element['date_fin']),
              style: const TextStyle(
                  color: Colors.grey, fontWeight: FontWeight.bold),
            ),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => TimeDetailsPage(
                        title: widget.title,
                        start: "${DateFormat('yMMMEd').format(element['date_debut'])} "
                            "${DateFormat('Hm').format(element['date_debut'])}",
                        end: DateFormat('Hm').format(element['date_fin']),
                        duration: shwoTimeInterval(element['date_debut'], element['date_fin']),
                      )
                  )
              );
            },
          ),
        ),
        itemComparator: (item1, item2) =>
            (item1['date_debut']).compareTo(item2['date_debut']),
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
