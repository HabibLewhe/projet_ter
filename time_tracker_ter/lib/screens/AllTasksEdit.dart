//import 'dart:html';

import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_login_ui/screens/EditTask.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:page_transition/page_transition.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// import 'package:shared_preferences/shared_preferences.dart';

import '../model/Categorie.dart';
import '../model/InitDatabase.dart';
import '../model/Tache.dart';
import '../services/DatabaseService.dart';
import '../utilities/constants.dart';
import 'package:grouped_list/grouped_list.dart';

class AllTasksEdit extends StatefulWidget {
  @override
  _AllTasksEditState createState() => _AllTasksEditState();
}

class _AllTasksEditState extends State<AllTasksEdit> {
  List<dynamic> groupedData = [];
  final _formKey = GlobalKey<FormState>();
  String _newName;
  int _newCategoryId;
  List<Tache> taches = [];
  static const Color _color = Color.fromARGB(255, 61, 122, 255);
  static const Color _color1 = Color.fromARGB(255, 61, 148, 255);
  static const Color _color2 = Color.fromARGB(255, 41, 166, 255);
  static const Color _color3 = Color.fromARGB(255, 21, 177, 255);

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await getCategories();
    await getTaches();
    String path = await getDatabasesPath();
    path = join(path, 'data.db');
    Database db = await openDatabase(path);
    // await insertTaches(db, taches);
    groupedData = _buildGroupedData();
    setState(() {});
  }

  void refreshData() {
    setState(() {
      _initData();
    });
  }

  //INSERT to Tache
  Future<void> insertTaches(Database db, List<Tache> taches) async {
    final batch = db.batch();
    for (final tache in taches) {
      batch.insert('taches', {
        'id': tache.id,
        'nom': tache.nom,
        'couleur': tache.couleur,
        'temps_ecoule': tache.temps_ecoule.toIso8601String(),
        'id_categorie': tache.id_categorie
      });
    }
    await batch.commit();
  }

  //GET categorie from data
  List<Categorie> categories = [];
  void getCategories() async {
    Database database = await InitDatabase().database;
    //get id_user connected
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int id_user = prefs.getInt('userId');
    if (id_user != null) {
      var cats = await database.query('categories',
          //where email and password are equal to the email and password entered by the user
          where: 'id_categorie_sup = 1 AND id_user = ?',
          whereArgs: [id_user]);
      setState(() {
        categories = cats.map((e) => Categorie.fromMap(e)).toList();
      });
      //print all categories one by one
    }
  }

  void getTaches() async {
    Database database = await InitDatabase().database;
    List<Map<String, dynamic>> maps = await database.query('taches');
    setState(() {
      taches = maps.map((map) => Tache.fromMap(map)).toList();
    });

    //return tachesFromdata;
  }

  List<dynamic> _buildGroupedData() {
    final result = <dynamic>[];
    for (final categorie in categories) {
      // Get all tasks by given category.
      final tasksForCategory =
          taches.where((t) => t.id_categorie == categorie.id).toList();
      result.add({'name': categorie.nom, 'items': tasksForCategory});
    }
    print(result.toString());
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("All Tasks"),
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
                  Icons.dashboard,
                  color: Colors.white,
                ),
              )),
          actions: [
            Container(
                margin:
                    const EdgeInsets.only(top: 15.0, bottom: 15.0, right: 30.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop(true);
                  },
                  child: Icon(
                    Icons.done_all,
                    color: Colors.white,
                  ),
                ))
          ],
        ),
        body: GroupedListView<dynamic, String>(
            useStickyGroupSeparators: true,
            elements: groupedData,
            groupBy: (element) => element['name'],
            groupSeparatorBuilder: (value) => Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.blue,
                  child: Text(
                    value,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                ),
            itemBuilder: (context, dynamic item) => Card(
                  child: Column(
                    children: [
                      ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: item['items'].length,
                          itemBuilder: (ctx, index) {
                            final task = item['items'][index];
                            return ListTile(
                              title: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      //DETELE TACHE
                                      showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title:
                                                  Text('Delete Confirmation'),
                                              content: Text(
                                                  'Are you sure you want to delete this task?'),
                                              actions: [
                                                TextButton(
                                                  child: const Text('Cancel'),
                                                  onPressed: () {
                                                    Navigator.of(context)
                                                        .pop(); //Dismiss Dialog
                                                  },
                                                ),
                                                ElevatedButton(
                                                  onPressed: () async {
                                                    Navigator.of(context)
                                                        .pop(); //Dismiss Dialog
                                                    setState(() {
                                                      DeleteTache(task.id);
                                                      refreshData();
                                                    });
                                                  },
                                                  child: const Text('Delete'),
                                                ),
                                              ],
                                            );
                                          });
                                    },
                                    child: Icon(
                                      Icons.delete_sharp,
                                      color: Colors.blueGrey,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 18,
                                  ),
                                  Expanded(
                                    child: Text(task.nom),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => EditTask(
                                              task, categories, refreshData),
                                        ),
                                      );
                                    },
                                    child: Icon(
                                      Icons.create,
                                      color: Colors.blueGrey,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          })
                    ],
                  ),
                )));
  }
}