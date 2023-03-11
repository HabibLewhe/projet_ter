import 'package:flutter/material.dart';

class TimeDetailsPage extends StatefulWidget {
  final String title;
  final String start;
  final String end;
  final String duration;

  const TimeDetailsPage({
    super.key,
    required this.title,
    required this.start,
    required this.end,
    required this.duration,
  });

  @override
  State<TimeDetailsPage> createState() => _TimeDetailsPageState();
}

class _TimeDetailsPageState extends State<TimeDetailsPage> {

  static const Color _mainColor = Color.fromRGBO(0, 93, 164, 1);
  static const Color _sndColor = Color.fromRGBO(0, 93, 164, .25);
  static const Color _trdColor = Color.fromRGBO(150, 178, 200, 0.75);

  void _showDatePicker(){}

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
      ),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            InkWell(
              onTap: () {_showDatePicker;},
              child: Container(
                padding: const EdgeInsets.all(13.0),
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10.0),
                    topRight: Radius.circular(10.0),
                  ),
                    color: Colors.white,
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "Start",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.start,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        widget.start,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.black38),
                        textAlign: TextAlign.end,
                      ),
                    )
                  ],
                ),
              ),
            ),
            InkWell(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.all(13.0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: BorderDirectional(
                    top: BorderSide(color: Colors.black12, width: 1.0),
                    bottom: BorderSide(color: Colors.black12, width: 1.0),
                  )
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "End",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.start,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        widget.end,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey
                        ),
                        textAlign: TextAlign.end,
                      ),
                    )
                  ],
                ),
              ),
            ),
            InkWell(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.all(13.0),
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(10.0),
                    bottomRight: Radius.circular(10.0),
                  ),
                    color: Colors.white,
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "Duration",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.start,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        widget.duration,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey
                        ),
                        textAlign: TextAlign.end,
                      ),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
