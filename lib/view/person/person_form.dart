import 'package:ag_selector/controller/persistence/persistence_manager.dart';
import 'package:ag_selector/model/ag.dart';
import 'package:ag_selector/model/person.dart';
import 'package:ag_selector/model/person_ag_preference.dart';
import 'package:ag_selector/util/string_utils.dart';
import 'package:ag_selector/view/person/select_person_apart.dart';
import 'package:ag_selector/view/select_preferences.dart';
import 'package:ag_selector/view/select_weekdays.dart';
import 'package:flutter/material.dart';

class PersonForm extends StatefulWidget {
  final Function(Person, List<PersonAgPreference>, List<Person>) onPersonCreated;
  final Function(Person, List<PersonAgPreference>, List<Person>) onPersonEdited;
  final Function(Person) onPersonDeleted;

  final PersistenceManager persistenceManager;

  final Person person;

  final bool createMode;

  final List<Person> persons;

  final List<AG> ags;

  const PersonForm({
    super.key,
    required this.onPersonCreated,
    required this.onPersonEdited,
    required this.onPersonDeleted,
    required this.person,
    required this.createMode,
    required this.ags,
    required this.persistenceManager,
    required this.persons,
  });

  @override
  State<PersonForm> createState() => _PersonFormState();
}

class _PersonFormState extends State<PersonForm> {
  final _nameController = TextEditingController();
  final _houseController = TextEditingController();
  final _schoolClassController = TextEditingController();

  List<String> weekdaysPresent = [];
  List<PersonAgPreference> personAgPreferences = [];
  List<Person> personsApart = [];

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.person.name; // Pre-fill form fields
    _houseController.text = widget.person.house;
    _schoolClassController.text = widget.person.schoolClass;

    weekdaysPresent = widget.person.weekdaysPresent;

    reloadPersonAgPreferences();
    reloadPersonsApart();
  }

  void reloadPersonAgPreferences() async {
    if (widget.person.id == -1) {
      personAgPreferences = [];
    } else {
      personAgPreferences =
          await widget.persistenceManager.getPersonAgPreferences(widget.person);
      setState(() {});
    }
  }

  void reloadPersonsApart() async {
    if (widget.person.id == -1) {
      personsApart = [];
    } else {
      personsApart = await widget.persistenceManager.loadPersonApartForPerson(widget.person);
      setState(() {});
    }
  }

  void setPersonAgPreferences(
      List<PersonAgPreference> personAgPreferencesParam) {
    personAgPreferences = personAgPreferencesParam;
    setState(() {});
  }

  void onWeekdaysSelected(List<String> weekdaysPresent) {
    setState(() {
      this.weekdaysPresent = weekdaysPresent;
    });
  }

  void onPersonApartSelected(List<Person> personsApart) {
    setState(() {
      this.personsApart = personsApart;
    });
  }

  void selectWeekdays() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => SelectWeekdaysForm(
                onWeekdaysSelected: onWeekdaysSelected,
                weekdays: weekdaysPresent,
              )),
    );
  }

  void selectPersonsApart() {
    List<Person> personListWithoutCurrent = [...widget.persons];
    personListWithoutCurrent.remove(widget.person);
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => SelectPersonApartForm(
                persons: personListWithoutCurrent,
                personsApart: personsApart,
                onPersonsApartSelected: onPersonApartSelected,
              )),
    );
  }

  void selectAGPreferences() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => SelectPreferences(
                persistenceManager: widget.persistenceManager,
                ags: getAGsBasedOnWeekdaysPresent(widget.ags, weekdaysPresent),
                person: widget.person,
                setPersonAgPreferences: setPersonAgPreferences,
                personAgPreferences: personAgPreferences,
                weekdaysPresent: weekdaysPresent,
              )),
    );
  }

  List<AG> getAGsBasedOnWeekdaysPresent(
      List<AG> ags, List<String> weekdayPresent) {
    Set<AG> personAGs = <AG>{};
    for (AG ag in ags) {
      for (String weekday in weekdaysPresent) {
        if (ag.weekdays.contains(weekday)) {
          personAGs.add(ag);
        }
      }
    }
    return personAGs.toList();
  }

  // Function called when form is submitted
  void _submitForm() {
    final name = _nameController.text;
    final house = _houseController.text;
    final schoolClass = _schoolClassController.text;

    if (name.isEmpty || house.isEmpty || schoolClass.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Kein Name, Haus oder Klasse eingetragen'),
            content: const Text('Bitte alle Felder ausfüllen.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    final Person newPerson = Person(
        id: widget.person.id,
        name: name,
        house: house,
        schoolClass: schoolClass,
        weekdaysPresent: weekdaysPresent);

    if (widget.createMode == true) {
      widget.onPersonCreated(newPerson, personAgPreferences, personsApart);
      setState(() {
        _nameController.text = "";
        personAgPreferences = [];
        personsApart = [];
      });
    } else {
      widget.onPersonEdited(newPerson, personAgPreferences, personsApart);
      Navigator.pop(context);
    }
  }

  void _deletePerson() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sicher?'),
          content: const Text('Wollen Sie wirklich diese Person löschen?'),
          actions: [
            TextButton(
              onPressed: () => _deletePersonIntern(widget.person),
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

  void _deletePersonIntern(Person person){
    widget.onPersonDeleted(widget.person); // Call callback with delete person
    Navigator.pop(context);
    Navigator.pop(context);
  }

  List<PersonAgPreference> sortedAgPreferences(List<PersonAgPreference> personAgPreferences){
    personAgPreferences.sort((a, b) => a.preferenceNumber.compareTo(b.preferenceNumber));
    return personAgPreferences;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: widget.createMode == true
            ? const Text('Person erstellen')
            : const Text('Person bearbeiten'),
      ),
      body: Form(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Text fields for name, company, address
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Name"),
              ),
              TextFormField(
                controller: _houseController,
                decoration: const InputDecoration(labelText: "Haus"),
              ),
              TextFormField(
                controller: _schoolClassController,
                decoration: const InputDecoration(labelText: "Klasse"),
              ),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        selectWeekdays();
                      },
                      child: Text(
                        "Wochentage anwesend: ${StringUtils.stringListToString(weekdaysPresent)}",
                        style: const TextStyle(fontSize: 16.0),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        selectPersonsApart();
                      },
                      child: const Text(
                        "Personen ausschließen",
                        style: TextStyle(fontSize: 16.0),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        selectAGPreferences();
                      },
                      child: const Text(
                        "Präferenzen wählen",
                        style: TextStyle(fontSize: 16.0),
                      ),
                    ),
                  ),
                ],
              ),
              for(PersonAgPreference personAgPreference in sortedAgPreferences(personAgPreferences))
                Table(
                  border: TableBorder.all(),
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    TableRow(children: [
                      Text(
                        personAgPreference.ag.name,
                        textAlign: TextAlign.center),
                      Text(
                        personAgPreference.weekday,
                        textAlign: TextAlign.center),
                      Text(
                        "${personAgPreference.preferenceNumber}",
                        textAlign: TextAlign.center),
                    ])
                  ]
                ),
              widget.createMode == true
                  ? FloatingActionButton(
                      onPressed: _submitForm,
                      heroTag: "person_add",
                      child: const Icon(Icons.add),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FloatingActionButton(
                          onPressed: _submitForm,
                          heroTag: "person_submit",
                          child: const Icon(Icons.check),
                        ),
                        FloatingActionButton(
                          onPressed: _deletePerson,
                          heroTag: "person_delete",
                          child: const Icon(Icons.delete),
                        ),
                      ],
                    )
            ],
          ),
        ),
      ),
    );
  }
}
