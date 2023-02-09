import 'package:flutter/material.dart';
import 'Categories.dart';
import 'Taches.dart';
import 'package:fluttertoast/fluttertoast.dart';
final cate1 = Categories("Categorie 1", 0, 0, 0, null,null);
final cate2 = Categories("Categorie 2", 0, 0, 0, null,null);
final cate3 = Categories("Categorie 3", 0, 0, 0, null,null);

List<Categories> listeCategories = [cate1,cate2,cate3];
late Categories selectedCategorie;
late Taches selectedTache;

//int idCateCounter=0;
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text("Time Tracker"),
          ),
          body: Center(
            child: Column(
              children: <Widget>[
                MaterialButton(
                  child: Text("New Project"),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CreerCategorie()),
                    );
                  },
                  color: Colors.red,
                ),
                Container(
                  height: 300.0,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: listeCategories.length,
                    itemBuilder: (BuildContext context,int index){
                      return ListTile(
                        title:Text('${listeCategories[index].nomCategorie}'),
                        onTap: (){

                          selectedCategorie = listeCategories[index];
                          //String nomSelectedCate=selectedCategorie.nomCategorie;
                          print("selected categorie = $selectedCategorie");
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => GestionCateGorie()),
                          );
                        },
                      );
                      // return Container(
                      //   child: Center(child: Text('Entry ${listeCategories[index].nomCategorie}')),
                      // );
                    },
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
class GestionCateGorie extends StatelessWidget{
  String nomSelectedCate=selectedCategorie.nomCategorie;
  List<Taches>? listTaches = selectedCategorie.listTaches;
  List<Categories>? listSouCategories= selectedCategorie.listSousCategories;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("$nomSelectedCate"),
        actions: <Widget>[
          MaterialButton(
            child: Text("Edit"),
            onPressed: () {
              print("Click on EDIT");
            },
            color: Colors.blue,
          ),
        ],
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            Container(
              height: 300.0,
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: listSouCategories?.length,
                itemBuilder: (BuildContext context,int index){
                  if(listSouCategories!=null){
                    return ListTile(
                      title:Text('${listeCategories[index].nomCategorie}'),
                      onTap: (){

                        selectedCategorie = listeCategories[index];
                        //String nomSelectedCate=selectedCategorie.nomCategorie;
                        print("selected categorie = $selectedCategorie");
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => GestionCateGorie()),
                        );
                      },
                    );

                  }
                  else{
                    return Text(
                      "there is no task",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    );
                  };

                },
              ),
            )

          ],
        ),
      ),
    );
  }


}
class CreerCategorie extends StatelessWidget {
  final nomCategorieController = TextEditingController();
  // late List<Categories> listeCategories;
  // int idCateCounter=0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("New Categorie"),
        actions:<Widget> [
          MaterialButton(
            child: Text("Save"),
            onPressed: () {
              var contentNomCate = Text(nomCategorieController.text);
              print(contentNomCate.toString());
              if(contentNomCate.toString() != ""){
                final newCate = Categories(contentNomCate.toString(), 0, 0, 0, null,null);
                print(newCate.toString());

              }
            },
            color: Colors.blue,
          ),
        ],
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            TextFormField(
              controller: nomCategorieController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Enter new category's name "
              ),
            ),
          ],
        ),
      ),
    );
  }

}

void removeCategories(List<Categories> listeCate,String nomCategorie){
  for(int i=0;i<listeCate.length;i++){
    if(listeCate[i].nomCategorie==nomCategorie){
      listeCate.removeAt(i);
      break;
    }
    else{
      print("erreur, can't find this object in listCategories");
    }
    
  }
}


// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key, required this.title});
//
//   // This widget is the home page of your application. It is stateful, meaning
//   // that it has a State object (defined below) that contains fields that affect
//   // how it looks.
//
//   // This class is the configuration for the state. It holds the values (in this
//   // case the title) provided by the parent (in this case the App widget) and
//   // used by the build method of the State. Fields in a Widget subclass are
//   // always marked "final".
//
//   final String title;
//
//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }
//
// class _MyHomePageState extends State<MyHomePage> {
//   int _counter = 0;
//
//   void _incrementCounter() {
//     setState(() {
//       // This call to setState tells the Flutter framework that something has
//       // changed in this State, which causes it to rerun the build method below
//       // so that the display can reflect the updated values. If we changed
//       // _counter without calling setState(), then the build method would not be
//       // called again, and so nothing would appear to happen.
//       _counter++;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // This method is rerun every time setState is called, for instance as done
//     // by the _incrementCounter method above.
//     //
//     // The Flutter framework has been optimized to make rerunning build methods
//     // fast, so that you can just rebuild anything that needs updating rather
//     // than having to individually change instances of widgets.
//     return Scaffold(
//       appBar: AppBar(
//         // Here we take the value from the MyHomePage object that was created by
//         // the App.build method, and use it to set our appbar title.
//         title: Text(widget.title),
//       ),
//       body: Center(
//         // Center is a layout widget. It takes a single child and positions it
//         // in the middle of the parent.
//         child: Column(
//           // Column is also a layout widget. It takes a list of children and
//           // arranges them vertically. By default, it sizes itself to fit its
//           // children horizontally, and tries to be as tall as its parent.
//           //
//           // Invoke "debug painting" (press "p" in the console, choose the
//           // "Toggle Debug Paint" action from the Flutter Inspector in Android
//           // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
//           // to see the wireframe for each widget.
//           //
//           // Column has various properties to control how it sizes itself and
//           // how it positions its children. Here we use mainAxisAlignment to
//           // center the children vertically; the main axis here is the vertical
//           // axis because Columns are vertical (the cross axis would be
//           // horizontal).
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             const Text(
//               'You have pushed the button this many times:',
//             ),
//             Text(
//               '$_counter',
//               style: Theme.of(context).textTheme.headline4,
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _incrementCounter,
//         tooltip: 'Increment',
//         child: const Icon(Icons.add),
//       ), // This trailing comma makes auto-formatting nicer for build methods.
//     );
//   }
// }
