import 'package:ag_selector/model/persistence_object.dart';
import 'package:ag_selector/util/string_utils.dart';

class AG implements PersistenceObject {
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
  String toString() {
    return "Name: $name, Wochentage: ${StringUtils.stringListToString(weekdays)}, Beginn: ${StringUtils.timeToString(startTime.hour, startTime.minute)}, Ende: ${StringUtils.timeToString(endTime.hour, endTime.minute)}, Beschreibung: $description, max Personen: $maxPersons";
  }

  String toShortString() {
    return "$name, Wochentage: ${weekdays.length}, ${StringUtils.timeToString(startTime.hour, startTime.minute)} - ${StringUtils.timeToString(endTime.hour, endTime.minute)}, $description, $maxPersons";
  }
}
