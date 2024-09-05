import 'package:ag_selector/controller/persistence/persistence_manager.dart';
import 'package:ag_selector/model/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SettingsForm extends StatefulWidget {
  final PersistenceManager persistenceManager;

  const SettingsForm({
    super.key,
    required this.persistenceManager,
  });

  @override
  State<SettingsForm> createState() => _SettingsFormListState();
}

class _SettingsFormListState extends State<SettingsForm> {
  final TextEditingController _numberOfPreferencesController =
      TextEditingController();

  Settings settings = Settings(Settings.defaultNumberOfPreferences);

  @override
  void initState() {
    super.initState();

    reloadSettings();
  }

  void reloadSettings() async {
    settings = await widget.persistenceManager.loadSettings();

    _numberOfPreferencesController.text =
        settings.numberOfPreferences.toString(); // Pre-fill form fields
    setState(() {});
  }

  // Function called when form is submitted
  void _submitForm() {
    final String numberOfPreferences = _numberOfPreferencesController.text;

    if (numberOfPreferences.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Anzahl an Präferenzen nicht gesetzt!'),
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

    settings.numberOfPreferences = int.parse(numberOfPreferences);
    widget.persistenceManager.insertSettings(settings);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        title: const Text("Einstellungen"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            TextFormField(
              controller: _numberOfPreferencesController,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: "Anzahl an Präferenzen"),
            ),
            FloatingActionButton(
              onPressed: _submitForm,
              heroTag: "settings_submit",
              child: const Icon(Icons.check),
            ),
          ],
        ),
      ),
    );
  }
}
