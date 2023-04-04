import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../model/InitDatabase.dart';
import '../utilities/constants.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SettingsTimeFilter extends StatefulWidget {
  final int timeFilterPreference;
  final int timeFilterCounter;
  final int colorIndex;

  SettingsTimeFilter(
      {this.timeFilterPreference, this.timeFilterCounter, this.colorIndex});

  @override
  State<StatefulWidget> createState() => _SettingsTimeFilter();
}

class _SettingsTimeFilter extends State<SettingsTimeFilter> {
  void updateTimeFilterPreference(int preference) async {
    Database database = await InitDatabase().database;
    await database.update('parametres', {'time_filter_preference': preference});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor1,
      appBar: AppBar(
        title: Text("Settings"),
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
            Navigator.of(context).pop();
          },
          icon: Icon(Icons.backspace),
        )),
      ),
      body: Column(
        children: [
          Container(
            height: 140,
            width: double.infinity,
            alignment: Alignment.center,
            margin: const EdgeInsets.only(bottom: 20.0, top: 20.0),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor, width: 2),
                color: backgroundColor2,
              ),
              margin: const EdgeInsets.only(left: 20.0, right: 20.0),
              padding: const EdgeInsets.only(top: 10.0),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      // appuie sur "Today"
                      if (widget.timeFilterPreference != 0) {
                        updateTimeFilterPreference(0);
                      }
                      Navigator.pop(context, 0);
                    },
                    child: buildRow(
                        SvgPicture.asset('assets/icons/calendar_today.svg'),
                        "Today",
                        widget.timeFilterCounter == 0 &&
                            widget.timeFilterPreference == 0),
                  ),
                  Divider(
                    color: borderColor,
                    thickness: 2,
                  ),
                  GestureDetector(
                    onTap: () {
                      // appuie sur "Yesterday"
                      if (widget.timeFilterPreference != 0) {
                        updateTimeFilterPreference(0);
                      }
                      Navigator.pop(context, 1);
                    },
                    child: buildRow(
                        SvgPicture.asset('assets/icons/calendar_yesterday.svg'),
                        "Yesterday",
                        widget.timeFilterCounter == 1 &&
                            widget.timeFilterPreference == 0),
                  ),
                ],
              ),
            ),
          ),
          Container(
            height: 140,
            width: double.infinity,
            alignment: Alignment.center,
            margin: const EdgeInsets.only(bottom: 20.0, top: 20.0),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor, width: 2),
                color: backgroundColor2,
              ),
              margin: const EdgeInsets.only(left: 20.0, right: 20.0),
              padding: const EdgeInsets.only(top: 10.0),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      // appuie sur "This Week"
                      if (widget.timeFilterPreference != 1) {
                        updateTimeFilterPreference(1);
                      }
                      Navigator.pop(context, 0);
                    },
                    child: buildRow(
                        SvgPicture.asset('assets/icons/calendar_this_week.svg'),
                        "This Week",
                        widget.timeFilterCounter == 0 &&
                            widget.timeFilterPreference == 1),
                  ),
                  Divider(
                    color: borderColor,
                    thickness: 2,
                  ),
                  GestureDetector(
                    onTap: () {
                      // appuie sur "Last Week"
                      if (widget.timeFilterPreference != 1) {
                        updateTimeFilterPreference(1);
                      }
                      Navigator.pop(context, 1);
                    },
                    child: buildRow(
                        SvgPicture.asset('assets/icons/calendar_last_week.svg'),
                        "Last Week",
                        widget.timeFilterCounter == 1 &&
                            widget.timeFilterPreference == 1),
                  ),
                ],
              ),
            ),
          ),
          Container(
            height: 140,
            width: double.infinity,
            alignment: Alignment.center,
            margin: const EdgeInsets.only(bottom: 20.0, top: 20.0),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor, width: 2),
                color: backgroundColor2,
              ),
              margin: const EdgeInsets.only(left: 20.0, right: 20.0),
              padding: const EdgeInsets.only(top: 10.0),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      // appuie sur "This Month"
                      if (widget.timeFilterPreference != 2) {
                        updateTimeFilterPreference(2);
                      }
                      Navigator.pop(context, 0);
                    },
                    child: buildRow(
                        SvgPicture.asset(
                            'assets/icons/calendar_this_month.svg'),
                        "This Month",
                        widget.timeFilterCounter == 0 &&
                            widget.timeFilterPreference == 2),
                  ),
                  Divider(
                    color: borderColor,
                    thickness: 2,
                  ),
                  GestureDetector(
                    onTap: () {
                      // appuie sur "Last Month"
                      if (widget.timeFilterPreference != 2) {
                        updateTimeFilterPreference(2);
                      }
                      Navigator.pop(context, 1);
                    },
                    child: buildRow(
                        SvgPicture.asset(
                            'assets/icons/calendar_last_month.svg'),
                        "Last Month",
                        widget.timeFilterCounter == 1 &&
                            widget.timeFilterPreference == 2),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Row buildRow(SvgPicture svg, String titre, bool visibility) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          height: 50,
          width: 50,
          child: svg,
        ),
        Container(
          height: 50,
          width: 150,
          alignment: Alignment.centerLeft,
          child: Text(
            titre,
            style: TextStyle(fontSize: 20.0),
          ),
        ),
        visibility
            ? Container(
                height: 50,
                width: 30,
                child: Icon(Icons.check),
              )
            : Container(),
      ],
    );
  }
}
