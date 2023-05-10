import 'dart:io';
import 'package:time_tracker_ter/model/InitDatabase.dart';
import 'package:csv/csv.dart';
import 'package:downloads_path_provider/downloads_path_provider.dart';
import 'package:flutter/material.dart';
import 'package:time_tracker_ter/model/InitDatabase.dart';
import 'package:time_tracker_ter/utilities/constants.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class ExportService {
  // Use in device app or remote smtp server
  static bool sendUsingLocalApp = true;

  // Use SQL columns for CSV
  static String csvColumns = '*';



  // Fetch data from database
  static Future<List> _getExportedData([categoryId]) async {
    // get database values;
    Database database = await InitDatabase().database;

    String query = '''
      SELECT $csvColumns FROM taches 
          JOIN categories ON categories.id = taches.id_categorie
    ''';

    if (categoryId != null) {
      query += " WHERE id_categorie = $categoryId;";
    }

    var rows = await database.rawQuery(query);

    if (rows.length == 0) {
      // Todo: add error handling
      throw Exception('No data to export');
    }

    List list = rows.map((e) => e.values.toList()).toList();
    list.insert(0, rows.first.keys);

    return list;
  }

  // Write data to CSV file
  static Future<String> _writeExportedData(List list) async {
    await Permission.storage.request();

    if (!await Permission.storage.isGranted) {
      throw Exception('Permission denied');
    }

    String output = ListToCsvConverter().convert(list);
    String dirPath = (await DownloadsPathProvider.downloadsDirectory).path;

    var date = DateTime.now();
    var formatter = new DateFormat('yyyy-MM-dd');
    var path = join(dirPath, 'export-${formatter.format(date)}.csv');

    try {
      File(path)
        ..createSync(recursive: true)
        ..writeAsStringSync(output, mode: FileMode.write);
    } catch (err) {
      // Protected folder fallback.
      dirPath = (await getApplicationDocumentsDirectory()).path;
      path = join(dirPath, 'export-${formatter.format(date)}.csv');

      File(path)
        ..createSync(recursive: true)
        ..writeAsStringSync(output);
    }

    return path;
  }

  // Send CSV file using app
  static _sendEmailLocalApp(String path, String email) {
    String fileName = basename(path);

    var message = Email(
        subject: 'Exported File - $fileName',
        attachmentPaths: [path],
        recipients: [email],
        isHTML: false,
        body: 'Exported file from app');

    FlutterEmailSender.send(message);
  }

  // Send CSV file using SMTP server
  static _sendEmailRemoteServer(String path, String email) async {
    String fileName = basename(path);
    final server = gmail(smtpUsername, smtpPassword);
    // final server = smtp_server(smtpUsername, smtpPassword);
    // final server = mailgun(smtpUsername, smtpPassword);
    // final server = sendgrid(smtpUsername, smtpPassword);

    final message = Message()
      ..from = Address(smtpUsername, smtpSenderName)
      ..recipients.add(email)
      ..subject = 'Exported File - $fileName'
      ..attachments.add(FileAttachment(File(path)));

    final sendReport = await send(message, server);
    print('Message sent: ' + sendReport.toString());
  }

  static void export(String email, {int categoryId}) async {
    try {
      var data = await _getExportedData(categoryId);
      var path = await _writeExportedData(data);

      if (sendUsingLocalApp) {
        _sendEmailLocalApp(path, email);
      } else {
        _sendEmailRemoteServer(path, email);
      }
    } catch (err) {
      showErrorMessage(err.toString());
      print(err);
    }
  }

  static Future<String> promptEmail(BuildContext context) async {
    TextEditingController c = TextEditingController();
    bool send = false;
    await showDialog(
        context: context,
        builder: (ctx) => SimpleDialog(
              title: Text('Export to Email'),
              contentPadding: EdgeInsets.all(20),
              children: [
                TextField(
                  controller: c,
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
                          send = true;
                          Navigator.of(context).pop();
                        },
                        child: Text('Exporter'))
                  ],
                )
              ],
            ));

    if (send == false) return null;

    return c.text;
  }
}
