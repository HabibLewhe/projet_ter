import 'package:flutter/material.dart';
import 'package:flutter_login_ui/screens/Home.dart';
import 'package:flutter_login_ui/model/InitDatabase.dart';

void main() async {
  // await InitDatabase().database;
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Login UI',
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
    );
  }
}
