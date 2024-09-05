import 'package:ag_selector/model/ag.dart';
import 'package:ag_selector/model/persistence_object.dart';
import 'package:ag_selector/model/person.dart';

class SelectionObject implements PersistenceObject {
  @override
  int id;

  Person person;

  AG ag;

  String weekday;

  SelectionObject({
    required this.id,
    required this.weekday,
    required this.person,
    required this.ag,
  });
}
