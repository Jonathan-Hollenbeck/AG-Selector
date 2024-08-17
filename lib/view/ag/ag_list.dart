import 'package:ag_selector/controller/persistence/persistence_manager.dart';
import 'package:ag_selector/model/ag.dart';
import 'package:ag_selector/model/weekdays.dart';
import 'package:ag_selector/util/string_utils.dart';
import 'package:ag_selector/view/ag/ag_form.dart';
import 'package:flutter/material.dart';

class AGList extends StatefulWidget {
  final PersistenceManager persistenceManager;

  const AGList({super.key, required this.persistenceManager});

  @override
  State<AGList> createState() => _AGListState();
}

class _AGListState extends State<AGList> {
  List<AG> ags = [];

  @override
  void initState() {
    super.initState();
    reloadAgs();
  }

  void reloadAgs() async {
    ags = await widget.persistenceManager.loadAgs();
    setState(() {});
  }

  void onAGCreated(AG ag) async {
    widget.persistenceManager.insertAG(ag);
    reloadAgs();
  }

  void onAGEdited(AG ag) async {
    widget.persistenceManager.updateAG(ag);
    reloadAgs();
  }

  void onAGDeleted(AG ag) async {
    widget.persistenceManager.deleteAG(ag);
    reloadAgs();
  }

  void openAGForm(AG ag, bool createMode) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => AGForm(
                onAGCreated: (AG ag) {
                  onAGCreated(ag);
                },
                onAGEdited: (AG ag) {
                  onAGEdited(ag);
                },
                onAGdDeleted: (AG ag) {
                  onAGDeleted(ag);
                },
                ag: ag,
                createMode: createMode,
              )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        title: const Text("AGs"),
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
                openAGForm(AG.createEmptyAG(), true);
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
                    "Beschreibung",
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
                    "Max Personenzahl",
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                  ),
                  Text(
                    "Startzeit",
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                  ),
                  Text(
                    "Endzeit",
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
                for (AG ag in ags)
                  TableRow(children: [
                    Text(ag.name, textAlign: TextAlign.center),
                    Text(ag.description, textAlign: TextAlign.center),
                    Text(Weekdays.weekdaysToShortString(ag.weekdays),
                        textAlign: TextAlign.center),
                    Text(ag.maxPersons.toString(), textAlign: TextAlign.center),
                    Text(
                        StringUtils.timeToString(
                            ag.startTime.hour, ag.startTime.minute),
                        textAlign: TextAlign.center),
                    Text(
                        StringUtils.timeToString(
                            ag.endTime.hour, ag.endTime.minute),
                        textAlign: TextAlign.center),
                    ElevatedButton(
                        onPressed: () {
                          openAGForm(ag, false);
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
