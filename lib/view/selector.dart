import 'package:ag_selector/controller/create_selection.dart';
import 'package:ag_selector/controller/pdf_exporter.dart';
import 'package:ag_selector/controller/persistence/persistence_manager.dart';
import 'package:ag_selector/model/ag.dart';
import 'package:ag_selector/model/person.dart';
import 'package:ag_selector/model/settings.dart';
import 'package:flutter/material.dart';

class Selector extends StatefulWidget {
  final PersistenceManager persistenceManager;

  const Selector({super.key, required this.persistenceManager});

  @override
  State<Selector> createState() => _SelectorListState();
}

class _SelectorListState extends State<Selector> {
  Map<Person, Map<String, AG>> selection = <Person, Map<String, AG>>{};

  CreateSelection createSelection = CreateSelection();

  Settings settings = Settings(Settings.defaultNumberOfPreferences);

  List<Person> persons = [];
  List<AG> ags = [];

  PdfExporter pdfExporter = PdfExporter();

  Set<String> filterHouseSet = {};
  Set<String> filterSchoolClassSet = {};
  Set<String> filterWeekdaySet = {};
  Set<String> filterAGSet = {};

  String filterHouse = "Haus";
  String filterSchoolClass = "Klasse";
  String filterWeekday = "Wochentag";
  String filterAG = "AG";

  bool isInSelection(Person person, String weekday) {
    if (selection.keys.contains(person)) {
      if (selection[person]!.keys.contains(weekday)) {
        return true;
      }
    }
    return false;
  }

  void createSelectionForPersons() async {
    selection = await createSelection.createSelection(
        widget.persistenceManager, persons, ags, settings.numberOfPreferences, context);
    setState(() {
      for (Person person in selection.keys) {
        for (String weekday in selection[person]!.keys) {
          filterWeekdaySet.add(weekday);
        }
      }
      filterWeekdaySet.add("Wochentag");
    });
    persons.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  @override
  void initState() {
    super.initState();

    reloadPersons();
    reloadAgs();
    reloadSettings();
    setState(() {
      filterWeekdaySet.add("Wochentag");
    });
  }

  void reloadAgs() async {
    ags = await widget.persistenceManager.loadAgs();
    filterAGSet.add("AG");
    for (AG ag in ags) {
      filterAGSet.add(ag.name);
    }
    setState(() {});
  }

  void reloadPersons() async {
    persons = await widget.persistenceManager.loadPersons();
    filterHouseSet.add("Haus");
    filterSchoolClassSet.add("Klasse");
    for (Person person in persons) {
      filterHouseSet.add(person.house);
      filterSchoolClassSet.add(person.schoolClass);
    }
    setState(() {});
  }

  void reloadSettings() async {
    settings = await widget.persistenceManager.loadSettings();
    setState(() {});
  }

  void savePDF() async {
    final String? success = await pdfExporter.generatePdf(selection, persons, ags, widget.persistenceManager);
    if (success == null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('PDF speichern'),
            content: const Text('PDF erfolgreich gespeichert.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('PDF speichern'),
            content: Text('Fehler beim speichern des PDFs:\n$success'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        title: const Text("Wähler"),
      ),
      body: Form(
          child: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      createSelectionForPersons();
                    },
                    child: const Text(
                      "Selektionsvorschlag generieren",
                      style: TextStyle(fontSize: 16.0),
                    ),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      savePDF();
                    },
                    child: const Text(
                      "Pdf exportieren",
                      style: TextStyle(fontSize: 16.0),
                    ),
                  ),
                ),
              ],
            ),
            Table(
              border: TableBorder.all(),
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                TableRow(children: [
                  const Text(
                    "Person",
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                  ),
                  DropdownButton(
                    value: filterHouse,
                    items: filterHouseSet
                        .map<DropdownMenuItem<String>>(
                          (String value) => DropdownMenuItem(
                              value: value, child: Text(value)),
                        )
                        .toList(),
                    onChanged: (String? value) {
                      if (value != null) {
                        setState(() {
                          filterHouse = value;
                        });
                      }
                    },
                  ),
                  DropdownButton(
                    value: filterSchoolClass,
                    items: filterSchoolClassSet
                        .map<DropdownMenuItem<String>>(
                          (String value) => DropdownMenuItem(
                              value: value, child: Text(value)),
                        )
                        .toList(),
                    onChanged: (String? value) {
                      if (value != null) {
                        setState(() {
                          filterSchoolClass = value;
                        });
                      }
                    },
                  ),
                  DropdownButton(
                    value: filterWeekday,
                    items: filterWeekdaySet
                        .map<DropdownMenuItem<String>>(
                          (String value) => DropdownMenuItem(
                              value: value, child: Text(value)),
                        )
                        .toList(),
                    onChanged: (String? value) {
                      if (value != null) {
                        setState(() {
                          filterWeekday = value;
                        });
                      }
                    },
                  ),
                  DropdownButton(
                    value: filterAG,
                    items: filterAGSet
                        .map<DropdownMenuItem<String>>(
                          (String value) => DropdownMenuItem(
                              value: value, child: Text(value)),
                        )
                        .toList(),
                    onChanged: (String? value) {
                      if (value != null) {
                        setState(() {
                          filterAG = value;
                        });
                      }
                    },
                  ),
                ]),
                for (int i = 0; i < persons.length; i++)
                  if (selection[persons[i]] != null &&
                      (filterHouse == "Haus" || filterHouse == persons[i].house) &&
                      (filterSchoolClass == "Klasse" ||
                          filterSchoolClass == persons[i].schoolClass))
                    for (String weekday in persons[i].weekdaysPresent)
                      if (isInSelection(persons[i], weekday) == true &&
                          (filterWeekday == "Wochentag" ||
                              filterWeekday == weekday) &&
                          (filterAG == "AG" ||
                              filterAG == selection[persons[i]]![weekday]!.name))
                        TableRow(
                          decoration: BoxDecoration(
                              color:
                                Color.fromARGB(
                                  (i % 2) * 255,
                                  192,
                                  192,
                                  192
                              )
                            ),
                          children: [
                            Text(persons[i].name),
                            Text(persons[i].house),
                            Text(persons[i].schoolClass),
                            Text(weekday),
                            Text(selection[persons[i]]![weekday]!.name),
                            /**DropdownButton(
                              value: selection[persons[i]]![weekday],
                              items: ags
                                  .map<DropdownMenuItem<AG>>(
                                    (AG ag) => DropdownMenuItem(
                                        value: ag, child: Text(ag.name)),
                                  )
                                  .toList(),
                              onChanged: (AG? ag) {
                                setState(() {
                                  if (selection[persons[i]] != null) {
                                    selection[persons[i]]![weekday] = ag!;
                                  }
                                });
                              },
                            ),**/
                        ])
              ],
            ),
          ],
        ),
      )),
    );
  }
}
