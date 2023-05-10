import 'dart:io';
import 'package:time_tracker_ter/model/InitDatabase.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../model/Categorie.dart';
import '../model/Tache.dart';

class ExportService {

  // Use in device app or remote smtp server
  static bool sendUsingLocalApp = true;
  TextEditingController mail = TextEditingController();


  /**
   * fonction qui envoi un mail avec le fichier csv en pièce jointe
   */
  Future<void> sendEmailWithAttachment(String filePath,String recipient) async {
    //configurer le serveur smtp avec les identifiants de l'adresse gmail : timetrucker5
    //le mot de passe est généré par google (2 étapes de vérification)
    final smtpServer = gmail('timetrucker5@gmail.com', 'vommpnzpffrxxsio');

    //Création du message
    final message = Message()
      ..from = Address('timetrucker5@gmail.com', 'Time Trucker') //expéditeur
      ..recipients.add(recipient) //destinataire
      ..subject = 'Export Time Trucker CSV' //sujet
      ..text = 'Export Time Trucker CSV' //texte
      ..attachments.add(FileAttachment(File(filePath)));

    try {
      //envoi du message
      final sendReport = await send(message, smtpServer);
      //
      print('Message sent: ' + sendReport.toString());
    } on MailerException catch (e) {
      //si le message n'a pas été envoyé, on affiche les problèmes
      print('Message not sent. \n'+ e.toString());
      for (var p in e.problems) {
        print('Problem: ${p.code}: ${p.msg}');
      }
    }
  }

  /**
   * fonction qui exporte les données de la base de données dans un fichier csv
   */
  Future<void> exportAndEmail(String recipient) async {
    // avoir instance de la base de données
    Database db = await InitDatabase().database;
    // avoir toutes les catégories
    List<Map> categories = await db.rawQuery('SELECT * FROM categories');

    // Create a List of List of dynamic data
    List<List<dynamic>> csvData = [];
    // Ajouter les entêtes
    csvData.add([
      'N°',
      'categorie',
      'temps_ecoule',
    ]);

    //parcourir les catégories
    for (var index = 0;  index < categories.length; index++) {
      //créer une instance de la catégorie
      Categorie category = Categorie.fromMap(categories[index]);
      //ajouter les données de la catégorie dans le fichier csv
      csvData.add([
        index+1,
        category.nom,
        category.temps_ecoule,
      ]);
      //avoir toutes les taches de la catégorie
      List<Map> tasks = await db.rawQuery('SELECT * FROM taches WHERE id_categorie = ?', [category.id]);
      //parcourir les taches
      for (var taskIndex = 0; taskIndex < tasks.length; taskIndex++) {
        //créer une instance de la tache
        Tache task = Tache.fromMap(tasks[taskIndex]);
        //ajouter les données de la tache dans le fichier csv
        csvData.add([
          '', //laisser un espace vide pour le numéro de la catégorie
          taskIndex+1,
          task.nom,
          task.temps_ecoule,
        ]);
      }
    }

    String csv = const ListToCsvConverter().convert(csvData);

    // Get the documents directory path
    final dir = await getApplicationDocumentsDirectory();
    // Create a file within the directory
    final file = File('${dir.path}/TimeTrucker.csv');
    // Write the CSV data into the file
    await file.writeAsString(csv);
    await sendEmailWithAttachment(file.path,recipient);
  }


  //fonction qui affiche une boite de dialogue pour entrer l'adresse mail
  Future<void> promptEmail(BuildContext context) async {
    bool send = false;
    await showDialog(
        context: context,
        builder: (ctx) => SimpleDialog(
              title: Text('Export to Email'),
              contentPadding: EdgeInsets.all(20),
              children: [
                TextField(
                  controller: mail,
                  decoration: InputDecoration(
                      hintText: 'example@example.com', labelText: 'Email'),
                ),
                SizedBox(
                  height: 20,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('Annuler')),
                    ElevatedButton(
                        onPressed: () {
                          exportAndEmail(mail.text);
                          Navigator.of(context).pop();
                        },
                        child: Text('Exporter'))
                  ],
                )
              ],
            ));
  }
}
