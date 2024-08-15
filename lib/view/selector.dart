import 'package:ag_selector/controller/create_selection.dart';
import 'package:ag_selector/model/ag.dart';
import 'package:ag_selector/model/person.dart';
import 'package:ag_selector/model/settings.dart';
import 'package:flutter/material.dart';

class Selector extends StatefulWidget {
  final List<Person> persons;

  final List<AG> ags;

  final Settings settings;

  const Selector(
      {super.key,
      required this.persons,
      required this.ags,
      required this.settings});

  @override
  State<Selector> createState() => _SelectorListState();
}

class _SelectorListState extends State<Selector> {
  Map<Person, Map<String, AG>> selection = <Person, Map<String, AG>>{};

  CreateSelection createSelection = CreateSelection();

  bool isInSelection(Person person, String wochentag) {
    if (selection.keys.contains(person)) {
      if (selection[person]!.keys.contains(wochentag)) {
        return true;
      }
    }
    return false;
  }

  void createSelectionForPersons() async {
    selection = await createSelection.createSelection(
        widget.persons, widget.ags, widget.settings.numberOfPreferences);
    for (Person person in selection.keys) {
      for (String weekday in selection[person]!.keys) {
        print("${person.name}: $weekday: ${selection[person]![weekday]}\n");
      }
    }
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
                    onPressed: () {},
                    child: const Text(
                      "Selektionsvorschlag generieren",
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
                for (Person person in widget.persons)
                  for (String weekday in person.weekdaysPresent)
                    if (isInSelection(person, weekday) == true)
                      TableRow(children: [
                        Text(person.name),
                        Text(person.house),
                        Text(person.schoolClass),
                        Text(weekday),
                        DropdownButton(
                          value: selection[person]![weekday],
                          items: widget.ags
                              .map<DropdownMenuItem<AG>>(
                                (AG value) => DropdownMenuItem(
                                    value: value, child: Text(value.name)),
                              )
                              .toList(),
                          onChanged: (AG? value) {
                            setState(() {
                              selection[person]![weekday] = value!;
                            });
                          },
                        ),
                      ])
              ],
            ),
          ],
        ),
      )),
    );
  }
}
