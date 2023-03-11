import 'package:flutter/material.dart';
import 'package:flutter_login_ui/model/Categorie.dart';
import 'package:flutter_login_ui/model/Tache.dart';
import 'package:flutter_login_ui/screens/AddCategorie.dart';
import 'package:flutter_login_ui/screens/AddTache.dart';
import 'package:page_transition/page_transition.dart';
import 'package:sqflite/sqflite.dart';
import '../model/InitDatabase.dart';
import '../utilities/constants.dart';

class CategorieDetail extends StatefulWidget {
  final Categorie categorie;
  final int colorIndex;

  CategorieDetail({this.categorie, this.colorIndex}) ;

  @override
  CategorieDetail_ createState() => CategorieDetail_();
}

class CategorieDetail_ extends State<CategorieDetail> {

  //list of categories
  List<Tache> taches = [];

  @override
  void initState() {
    super.initState();
    getTaches();
  }

  void getTaches() async {
    Database database = await InitDatabase().database;
    //get all tacthes of the categorie
    var tachesOfCategorie = await database.query(
        'taches',
        //where categorie id is equal to the categorie id
        where: 'id_categorie = ?',
        whereArgs: [widget.categorie.id]
    );

    //add all taches to the list
    setState(() {
      tachesOfCategorie.forEach((tache) {
        print(tache);
        taches.add(Tache.fromMap(tache));
      });
    });

  }


  void _addTacheItem() {
    //supprimer toutes les taches
    taches.clear();
    //ajouter les taches
    getTaches();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categorie.nom),
        centerTitle: true,
        flexibleSpace: Container(
          decoration:  BoxDecoration(
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
                Navigator.of(context).pop(true);
              },
              icon: Icon(Icons.backspace),
            )),

        actions: [
          Container(
              child: IconButton(
                color: Colors.white,
                onPressed: () {},
                icon: Icon(Icons.edit_note),
              )),
        ],
      ),
      body: Column(
        children: [
          getCategoriesContainer(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
          onTap: (value) {
            if (value == 0) Navigator.push(context, PageTransition(
                type: PageTransitionType.bottomToTop,
                child: AddTache(onDataAdded : _addTacheItem,
                    colorIndex : widget.colorIndex,categorie: widget.categorie)
                ,childCurrent: this.widget,duration: Duration(milliseconds: 500)));
          },
          backgroundColor: Colors.white,
          selectedItemColor:  allColors[widget.colorIndex][1],
          unselectedItemColor: allColors[widget.colorIndex][1],
          selectedFontSize: 19,
          unselectedFontSize: 19,
          items:  <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle),
              label: 'Ajouter',
            ),
            BottomNavigationBarItem(
              icon: SizedBox(),
              label: 'Total 0:00',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.mail),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month),
              label: 'Calendrier',
            ),
          ],
          iconSize: 40,
          elevation: 5),
    );
  }

  Row buildRowCategorie(IconData icons,Tache tache) {
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
              color: Color(int.parse("0x" + tache.couleur)) ),
        ),
        GestureDetector(
          // get tap location
          // show the context menu
          onLongPress: () {
          },
          child:
          Container(
            height: 50,
            width: 150,
            alignment: Alignment.center,
            child: Text(
              tache.nom,
              style: TextStyle(fontSize: 20.0, color: Colors.black87),
            ),
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
                  style: TextStyle(fontSize: 20.0, color: Colors.black87),
                ),
              ),
              Container(
                height: 50,
                width: 50,
                child: Icon(
                  Icons.arrow_circle_right,
                  size: 30,
                  color: allColors[widget.colorIndex][1],),
              )
            ],
          ),
        ),
      ],
    );
  }

  Container getCategoriesContainer() {
    if (taches == null || taches.length == 0) {
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
        ),
        margin: const EdgeInsets.only(left: 20.0, right: 20.0),
        //get the categories from the database
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListView.builder(
                shrinkWrap: true,
                itemCount: taches.length,
                itemBuilder: (context, index) {
                  return buildRowCategorie(Icons.play_arrow, taches[index]);
                },
              ),
            ],
          ),
        ),

      ),
    );
  }
}
