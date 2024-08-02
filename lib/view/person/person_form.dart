import 'package:ag_selector/model/ag.dart';
import 'package:ag_selector/model/person.dart';
import 'package:ag_selector/util/string_utils.dart';
import 'package:ag_selector/view/select_preferences.dart';
import 'package:ag_selector/view/select_weekdays.dart';
import 'package:flutter/material.dart';

class PersonForm extends StatefulWidget {
  final Function(Person) onPersonCreated;
  final Function(Person) onPersonEdited;
  final Function(Person) onPersonDeleted;

  final Person person;

  final int numberOfPreferences;

  final bool createMode;

  final List<AG> ags;

  const PersonForm({
    super.key,
    required this.onPersonCreated,
    required this.onPersonEdited,
    required this.onPersonDeleted,
    required this.person,
    required this.createMode,
    required this.ags,
    required this.numberOfPreferences,
  });

  @override
  State<PersonForm> createState() => _PersonFormState();
}

class _PersonFormState extends State<PersonForm> {
  final _nameController = TextEditingController();
  final _houseController = TextEditingController();
  final _schoolClassController = TextEditingController();

  List<String> weekdaysPresent = [];

  Map<String, Map<int, AG>> agPreferencesByWeekday = <String, Map<int, AG>>{};

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.person.name; // Pre-fill form fields
    _houseController.text = widget.person.house;
    _schoolClassController.text = widget.person.schoolClass;
  }

  void onWeekdaysSelected(List<String> weekdaysPresent) {
    setState(() {
      this.weekdaysPresent = weekdaysPresent;
    });
  }

  void onPreferencesSelected(Map<String, Map<int, AG>> agPreferencesByWeekday) {
    setState(() {
      this.agPreferencesByWeekday = agPreferencesByWeekday;
    });
  }

  void selectWeekdays() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => SelectWeekdaysForm(
                onWeekdaysSelected: (weekdays) {
                  onWeekdaysSelected(weekdays);
                },
                weekdays: weekdaysPresent,
              )),
    );
  }

  void selectAGPreferences() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => SelectPreferences(
                onPreferencesSelected: (agPreferencesByWeekday) {
                  onPreferencesSelected(agPreferencesByWeekday);
                },
                agPreferencesByWeekday: agPreferencesByWeekday,
                numberOfPreferences: widget.numberOfPreferences,
                ags: getAGsBasedOnWeekdaysPresent(widget.ags, weekdaysPresent),
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
      return; // Handle empty fields (optional)
    }

    final Person newPerson = Person(
        id: -1,
        name: name,
        house: house,
        schoolClass: schoolClass,
        weekdaysPresent: weekdaysPresent,
        agPreferencesByWeekday: agPreferencesByWeekday);

    if (widget.createMode == true) {
      widget.onPersonCreated(newPerson);
      setState(() {
        _nameController.text = "";
      });
    } else {
      widget.onPersonEdited(newPerson);
      Navigator.pop(context);
    }
  }

  void _deletePerson() {
    widget.onPersonDeleted(widget.person); // Call callback with delete person
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Person bearbeiten'),
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
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        selectAGPreferences();
                      },
                      child: Text(
                        "${agPreferencesByWeekday.length} Präferenzen ausgewählt",
                        style: const TextStyle(fontSize: 16.0),
                      ),
                    ),
                  ),
                ],
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
