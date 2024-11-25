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

  Map<Person, List<PersonAgPreference>> personToPreferenceList = <Person, List<PersonAgPreference>>{};

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
    reloadPersonAgPreferences();
  }

  void reloadPersonAgPreferences() async {
    personToPreferenceList.clear();
    for(Person person in persons){
      List<PersonAgPreference> personAgPreferences = await widget.persistenceManager.getPersonAgPreferences(person);
      if(!personToPreferenceList.keys.contains(person)){
        personToPreferenceList[person] = personAgPreferences;
      }
    }
    setState(() {});
  }

  void onPersonCreated(
      Person person, List<PersonAgPreference> personAgPreferences, List<Person> personsApart) async {
    int id = await widget.persistenceManager.insertPerson(person);
    person.id = id;

    widget.persistenceManager.deletePersonAgPreferencesForPerson(person);
    for (PersonAgPreference personAgPreference in personAgPreferences) {
      personAgPreference.person = person;
      widget.persistenceManager.insertPersonAgPreference(personAgPreference);
    }

    widget.persistenceManager.updatePersonApart(person, personsApart);

    reloadPersons();
  }

  void onPersonEdited(
      Person person, List<PersonAgPreference> personAgPreferences, List<Person> personsApart) async {
    widget.persistenceManager.updatePerson(person);

    widget.persistenceManager.deletePersonAgPreferencesForPerson(person);
    for (PersonAgPreference personAgPreference in personAgPreferences) {
      personAgPreference.person = person;
      widget.persistenceManager.insertPersonAgPreference(personAgPreference);
    }

    widget.persistenceManager.updatePersonApart(person, personsApart);

    reloadPersons();
  }

  void deletePerson(Person person){
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sicher?'),
          content: const Text('Wollen Sie wirklich diese Person löschen?'),
          actions: [
            TextButton(
              onPressed: () => deletePersonIntern(person),
              child: const Text('Ja'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Nein'),
            ),
          ],
        );
      },
    );
  }

  void deletePersonIntern(Person person) {
    widget.persistenceManager.deletePerson(person);
    Navigator.pop(context);
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
                persons: persons,
              )),
    );
  }

  String getPreferencesForPerson(Person person){
    String result = "";
    Map<String, int> resultMap = <String, int>{};
    List<PersonAgPreference>? list = personToPreferenceList[person];
    if(list != null){
      for(PersonAgPreference personAgPreference in list){
        String weekday = personAgPreference.weekday;
        if(!resultMap.keys.contains(weekday)){
          resultMap[weekday] = 0;
        }
        resultMap[weekday] = resultMap[weekday]! + 1;
      }
    }
    for(String weekday in resultMap.keys){
      result += "${Weekdays.weekdayToShortString(weekday)}: ${resultMap[weekday]}, ";
    }
    if(result.isNotEmpty){
      return result.substring(0, result.length - 2);
    }
    return "";
  }

  void deleteAllPreferences(){
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sicher?'),
          content: const Text('Wollen Sie wirklich alle Präferenzen löschen?'),
          actions: [
            TextButton(
              onPressed: () => deleteAllPreferencesIntern(),
              child: const Text('Ja'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Nein'),
            ),
          ],
        );
      },
    );
  }

  void deleteAllPreferencesIntern() async {
    for(Person person in persons){
      await widget.persistenceManager.deletePersonAgPreferencesForPerson(person);
    }
    setState(() {
      Navigator.pop(context);
      reloadPersonAgPreferences();
    });
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
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
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                  ),
                  onPressed: () {
                    deleteAllPreferences();
                  },
                  child: const Text("Alle Präferenzen löschen"),
                ),
              ]
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
                    "Präferenzen",
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
                  const Text(
                    "Löschen",
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
                    Text(getPreferencesForPerson(person),
                        textAlign: TextAlign.center),
                    ElevatedButton(
                        onPressed: () {
                          openPersonForm(person, false);
                        },
                        child: const Icon(Icons.edit)),
                    ElevatedButton(
                        onPressed: () {
                          deletePerson(person);
                        },
                        child: const Icon(Icons.delete))
                  ])
              ],
            ),
          ],
        ),
      )),
    );
  }
}
