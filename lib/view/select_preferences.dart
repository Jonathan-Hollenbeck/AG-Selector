import 'package:ag_selector/controller/persistence/persistence_manager.dart';
import 'package:ag_selector/model/ag.dart';
import 'package:ag_selector/model/settings.dart';
import 'package:ag_selector/util/int_utils.dart';
import 'package:ag_selector/util/string_utils.dart';
import 'package:flutter/material.dart';

class SelectPreferences extends StatefulWidget {
  final PersistenceManager persistenceManager;

  final List<AG> ags;

  final List<String> weekdaysPresent;

  const SelectPreferences(
      {super.key,
      required this.ags,
      required this.weekdaysPresent,
      required this.persistenceManager});

  @override
  State<SelectPreferences> createState() => _SelectPreferencesState();
}

class _SelectPreferencesState extends State<SelectPreferences> {
  Map<AG, String> agToPreference = <AG, String>{};
  Map<AG, String> agToWeekday = <AG, String>{};

  List<String> numberOfPreferencesList = [];

  Settings settings = Settings(Settings.defaultNumberOfPreferences);

  AG? getAGWithWeekdayAndPreference(String weekday, int preference) {
    if (widget.agPreferencesByWeekday.keys.contains(weekday) == true) {
      if (widget.agPreferencesByWeekday[weekday]!.keys.contains(preference)) {
        return widget.agPreferencesByWeekday[weekday]![preference];
      }
    }
    return null;
  }

  void setAGPreferencesByWeekday(AG ag) {
    setState(() {
      String? weekday = agToWeekday[ag];
      String? preferenceString = agToPreference[ag];
      if (weekday != null &&
          weekday != "" &&
          preferenceString != null &&
          preferenceString != "") {
        int preference = int.parse(preferenceString);

        AG? previouseAG = getAGWithWeekdayAndPreference(weekday, preference);

        if (previouseAG != null) {
          agToPreference[previouseAG] = "";
        }

        widget.agPreferencesByWeekday[weekday] = {preference: ag};
      }
    });
  }

  @override
  void initState() {
    super.initState();

    for (AG ag in widget.ags) {
      agToPreference[ag] = "";
      agToWeekday[ag] = "";
    }

    numberOfPreferencesList = StringUtils.getStringListPlusEmpty(
        StringUtils.copyStringList(StringUtils.intListToStringList(
            IntUtils.intToIntList(settings.numberOfPreferences)
                .map((int value) => value + 1)
                .toList())));
  }

  // Function called when form is submitted
  void _submitForm() {
    
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
                      value: agToPreference[ag],
                      items: numberOfPreferencesList
                          .map<DropdownMenuItem<String>>(
                            (String value) => DropdownMenuItem(
                                value: value, child: Text(value)),
                          )
                          .toList(),
                      onChanged: (String? value) {
                        setState(() {
                          agToPreference[ag] = value!;
                        });
                        setAGPreferencesByWeekday(ag);
                      },
                    ),
                    DropdownButton(
                      value: agToWeekday[ag],
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
                        setState(() {
                          agToWeekday[ag] = value!;
                        });
                        setAGPreferencesByWeekday(ag);
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
