import 'package:ag_selector/model/ag.dart';
import 'package:ag_selector/model/persistend_object.dart';
import 'package:ag_selector/model/weekdays.dart';

class Person implements PersistendObject {
  //Database field names:
  static const String nameDBField = "name";
  static const String houseDBField = "description";
  static const String schoolClassDBField = "maxPersons";
  static const String weekdaysPresentDBField = "weekdays";

  @override
  int id;

  String name;
  String house;
  String schoolClass;

  List<String> weekdaysPresent;

  Map<String, Map<int, AG>> agPreferencesByWeekday;

  Person({
    required this.id,
    required this.name,
    required this.house,
    required this.schoolClass,
    required this.weekdaysPresent,
    required this.agPreferencesByWeekday,
  });

  static Person createEmptyPerson() {
    return Person(
        id: -1,
        name: "",
        house: "",
        schoolClass: "",
        weekdaysPresent: List.empty(),
        agPreferencesByWeekday: <String, Map<int, AG>>{});
  }

  @override
  Map<String, Object> toObjectMap(bool withId) {
    Map<String, Object> objectMap = {};
    if (withId == true) {
      objectMap.putIfAbsent(PersistendObject.idDBField, () => id);
    }
    objectMap.putIfAbsent(Person.nameDBField, () => name);
    objectMap.putIfAbsent(Person.houseDBField, () => house);
    objectMap.putIfAbsent(Person.schoolClassDBField, () => schoolClass);
    objectMap.putIfAbsent(Person.weekdaysPresentDBField,
        () => Weekdays.getByteCodeForWeekdays(weekdaysPresent));
    return objectMap;
  }

  static Person fromObjectMap(Map<String, Object?> objectMap,
      Map<String, Map<int, AG>> agPreferencesByWeekday) {
    int id = objectMap[PersistendObject.idDBField] != null
        ? objectMap[PersistendObject.idDBField] as int
        : -1;
    String name = objectMap[Person.nameDBField] != null
        ? objectMap[Person.nameDBField] as String
        : "";
    String house = objectMap[Person.houseDBField] != null
        ? objectMap[Person.houseDBField] as String
        : "";
    String schoolClass = objectMap[Person.schoolClassDBField] != null
        ? objectMap[Person.schoolClassDBField] as String
        : "";
    List<String> weekdaysPresent =
        objectMap[Person.weekdaysPresentDBField] != null
            ? Weekdays.getWeekdaysFromByteCode(
                objectMap[Person.weekdaysPresentDBField] as int)
            : [];
    Person newPerson = Person(
        id: id,
        name: name,
        house: house,
        schoolClass: schoolClass,
        weekdaysPresent: weekdaysPresent,
        agPreferencesByWeekday: agPreferencesByWeekday);
    return newPerson;
  }

  @override
  String toString() {
    return "Name: $name, Haus: $house, Klasse: $schoolClass, Wochentage anwesend: ${weekdaysPresent.length}, Präferenzen gesetzt: ${agPreferencesByWeekday.isNotEmpty}";
  }

  String toShortString() {
    return "$name, $house, $schoolClass";
  }
}
