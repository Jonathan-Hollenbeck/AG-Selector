import 'package:ag_selector/controller/persistence/persistence_manager.dart';
import 'package:ag_selector/model/ag.dart';
import 'package:ag_selector/model/person.dart';
import 'package:ag_selector/model/person_ag_preference.dart';
import 'package:ag_selector/model/settings.dart';
import 'package:ag_selector/util/int_utils.dart';
import 'package:ag_selector/util/string_utils.dart';
import 'package:flutter/material.dart';

class SelectPreferences extends StatefulWidget {
  final PersistenceManager persistenceManager;

  final Person person;

  final List<AG> ags;

  final List<String> weekdaysPresent;

  const SelectPreferences(
      {super.key,
      required this.ags,
      required this.weekdaysPresent,
      required this.persistenceManager,
      required this.person});

  @override
  State<SelectPreferences> createState() => _SelectPreferencesState();
}

class _SelectPreferencesState extends State<SelectPreferences> {
  List<String> numberOfPreferencesList = [];

  List<PersonAgPreference> personAgPreferences = [];

  Settings settings = Settings(Settings.defaultNumberOfPreferences);

  void setAGPreference(AG ag, String preferenceString) {
    setState(() {
      PersonAgPreference? personAgPreference = getPersonAgPreferenceFromAG(ag);
      if (personAgPreference != null && preferenceString != "") {
        int preference = int.parse(preferenceString);

        personAgPreference.preferenceNumber = preference;
      }
    });
  }

  void setAGWeekday(AG ag, String weekday) {
    setState(() {
      PersonAgPreference? personAgPreference = getPersonAgPreferenceFromAG(ag);
      if (personAgPreference != null && weekday != "") {
        personAgPreference.weekday = weekday;
      }
    });
  }

  PersonAgPreference? getPersonAgPreferenceFromAG(AG ag) {
    for (PersonAgPreference personAgPreference in personAgPreferences) {
      if (personAgPreference.ag == ag) {
        return personAgPreference;
      }
    }
    return null;
  }

  String getPreferenceFromAG(AG ag) {
    for (PersonAgPreference personAgPreference in personAgPreferences) {
      if (personAgPreference.ag == ag) {
        return personAgPreference.preferenceNumber.toString();
      }
    }
    return "";
  }

  String getWeekdayFromAG(AG ag) {
    for (PersonAgPreference personAgPreference in personAgPreferences) {
      if (personAgPreference.ag == ag) {
        return personAgPreference.weekday;
      }
    }
    return "";
  }

  @override
  void initState() {
    super.initState();

    reloadPersonAgPreferences();

    numberOfPreferencesList = StringUtils.getStringListPlusEmpty(
        StringUtils.copyStringList(StringUtils.intListToStringList(
            IntUtils.intToIntList(settings.numberOfPreferences)
                .map((int value) => value + 1)
                .toList())));
  }

  void reloadPersonAgPreferences() async {
    personAgPreferences =
        await widget.persistenceManager.getPersonAgPreferences(widget.person);
    setState(() {});
  }

  // Function called when form is submitted
  void _submitForm() {
    widget.persistenceManager.deletePersonAgPreferencesForPerson(widget.person);
    for (PersonAgPreference personAgPreference in personAgPreferences) {
      widget.persistenceManager.insertPersonAgPreference(personAgPreference);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Präferenzen wählen'),
      ),
      body: Form(
          child: SingleChildScrollView(
        child: Column(
          children: [
            Table(
              border: TableBorder.all(),
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                const TableRow(children: [
                  Text(
                    "AG",
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                  ),
                  Text(
                    "Präferenz",
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
                ]),
                for (AG ag in widget.ags)
                  TableRow(children: [
                    Text(ag.toShortString()),
                    DropdownButton(
                      value: getPreferenceFromAG(ag),
                      items: numberOfPreferencesList
                          .map<DropdownMenuItem<String>>(
                            (String value) => DropdownMenuItem(
                                value: value, child: Text(value)),
                          )
                          .toList(),
                      onChanged: (String? value) {
                        setAGPreference(ag, value!);
                      },
                    ),
                    DropdownButton(
                      value: getWeekdayFromAG(ag),
                      items: StringUtils.getStringListPlusEmpty(
                              StringUtils.copyStringList(
                                  StringUtils.getIntersectionBetweenTwoLists(
                                      widget.weekdaysPresent, ag.weekdays)))
                          .map<DropdownMenuItem<String>>(
                            (String value) => DropdownMenuItem(
                                value: value, child: Text(value)),
                          )
                          .toList(),
                      onChanged: (String? value) {
                        setAGWeekday(ag, value!);
                      },
                    ),
                  ])
              ],
            ),
            FloatingActionButton(
                onPressed: _submitForm, child: const Icon(Icons.check)),
          ],
        ),
      )),
    );
  }
}
