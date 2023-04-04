import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_login_ui/model/Tache.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utilities/constants.dart';
import '../model/Categorie.dart';
import '../services/DatabaseService.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';

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
  var colorIndex = 1;
  TextEditingController _controllerTextFieldTache;

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
    idCategorie = tache.id_categorie;
    _controllerTextFieldTache = TextEditingController(text: tache.nom);
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
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: allColors[colorIndex],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          leading: Padding(
            padding: const EdgeInsets.only(left: 25.0),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).pop(true);
              },
              child: Icon(
                Icons.cancel_rounded,
                color: Colors.white,
                size: 38,
              ),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 25.0),
              child: GestureDetector(
                  onTap: () async {
                    if (_formKey.currentState.validate()) {
                      _formKey.currentState.save();
                      //print("this is id_categorie____$idCategorie");

                      //change nom
                      if (tache.nom != nom &&
                          tache.id_categorie == idCategorie) {
                        await ModifierNomTache(tache.id, nom);
                        await widget.refreshAllTasksEdit();
                        Navigator.of(context).pop(true);
                      }
                      // change id(groupe)
                      else if (tache.nom == nom &&
                          tache.id_categorie != idCategorie) {
                        await ModifierGroupeCategorie(tache.id, idCategorie);
                        await widget.refreshAllTasksEdit();
                        Navigator.of(context).pop(true);
                      }
                      //change nom et id
                      else if ((tache.nom != nom &&
                          tache.id_categorie != idCategorie)) {
                        await ModifierNomTache(tache.id, nom);
                        await ModifierGroupeCategorie(tache.id, idCategorie);
                        await widget.refreshAllTasksEdit();
                        Navigator.of(context).pop(true);
                      } else {
                        Navigator.of(context).pop(true);
                      }
                    }
                  },
                  child: Icon(
                    Icons.done,
                    size: 30,
                  )),
            ),
          ],
        ),
        body: Container(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(children: [
              Container(
                // nom tache
                height: 60,
                width: 390,
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400], width: 1.0),
                    borderRadius: BorderRadius.circular(13)),
                child: Row(children: [
                  SizedBox(
                    width: 10,
                  ),
                  Form(
                    key: _formKey,
                    child: Container(
                      padding: EdgeInsets.only(top: 5),
                      height: 60,
                      width: 300,
                      child: TextFormField(
                        controller: _controllerTextFieldTache,
                        //initialValue: tache.nom,
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.black,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                        ),
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
                  SizedBox(
                    width: 33,
                  ),
                  GestureDetector(
                    onTap: () {
                      // This function will be called when the cancel button is pressed
                      // You can clear the form by resetting the state and any necessary variables
                      setState(() {
                        _controllerTextFieldTache.clear();
                      });
                    },
                    child: Icon(
                      Icons.cancel,
                      size: 25,
                      color: Colors.grey,
                    ),
                  ),
                ]),
              ),
              SizedBox(
                height: 40,
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Project",
                    style: TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              Container(
                //nom du groupe
                height: 60,
                width: 390,
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400], width: 1.0),
                    borderRadius: BorderRadius.circular(13)),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Transform.scale(
                        scaleY: 1.5,
                        child: Icon(
                          Icons.folder_outlined,
                          size: 33,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    Container(
                      height: 60,
                      width: 320,
                      child: DropdownButtonFormField(
                        style: TextStyle(color: Colors.black, fontSize: 20),
                        value: idCategorie,
                        icon: Icon(Icons.arrow_drop_down),
                        decoration: InputDecoration(
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 10),
                            border: InputBorder.none),
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
                  ],
                ),
              )
            ]),
          ),

          //appbar

          // appBar: AppBar(
          //   title: Text("Edit"),
          //   centerTitle: true,
          //   flexibleSpace: Container(
          //     dpaddingecoration: const BoxDecoration(
          //       gradient: LinearGradient(
          //           begin: Alignment.topCenter,
          //           end: Alignment.bottomCenter,
          //           colors: [
          //             _color,
          //             _color1,
          //             _color2,
          //             _color3,
          //           ]),
          //     ),
          //   ),
          //   leadingWidth: 100,
          //   leading: Container(
          //       margin: const EdgeInsets.only(top: 15.0, bottom: 15.0),
          //       child: GestureDetector(
          //         onTap: () {
          //           Navigator.of(context).pop(true);
          //         },
          //         child: Icon(
          //           Icons.cancel,
          //           color: Colors.white,
          //         ),
          //       )),
          //   actions: [
          //     Container(
          //         margin:
          //             const EdgeInsets.only(top: 15.0, bottom: 15.0, right: 30.0),
          //         child: GestureDetector(
          //           onTap: () async {
          //             if (_formKey.currentState.validate()) {
          //               _formKey.currentState.save();
          //               print("this is id_categorie____$idCategorie");
          //               //change nom
          //               if (tache.nom != nom || tache.id_categorie == idCategorie) {
          //                 await ModifierNomTache(tache.id, nom);
          //                 widget.refreshAllTasksEdit();
          //                 Navigator.of(context).pop(true);
          //               }
          //               // change id(groupe)
          //               else if (tache.nom == nom ||
          //                   tache.id_categorie != idCategorie) {
          //                 await ModifierGroupeCategorie(tache.id, idCategorie);
          //                 widget.refreshAllTasksEdit();
          //                 Navigator.of(context).pop(true);
          //               }
          //               //change nom et id
          //               else if ((tache.nom != nom ||
          //                   tache.id_categorie != idCategorie)) {
          //                 await ModifierNomTache(tache.id, nom);
          //                 await ModifierGroupeCategorie(tache.id, idCategorie);
          //                 widget.refreshAllTasksEdit();
          //                 Navigator.of(context).pop(true);
          //               } else {
          //                 Navigator.of(context).pop(true);
          //               }
          //             }
          //           },
          //           child: Icon(
          //             //todo save
          //             Icons.save,
          //             color: Colors.white,
          //           ),
          //         ))
          //   ],
          // ),

//body

          // body: Container(
          //     child: Padding(
          //   padding: EdgeInsets.all(16),
          //   child: Column(children: [
          //     Container(
          //       decoration: BoxDecoration(
          //           border: Border.all(color: Colors.grey[400], width: 1.0),
          //           borderRadius: BorderRadius.circular(13)),
          //       child: Form(
          //         key: _formKey,
          //         child: Container(
          //           height: 50,
          //           width: 400,
          //           child: TextFormField(
          //             initialValue: tache.nom,
          //             decoration: InputDecoration(border: InputBorder.none),
          //             validator: (value) {
          //               if (value.isEmpty) {
          //                 return "Please enter a task name";
          //               }
          //               return null;
          //             },
          //             onSaved: (value) => nom = value,
          //             onFieldSubmitted: (value) {
          //               setState(() {
          //                 nom = value;
          //               });
          //             },
          //           ),
          //         ),
          //       ),
          //     ),
          //     //this
          //     SizedBox(
          //       height: 14,
          //     ),
          //     Row(
          //       children: [
          //         Padding(
          //           padding: const EdgeInsets.only(bottom: 6),
          //           child: Text(
          //             "Project",
          //             style: TextStyle(
          //               color: Colors.blueGrey,
          //               fontSize: 16,
          //             ),
          //           ),
          //         ),
          //       ],
          //     ),

          //DROP DOWN

          //     Container(
          //       decoration: BoxDecoration(
          //           border: Border.all(color: Colors.grey[400], width: 1.0),
          //           borderRadius: BorderRadius.circular(13)),
          //       child: DropdownButtonFormField(
          //         decoration: InputDecoration(
          //             border: InputBorder.none,
          //             hintStyle: TextStyle(
          //               fontSize: 30,
          //               fontWeight: FontWeight.bold,
          //             ),
          //             labelText: getCategorieNom(categories, tache.id_categorie),
          //             contentPadding: EdgeInsets.only(left: 8)
          //             //border: OutlineInputBorder(),
          //             ),
          //         items: categories
          //             .map((categorie) => DropdownMenuItem(
          //                 child: Padding(
          //                   padding: const EdgeInsets.only(left: 8),
          //                   child: Text(categorie.nom),
          //                 ),
          //                 value: categorie.id))
          //             .toList(),
          //         onChanged: (newValue) {
          //           setState(() {
          //             idCategorie = newValue;
          //           });
          //         },
          //       ),
          //     ),
          //   ]),
          // )),
        ));
  }
}
