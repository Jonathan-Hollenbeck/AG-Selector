import 'package:ag_selector/controller/create_selection.dart';
import 'package:ag_selector/controller/pdf_exporter.dart';
import 'package:ag_selector/controller/persistence/persistence_manager.dart';
import 'package:ag_selector/model/ag.dart';
import 'package:ag_selector/model/person.dart';
import 'package:ag_selector/model/selection_object.dart';
import 'package:ag_selector/model/settings.dart';
import 'package:ag_selector/util/string_utils.dart';
import 'package:flutter/material.dart';

class Selector extends StatefulWidget {
  final PersistenceManager persistenceManager;

  const Selector({super.key, required this.persistenceManager});

  @override
  State<Selector> createState() => _SelectorListState();
}

class _SelectorListState extends State<Selector> {
  List<SelectionObject> selection = [];

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

  bool isPersonAndWeekdayInSelection(Person person, String weekday) {
    for(SelectionObject selectionObject in selection){
      if(selectionObject.person.id == person.id && selectionObject.weekday == weekday){
        return true;
      }
    }
    return false;
  }

  bool isPersonInSelection(Person person) {
    for(SelectionObject selectionObject in selection){
      if(selectionObject.person.id == person.id){
        return true;
      }
    }
    return false;
  }

  void createSelectionForPersons() async {
    selection = await createSelection.createSelection(
        widget.persistenceManager, persons, ags, settings.numberOfPreferences, context);
    selection.sort((a, b) => StringUtils.combineHouseAndClass(a.person).compareTo(StringUtils.combineHouseAndClass(b.person)));
    setState(() {
      for(SelectionObject selectionObject in selection){
        filterWeekdaySet.add(selectionObject.weekday);
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
                for (int i = 0; i < selection.length; i++)
                  if ((filterHouse == "Haus" || filterHouse == selection[i].person.house) &&
                      (filterSchoolClass == "Klasse" ||
                          filterSchoolClass == selection[i].person.schoolClass))
                      if (isPersonAndWeekdayInSelection(selection[i].person, selection[i].weekday) == true &&
                          (filterWeekday == "Wochentag" ||
                              filterWeekday == selection[i].weekday) &&
                          (filterAG == "AG" ||
                              filterAG == selection[i].ag.name))
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
                            Text(selection[i].person.name),
                            Text(selection[i].person.house),
                            Text(selection[i].person.schoolClass),
                            Text(selection[i].weekday),
                            Text(selection[i].ag.name),
                        ])
              ],
            ),
          ],
        ),
      )),
    );
  }
}
