import 'package:flutter/material.dart';
import 'package:flutter_login_ui/model/Categorie.dart';
import 'package:flutter_login_ui/screens/AddCategorie.dart';
import 'package:flutter_login_ui/screens/CategorieDetail.dart';
import 'package:page_transition/page_transition.dart';
import 'package:sqflite/sqflite.dart';
import '../model/InitDatabase.dart';
import '../utilities/constants.dart';

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  var colorIndex = 2;
  _MyHomePageState() {
    //get all categories
    getColorIndexOfUser();
  }
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
    // SharedPreferences prefs = await SharedPreferences.getInstance();
    //int id_user = 1;
    var cats = await database.query(
        'categories',
        //where user id is equal to 1 (connected user)
        where: 'id_categorie_sup = 1 AND id_user = 1 and id != 1'
    );
    setState(() {
      categories = cats.map((e) => Categorie.fromMap(e)).toList();
    });
    //print all categories one by one
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

  void getColorIndexOfUser() async {
    Database database = await InitDatabase().database;
    var user = await database.query(
        'users',
        //where user id is equal to 1 (connected user)
        where: 'id = 1'
    );
    setState(() {
      colorIndex = user.first['color'];
    });
  }

  void updateColorIndex(int index) async {
    Database database = await InitDatabase().database;
    await database.update('users', {'color': index}, where: 'id = ?', whereArgs: [1]);
    setState(() {
      colorIndex = index;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Overview"),
        centerTitle: true,
        flexibleSpace:GestureDetector(
        // get tap location
        // show the context menu
        onLongPress: () {
            showColorPickerDialog(context);
        },
        child: Container(
          decoration:  BoxDecoration(
            gradient: LinearGradient(
                colors: allColors[colorIndex],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
           ),
          ),
        ),
      ),

        leading: Container(
            child: IconButton(
              color: Colors.white,
              onPressed: () {},
              icon: Icon(Icons.error),
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
          Container(
            width: double.infinity,
            color:  allColors[colorIndex][1],
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
                    style: TextStyle(fontSize: 20.0, color:  allColors[colorIndex][1]),
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
                border: Border.all(color: allColors[colorIndex][0],width: 1),
                color:  allColors[colorIndex][1],
              ),
              margin: const EdgeInsets.only(left: 20.0, right: 20.0),
              child: Column(
                children: [
                  buildRow(Icons.copy_sharp, "All Tasks"),
                  Divider(
                      color:  allColors[colorIndex][1],
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
            if (value == 0) Navigator.push(context, PageTransition(type: PageTransitionType.bottomToTop, child: AddCatePage(onDataAdded: _addCategorieItem, colorIndex: colorIndex, ),childCurrent: this.widget,duration: Duration(milliseconds: 500)));
          },
          backgroundColor: Colors.white,
          selectedItemColor:  allColors[colorIndex][1],
          unselectedItemColor: allColors[colorIndex][1],
          selectedFontSize: 19,
          unselectedFontSize: 19,
          items:  <BottomNavigationBarItem>[
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
            color: Colors.white,),
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
                  color: Colors.white,),
              )
            ],
          ),
        ),
      ],
    );
  }
  Row buildRowCategorie(IconData icons,Categorie categorie) {
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
            color: Color(int.parse("0x" + categorie.couleur)) ),
        ),
        GestureDetector(
        // get tap location
        // show the context menu
        onLongPress: () {
          showDelModDialog( context, categorie.id);
        },
        onTap: () {
          Navigator.push(context, PageTransition(type: PageTransitionType.rightToLeftWithFade  , child: CategorieDetail(categorie : categorie  , colorIndex : colorIndex)  , childCurrent: this.widget, duration: Duration(milliseconds: 500)));
        },
        child:
            Container(
              height: 50,
              width: 150,
              alignment: Alignment.center,
              child: Text(
               categorie.nom,
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
                  color: Colors.black87,),
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
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    return buildRowCategorie(Icons.folder, categories[index]);
                  },
                ),
              ],
            ),
          ),
          //   child: ListView(
          //   children: <Widget>[
          //     FutureBuilder<List<Categorie>>(
          //       future: getCategories_(),
          //       builder: (context, AsyncSnapshot<List<Categorie>> snapshot) {
          //
          //         if (snapshot.hasData) {
          //           return ListView.builder(
          //             shrinkWrap: true,
          //             itemCount: categories.length,
          //             itemBuilder: (context, index) {
          //               return buildRow(Icons.import_contacts_sharp, categories[index].nom);
          //             },
          //           );
          //         } else {
          //           return Center(child: CircularProgressIndicator());
          //         }
          //       },
          //     ),
          //   ],
          // ),
        ),
      );
    }

  showAlertDialog(BuildContext context) {
    // set up the buttons

    Widget continueButton = TextButton(
      child: Icon(Icons.add),
      onPressed:  () {
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


  showDelModDialog(BuildContext context,int id) {
    // set up the buttons
    Widget deletBtn = TextButton(
      child: Row(
        children: [
          Icon(Icons.delete,color: Colors.red),
          Text("Delete",style: TextStyle(color: Colors.red)),
        ],
      ),
      onPressed:  () {
        //delete the categorie
        deleteCategorie(id);
        Navigator.of(context).pop();
      },
    );
    Widget editBtn = TextButton(
      child: Row(
        children: [
          Icon(Icons.edit,color: Colors.blue),
          Text("Edit",style: TextStyle(color: Colors.blue)),
        ],
      ),
      onPressed:  () {
        // do something
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

  getColorFromName(String name){
    switch(name){
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
          Text("Back",style: TextStyle(color: Colors.white ),textAlign: TextAlign.center,),
        ],
      ),
      onPressed:  () {
        //save the categorie
        //get the color from the dropdown
        var colorIndex_ = colorIndex;
        updateColorIndex(colorIndex_);
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
              Text("Red",style: TextStyle(color: Colors.white)),
            ],
          ),
          onPressed:() {
            //get the color from the dropdown
            updateColorIndex(0);
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
              Text("Blue",style: TextStyle(color: Colors.white)),
            ],
          ),
          onPressed:() {
            //get the color from the dropdown
            updateColorIndex(1);
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
              Text("Orange",style: TextStyle(color: Colors.white)),
            ],
          ),
          onPressed:() {
            //get the color from the dropdown
            updateColorIndex(2);
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
                  "Couleur",
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
