import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_svg/svg.dart';
import 'package:sqflite/sqflite.dart';
import '../model/InitDatabase.dart';
import '../model/Categorie.dart';
import '../utilities/constants.dart';

class AddTache extends StatefulWidget {
  final Function() onDataAdded;
  final int colorIndex;
  final Categorie categorie;

  AddTache({this.onDataAdded, this.colorIndex, this.categorie});

  @override
  _AddTacheState createState() => _AddTacheState();
}

class _AddTacheState extends State<AddTache> {
  TextEditingController nom = TextEditingController();
  Color selectedColor = Colors.blue;

  void addTache() async {
    Database database = await InitDatabase().database;
    //vérifier si le nom de tache est vide
    if (nom.text == '') {
      //afficher un message d'erreur
      showErrorMessage("Veuillez entrer un nom de tache");
      return;
    }

    //inserer une nouvelle tache
    await database.insert('taches', {
      'nom': nom.text,
      'couleur': selectedColor.value.toRadixString(16),
      //current date
      'temps_ecoule': "00:00:00",
      'id_categorie': widget.categorie.id,
    });

    //afficher un message de succès
    showSuccessMessage("Tache ajoutée avec succès");
    //notifier le widget parent que les données ont été ajoutées
    widget.onDataAdded();
    //go back to home page
    Navigator.of(context).pop();
  }

  void changeColor(Color color) {
    print(color.toString());
    setState(() => selectedColor = color);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Nouvelle Tâche"),
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
          onPressed: () => Navigator.of(context).pop(true),
          icon: Icon(Icons.backspace),
        )),
        actions: [
          Container(
            padding: EdgeInsets.only(right: 20.0),
            child: GestureDetector(
              onTap: () {
                addTache();
              },
              child: SvgPicture.asset(
                'assets/icons/save.svg',
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          SizedBox(height: 10.0),
          Container(
            alignment: Alignment.centerLeft,
            margin: EdgeInsets.only(left: 5.0, right: 5.0),
            decoration: makeBoxDecoration(allColors[widget.colorIndex][0]),
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
                hintText: 'Entrer le nom de la tache',
                hintStyle: kHintTextStyle,
              ),
            ),
          ),
          SizedBox(height: 10.0),
          //add color picker
          Container(
            alignment: Alignment.center,
            margin: EdgeInsets.only(left: 5.0, right: 5.0),
            decoration: makeBoxDecoration(allColors[widget.colorIndex][0]),
            height: 60.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: 50.0,
                  height: 50.0,
                  decoration: BoxDecoration(
                    color: selectedColor,
                    borderRadius: BorderRadius.circular(50.0),
                  ),
                ),
                SizedBox(width: 10.0),
                TextButton(
                  child: Text(
                    'Selectionner une couleur',
                    style: TextStyle(fontSize: 20.0, color: Colors.white),
                  ),
                  onPressed: () => showGeneralDialog(
                    context: context,
                    transitionBuilder:
                        (context, animation, secondaryAnimation, child) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 1),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      );
                    },
                    pageBuilder: (ctx, a1, a2) {
                      return AlertDialog(
                        title: const Text('Selectionner une couleur'),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(16.0))),
                        content: SingleChildScrollView(
                          child: ColorPicker(
                            pickerColor: selectedColor,
                            onColorChanged: changeColor,
                            colorPickerWidth: 300.0,
                            pickerAreaHeightPercent: 0.7,
                            enableAlpha: true,
                            displayThumbColor: true,
                            labelTypes: [],
                            paletteType: PaletteType.hsv,
                            pickerAreaBorderRadius: const BorderRadius.all(
                              Radius.circular(16.0),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
