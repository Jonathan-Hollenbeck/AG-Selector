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

  final List<String> weekdaysPresent;

  final List<AG> ags;

  final List<PersonAgPreference> personAgPreferences;

  const SelectPreferences(
      {super.key,
      required this.ags,
      required this.persistenceManager,
      required this.person,
      required this.setPersonAgPreferences,
      required this.personAgPreferences,
      required this.weekdaysPresent});

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
      if (preferenceString != "") {
        //get int from preference String
        int preference = int.parse(preferenceString);

        //remove old preference
        PersonAgPreference? oldPreference = getPersonAgPreferenceByAGWeekdayPreferenceNumber(ag, weekday, preference);
        if(oldPreference != null){
          personAgPreferences.remove(oldPreference);
        }

        //add new one
        PersonAgPreference? personAgPreference =
            getPersonAgPreferenceFromAGAndWeekday(ag, weekday);

        if (personAgPreference != null) {
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
      else{
        PersonAgPreference? personAgPreference = getPersonAgPreferenceFromAGAndWeekday(ag, weekday);
        if(personAgPreference != null){
          personAgPreferences.remove(personAgPreference);
        }
      }
      resetAgNWeekdayPreferenceView();
    setState(() {});
  }

  PersonAgPreference? getPersonAgPreferenceByAGWeekdayPreferenceNumber(
      AG ag, String weekday, int preference) {
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
      if (personAgPreference.ag.id == ag.id &&
          personAgPreference.weekday == weekday) {
        return personAgPreference;
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();

    //create filter
    filterWeekdaySet.add("Wochentag");
    for (AG ag in widget.ags) {
      for (String weekday in ag.weekdays) {
        if (widget.weekdaysPresent.contains(weekday)) {
          filterWeekdaySet.add(weekday);
        }
      }
    }

    reloadSettings();
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
    reloadPersonAgPreferences();
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
    resetAgNWeekdayPreferenceView();
    setState(() {});
  }

  void resetAgNWeekdayPreferenceView(){
    agNWeekdayToPreference.clear();
    for(AG ag in widget.ags){
      for(String weekday in ag.weekdays){
        if(!agNWeekdayToPreference.keys.contains(ag.id)){
        agNWeekdayToPreference[ag.id] = {};
        }
        if(!agNWeekdayToPreference[ag.id]!.keys.contains(weekday)){
          agNWeekdayToPreference[ag.id]![weekday] = "";
        }
      }
    }
    for(PersonAgPreference personAgPreference in personAgPreferences){
      AG ag = personAgPreference.ag;
      String weekday = personAgPreference.weekday;
      int preferenceNumber = personAgPreference.preferenceNumber;
      agNWeekdayToPreference[ag.id]![weekday] = "$preferenceNumber";
    }
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
                for (String weekday in widget.weekdaysPresent)
                  for (int i = 0; i < widget.ags.length; i++)
                    if (agNWeekdayToPreference[widget.ags[i].id] != null &&
                        agNWeekdayToPreference[widget.ags[i].id]![weekday] != null &&
                        (filterWeekday == "Wochentag" ||
                            filterWeekday == weekday))
                      TableRow(
                        decoration: BoxDecoration(
                            color:
                              Color.fromARGB(
                                (i % 2) * 255,
                                192,
                                192,
                                192
                            )
                          ),
                        children: [
                        Text(widget.ags[i].toShortString()),
                        Text(weekday),
                        DropdownButton(
                          value: agNWeekdayToPreference[widget.ags[i].id]![weekday],
                          items: numberOfPreferencesList
                              .map<DropdownMenuItem<String>>(
                                (String value) => DropdownMenuItem(
                                    value: value, child: Text(value)),
                              )
                              .toList(),
                          onChanged: (String? value) {
                            if (value != null) {
                              setAGPreference(widget.ags[i], weekday, value);
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
