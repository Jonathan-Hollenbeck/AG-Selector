import 'package:ag_selector/model/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SettingsForm extends StatefulWidget {
  final Function(Settings settings) setSettings;
  final Settings settings;

  const SettingsForm(
      {super.key, required this.settings, required this.setSettings});

  @override
  State<SettingsForm> createState() => _SettingsFormListState();
}

class _SettingsFormListState extends State<SettingsForm>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _numberOfPreferencesController =
      TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _numberOfPreferencesController.text =
        widget.settings.numberOfPreferences.toString(); // Pre-fill form fields
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
      return; // Handle empty fields (optional)
    }

    final Settings settings = Settings(int.parse(numberOfPreferences));

    widget.setSettings(settings);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
