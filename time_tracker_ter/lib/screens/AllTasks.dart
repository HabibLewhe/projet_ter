import 'package:flutter/material.dart';
import 'package:flutter_login_ui/model/Categorie.dart';
import 'package:flutter_login_ui/screens/AddCategorie.dart';
import 'package:page_transition/page_transition.dart';
import 'package:sqflite/sqflite.dart';
import '../model/InitDatabase.dart';
import '../model/Tache.dart';
import '../utilities/constants.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AllTasksPage extends StatefulWidget {
  final int colorIndex;

  AllTasksPage({this.colorIndex});

  @override
  _AllTasksPageState createState() => _AllTasksPageState();
}

class _AllTasksPageState extends State<AllTasksPage> {
  List<Categorie> categories = [];
  List<Tache> taches = [];

  @override
  void initState() {
    super.initState();
    getCategories();
    getTaches();
  }

  void getTaches() async {
    Database database = await InitDatabase().database;
    var t = await database.query('taches');
    setState(() {
      taches = t.map((e) => Tache.fromMap(e)).toList();
    });
  }

  void deleteTache(int id) async {
    Database database = await InitDatabase().database;
    await database.delete('taches', where: 'id = ?', whereArgs: [id]);
    taches.clear();
    getTaches();
  }

  void getCategories() async {
    Database database = await InitDatabase().database;
    var cats = await database.query('categories');
    setState(() {
      categories = cats.map((e) => Categorie.fromMap(e)).toList();
    });
  }

  List<Tache> getTachesCategorie(Categorie categorie) {
    List<Tache> t = [];
    for (int i = 0; i < taches.length; i++) {
      if (taches[i].id_categorie == categorie.id) {
        t.add(taches[i]);
      }
    }
    return t;
  }

  void deleteCategorie(int id) async {
    Database database = await InitDatabase().database;
    await database.delete('categories', where: 'id = ?', whereArgs: [id]);
    categories.clear();
    getCategories();
  }

  void _addCategorieItem() {
    //clear all categories
    categories.clear();
    getCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor1,
      appBar: AppBar(
        title: Text("All Tasks"),
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
        leading: Padding(
          padding: const EdgeInsets.only(left: 25.0),
          child: GestureDetector(
            onTap: () {
              // TODO : traiter appuie sur bouton info
            },
            child: SvgPicture.asset(
              'assets/icons/info.svg',
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 25.0),
            child: GestureDetector(
              onTap: () {
                // TODO : traiter appuie sur bouton edit
              },
              child: SvgPicture.asset(
                'assets/icons/edit.svg',
              ),
            ),
          ),
        ],
      ),
      body: Padding(
          padding: EdgeInsets.only(top: 20.0),
          child:
              //affiche la page dynamiquement
              getPageContainer()),
      bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          onTap: (value) {
            // cas où appuie sur le bouton +
            if (value == 0) {
              // afficher la page pour ajouter une catégorie
              Navigator.push(
                  context,
                  PageTransition(
                      type: PageTransitionType.bottomToTop,
                      child: AddCatePage(
                        onDataAdded: _addCategorieItem,
                        colorIndex: widget.colorIndex,
                      ),
                      childCurrent: this.widget,
                      duration: Duration(milliseconds: 500)));
            }
            // cas où appuie sur le bouton balai
            else if (value == 1) {
              // TODO : traitement appuie bouton balai
            }
            // cas où appuie sur le bouton export
            else if (value == 3) {
              // TODO : traitement appuie bouton export
            }
            // cas où appuie sur le bouton time filter
            else if (value == 4) {
              // TODO : traitement appuie bouton time filter
            }
          },
          backgroundColor: backgroundColor2,
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
              icon: SvgPicture.asset(
                'assets/icons/broom.svg',
                color: allColors[widget.colorIndex][1],
              ),
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

  Widget getPageContainer() {
    List<Tache> singleTasks = [];
    for (int i = 0; i < taches.length; i++) {
      if (taches[i].id_categorie == null) {
        singleTasks.add(taches[i]);
      }
    }
    if (singleTasks.isEmpty) {
      return Container();
    }
    return SingleChildScrollView(
      child: Column(
        children: [
          if (singleTasks.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 16.0),
                  child: Text(
                    "Single Tasks",
                    style: TextStyle(
                        fontSize: 20,
                        color: allColors[widget.colorIndex][1],
                        fontFamily: 'Montserrat'),
                  ),
                ),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor, width: 1),
                    color: backgroundColor2,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: singleTasks.length,
                        itemBuilder: (BuildContext context, int index) {
                          final singleTask = singleTasks[index];
                          return buildRowTache((singleTask.nom), singleTask.id);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ...categories.map((categorie) {
            final tachesCategorie = getTachesCategorie(categorie);
            return buildRowCategorie(
                categorie.nom, categorie.id, tachesCategorie);
          }).toList(),
        ],
      ),
    );
  }

  Container buildRowCategorie(
      String titre, int id, List<Tache> listeTachesCat) {
    return Container(
        width: double.infinity,
        alignment: Alignment.centerLeft,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: EdgeInsets.only(left: 16.0, top: 10.0),
            child: Text(
              titre,
              style: TextStyle(
                  fontSize: 20,
                  color: allColors[widget.colorIndex][1],
                  fontFamily: 'Montserrat'),
            ),
          ),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: 1),
              color: backgroundColor2,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: listeTachesCat.length,
                  itemBuilder: (context, index) {
                    return buildRowTache(
                        listeTachesCat[index].nom, listeTachesCat[index].id);
                  },
                ),
              ],
            ),
          ),
        ]));
  }

  Container buildRowTache(String titre, int id) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 1),
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
            // sur un appuie long :
            // afficher le popup pour supprimer ou éditer la tache
            onLongPress: () {
              showDelModDialog(context, id);
              print(titre);
            },
            child: Container(
              height: 50,
              width: 150,
              alignment: Alignment.centerLeft,
              child: Text(
                titre,
                style: TextStyle(fontSize: 20.0, color: Colors.black),
              ),
            ),
          ),
          Container(
            height: 50,
            width: 100,
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
                    style: TextStyle(fontSize: 20.0, color: Colors.black),
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

  showAlertDialog(BuildContext context) {
    // set up the buttons
    Widget continueButton = TextButton(
      child: Icon(Icons.add),
      onPressed: () {
        // do something
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("AlertDialog"),
      content: Text("Would you like to continue?"),
      actions: [
        continueButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  showDelModDialog(BuildContext context, int id) {
    // set up the buttons
    Widget deletBtn = TextButton(
      child: Row(
        children: [
          Icon(Icons.delete, color: Colors.red),
          Text("Delete", style: TextStyle(color: Colors.red)),
        ],
      ),
      onPressed: () {
        // appuie sur le bouton delete
        // on supprime la tache
        deleteTache(id);
        // on ferme le popup
        Navigator.of(context).pop();
      },
    );
    Widget editBtn = TextButton(
      child: Row(
        children: [
          Icon(Icons.edit, color: Colors.blue),
          Text("Edit", style: TextStyle(color: Colors.blue)),
        ],
      ),
      onPressed: () {
        // TODO : traitement bouton edit tache
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Confirmation"),
      content: Text("Que voulez vous faire?"),
      actions: [
        deletBtn,
        editBtn,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}
