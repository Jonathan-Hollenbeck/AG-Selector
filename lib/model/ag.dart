import 'package:ag_selector/model/persistend_object.dart';
import 'package:ag_selector/model/weekdays.dart';
import 'package:ag_selector/util/string_utils.dart';

class AG implements PersistendObject {
  //Database field names:
  static const String nameDBField = "name";
  static const String descriptionDBField = "description";
  static const String maxPersonsDBField = "maxPersons";
  static const String weekdaysDBField = "weekdays";
  static const String startTimeDBField = "startTime";
  static const String endTimeDBField = "endTime";

  String name;
  String description;

  @override
  int id;
  int maxPersons;

  List<String> weekdays;

  DateTime startTime;
  DateTime endTime;

  AG({
    required this.id,
    required this.name,
    required this.weekdays,
    required this.startTime,
    required this.endTime,
    required this.description,
    required this.maxPersons,
  });

  static AG createEmptyAG() {
    return AG(
        id: -1,
        name: "",
        weekdays: List.empty(),
        startTime: DateTime.now(),
        endTime: DateTime.now(),
        description: "",
        maxPersons: 0);
  }

  @override
  Map<String, Object> toObjectMap(bool withId) {
    Map<String, Object> objectMap = {};
    if (withId == true) {
      objectMap.putIfAbsent(PersistendObject.idDBField, () => id);
    }
    objectMap.putIfAbsent(AG.nameDBField, () => name);
    objectMap.putIfAbsent(AG.descriptionDBField, () => description);
    objectMap.putIfAbsent(AG.maxPersonsDBField, () => maxPersons);
    objectMap.putIfAbsent(
        AG.weekdaysDBField, () => Weekdays.getByteCodeForWeekdays(weekdays));
    objectMap.putIfAbsent(
        AG.startTimeDBField, () => startTime.millisecondsSinceEpoch);
    objectMap.putIfAbsent(
        AG.endTimeDBField, () => endTime.millisecondsSinceEpoch);
    return objectMap;
  }

  static AG fromObjectMap(Map<String, Object?> objectMap) {
    int id = objectMap[PersistendObject.idDBField] != null
        ? objectMap[PersistendObject.idDBField] as int
        : -1;
    int maxPersons = objectMap[AG.maxPersonsDBField] != null
        ? objectMap[AG.maxPersonsDBField] as int
        : 0;
    String name = objectMap[AG.nameDBField] != null
        ? objectMap[AG.nameDBField] as String
        : "";
    String description = objectMap[AG.descriptionDBField] != null
        ? objectMap[AG.descriptionDBField] as String
        : "";
    List<String> weekdays = objectMap[AG.weekdaysDBField] != null
        ? Weekdays.getWeekdaysFromByteCode(objectMap[AG.weekdaysDBField] as int)
        : [];
    DateTime startTime = objectMap[AG.startTimeDBField] != null
        ? DateTime.fromMillisecondsSinceEpoch(
            objectMap[AG.startTimeDBField] as int)
        : DateTime.now();
    DateTime endTime = objectMap[AG.endTimeDBField] != null
        ? DateTime.fromMillisecondsSinceEpoch(
            objectMap[AG.endTimeDBField] as int)
        : DateTime.now();
    AG newAG = AG(
        id: id,
        name: name,
        weekdays: weekdays,
        startTime: startTime,
        endTime: endTime,
        description: description,
        maxPersons: maxPersons);
    return newAG;
  }

  @override
  String toString() {
    return "Name: $name, Wochentage: ${StringUtils.stringListToString(weekdays)}, Beginn: ${StringUtils.timeToString(startTime.hour, startTime.minute)}, Ende: ${StringUtils.timeToString(endTime.hour, endTime.minute)}, Beschreibung: $description, max Personen: $maxPersons";
  }

  String toShortString() {
    return "$name, Wochentage: ${weekdays.length}, ${StringUtils.timeToString(startTime.hour, startTime.minute)} - ${StringUtils.timeToString(endTime.hour, endTime.minute)}, $description, $maxPersons";
  }
}
