import 'package:ag_selector/model/ag.dart';
import 'package:ag_selector/util/string_utils.dart';
import 'package:ag_selector/view/select_weekdays.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AGForm extends StatefulWidget {
  final Function(AG) onAGCreated;
  final Function(AG) onAGEdited;
  final Function(AG) onAGdDeleted;
  final AG ag;
  final bool createMode;

  const AGForm({
    super.key,
    required this.onAGCreated,
    required this.onAGEdited,
    required this.onAGdDeleted,
    required this.ag,
    required this.createMode,
  });

  @override
  State<AGForm> createState() => _AGFormState();
}

class _AGFormState extends State<AGForm> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _maxPersonsController = TextEditingController();

  DateTime startTime = DateTime(1970, 1, 1, 12, 00);
  DateTime endTime = DateTime(1970, 1, 1, 13, 00);

  List<String> weekdays = [];

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.ag.name; // Pre-fill form fields
    _descriptionController.text = widget.ag.description;
    _maxPersonsController.text = widget.ag.maxPersons.toString();

    startTime = widget.ag.startTime;
    endTime = widget.ag.endTime;

    weekdays = widget.ag.weekdays;
  }

  void onWeekdaysSelected(List<String> weekdays) {
    setState(() {
      this.weekdays = weekdays;
    });
  }

  void selectWeekdays() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => SelectWeekdaysForm(
                onWeekdaysSelected: (weekdays) {
                  onWeekdaysSelected(weekdays);
                },
                weekdays: weekdays,
              )),
    );
  }

  // Function called when form is submitted
  void _submitForm() {
    final String name = _nameController.text;
    final String description = _descriptionController.text;
    final String maxPersons = _maxPersonsController.text;

    if (name.isEmpty || weekdays.isEmpty || maxPersons.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Kein Name oder Wochentag eingetragen'),
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

    final AG newAG = AG(
        id: -1,
        name: name,
        weekdays: weekdays,
        description: description,
        startTime: startTime,
        endTime: endTime,
        maxPersons: int.parse(maxPersons));

    if (widget.createMode == true) {
      widget.onAGCreated(newAG);
      setState(() {
        _nameController.text = "";
      });
    } else {
      widget.onAGEdited(newAG);
      Navigator.pop(context);
    }
  }

  void _deleteAG() {
    widget.onAGdDeleted(widget.ag); // Call callback with delete ag
    Navigator.pop(context);
  }

  void _showDialog(Widget child) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => Container(
        height: 216,
        padding: const EdgeInsets.only(top: 6.0),
        // The Bottom margin is provided to align the popup above the system
        // navigation bar.
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        // Provide a background color for the popup.
        color: CupertinoColors.systemBackground.resolveFrom(context),
        // Use a SafeArea widget to avoid system overlaps.
        child: SafeArea(
          top: false,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: widget.createMode == true
            ? const Text('AG erstellen')
            : const Text('AG bearbeiten'),
      ),
      body: Form(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Text fields for name, company, address
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Name"),
              ),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        selectWeekdays();
                      },
                      child: Text(
                        "Wochentage: ${StringUtils.stringListToString(weekdays)}",
                        style: const TextStyle(fontSize: 16.0),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text("Anfangszeit"),
                  CupertinoButton(
                    // Display a CupertinoDatePicker in date picker mode.
                    onPressed: () => _showDialog(
                      CupertinoDatePicker(
                        initialDateTime: startTime,
                        mode: CupertinoDatePickerMode.time,
                        use24hFormat: true,
                        // This is called when the user changes the date.
                        onDateTimeChanged: (DateTime newTime) {
                          setState(() => startTime = newTime);
                        },
                      ),
                    ),
                    // In this example, the date is formatted manually. You can
                    // use the intl package to format the value based on the
                    // user's locale settings.
                    child: Text(
                      StringUtils.timeToString(
                          startTime.hour, startTime.minute),
                      style: const TextStyle(
                        fontSize: 22.0,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text("Endzeit"),
                  CupertinoButton(
                    // Display a CupertinoDatePicker in date picker mode.
                    onPressed: () => _showDialog(
                      CupertinoDatePicker(
                        initialDateTime: endTime,
                        mode: CupertinoDatePickerMode.time,
                        use24hFormat: true,
                        // This is called when the user changes the date.
                        onDateTimeChanged: (DateTime newTime) {
                          setState(() => endTime = newTime);
                        },
                      ),
                    ),
                    // In this example, the date is formatted manually. You can
                    // use the intl package to format the value based on the
                    // user's locale settings.
                    child: Text(
                      StringUtils.timeToString(endTime.hour, endTime.minute),
                      style: const TextStyle(
                        fontSize: 22.0,
                      ),
                    ),
                  ),
                ],
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: "Beschreibung"),
              ),
              TextFormField(
                controller: _maxPersonsController,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: "Maximale Personenanzahl"),
              ),
              widget.createMode == true
                  ? FloatingActionButton(
                      onPressed: _submitForm,
                      heroTag: "ag_add",
                      child: const Icon(Icons.add),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FloatingActionButton(
                          onPressed: _submitForm,
                          heroTag: "ag_submit",
                          child: const Icon(Icons.check),
                        ),
                        FloatingActionButton(
                          onPressed: _deleteAG,
                          heroTag: "ag_delete",
                          child: const Icon(Icons.delete),
                        ),
                      ],
                    )
            ],
          ),
        ),
      ),
    );
  }
}
