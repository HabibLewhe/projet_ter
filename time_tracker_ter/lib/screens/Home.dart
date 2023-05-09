import 'package:flutter/material.dart';

import 'package:flutter_svg/svg.dart';
import 'package:page_transition/page_transition.dart';
import 'package:sqflite/sqflite.dart';
import '../model/Categorie.dart';
import '../model/InitDatabase.dart';
import '../utilities/constants.dart';
import 'AddCategorie.dart';
import 'AllTasks.dart';
import 'CategorieDetail.dart';

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var colorIndex = 1;
  String tempsEcouleTotal = "00:00:00";

  _MyHomePageState() {
    getPreferedTheme();
  }

  //list of categories
  Future<List<Categorie>> futureCategories;
  List<Categorie> categories = [];

  @override
  void initState() {
    super.initState();
    futureCategories = getCategories();
  }

  Future<List<Categorie>> getCategories() async {
    Database database = await InitDatabase().database;
    var cats = await database.query('categories');
    List<Categorie> liste = cats.map((e) => Categorie.fromMap(e)).toList();
    setState(() {
      categories = liste;
    });
    String tempsEcoule = "00:00:00";
    for (int i = 0; i < categories.length; i++) {
      Duration duration1 = Duration(
        hours: int.parse(tempsEcoule.split(':')[0]),
        minutes: int.parse(tempsEcoule.split(':')[1]),
        seconds: int.parse(tempsEcoule.split(':')[2]),
      );
      Duration duration2 = Duration(
        hours: int.parse(categories[i].temps_ecoule.split(':')[0]),
        minutes: int.parse(categories[i].temps_ecoule.split(':')[1]),
        seconds: int.parse(categories[i].temps_ecoule.split(':')[2]),
      );
      Duration sum = duration1 + duration2;
      tempsEcoule =
          "${sum.inHours}:${sum.inMinutes.remainder(60).toString().padLeft(2, '0')}:${sum.inSeconds.remainder(60).toString().padLeft(2, '0')}";
    }
    setState(() {
      tempsEcouleTotal = tempsEcoule;
    });
    return liste;
  }

  void deleteCategorie(int id) async {
    Database database = await InitDatabase().database;
    await database.delete('categories', where: 'id = ?', whereArgs: [id]);
    categories = await futureCategories;
    categories.clear();
    getCategories();
  }

  void _addCategorieItem() async {
    //clear all categories
    categories.clear();
    categories = await getCategories();
  }

  void getPreferedTheme() async {
    Database database = await InitDatabase().database;
    final Map<String, dynamic> queryResult =
        (await database.query('parametres')).first;
    setState(() {
      colorIndex = queryResult['theme_prefere'];
    });
  }

  void updatePreferedTheme(int index) async {
    Database database = await InitDatabase().database;
    await database.update('parametres', {'theme_prefere': index});
    setState(() {
      colorIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: backgroundColor1,
        appBar: AppBar(
          title: Text("Overview"),
          centerTitle: true,
          flexibleSpace: GestureDetector(
            onLongPress: () {
              // TODO : faire en sorte que le choix se fasse plus explicitement (bouton paramètres)
              // sur un appuie long sur la barre du haut
              // on affiche le popup pour choisir le theme de l'app
              showColorPickerDialog(context);
            },
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: allColors[colorIndex],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
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
        body: FutureBuilder<List<Categorie>>(
          future: futureCategories,
          builder:
              (BuildContext context, AsyncSnapshot<List<Categorie>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(),
              );
            } else if (snapshot.hasError) {
              return BottomAppBar(
                child: Center(
                  child: Text('Error loading categories'),
                ),
              );
            } else {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      color: allColors[colorIndex][1],
                      alignment: Alignment.center,
                      height: 93,
                      margin: const EdgeInsets.only(bottom: 35.0),
                      child: Container(
                          width: double.infinity,
                          margin:
                              const EdgeInsets.only(left: 20.0, right: 20.0),
                          height: 50,
                          child: MaterialButton(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50.0),
                            ),
                            onPressed: () {
                              // TODO : traiter appuie sur le bouton Quick Start
                            },
                            child: Text(
                              "Quick Start",
                              style: TextStyle(
                                  fontSize: 20.0,
                                  color: allColors[colorIndex][1]),
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
                          border: Border.all(
                              color: allColors[colorIndex][0], width: 1),
                          color: allColors[colorIndex][1],
                        ),
                        margin: const EdgeInsets.only(left: 20.0, right: 20.0),
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () {
                                // sur un appuie sur la ligne "All Tasks"
                                // Naviguer vers la page All Tasks
                                Navigator.push(
                                    context,
                                    PageTransition(
                                        type: PageTransitionType
                                            .rightToLeftWithFade,
                                        child: AllTasksPage(
                                            timeFilterCounter: 0,
                                            colorIndex: colorIndex),
                                        childCurrent: this.widget,
                                        duration: Duration(milliseconds: 500)));
                              },
                              child: buildRow("papers", "All Tasks"),
                            ),
                            Divider(
                              color: backgroundColor2,
                              thickness: 0.6,
                            ),
                            GestureDetector(
                              onTap: () {
                                // sur un appuie sur la ligne "Single Tasks"
                                // Naviguer vers la page Single Tasks
                                Navigator.push(
                                    context,
                                    PageTransition(
                                        type: PageTransitionType.rightToLeftWithFade,
                                        child: CategorieDetail(
                                          categorie: categories[0], colorIndex: colorIndex, timeFilterCounter: 0,),
                                        childCurrent: this.widget,
                                        duration: Duration(milliseconds: 500)));
                              },
                              child: buildRow("paper", "Single Tasks"),
                            ),
                          ],
                        ),
                      ),
                    ),
                    //container of my categories
                    getCategoriesContainer()
                  ],
                ),
              );
            }
          },
        ),
        bottomNavigationBar: BottomNavigationBar(
            onTap: (value) {
              // cas où on appuie sur le bouton "+"
              if (value == 0) {
                // on affiche la page pour créer une catégorie
                Navigator.push(
                    context,
                    PageTransition(
                        type: PageTransitionType.bottomToTop,
                        child: AddCatePage(
                          onDataAdded: _addCategorieItem,
                          colorIndex: colorIndex,
                        ),
                        childCurrent: this.widget,
                        duration: Duration(milliseconds: 500)));
              }
              // cas où on appuie sur le bouton export
              else if (value == 2) {
                // TODO : traitement appuie bouton export
              }
            },
            backgroundColor: Colors.white,
            selectedItemColor: allColors[colorIndex][1],
            unselectedItemColor: allColors[colorIndex][1],
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
                icon: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Total ",
                      overflow: TextOverflow.visible,
                      style: TextStyle(
                          fontSize: 19, color: allColors[colorIndex][1]),
                    ),
                    Text(
                      tempsEcouleTotal,
                      overflow: TextOverflow.visible,
                      style: TextStyle(
                          fontSize: 19, color: allColors[colorIndex][1]),
                    ),
                  ],
                ),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: SvgPicture.asset(
                  'assets/icons/mail.svg',
                  color: allColors[colorIndex][1],
                ),
                label: '',
              ),
            ],
            iconSize: 40,
            elevation: 5));
  }

  Row buildRow(String icon, String titre) {
    String tempsEcoule = "00:00:00";
    if (titre == "All Tasks") {
      tempsEcoule = tempsEcouleTotal;
    } else if (titre == "Single Tasks") {
      tempsEcoule = categories[0].temps_ecoule;
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          height: 50,
          width: 50,
          child: (icon == "paper")
              ? Image.asset(
                  'assets/icons/paper.png',
                )
              : ((icon == "papers")
                  ? Image.asset(
                      'assets/icons/papers.png',
                    )
                  : Container()),
        ),
        Container(
          height: 50,
          width: 150,
          alignment: Alignment.centerLeft,
          child: Text(
            titre,
            style: TextStyle(fontSize: 20.0, color: Colors.white),
          ),
        ),
        Container(
          height: 50,
          width: 115,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                height: 50,
                width: 80,
                alignment: Alignment.center,
                child: Text(
                  tempsEcoule,
                  style: TextStyle(fontSize: 20.0, color: Colors.white),
                ),
              ),
              Container(
                height: 35,
                width: 35,
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: SvgPicture.asset(
                    'assets/icons/arrow_right_in_circle.svg',
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildRowCategorie(IconData icons, Categorie categorie) {
    // id != 1 pour ne pas afficher la categorie "Single Tasks"
    if (categorie.id != 1) {
      return GestureDetector(
        onLongPress: () {
          // sur un appuie long :
          // afficher le popup pour supprimer ou éditer la catégorie
          showDelModDialog(context, categorie.id);
        },
        onTap: () {
          // sur un appuie court :
          // naviguer vers la page de détail de la catégorie
          Navigator.push(
              context,
              PageTransition(
                  type: PageTransitionType.rightToLeftWithFade,
                  child: CategorieDetail(
                      categorie: categorie, colorIndex: colorIndex, timeFilterCounter: 0,),
                  childCurrent: this.widget,
                  duration: Duration(milliseconds: 500)));
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 50,
              width: 50,
              child: Image.asset('assets/icons/dossier.png'),
            ),
            Container(
              height: 50,
              width: 150,
              alignment: Alignment.centerLeft,
              child: Text(
                categorie.nom,
                style: TextStyle(fontSize: 20.0, color: Colors.black87),
              ),
            ),
            Container(
              height: 50,
              width: 115,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    height: 50,
                    width: 80,
                    alignment: Alignment.center,
                    child: Text(
                      categorie.temps_ecoule,
                      style: TextStyle(fontSize: 20.0, color: colorTime1),
                    ),
                  ),
                  Container(
                    height: 35,
                    width: 35,
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: SvgPicture.asset(
                        'assets/icons/arrow_right_in_circle.svg',
                        color: Color(0xff848484),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return Container();
    }
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
          color: backgroundColor2,
        ),
        margin: const EdgeInsets.only(left: 20.0, right: 20.0),
        //get the categories from the database
        child: ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            return buildRowCategorie(Icons.folder, categories[index]);
          },
        ),
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
        // appuie bouton delete
        // on supprime la catégorie
        deleteCategorie(id);
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
        // TODO : traitement bouton edit categorie
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

  getColorFromName(String name) {
    switch (name) {
      case "blue":
        return Colors.blue;
      case "red":
        return Colors.red;
      case "orange":
        return Colors.orange;
    }
  }

  int selectedValue = 0;

  showColorPickerDialog(BuildContext context) {
    //save button
    Widget backBtn = TextButton(
      child: Row(
        //center the text
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Back",
            style: TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      onPressed: () {
        //save the categorie
        //get the color from the dropdown
        var colorIndex_ = colorIndex;
        updatePreferedTheme(colorIndex_);
        //saveCategorie(dropdownValue);
        Navigator.of(context).pop();
      },
    );

    var choixCouleur = Column(
      children: <Widget>[
        TextButton(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(allColors[0][1]),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text("Red", style: TextStyle(color: Colors.white)),
            ],
          ),
          onPressed: () {
            //get the color from the dropdown
            updatePreferedTheme(0);
            //saveCategorie(dropdownValue);
          },
        ),
        TextButton(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(allColors[1][1]),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text("Blue", style: TextStyle(color: Colors.white)),
            ],
          ),
          onPressed: () {
            //get the color from the dropdown
            updatePreferedTheme(1);
            //saveCategorie(dropdownValue);
          },
        ),
        TextButton(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(allColors[2][1]),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text("Orange", style: TextStyle(color: Colors.white)),
            ],
          ),
          onPressed: () {
            //get the color from the dropdown
            updatePreferedTheme(2);
            //saveCategorie(dropdownValue);
          },
        ),
      ],
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16.0))),
      contentPadding: EdgeInsets.only(top: 10.0),
      content: Container(
        width: 300.0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  "Prefered theme",
                  style: TextStyle(fontSize: 24.0),
                ),
              ],
            ),
            SizedBox(
              height: 5.0,
            ),
            Divider(
              color: Colors.grey,
              height: 4.0,
            ),
            Padding(
              padding: EdgeInsets.only(left: 30.0, right: 30.0),
              child: choixCouleur,
            ),
            InkWell(
              child: Container(
                decoration: BoxDecoration(
                  color: allColors[colorIndex][1],
                  borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(16.0),
                      bottomRight: Radius.circular(16.0)),
                ),
                child: backBtn,
              ),
            ),
          ],
        ),
      ),
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return alert;
          },
        );
      },
    );
  }
}
