import 'package:flutter/material.dart';
import 'package:flutter_login_ui/model/Categorie.dart';
import 'package:flutter_login_ui/screens/AddTache.dart';
import 'package:flutter_svg/svg.dart';
import 'package:page_transition/page_transition.dart';
import 'package:sqflite/sqflite.dart';
import '../model/InitDatabase.dart';
import '../model/Tache.dart';
import '../utilities/constants.dart';

class CategorieDetail extends StatefulWidget {
  final Categorie categorie;
  final int colorIndex;

  CategorieDetail({this.categorie, this.colorIndex});

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
    //get all taches of the categorie
    var tachesOfCategorie = await database.query('taches',
        //where categorie id is equal to the categorie id
        where: 'id_categorie = ?',
        whereArgs: [widget.categorie.id]);

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
      backgroundColor: backgroundColor1,
      appBar: AppBar(
        title: Text(widget.categorie.nom),
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
        actions: [
          Container(
              child: IconButton(
            color: Colors.white,
            onPressed: () {
              // TODO : traitement appuie sur le bouton edit
            },
            icon: Icon(Icons.edit_note),
          )),
        ],
      ),
      body: getCategorieContainer(),
      bottomNavigationBar: BottomNavigationBar(
          onTap: (value) {
            // cas où appuie sur le bouton +
            if (value == 0) {
              Navigator.push(
                  context,
                  PageTransition(
                      type: PageTransitionType.bottomToTop,
                      child: AddTache(
                          onDataAdded: _addTacheItem,
                          colorIndex: widget.colorIndex,
                          categorie: widget.categorie),
                      childCurrent: this.widget,
                      duration: Duration(milliseconds: 500)));
            }
            // cas où appuie sur le bouton export
            else if (value == 2) {
              // TODO : traitement appuie sur le bouton export
            }
            // cas où appuie sur le bouton time filter
            else if (value == 3) {
              // TODO : traitement appuie sur le bouton time filter
            }
          },
          backgroundColor: Colors.white,
          selectedItemColor: allColors[widget.colorIndex][1],
          unselectedItemColor: allColors[widget.colorIndex][1],
          selectedFontSize: 15,
          unselectedFontSize: 15,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Text(
                'Total 0:00',
                overflow: TextOverflow.visible,
                style: TextStyle(
                    fontSize: 19, color: allColors[widget.colorIndex][1]),
              ),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/icons/mail.svg',
                color: allColors[widget.colorIndex][1],
              ),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/icons/calendar.svg',
                color: allColors[widget.colorIndex][1],
              ),
              label: '',
            ),
          ],
          iconSize: 40,
          elevation: 5),
    );
  }

  Container buildRowTache(Tache tache) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 0.5),
        color: backgroundColor2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 20,
            width: 20,
            child: GestureDetector(
              onTap: () {
                // TODO : lancer chronomètre pour la tache
              },
              child: SvgPicture.asset(
                'assets/icons/play_arrow.svg',
              ),
            ),
          ),
          GestureDetector(
            // get tap location
            // show the context menu
            onLongPress: () {},
            child: Container(
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
                  height: 30,
                  width: 30,
                  child: GestureDetector(
                    onTap: () {
                      // TODO : naviguer vers l'historique de la tache
                    },
                    child: Stack(
                      children: [
                        SvgPicture.asset(
                          'assets/icons/circle.svg',
                          color: allColors[widget.colorIndex][1],
                        ),
                        Padding(
                          padding: EdgeInsets.all(10),
                          child: SvgPicture.asset(
                            'assets/icons/arrow_right_in_circle.svg',
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Container getCategorieContainer() {
    if (taches == null || taches.length == 0) {
      return Container();
    }
    return Container(
      width: double.infinity,
      alignment: Alignment.topCenter,
      margin: const EdgeInsets.only(bottom: 20.0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: backgroundColor2,
        ),
        //get the categories from the database
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: taches.length,
          itemBuilder: (context, index) {
            return buildRowTache(taches[index]);
          },
        ),
      ),
    );
  }
}
