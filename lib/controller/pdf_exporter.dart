import 'dart:io';
import 'package:ag_selector/controller/persistence/persistence_manager.dart';
import 'package:ag_selector/model/ag.dart';
import 'package:ag_selector/model/person.dart';
import 'package:ag_selector/model/person_ag_preference.dart';
import 'package:ag_selector/util/string_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';

class PdfExporter {

  int agPdfColorCounter = 0;

  bool checkInsertRowIntoAgPDF(Map<Person, Map<String, AG>> selection, Person person, String weekday, String agName, String weekdayLoop){
    if(checkIfPersonInAg(selection, person, weekday, agName) == true && weekday == weekdayLoop){
      agPdfColorCounter++;
      return true;
    }
    return false;
  }

  bool checkIfPersonInAg(Map<Person, Map<String, AG>> selection, Person person, String weekday, String agName){
    if(selection[person]![weekday]!.name == agName){
      return true;
    }
    return false;
  }

  String combineHouseAndClass(Person person){
    return "${person.schoolClass}${person.house}";
  }

  AG? getAgById(int id, List<AG> ags){
    for(AG ag in ags){
      if(ag.id == id){
        return ag;
      }
    }
    return null;
  }

  Future<String?> generatePdf(
      Map<Person, Map<String, AG>> selection, List<Person> persons, List<AG> ags, PersistenceManager persistenceManager) async {

    agPdfColorCounter = 0;

    persons.sort((a, b) => combineHouseAndClass(a).compareTo(combineHouseAndClass(b)));

    List<Person> selectionKeysSorted = selection.keys.toList();
    selectionKeysSorted.sort((a, b) => combineHouseAndClass(a).compareTo(combineHouseAndClass(b)));

    Map<int, Map<String, int>> agPreferenceCounter = {};

    for(Person person in selection.keys){
      List<PersonAgPreference> personAgPreferences = await persistenceManager.getPersonAgPreferences(person);
      for(PersonAgPreference personAgPreference in personAgPreferences){
        int agId = personAgPreference.ag.id;
        String weekday = personAgPreference.weekday;
        int preference = personAgPreference.preferenceNumber;
        if(preference == 1){
          if(!agPreferenceCounter.keys.contains(agId)){
            agPreferenceCounter[agId] = {};
          }
          if(!agPreferenceCounter[agId]!.keys.contains(weekday)){
            agPreferenceCounter[agId]![weekday] = 0;
          }
          agPreferenceCounter[agId]![weekday] = agPreferenceCounter[agId]![weekday]! + 1;
        }
      }
    }

    Set<String> houses = {};
    for (Person person in persons) {
      houses.add(person.house);
    }

    Map<int, Map<String, int>> agPersonCounter = {};
    Set<int> agIds = {};
    for (Person person in selection.keys) {
      for(String weekday in selection[person]!.keys){
        int agId = selection[person]![weekday]!.id;
        if(!agPersonCounter.keys.contains(agId)){
          agPersonCounter[agId] = {};
        }
        if(!agPersonCounter[agId]!.keys.contains(weekday)){
          agPersonCounter[agId]![weekday] = 0;
        }
        agPersonCounter[agId]![weekday] = agPersonCounter[agId]![weekday]! + 1;
        agIds.add(agId);
      }
    }
    print(agPreferenceCounter.keys.length);
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
                          for (Person person in selectionKeysSorted)
                            for(String weekday in selection[person]!.keys)
                              if(checkInsertRowIntoAgPDF(selection, person, weekday, currentAG.name, weekdayLoop))
                                  pw.TableRow(
                                      decoration: pw.BoxDecoration(
                                          color: PdfColor(
                                              1.0 - (((agPdfColorCounter % 2) / 10) * 2),
                                              1.0 - (((agPdfColorCounter % 2) / 10) * 2),
                                              1.0 - (((agPdfColorCounter % 2) / 10) * 2))),
                                      children: [
                                        pw.Text("$agPdfColorCounter" , textAlign: pw.TextAlign.center),
                                        pw.Text(person.name,
                                            textAlign: pw.TextAlign.center,
                                            style: pw.TextStyle(font: font)),
                                        pw.Text(
                                          person.schoolClass,
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
                    for (int agId in agPreferenceCounter.keys)
                      for(String weekday in agPreferenceCounter[agId]!.keys)
                        if(getAgById(agId, ags) != null)
                          pw.TableRow(
                              children: [
                                pw.Text(getAgById(agId, ags)!.name,
                                    textAlign: pw.TextAlign.center,
                                    style: pw.TextStyle(font: font)),
                                pw.Text(
                                  weekday,
                                  textAlign: pw.TextAlign.center,
                                  style: pw.TextStyle(font: font)
                                ),
                                pw.Text(
                                  "${agPreferenceCounter[agId]![weekday]!}",
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
