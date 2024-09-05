import 'package:ag_selector/model/persistence_object.dart';

class Person implements PersistenceObject {
  @override
  int id;

  String name;
  String house;
  String schoolClass;

  List<String> weekdaysPresent;

  Person({
    required this.id,
    required this.name,
    required this.house,
    required this.schoolClass,
    required this.weekdaysPresent,
  });

  static Person createEmptyPerson() {
    return Person(
        id: -1,
        name: "",
        house: "",
        schoolClass: "",
        weekdaysPresent: List.empty());
  }

  @override
  String toString() {
    return "Name: $name, Haus: $house, Klasse: $schoolClass, Wochentage anwesend: ${weekdaysPresent.length}";
  }

  String toShortString() {
    return "$name, $house, $schoolClass";
  }
}
