import 'package:ag_selector/controller/persistence/persistence_manager.dart';
import 'package:ag_selector/model/ag.dart';
import 'package:ag_selector/model/person.dart';
import 'package:ag_selector/model/person_ag_preference.dart';
import 'package:ag_selector/model/weekdays.dart';
import 'package:ag_selector/view/person/person_form.dart';
import 'package:flutter/material.dart';

class PersonList extends StatefulWidget {
  final PersistenceManager persistenceManager;

  const PersonList({super.key, required this.persistenceManager});

  @override
  State<PersonList> createState() => _PersonListState();
}

class _PersonListState extends State<PersonList> {
  List<Person> persons = [];
  List<AG> ags = [];

  Set<String> filterHouseSet = {};
  Set<String> filterSchoolClassSet = {};

  String filterHouse = "Haus";
  String filterSchoolClass = "Klasse";

  @override
  void initState() {
    super.initState();
    reloadPersons();
    reloadAgs();
  }

  void reloadAgs() async {
    ags = await widget.persistenceManager.loadAgs();
    ags.sort((a, b) => a.name.toLowerCase().compareTo(b.name));
    setState(() {});
  }

  void reloadPersons() async {
    persons = await widget.persistenceManager
        .loadPersonsFilter(filterHouse, filterSchoolClass);
    persons.sort((a, b) => a.house.toLowerCase().compareTo(b.house));
    filterHouseSet.add("Haus");
    filterSchoolClassSet.add("Klasse");
    for (Person person in persons) {
      filterHouseSet.add(person.house);
      filterSchoolClassSet.add(person.schoolClass);
    }
    setState(() {});
  }

  void onPersonCreated(
      Person person, List<PersonAgPreference> personAgPreferences) async {
    int id = await widget.persistenceManager.insertPerson(person);
    person.id = id;

    widget.persistenceManager.deletePersonAgPreferencesForPerson(person);
    for (PersonAgPreference personAgPreference in personAgPreferences) {
      personAgPreference.person = person;
      widget.persistenceManager.insertPersonAgPreference(personAgPreference);
    }

    reloadPersons();
  }

  void onPersonEdited(
      Person person, List<PersonAgPreference> personAgPreferences) async {
    widget.persistenceManager.updatePerson(person);

    widget.persistenceManager.deletePersonAgPreferencesForPerson(person);
    for (PersonAgPreference personAgPreference in personAgPreferences) {
      personAgPreference.person = person;
      widget.persistenceManager.insertPersonAgPreference(personAgPreference);
    }

    reloadPersons();
  }

  void onPersonDeleted(Person person) async {
    widget.persistenceManager.deletePerson(person);
    reloadPersons();
  }

  void openPersonForm(Person person, bool createMode) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => PersonForm(
                onPersonCreated: onPersonCreated,
                onPersonEdited: onPersonEdited,
                onPersonDeleted: onPersonDeleted,
                persistenceManager: widget.persistenceManager,
                person: person,
                createMode: createMode,
                ags: ags,
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
                TableRow(children: [
                  const Text(
                    "Name",
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
                        filterHouse = value;
                        reloadPersons();
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
                        filterSchoolClass = value;
                        reloadPersons();
                      }
                    },
                  ),
                  const Text(
                    "Wochentage",
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                  ),
                  const Text(
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
