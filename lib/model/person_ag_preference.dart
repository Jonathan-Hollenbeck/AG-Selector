import 'package:ag_selector/model/ag.dart';
import 'package:ag_selector/model/persistence_object.dart';
import 'package:ag_selector/model/person.dart';

class PersonAgPreference implements PersistenceObject{
  @override
  int id;
  int preferenceNumber;

  Person person;

  AG ag;

  String weekday;

  PersonAgPreference({
    required this.id,
    required this.preferenceNumber,
    required this.weekday,
    required this.person,
    required this.ag,
  });
}