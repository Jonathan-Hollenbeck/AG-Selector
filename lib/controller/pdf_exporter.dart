import 'dart:io';
import 'package:ag_selector/model/ag.dart';
import 'package:ag_selector/model/person.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';

class PdfExporter {
  String combineHouseAndClass(Person person){
    return "${person.house}${person.schoolClass}";
  }

  Future<String?> generatePdf(
      Map<Person, Map<String, AG>> selection, List<Person> persons) async {

    persons.sort((a, b) => combineHouseAndClass(a).compareTo(combineHouseAndClass(b)));
    
    Set<String> houses = {};
    for (Person person in persons) {
      houses.add(person.house);
    }
    
    Set<String> ags = {};
    for(Person person in selection.keys){
      for(String weekday in selection[person]!.keys){
        ags.add(selection[person]![weekday]!.name);
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

    for (String agName in ags) {
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
                        pw.Text(
                          "AG",
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 16.0, font: font),
                        ),
                      ]),
                      for (Person person in selection.keys)
                        for(String weekday in selection[person]!.keys)
                          if(selection[person]![weekday]!.name == agName)
                              pw.TableRow(
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
                                    pw.Text(
                                      selection[person]![weekday]!
                                          .name,
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
        return null;
      } else {
        return "Dateispeicherung nicht erlaubt! Dateistatus: ${storageStatus.toString()}";
      }
    } catch (e) {
      return e.toString();
    }
  }

  bool isPersonWithHouseNSchoolClassInPersons(
      List<Person> persons, String house, String schoolClass) {
    for (Person person in persons) {
      if (person.house == house && person.schoolClass == schoolClass) {
        return true;
      }
    }

    return false;
  }
}
