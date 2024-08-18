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
        widget.persistenceManager, persons, ags, settings.numberOfPreferences);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    reloadPersons();
    reloadAgs();
    reloadSettings();
    setState(() {});
  }

  void reloadAgs() async {
    ags = await widget.persistenceManager.loadAgs();
    setState(() {});
  }

  void reloadPersons() async {
    persons = await widget.persistenceManager.loadPersons();
    setState(() {});
  }

  void reloadSettings() async {
    settings = await widget.persistenceManager.loadSettings();
    setState(() {});
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
                      pdfExporter.generatePdf(selection, persons);
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
                const TableRow(children: [
                  Text(
                    "Person",
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                  ),
                  Text(
                    "Haus",
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                  ),
                  Text(
                    "Klasse",
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                  ),
                  Text(
                    "Wochentag",
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                  ),
                  Text(
                    "AG",
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                  ),
                ]),
                for (Person person in persons)
                  if (selection[person] != null)
                    for (String weekday in person.weekdaysPresent)
                      if (isInSelection(person, weekday) == true)
                        TableRow(children: [
                          Text(person.name),
                          Text(person.house),
                          Text(person.schoolClass),
                          Text(weekday),
                          Text(selection[person]![weekday]!.name),
                          /**DropdownButton(
                            value: selection[person]![weekday],
                            items: ags
                                .map<DropdownMenuItem<AG>>(
                                  (AG ag) => DropdownMenuItem(
                                      value: ag, child: Text(ag.name)),
                                )
                                .toList(),
                            onChanged: (AG? ag) {
                              setState(() {
                                if (selection[person] != null) {
                                  selection[person]![weekday] = ag!;
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
