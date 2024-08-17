import 'package:ag_selector/controller/persistence/persistence_manager.dart';
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
  PersistenceManager persistenceManager = PersistenceManager();

  @override
  void initState() {
    persistenceManager.bindDatabase(persistenceManager.getDefaultDatabasePath(),
        PersistenceManager.defaultDatabaseName);
    super.initState();
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
              persistenceManager: persistenceManager,
            ),
            AGList(
              persistenceManager: persistenceManager,
            ),
            PersonList(
              persistenceManager: persistenceManager,
            ),
            Selector(persistenceManager: persistenceManager),
          ],
        ),
      ),
    );
  }
}
