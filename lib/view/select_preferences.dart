import 'package:ag_selector/controller/persistence/persistence_manager.dart';
import 'package:ag_selector/model/ag.dart';
import 'package:ag_selector/model/person.dart';
import 'package:ag_selector/model/person_ag_preference.dart';
import 'package:ag_selector/model/settings.dart';
import 'package:ag_selector/util/int_utils.dart';
import 'package:ag_selector/util/string_utils.dart';
import 'package:flutter/material.dart';

class SelectPreferences extends StatefulWidget {
  final Function(List<PersonAgPreference>) setPersonAgPreferences;

  final PersistenceManager persistenceManager;

  final Person person;

  final List<AG> ags;

  final List<PersonAgPreference> personAgPreferences;

  const SelectPreferences(
      {super.key,
      required this.ags,
      required this.persistenceManager,
      required this.person,
      required this.setPersonAgPreferences,
      required this.personAgPreferences});

  @override
  State<SelectPreferences> createState() => _SelectPreferencesState();
}

class _SelectPreferencesState extends State<SelectPreferences> {
  List<String> numberOfPreferencesList = [];
  List<PersonAgPreference> personAgPreferences = [];

  Map<int, Map<String, String>> agNWeekdayToPreference =
      <int, Map<String, String>>{};

  Settings settings = Settings(Settings.defaultNumberOfPreferences);

  Set<String> filterWeekdaySet = {};

  String filterWeekday = "Wochentag";

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

    //create map for view
    filterWeekdaySet.add("Wochentag");
    for (AG ag in widget.ags) {
      for (String weekday in ag.weekdays) {
        filterWeekdaySet.add(weekday);
        if (agNWeekdayToPreference.keys.contains(ag.id)) {
          agNWeekdayToPreference[ag.id]!.putIfAbsent(weekday, () => "");
        } else {
          agNWeekdayToPreference.putIfAbsent(ag.id, () => {weekday: ""});
        }
      }
    }

    reloadSettings();
    reloadPersonAgPreferences();
    setState(() {});
  }

  void reloadSettings() async {
    settings = await widget.persistenceManager.loadSettings();

    numberOfPreferencesList = StringUtils.getStringListPlusEmpty(
        StringUtils.copyStringList(StringUtils.intListToStringList(
            IntUtils.intToIntList(settings.numberOfPreferences)
                .map((int value) => value + 1)
                .toList())));
    setState(() {});
  }

  void reloadPersonAgPreferences() async {
    personAgPreferences = widget.personAgPreferences;

    List<PersonAgPreference> removeList = [];
    for (PersonAgPreference personAgPreference in personAgPreferences) {
      //check if personAgPreferences preference numbers is out of bounds and delete if so
      if (personAgPreference.preferenceNumber > settings.numberOfPreferences) {
        removeList.add(personAgPreference);
      }
    }
    for (PersonAgPreference removePersonAgPreference in removeList) {
      personAgPreferences.remove(removePersonAgPreference);
    }

    for (PersonAgPreference personAgPreference in personAgPreferences) {
      //fill in the view map with the loaded preferences
      if (agNWeekdayToPreference.keys.contains(personAgPreference.ag.id) &&
          agNWeekdayToPreference[personAgPreference.ag.id]!
              .keys
              .contains(personAgPreference.weekday)) {
        agNWeekdayToPreference[personAgPreference.ag.id]![personAgPreference
            .weekday] = personAgPreference.preferenceNumber.toString();
      }
    }
    setState(() {});
  }

  // Function called when form is submitted
  void _submitForm() {
    widget.setPersonAgPreferences(personAgPreferences);
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
                TableRow(children: [
                  const Text(
                    "AG",
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
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
                  const Text(
                    "Präferenz",
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                  ),
                ]),
                for (AG ag in widget.ags)
                  for (String weekday in widget.person.weekdaysPresent)
                    if (agNWeekdayToPreference[ag.id] != null &&
                        agNWeekdayToPreference[ag.id]![weekday] != null &&
                        (filterWeekday == "Wochentag" ||
                            filterWeekday == weekday))
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
