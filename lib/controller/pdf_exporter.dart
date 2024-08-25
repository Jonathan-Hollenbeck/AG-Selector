import 'dart:io';
import 'package:ag_selector/model/ag.dart';
import 'package:ag_selector/model/person.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';

class PdfExporter {
  Future<bool> generatePdf(
      Map<Person, Map<String, AG>> selection, List<Person> persons) async {
    Set<String> houses = {};
    for (Person person in persons) {
      houses.add(person.house);
    }

    Set<String> classes = {};
    for (Person person in persons) {
      classes.add(person.schoolClass);
    }

    persons.sort((a, b) => a.house.compareTo(b.house));

    final pdf = pw.Document();

    for (String house in houses) {
      for (String schoolClass in classes) {
        if (isPersonWithHouseNSchoolClassInPersons(
            persons, house, schoolClass)) {
          pdf.addPage(
            pw.MultiPage(
                pageFormat: PdfPageFormat.a4,
                build: (context) => [
                      pw.Text(
                        "$house $schoolClass",
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 20.0),
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
                                    fontSize: 16.0),
                              ),
                              pw.Text(
                                "Wochentag",
                                textAlign: pw.TextAlign.center,
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 16.0),
                              ),
                              pw.Text(
                                "AG",
                                textAlign: pw.TextAlign.center,
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 16.0),
                              ),
                            ]),
                            for (int i = 0; i < persons.length; i++)
                              if (persons[i].house == house &&
                                  persons[i].schoolClass == schoolClass &&
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
                                              textAlign: pw.TextAlign.center),
                                          pw.Text(
                                            weekday,
                                            textAlign: pw.TextAlign.center,
                                          ),
                                          pw.Text(
                                            selection[persons[i]]![weekday]!
                                                .name,
                                            textAlign: pw.TextAlign.center,
                                          ),
                                        ])
                          ])),
                    ]),
          );
        }
      }
    }
    try {
      final storageStatus = await Permission.storage.request();

      if (storageStatus.isGranted) {
        //Permission granted, proceed with saving the file
        final Directory documentsDirectory =
            await getApplicationDocumentsDirectory();

        final file = File("${documentsDirectory.path}/AG_Selection.pdf");
        await file.writeAsBytes(await pdf.save());
        return true;
      }
    } catch (e) {
      return false;
    }
    return false;
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
