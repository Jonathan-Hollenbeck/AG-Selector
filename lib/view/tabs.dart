import 'package:ag_selector/controller/persistend_manager.dart';
import 'package:ag_selector/model/ag.dart';
import 'package:ag_selector/model/person.dart';
import 'package:ag_selector/model/settings.dart';
import 'package:ag_selector/view/ag/ag_list.dart';
import 'package:ag_selector/view/person/person_list.dart';
import 'package:ag_selector/view/selector.dart';
import 'package:ag_selector/view/settings_form.dart';
import 'package:flutter/material.dart';

class Tabs extends StatefulWidget {
  const Tabs({super.key});

  @override
  State<Tabs> createState() => _TabsState();
}

class _TabsState extends State<Tabs> {
  List<AG> ags = [];
  List<Person> persons = [];

  PersistendManager persistendManager = PersistendManager();

  Settings settings = Settings(Settings.DEFAULT_NUMBER_OF_PREFERENCES);

  @override
  void initState() {
    super.initState();
    persistendManager.bindDatabase(persistendManager.getDefaultDatabasePath(),
        PersistendManager.defaultDatabaseName);
  }

  void setSettings(Settings settings) {
    setState(() {
      this.settings = settings;
    });
  }

  void setPersons(List<Person> persons) {
    setState(() {
      this.persons = persons;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text("AG Selector"),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.settings)),
              Tab(icon: Icon(Icons.sports_soccer)),
              Tab(icon: Icon(Icons.person)),
              Tab(icon: Icon(Icons.list_alt)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            SettingsForm(
              setSettings: setSettings,
              settings: settings,
            ),
            AGList(
              persistendManager: persistendManager,
              settings: settings,
            ),
            PersonList(
              setPersons: setPersons,
              settings: settings,
              ags: ags,
            ),
            Selector(persons: persons, ags: ags, settings: settings),
          ],
        ),
      ),
    );
  }
}
