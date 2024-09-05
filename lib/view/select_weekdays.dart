import 'package:ag_selector/model/weekdays.dart';
import 'package:flutter/material.dart';

class SelectWeekdaysForm extends StatefulWidget {
  final List<String> weekdays;
  final Function(List<String>) onWeekdaysSelected;

  const SelectWeekdaysForm(
      {super.key, required this.onWeekdaysSelected, required this.weekdays});

  @override
  State<SelectWeekdaysForm> createState() => _SelectWeekdaysFormState();
}

class _SelectWeekdaysFormState extends State<SelectWeekdaysForm> {
  bool checkboxMonday = false;
  bool checkboxTuesday = false;
  bool checkboxWednesday = false;
  bool checkboxThursday = false;
  bool checkboxFriday = false;
  bool checkboxSaturday = false;
  bool checkboxSunday = false;

  @override
  void initState() {
    super.initState();
    if (widget.weekdays.contains(Weekdays.monday)) {
      checkboxMonday = true;
    }
    if (widget.weekdays.contains(Weekdays.tuesday)) {
      checkboxTuesday = true;
    }
    if (widget.weekdays.contains(Weekdays.wednesday)) {
      checkboxWednesday = true;
    }
    if (widget.weekdays.contains(Weekdays.thursday)) {
      checkboxThursday = true;
    }
    if (widget.weekdays.contains(Weekdays.friday)) {
      checkboxFriday = true;
    }
    if (widget.weekdays.contains(Weekdays.saturday)) {
      checkboxSaturday = true;
    }
    if (widget.weekdays.contains(Weekdays.sunday)) {
      checkboxSunday = true;
    }
  }

  // Function called when form is submitted
  void _submitForm() {
    List<String> weekdays = [];
    if (checkboxMonday == true) {
      weekdays.add(Weekdays.monday);
    }
    if (checkboxTuesday == true) {
      weekdays.add(Weekdays.tuesday);
    }
    if (checkboxWednesday == true) {
      weekdays.add(Weekdays.wednesday);
    }
    if (checkboxThursday == true) {
      weekdays.add(Weekdays.thursday);
    }
    if (checkboxFriday == true) {
      weekdays.add(Weekdays.friday);
    }
    if (checkboxSaturday == true) {
      weekdays.add(Weekdays.saturday);
    }
    if (checkboxSunday == true) {
      weekdays.add(Weekdays.sunday);
    }
    widget.onWeekdaysSelected(weekdays);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Wochentage auswählen'),
      ),
      body: Form(
          child: SingleChildScrollView(
        child: Column(
          children: [
            CheckboxListTile(
              value: checkboxMonday,
              onChanged: (bool? value) {
                setState(() {
                  checkboxMonday = value!;
                });
              },
              title: const Text(Weekdays.monday),
            ),
            CheckboxListTile(
              value: checkboxTuesday,
              onChanged: (bool? value) {
                setState(() {
                  checkboxTuesday = value!;
                });
              },
              title: const Text(Weekdays.tuesday),
            ),
            CheckboxListTile(
              value: checkboxWednesday,
              onChanged: (bool? value) {
                setState(() {
                  checkboxWednesday = value!;
                });
              },
              title: const Text(Weekdays.wednesday),
            ),
            CheckboxListTile(
              value: checkboxThursday,
              onChanged: (bool? value) {
                setState(() {
                  checkboxThursday = value!;
                });
              },
              title: const Text(Weekdays.thursday),
            ),
            CheckboxListTile(
              value: checkboxFriday,
              onChanged: (bool? value) {
                setState(() {
                  checkboxFriday = value!;
                });
              },
              title: const Text(Weekdays.friday),
            ),
            CheckboxListTile(
              value: checkboxSaturday,
              onChanged: (bool? value) {
                setState(() {
                  checkboxSaturday = value!;
                });
              },
              title: const Text(Weekdays.saturday),
            ),
            CheckboxListTile(
              value: checkboxSunday,
              onChanged: (bool? value) {
                setState(() {
                  checkboxSunday = value!;
                });
              },
              title: const Text(Weekdays.sunday),
            ),
            FloatingActionButton(
                onPressed: _submitForm, child: const Icon(Icons.check)),
          ],
        ),
      )),
    );
  }
}
