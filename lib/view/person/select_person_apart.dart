import 'package:ag_selector/model/person.dart';
import 'package:flutter/material.dart';

class SelectPersonApartForm extends StatefulWidget {
  final List<Person> persons;
  final List<Person> personsApart;
  final Function(List<Person>) onPersonsApartSelected;

  const SelectPersonApartForm(
      {super.key, required this.onPersonsApartSelected, required this.persons, required this.personsApart});

  @override
  State<SelectPersonApartForm> createState() => _SelectPersonApartFormState();
}

class _SelectPersonApartFormState extends State<SelectPersonApartForm> {
  Map<Person, bool> personsApartMap = {};

  @override
  void initState() {
    super.initState();
    for(Person person in widget.persons){
      bool checked = false;
      for(Person personApart in widget.personsApart){
        if(person.id == personApart.id){
          checked = true;
        }
      }
      personsApartMap[person] = checked;
    }
  }

  // Function called when form is submitted
  void _submitForm() {
    List<Person> personsApart = [];
    for(Person person in personsApartMap.keys){
      if(personsApartMap[person] == true){
        personsApart.add(person);
      }
    }
    widget.onPersonsApartSelected(personsApart);
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
            for (Person person in widget.persons)
              CheckboxListTile(
                value: personsApartMap[person],
                onChanged: (bool? value) {
                  setState(() {
                    personsApartMap[person] = value!;
                  });
                },
                title: Text(person.name),
              ),
            FloatingActionButton(
                onPressed: _submitForm, child: const Icon(Icons.check)),
          ],
        ),
      )),
    );
  }
}
