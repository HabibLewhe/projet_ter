import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_login_ui/model/Tache.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/Categorie.dart';
import '../services/DatabaseService.dart';

class EditTask extends StatefulWidget {
  final Tache passingTache;
  List<Categorie> passingCategories = [];
  final Function refreshAllTasksEdit;

  EditTask(this.passingTache, this.passingCategories, this.refreshAllTasksEdit);

  @override
  _EditTaskState createState() => _EditTaskState();
}

class _EditTaskState extends State<EditTask> {
  String nom;
  int idCategorie;
  Tache tache;
  List<Categorie> categories;

  final _formKey = GlobalKey<FormState>();
  static const Color _color = Color.fromARGB(255, 61, 122, 255);
  static const Color _color1 = Color.fromARGB(255, 61, 148, 255);
  static const Color _color2 = Color.fromARGB(255, 41, 166, 255);
  static const Color _color3 = Color.fromARGB(255, 21, 177, 255);
  @override
  void initState() {
    super.initState();
    tache = widget.passingTache;
    categories = widget.passingCategories;
    print(tache.nom);
    print(categories.toString());
  }

  String getCategorieNom(List<Categorie> categories, int id) {
    final matchingCat =
        categories.firstWhere((cat) => cat.id == id, orElse: () => null);
    return matchingCat?.nom ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit"),
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
            margin: const EdgeInsets.only(top: 15.0, bottom: 15.0),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).pop(true);
              },
              child: Icon(
                Icons.cancel,
                color: Colors.white,
              ),
            )),
        actions: [
          Container(
              margin:
                  const EdgeInsets.only(top: 15.0, bottom: 15.0, right: 30.0),
              child: GestureDetector(
                onTap: () async {
                  if (_formKey.currentState.validate()) {
                    _formKey.currentState.save();
                    print("this is id_categorie____$idCategorie");
                    //change nom
                    if (tache.nom != nom || tache.id_categorie == idCategorie) {
                      await ModifierNomTache(tache.id, nom);
                      widget.refreshAllTasksEdit();
                      Navigator.of(context).pop(true);
                    }
                    // change id(groupe)
                    else if (tache.nom == nom ||
                        tache.id_categorie != idCategorie) {
                      await ModifierGroupeCategorie(tache.id, idCategorie);
                      widget.refreshAllTasksEdit();
                      Navigator.of(context).pop(true);
                    }
                    //change nom et id
                    else if ((tache.nom != nom ||
                        tache.id_categorie != idCategorie)) {
                      await ModifierNomTache(tache.id, nom);
                      await ModifierGroupeCategorie(tache.id, idCategorie);
                      widget.refreshAllTasksEdit();
                      Navigator.of(context).pop(true);
                    } else {
                      Navigator.of(context).pop(true);
                    }
                  }
                },
                child: Icon(
                  //todo save
                  Icons.save,
                  color: Colors.white,
                ),
              ))
        ],
      ),
      body: Container(
          child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(children: [
          Container(
            decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[400], width: 1.0),
                borderRadius: BorderRadius.circular(13)),
            child: Form(
              key: _formKey,
              child: TextFormField(
                initialValue: tache.nom,
                decoration: InputDecoration(
                    labelText: "Task name", border: InputBorder.none),
                validator: (value) {
                  if (value.isEmpty) {
                    return "Please enter a task name";
                  }
                  return null;
                },
                onSaved: (value) => nom = value,
                onFieldSubmitted: (value) {
                  setState(() {
                    nom = value;
                  });
                },
              ),
            ),
          ),
          //this
          SizedBox(
            height: 14,
          ),
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  "Project",
                  style: TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[400], width: 1.0),
                borderRadius: BorderRadius.circular(13)),
            child: DropdownButtonFormField(
              decoration: InputDecoration(
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                  labelText: getCategorieNom(categories, tache.id_categorie),
                  contentPadding: EdgeInsets.only(left: 8)
                  //border: OutlineInputBorder(),
                  ),
              items: categories
                  .map((categorie) => DropdownMenuItem(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(categorie.nom),
                      ),
                      value: categorie.id))
                  .toList(),
              onChanged: (newValue) {
                setState(() {
                  idCategorie = newValue;
                });
              },
            ),
          ),
        ]),
      )),
    );
  }
}
