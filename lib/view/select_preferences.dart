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

  Map<int, Map<String, String>> agNWeekdayToPreference =
      <int, Map<String, String>>{};

  Settings settings = Settings(Settings.defaultNumberOfPreferences);

  void setAGPreference(AG ag, String weekday, String preferenceString) {
    setState(() {
      if (preferenceString != "") {
        //get int from preference String
        int preference = int.parse(preferenceString);

        //reset previouse agNWeekdayToPreference for View
        PersonAgPreference? personAgPreferenceToReset =
            getPersonAgPreferenceByWeekdayAndPreferenceNumber(
                weekday, preference);
        if (personAgPreferenceToReset != null &&
            agNWeekdayToPreference[personAgPreferenceToReset.ag.id] != null) {
          agNWeekdayToPreference[personAgPreferenceToReset.ag.id]![
              personAgPreferenceToReset.weekday] = "";
          personAgPreferences.remove(personAgPreferenceToReset);
        }

        PersonAgPreference? personAgPreference =
            getPersonAgPreferenceFromAGAndWeekday(ag, weekday);

        if (personAgPreference != null && preferenceString != "") {
          //set preferenceNumber
          personAgPreference.preferenceNumber = preference;
        } else {
          personAgPreference = PersonAgPreference(
              id: -1,
              preferenceNumber: preference,
              weekday: weekday,
              person: widget.person,
              ag: ag);
          personAgPreferences.add(personAgPreference);
        }
      }
      setPersonPreferenceView(ag, weekday, preferenceString);
    });
  }

  void setPersonPreferenceView(AG ag, String weekday, String preferenceString) {
    //set new agNWeekdayToPreference for View
    if (agNWeekdayToPreference[ag.id] != null) {
      agNWeekdayToPreference[ag.id]![weekday] = preferenceString;
    }
  }

  PersonAgPreference? getPersonAgPreferenceByWeekdayAndPreferenceNumber(
      String weekday, int preference) {
    for (PersonAgPreference personAgPreference in personAgPreferences) {
      if (personAgPreference.weekday == weekday &&
          personAgPreference.preferenceNumber == preference) {
        return personAgPreference;
      }
    }
    return null;
  }

  PersonAgPreference? getPersonAgPreferenceFromAGAndWeekday(
      AG ag, String weekday) {
    for (PersonAgPreference personAgPreference in personAgPreferences) {
      if (personAgPreference.ag == ag &&
          personAgPreference.weekday == weekday) {
        return personAgPreference;
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();

    reloadPersonAgPreferences();
    reloadSettings();
  }

  void reloadSettings() async {
    settings = await widget.persistenceManager.loadSettings();

    numberOfPreferencesList = StringUtils.getStringListPlusEmpty(
        StringUtils.copyStringList(StringUtils.intListToStringList(
            IntUtils.intToIntList(settings.numberOfPreferences)
                .map((int value) => value + 1)
                .toList())));
  }

  void reloadPersonAgPreferences() async {
    personAgPreferences =
        await widget.persistenceManager.getPersonAgPreferences(widget.person);

    for (AG ag in widget.ags) {
      for (String weekday in ag.weekdays) {
        if (agNWeekdayToPreference.keys.contains(ag.id)) {
          agNWeekdayToPreference[ag.id]!.putIfAbsent(weekday, () => "");
        } else {
          agNWeekdayToPreference.putIfAbsent(ag.id, () => {weekday: ""});
        }
      }
    }

    for (PersonAgPreference personAgPreference in personAgPreferences) {
      if (agNWeekdayToPreference.keys.contains(personAgPreference.ag.id)) {
        agNWeekdayToPreference[personAgPreference.ag.id]![personAgPreference
            .weekday] = personAgPreference.preferenceNumber.toString();
      }
    }
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
                    "Wochentag",
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
                ]),
                for (AG ag in widget.ags)
                  for (String weekday in ag.weekdays)
                    if (agNWeekdayToPreference[ag.id] != null)
                      TableRow(children: [
                        Text(ag.toShortString()),
                        Text(weekday),
                        DropdownButton(
                          value: agNWeekdayToPreference[ag.id]![weekday],
                          items: numberOfPreferencesList
                              .map<DropdownMenuItem<String>>(
                                (String value) => DropdownMenuItem(
                                    value: value, child: Text(value)),
                              )
                              .toList(),
                          onChanged: (String? value) {
                            if (value != null) {
                              setAGPreference(ag, weekday, value);
                            }
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
