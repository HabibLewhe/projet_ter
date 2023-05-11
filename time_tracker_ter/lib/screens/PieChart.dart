import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';

import '../utilities/constants.dart';

class PieChartPage extends StatefulWidget {
  final Map<String,double> dataMap;
  final List<Color> colorList;
  final int colorIndex;

  PieChartPage({this.dataMap, this.colorList, this.colorIndex});

  @override
  PieChartPage_ createState() => PieChartPage_ ();
}

class PieChartPage_ extends State<PieChartPage> {
  @override
  void initState() {
    super.initState();
  }

  String calculerTempsTotal(){
    double totalSecondes = 0;
    for(var entry in widget.dataMap.entries){
      totalSecondes += entry.value;
    }
    int totalSecondesInt = totalSecondes.toInt();
    int heures = totalSecondesInt ~/ 3600;
    int minutes = (totalSecondesInt % 3600) ~/ 60;
    int secondes = totalSecondesInt % 60;

    String heureStr = heures.toString().padLeft(2, '0');
    String minuteStr = minutes.toString().padLeft(2, '0');
    String secondeStr = secondes.toString().padLeft(2, '0');

    return '$heureStr:$minuteStr:$secondeStr';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor1,
      appBar: AppBar(
        title: Text("Pie Chart"),
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
      ),
      body: Container(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Text("Temps total : "+calculerTempsTotal(), style: TextStyle(fontSize: 20.0, color: Colors.black87)),
                ],
              ),
              SizedBox(height: 10,),
              PieChart(
                chartValuesOptions: ChartValuesOptions(
                  showChartValuesInPercentage: true,
                ),
                dataMap: widget.dataMap,
                chartType: ChartType.disc,
                baseChartColor: Colors.grey[300],
                colorList: widget.colorList,
              ),
            ],
          )
      ),
    );
  }
}
