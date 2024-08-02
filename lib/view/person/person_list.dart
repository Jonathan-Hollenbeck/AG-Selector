import 'package:ag_selector/controller/persistend_manager.dart';
import 'package:ag_selector/model/ag.dart';
import 'package:ag_selector/model/person.dart';
import 'package:ag_selector/model/settings.dart';
import 'package:ag_selector/model/weekdays.dart';
import 'package:ag_selector/view/person/person_form.dart';
import 'package:flutter/material.dart';

class PersonList extends StatefulWidget {
  final PersistendManager persistendManager;
  final Function(List<Person>) setPersons;
  final Settings settings;
  final List<AG> ags;

  const PersonList(
      {super.key,
      required this.setPersons,
      required this.settings,
      required this.ags,
      required this.persistendManager});

  @override
  State<PersonList> createState() => _PersonListState();
}

class _PersonListState extends State<PersonList> {
  List<Person> persons = [];

  @override
  void initState() {
    super.initState();
    reloadAgs();
  }

  void reloadAgs() async {
    persons = await widget.persistendManager.loadPersons();
    setState(() {});
  }

  void onPersonCreated(Person person) async {
    widget.persistendManager
        .addPersistendObject(PersistendManager.personsTableName, person);
    reloadAgs();
  }

  void onPersonEdited(Person person) async {
    widget.persistendManager
        .editPersistendObject(PersistendManager.personsTableName, person);
    reloadAgs();
  }

  void onPersonDeleted(Person person) async {
    widget.persistendManager
        .deletePersistendObject(PersistendManager.personsTableName, person);
    reloadAgs();
  }

  void openPersonForm(Person person, bool createMode) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => PersonForm(
                onPersonCreated: (Person person) {
                  onPersonCreated(person);
                },
                onPersonEdited: (Person person) {
                  onPersonEdited(person);
                },
                onPersonDeleted: (Person person) {
                  onPersonDeleted(person);
                },
                person: person,
                createMode: createMode,
                ags: widget.ags,
                numberOfPreferences: widget.settings.numberOfPreferences,
              )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        title: const Text("Personen"),
      ),
      body: Form(
          child: SingleChildScrollView(
        child: Column(
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                elevation: 0,
              ),
              onPressed: () {
                openPersonForm(Person.createEmptyPerson(), true);
              },
              child: const Icon(Icons.add),
            ),
            Table(
              border: TableBorder.all(),
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                const TableRow(children: [
                  Text(
                    "Name",
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
                    "Wochentage",
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                  ),
                  Text(
                    "Bearbeiten",
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                  ),
                ]),
                for (Person person in persons)
                  TableRow(children: [
                    Text(person.name, textAlign: TextAlign.center),
                    Text(person.house, textAlign: TextAlign.center),
                    Text(person.schoolClass, textAlign: TextAlign.center),
                    Text(Weekdays.weekdaysToShortString(person.weekdaysPresent),
                        textAlign: TextAlign.center),
                    ElevatedButton(
                        onPressed: () {
                          openPersonForm(person, false);
                        },
                        child: const Icon(Icons.edit))
                  ])
              ],
            ),
          ],
        ),
      )),
    );
  }
}
