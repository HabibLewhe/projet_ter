import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

const timeFilterColor1 = Color(0xFF7A7A7A);
const timeFilterColor2 = Color(0xBF1C1B1B);
const borderColor = Color(0x1A000000);
const backgroundColor1 = Color(0xFFF3F3F3);
const backgroundColor2 = Color(0xFFFFFEFE);
const colorTime1 = Color(0xFF848484);
const colorTime2 = Color(0xFFFE7171);
const start = "Start";
const end = "End";
const duration = "Duration";
const longitude = "Longitude";
const latitude = "Latitude";
const delete = "Delete";
const now = "Now";
const today = "Today";
const thisWeek = "This week";
const thisMonth = "This month";
const total = "Total";
const confirmerSuppression = "Confirmer la suppression";
const supprimerCreneau = "Supprimer ce créneau ?";
const viderHistorique  = "Vider l'historique de cette tâche ?";
const annuler = "Annuler";
const supprimer = "Supprimer";
const alltasks = "All Tasks";
const singleTask = "Single Tasks";
const papers = "papers";
const paper = "paper";

final kHintTextStyle = TextStyle(
  color: Colors.white54,
  fontFamily: 'OpenSans',
);

final kLabelStyle = TextStyle(
  color: Colors.white,
  fontWeight: FontWeight.bold,
  fontFamily: 'OpenSans',
);

final kBoxDecorationStyle = BoxDecoration(
  color: Color(0xFFff7777),
  borderRadius: BorderRadius.circular(10.0),
  boxShadow: [
    BoxShadow(
      color: Colors.black12,
      blurRadius: 6.0,
      offset: Offset(0, 2),
    ),
  ],
);

makeBoxDecoration(Color color) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(10.0),
    boxShadow: [
      BoxShadow(
        color: Colors.black12,
        blurRadius: 6.0,
        offset: Offset(0, 2),
      ),
    ],
  );
}

//arrays of 4 colors
final List<Color> redColors = [Color(0xBFB52531), Color(0xFFB52531), Color(0xFF97232D)];
//orange color
final List<Color> blueColors  = [Color(0xBF005DA4), Color(0xFF005DA4), Color(0xFF2E6289)];
//blue color
final List<Color> orangeColors  = [Color(0xBFFF5C00), Color(0xFFFF5C00), Color(0xFFD96D31)];
//arrays of all arrays of colors
final List<List<Color>> allColors = [redColors, blueColors, orangeColors];

//functions to show success or error messages
showSuccessMessage(String msg) {
  Fluttertoast.showToast(
      msg:  msg,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16.0
  );
}

showErrorMessage(String msg) {
  Fluttertoast.showToast(
      msg: msg,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0
  );
}
