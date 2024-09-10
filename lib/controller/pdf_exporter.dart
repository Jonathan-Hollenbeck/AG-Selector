import 'dart:io';
import 'package:ag_selector/controller/persistence/persistence_manager.dart';
import 'package:ag_selector/model/ag.dart';
import 'package:ag_selector/model/person.dart';
import 'package:ag_selector/model/person_ag_preference.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';

class PdfExporter {

  int agPdfColorCounter = 0;

  bool checkIfPersonInAg(Map<Person, Map<String, AG>> selection, Person person, String weekday, String agName){
    if(selection[person]![weekday]!.name == agName){
      agPdfColorCounter++;
      return true;
    }
    return false;
  }

  String combineHouseAndClass(Person person){
    return "${person.schoolClass}${person.house}";
  }

  Future<String?> generatePdf(
      Map<Person, Map<String, AG>> selection, List<Person> persons, PersistenceManager persistenceManager) async {

    agPdfColorCounter = 0;

    persons.sort((a, b) => combineHouseAndClass(a).compareTo(combineHouseAndClass(b)));

    List<Person> selectionKeysSorted = selection.keys.toList();
    selectionKeysSorted.sort((a, b) => combineHouseAndClass(a).compareTo(combineHouseAndClass(b)));

    Map<String, Map<String, int>> agPreferenceCounter = {};

    for(Person person in selection.keys){
      List<PersonAgPreference> personAgPreferences = await persistenceManager.getPersonAgPreferences(person);
      for(PersonAgPreference personAgPreference in personAgPreferences){
        String agName = personAgPreference.ag.name;
        String weekday = personAgPreference.weekday;
        int preference = personAgPreference.preferenceNumber;
        if(preference == 1){
          if(!agPreferenceCounter.keys.contains(agName)){
            agPreferenceCounter[agName] = {};
          }
          if(!agPreferenceCounter[agName]!.keys.contains(weekday)){
            agPreferenceCounter[agName]![weekday] = 0;
          }
          agPreferenceCounter[agName]![weekday] = agPreferenceCounter[agName]![weekday]! + 1;
        }
      }
    }

    Set<String> houses = {};
    for (Person person in persons) {
      houses.add(person.house);
    }

    Set<String> agNames = {};
    for (Person person in selection.keys) {
      for(String weekday in selection[person]!.keys){
        agNames.add(selection[person]![weekday]!.name);
      }
    }

    final font = pw.Font.helvetica();

    final pdfHouse = pw.Document();

    for (String house in houses) {
      pdfHouse.addPage(
        pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            build: (context) => [
                pw.Text(
                  house,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 20.0, font: font),
                ),
                pw.Center(
                    child: pw.Table(
                        border: pw.TableBorder.all(),
                        defaultVerticalAlignment:
                            pw.TableCellVerticalAlignment.middle,
                        children: [
                      pw.TableRow(children: [
                        pw.Text(
                          "Person",
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 16.0, font: font),
                        ),
                        pw.Text(
                          "Klasse",
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 16.0, font: font),
                        ),
                        pw.Text(
                          "Wochentag",
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 16.0, font: font),
                        ),
                        pw.Text(
                          "AG",
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 16.0, font: font),
                        ),
                      ]),
                      for (int i = 0; i < persons.length; i++)
                        if (persons[i].house == house &&
                            selection[persons[i]] != null)
                          for (String weekday
                              in persons[i].weekdaysPresent)
                            if (selection[persons[i]]!
                                    .keys
                                    .contains(weekday) ==
                                true)
                              pw.TableRow(
                                  decoration: pw.BoxDecoration(
                                      color: PdfColor(
                                          1.0 - (((i % 2) / 10) * 2),
                                          1.0 - (((i % 2) / 10) * 2),
                                          1.0 - (((i % 2) / 10) * 2))),
                                  children: [
                                    pw.Text(persons[i].name,
                                        textAlign: pw.TextAlign.center,
                                        style: pw.TextStyle(font: font)),
                                    pw.Text(
                                      persons[i].schoolClass,
                                      textAlign: pw.TextAlign.center,
                                      style: pw.TextStyle(font: font)
                                    ),
                                    pw.Text(
                                      weekday,
                                      textAlign: pw.TextAlign.center,
                                      style: pw.TextStyle(font: font)
                                    ),
                                    pw.Text(
                                      selection[persons[i]]![weekday]!
                                          .name,
                                      textAlign: pw.TextAlign.center,
                                      style: pw.TextStyle(font: font)
                                    ),
                                  ])
                    ])),
                ]),
          );
    }

    final pdfAg = pw.Document();

    for (String agName in agNames) {
      pdfAg.addPage(
        pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            build: (context) => [
                pw.Text(
                  agName,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 20.0, font: font),
                ),
                pw.Center(
                    child: pw.Table(
                        border: pw.TableBorder.all(),
                        defaultVerticalAlignment:
                            pw.TableCellVerticalAlignment.middle,
                        children: [
                      pw.TableRow(children: [
                        pw.Text(
                          "Person",
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 16.0, font: font),
                        ),
                        pw.Text(
                          "Klasse",
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 16.0, font: font),
                        ),
                        pw.Text(
                          "Wochentag",
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 16.0, font: font),
                        ),
                      ]),
                      for (Person person in selectionKeysSorted)
                        for(String weekday in selection[person]!.keys)
                          if(checkIfPersonInAg(selection, person, weekday, agName))
                              pw.TableRow(
                                  decoration: pw.BoxDecoration(
                                      color: PdfColor(
                                          1.0 - (((agPdfColorCounter % 2) / 10) * 2),
                                          1.0 - (((agPdfColorCounter % 2) / 10) * 2),
                                          1.0 - (((agPdfColorCounter % 2) / 10) * 2))),
                                  children: [
                                    pw.Text(person.name,
                                        textAlign: pw.TextAlign.center,
                                        style: pw.TextStyle(font: font)),
                                    pw.Text(
                                      person.schoolClass,
                                      textAlign: pw.TextAlign.center,
                                      style: pw.TextStyle(font: font)
                                    ),
                                    pw.Text(
                                      weekday,
                                      textAlign: pw.TextAlign.center,
                                      style: pw.TextStyle(font: font)
                                    ),
                                  ])
                    ])),
                ]),
          );
    }

    final pdfTrend = pw.Document();

    pdfTrend.addPage(
      pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
              pw.Center(
                  child: pw.Table(
                      border: pw.TableBorder.all(),
                      defaultVerticalAlignment:
                          pw.TableCellVerticalAlignment.middle,
                      children: [
                    pw.TableRow(children: [
                      pw.Text(
                        "AG",
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 16.0, font: font),
                      ),
                      pw.Text(
                        "Wochentag",
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 16.0, font: font),
                      ),
                      pw.Text(
                        "Anzahl Präferenzen",
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 16.0, font: font),
                      ),
                    ]),
                    for (String agName in agPreferenceCounter.keys)
                      for(String weekday in agPreferenceCounter[agName]!.keys)
                          pw.TableRow(
                              children: [
                                pw.Text(agName,
                                    textAlign: pw.TextAlign.center,
                                    style: pw.TextStyle(font: font)),
                                pw.Text(
                                  weekday,
                                  textAlign: pw.TextAlign.center,
                                  style: pw.TextStyle(font: font)
                                ),
                                pw.Text(
                                  "${agPreferenceCounter[agName]![weekday]!}",
                                  textAlign: pw.TextAlign.center,
                                  style: pw.TextStyle(font: font)
                                ),
                              ])
                  ])),
              ]),
        );


    try {
      PermissionStatus storageStatus = PermissionStatus.granted;
      if(Platform.isAndroid){
        //Android Version <11
        storageStatus = await Permission.storage.status;
        if (!storageStatus.isGranted) {
          storageStatus = await Permission.storage.request();
          //Android Version >11
          if (!storageStatus.isGranted) {
            storageStatus = await Permission.manageExternalStorage.status;
            if (!storageStatus.isGranted) {
              storageStatus = await Permission.manageExternalStorage.request();
            }
          }
        }
      }

      if (storageStatus.isGranted || Platform.isLinux) {
        //Permission granted, proceed with saving the file
        final String? selectedDirectory =
            await FilePicker.platform.getDirectoryPath();

        final filePersons = File("$selectedDirectory/AG_Selection_Persons.pdf");
        await filePersons.writeAsBytes(await pdfHouse.save());

        final fileAgs = File("$selectedDirectory/AG_Selection_Ags.pdf");
        await fileAgs.writeAsBytes(await pdfAg.save());

        final fileTrend = File("$selectedDirectory/AG_Trend.pdf");
        await fileTrend.writeAsBytes(await pdfTrend.save());
        return null;
      } else {
        return "Dateispeicherung nicht erlaubt! Dateistatus: ${storageStatus.toString()}";
      }
    } catch (e) {
      return e.toString();
    }
  }
}
