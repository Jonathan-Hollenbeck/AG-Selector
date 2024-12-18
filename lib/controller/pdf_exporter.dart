import 'dart:io';
import 'package:ag_selector/controller/persistence/persistence_manager.dart';
import 'package:ag_selector/model/ag.dart';
import 'package:ag_selector/model/person.dart';
import 'package:ag_selector/model/person_ag_preference.dart';
import 'package:ag_selector/model/selection_object.dart';
import 'package:ag_selector/util/string_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';

class PdfExporter {

  int agPdfColorCounter = 0;

  AG? getAgById(int id, List<AG> ags){
    for(AG ag in ags){
      if(ag.id == id){
        return ag;
      }
    }
    return null;
  }

  List<SelectionObject> getAllSelectionObjectsForPerson(Person person, List<SelectionObject> selection){
    return selection.where((so) => so.person.id == person.id).toList();
  }

  List<Person> getAllPersonsInSelection(List<SelectionObject> selection){
    List<Person> persons = [];
    for(SelectionObject selectionObject in selection){
      persons.add(selectionObject.person);
    }
    return persons;
  }

  Future<String?> generatePdf(
      List<SelectionObject> selection, List<Person> persons, List<AG> ags, PersistenceManager persistenceManager) async {

    List<Person> selectionPersons = getAllPersonsInSelection(selection);
    selectionPersons.sort((a, b) => StringUtils.combineHouseAndClass(a).compareTo(StringUtils.combineHouseAndClass(b)));

    agPdfColorCounter = 0;

    persons.sort((a, b) => StringUtils.combineHouseAndClass(a).compareTo(StringUtils.combineHouseAndClass(b)));

    Map<String, Map<int, int>> agPreferenceCounter = {};

    for(Person person in selectionPersons){
      List<PersonAgPreference> personAgPreferences = await persistenceManager.getPersonAgPreferences(person);
      for(PersonAgPreference personAgPreference in personAgPreferences){
        int agId = personAgPreference.ag.id;
        String weekday = personAgPreference.weekday;
        int preference = personAgPreference.preferenceNumber;
        if(preference == 1){
          if(!agPreferenceCounter.keys.contains(weekday)){
            agPreferenceCounter[weekday] = {};
          }
          if(!agPreferenceCounter[weekday]!.keys.contains(agId)){
            agPreferenceCounter[weekday]![agId] = 0;
          }
          agPreferenceCounter[weekday]![agId] = agPreferenceCounter[weekday]![agId]! + 1;
        }
      }
    }

    Set<String> houses = {};
    for (Person person in persons) {
      houses.add(person.house);
    }

    Map<int, Map<String, int>> agPersonCounter = {};
    Set<int> agIds = {};
    for (SelectionObject selectionObject in selection) {
      int agId = selectionObject.ag.id;
      String weekday = selectionObject.weekday;
      if(!agPersonCounter.keys.contains(agId)){
        agPersonCounter[agId] = {};
      }
      if(!agPersonCounter[agId]!.keys.contains(weekday)){
        agPersonCounter[agId]![weekday] = 0;
      }
      agPersonCounter[agId]![weekday] = agPersonCounter[agId]![weekday]! + 1;
      agIds.add(agId);
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
                        if (persons[i].house == house)
                          for(SelectionObject selectionObject in getAllSelectionObjectsForPerson(persons[i], selection))
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
                                    selectionObject.weekday,
                                    textAlign: pw.TextAlign.center,
                                    style: pw.TextStyle(font: font)
                                  ),
                                  pw.Text(
                                    selectionObject.ag.name,
                                    textAlign: pw.TextAlign.center,
                                    style: pw.TextStyle(font: font)
                                  ),
                                ])
                    ])),
                ]),
          );
    }

    final pdfAg = pw.Document();

    for (int agId in agIds) {
      AG? currentAG = getAgById(agId, ags);
      if(currentAG != null){
        for(String weekdayLoop in currentAG.weekdays){
          agPdfColorCounter = 0;
          pdfAg.addPage(
            pw.MultiPage(
              orientation: pw.PageOrientation.landscape,
                pageFormat: PdfPageFormat.a4,
                build: (context) => [
                    pw.Text(
                      "${currentAG.name} $weekdayLoop (${StringUtils.timeToString(currentAG.startTime.hour, currentAG.startTime.minute)} - ${StringUtils.timeToString(currentAG.endTime.hour, currentAG.endTime.minute)}) ${agPersonCounter[agId]![weekdayLoop]} Personen",
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
                            pw.Text("" , textAlign: pw.TextAlign.center),
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
                            pw.Text("______" , textAlign: pw.TextAlign.center),
                            pw.Text("______" , textAlign: pw.TextAlign.center),
                            pw.Text("______" , textAlign: pw.TextAlign.center),
                            pw.Text("______" , textAlign: pw.TextAlign.center),
                            pw.Text("______" , textAlign: pw.TextAlign.center),
                            pw.Text("______" , textAlign: pw.TextAlign.center),
                            pw.Text("______" , textAlign: pw.TextAlign.center),
                            pw.Text("______" , textAlign: pw.TextAlign.center),
                            pw.Text("______" , textAlign: pw.TextAlign.center),
                            pw.Text("______" , textAlign: pw.TextAlign.center),
                          ]),
                          for(SelectionObject selectionObject in selection)
                            if(selectionObject.ag.id == currentAG.id && selectionObject.weekday == weekdayLoop)
                              pw.TableRow(
                                decoration: pw.BoxDecoration(
                                  color: PdfColor(
                                    1.0 - (((agPdfColorCounter % 2) / 10) * 2),
                                    1.0 - (((agPdfColorCounter % 2) / 10) * 2),
                                    1.0 - (((agPdfColorCounter++ % 2) / 10) * 2))),
                                children: [
                                  pw.Text("$agPdfColorCounter" , textAlign: pw.TextAlign.center),
                                  pw.Text(selectionObject.person.name,
                                    textAlign: pw.TextAlign.center,
                                    style: pw.TextStyle(font: font)),
                                  pw.Text(
                                    selectionObject.person.schoolClass,
                                    textAlign: pw.TextAlign.center,
                                    style: pw.TextStyle(font: font)
                                  ),
                                  pw.Text(""),
                                  pw.Text(""),
                                  pw.Text(""),
                                  pw.Text(""),
                                  pw.Text(""),
                                  pw.Text(""),
                                  pw.Text(""),
                                  pw.Text(""),
                                  pw.Text(""),
                                  pw.Text(""),
                                ])
                        ])),
                    ]),
            );
        }
      }
    }

    final pdfTrend = pw.Document();

    for(String weekday in agPreferenceCounter.keys){
      pdfTrend.addPage(
        pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            build: (context) => [
                pw.Text(
                  weekday,
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
                          "AG",
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 16.0, font: font),
                        ),
                        pw.Text(
                          "Anzahl erste Präferenzen",
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 16.0, font: font),
                        ),
                        pw.Text(
                          "Vergebene Plätze",
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 16.0, font: font),
                        ),
                      ]),
                      for (int agId in agPreferenceCounter[weekday]!.keys)
                        if(getAgById(agId, ags) != null)
                          pw.TableRow(
                              children: [
                                pw.Text(
                                  getAgById(agId, ags)!.name,
                                  textAlign: pw.TextAlign.center,
                                  style: pw.TextStyle(font: font)
                                ),
                                pw.Text(
                                  "${agPreferenceCounter[weekday]![agId]!}",
                                  textAlign: pw.TextAlign.center,
                                  style: pw.TextStyle(font: font)
                                ),
                                pw.Text(
                                  "${agPersonCounter[agId]![weekday]}/${getAgById(agId, ags)!.maxPersons}",
                                  textAlign: pw.TextAlign.center,
                                  style: pw.TextStyle(font: font)
                                ),
                              ])
                    ])),
                ]),
          );
    }

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
