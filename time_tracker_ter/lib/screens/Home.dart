import 'package:flutter/material.dart';
import 'package:flutter_login_ui/model/Categorie.dart';
import 'package:flutter_login_ui/screens/AddCategorie.dart';
import 'package:flutter_login_ui/screens/AllTasksEdit.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../model/InitDatabase.dart';
import 'login_screen.dart';

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const Color _color = Color(0xFFff3d3d);
  static const Color _color1 = Color(0xFFff3d3d);
  static const Color _color2 = Color(0xFFff2929);
  static const Color _color3 = Color(0xFFff1515);

  //list of categories
  List<Categorie> categories = [];

  @override
  void initState() {
    super.initState();
    getCategories();
  }

  void getCategories() async {
    Database database = await InitDatabase().database;
    //get id_user connected
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int id_user = prefs.getInt('userId');
    print(id_user);
    if (id_user != null) {
      var cats = await database.query('categories',
          //where email and password are equal to the email and password entered by the user
          where: 'id_categorie_sup = 1 AND id_user = ?',
          whereArgs: [id_user]);
      setState(() {
        print("setState HOME PAGE");
        categories = cats.map((e) => Categorie.fromMap(e)).toList();
      });
      //print all categories one by one
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Overview"),
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
              onPressed: () {},
              child: Text(
                "About",
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
                onPressed: () {
                  Navigator.push(
                      context,
                      PageTransition(
                          type: PageTransitionType.rightToLeft,
                          child: AllTasksEdit()));
                },
                child: Text(
                  "Edit", //Edit Bouton
                  style: TextStyle(color: _color),
                ),
              ))
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: _color,
            alignment: Alignment.center,
            height: 93,
            margin: const EdgeInsets.only(bottom: 35.0),
            child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(left: 20.0, right: 20.0),
                height: 50,
                child: MaterialButton(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50.0),
                  ),
                  onPressed: () {},
                  child: Text(
                    "Quick Start",
                    style: TextStyle(fontSize: 20.0, color: _color),
                  ),
                )),
          ),
          Container(
            width: double.infinity,
            alignment: Alignment.center,
            margin: const EdgeInsets.only(bottom: 20.0),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _color3, width: 1),
                color: _color,
              ),
              margin: const EdgeInsets.only(left: 20.0, right: 20.0),
              child: Column(
                children: [
                  buildRow(Icons.copy_sharp, "All Tasks"),
                  Divider(
                    color: _color3,
                    thickness: 1,
                  ),
                  buildRow(Icons.padding_sharp, "Single Task"),
                ],
              ),
            ),
          ),
          //container of my categories
          getCategoriesContainer()
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
          onTap: (value) {
            if (value == 0)
              Navigator.push(
                  context,
                  PageTransition(
                      type: PageTransitionType.bottomToTop,
                      child: AddCatePage(),
                      childCurrent: this.widget,
                      duration: Duration(milliseconds: 500)));
          },
          backgroundColor: Colors.white,
          selectedItemColor: _color3,
          unselectedItemColor: _color3,
          selectedFontSize: 19,
          unselectedFontSize: 19,
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle),
              label: 'Add project',
            ),
            BottomNavigationBarItem(
              icon: SizedBox(),
              label: 'Total 0:00',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.mail),
              label: 'contact',
            ),
          ],
          iconSize: 40,
          elevation: 5),
    );
  }

  Row buildRow(IconData icons, String titre) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          height: 50,
          width: 50,
          child: Icon(
            icons,
            size: 30,
            color: Colors.white,
          ),
        ),
        Container(
          height: 50,
          width: 150,
          alignment: Alignment.center,
          child: Text(
            titre,
            style: TextStyle(fontSize: 20.0, color: Colors.white),
          ),
        ),
        Container(
          height: 50,
          width: 100,
          //add child + text 00:00

          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                height: 50,
                width: 50,
                alignment: Alignment.center,
                child: Text(
                  "00:00",
                  style: TextStyle(fontSize: 20.0, color: Colors.white),
                ),
              ),
              Container(
                height: 50,
                width: 50,
                child: Icon(
                  Icons.arrow_circle_right,
                  size: 30,
                  color: Colors.white,
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  Container getCategoriesContainer() {
    if (categories == null || categories.length == 0) {
      return Container();
    }
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      margin: const EdgeInsets.only(bottom: 20.0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _color3, width: 1),
          color: _color,
        ),
        margin: const EdgeInsets.only(left: 20.0, right: 20.0),
        //get the categories from the database
        child: Column(
          children: [
            //for each category in the database, create a row
            for (var categorie in categories)
              buildRow(Icons.folder, categorie.nom),
          ],
        ),
      ),
    );
  }
}
