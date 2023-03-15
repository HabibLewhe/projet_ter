import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../model/InitDatabase.dart';
import '../utilities/constants.dart';

class AddCatePage extends StatefulWidget {
  @override
  _AddCatePageState createState() => _AddCatePageState();
}

class _AddCatePageState extends State<AddCatePage> {
  static const Color _color = Color(0xFF73AEF5);
  static const Color _color1 = Color(0xFF61A4F1);
  static const Color _color2 = Color(0xFF478DE0);
  static const Color _color3 = Color(0xFF398AE5);

  TextEditingController nom = TextEditingController();

  void addCategorie() async {
    Database database = await InitDatabase().database;
    //get id_user connected
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int id_user = prefs.getInt('userId');
    if (id_user != null) {
      //insert new categorie
      await database.insert('categories', {
        'nom': nom.text,
        'couleur': '0xFF73AEF5',
        'id_categorie_sup': 1,
        'id_user': id_user,
      });
    }

    //go back to home page
    Navigator.of(context).pop({'categorie': nom.text, 'couleur': '0xFF73AEF5'});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Nouvelle Catégorie"),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _color,
                  _color1,
                  _color2,
                  _color3,
                ]),
          ),
        ),
        leadingWidth: 100,
        leading: Container(
            margin: const EdgeInsets.only(top: 15.0, bottom: 15.0, left: 18.0),
            child: MaterialButton(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5.0),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                "Done",
                style: TextStyle(color: _color),
              ),
            )),
        actions: [
          Container(
              margin:
                  const EdgeInsets.only(top: 15.0, bottom: 15.0, right: 18.0),
              child: MaterialButton(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5.0),
                ),
                onPressed: () => addCategorie(),
                child: Text(
                  "save",
                  style: TextStyle(color: _color),
                ),
              ))
        ],
      ),
      body: Column(
        children: <Widget>[
          SizedBox(height: 10.0),
          Container(
            alignment: Alignment.centerLeft,
            margin: EdgeInsets.only(left: 5.0, right: 5.0),
            decoration: kBoxDecorationStyle,
            height: 60.0,
            child: TextField(
              keyboardType: TextInputType.name,
              controller: nom,
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'OpenSans',
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.only(top: 14.0),
                prefixIcon: Icon(
                  Icons.group_work,
                  color: Colors.white,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    Icons.cancel,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    nom.clear();
                  },
                ),
                hintText: 'Entrer le nom de la catégorie',
                hintStyle: kHintTextStyle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
