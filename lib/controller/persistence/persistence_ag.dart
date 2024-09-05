import 'package:ag_selector/model/ag.dart';
import 'package:ag_selector/model/persistence_object.dart';
import 'package:ag_selector/model/weekdays.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class PersistenceAg {
  static const String tableName = "AGs";

  //Database field names:
  static const String nameDBField = "name";
  static const String descriptionDBField = "description";
  static const String maxPersonsDBField = "maxPersons";
  static const String weekdaysDBField = "weekdays";
  static const String startTimeDBField = "startTime";
  static const String endTimeDBField = "endTime";

  Future<AG?> getById(Database? database, int id) async {
    AG? ag;
    if (database != null && database.isOpen) {
      final List<Map<String, Object?>> agsMap = await database.query(tableName,
          where: '${PersistenceObject.idDBField} = ?', whereArgs: [id]);
      ag = fromObjectMap(agsMap.first);
    }
    return ag;
  }

  Future<List<AG>> load(Database? database) async {
    List<AG> ags = [];
    if (database != null && database.isOpen) {
      final List<Map<String, Object?>> agsMap = await database.query(tableName);
      for (Map<String, Object?> agEntry in agsMap) {
        AG newAG = fromObjectMap(agEntry);
        ags.add(newAG);
      }
    }
    return ags;
  }

  Future<int> insert(Database? database, AG ag) async {
    int id = -1;
    if (database != null && database.isOpen) {
      Map<String, Object> objectMap = toObjectMap(ag, false);
      id = await database.insert(tableName, objectMap);
    }
    return id;
  }

  Future<int> delete(Database? database, AG ag) async {
    Future<int> numberOfRowsAffected = Future(() => 0);
    if (database != null && database.isOpen) {
      numberOfRowsAffected = database.delete(tableName,
          where: "${PersistenceObject.idDBField} = ?", whereArgs: [ag.id]);
    }
    return numberOfRowsAffected;
  }

  void update(Database? database, AG ag) {
    if (database != null && database.isOpen) {
      database.update(tableName, toObjectMap(ag, true),
          where: '${PersistenceObject.idDBField} = ?', whereArgs: [ag.id]);
    }
  }

  Map<String, Object> toObjectMap(AG ag, bool withId) {
    Map<String, Object> objectMap = {};
    if (withId == true) {
      objectMap.putIfAbsent(PersistenceObject.idDBField, () => ag.id);
    }
    objectMap.putIfAbsent(nameDBField, () => ag.name);
    objectMap.putIfAbsent(descriptionDBField, () => ag.description);
    objectMap.putIfAbsent(maxPersonsDBField, () => ag.maxPersons);
    objectMap.putIfAbsent(
        weekdaysDBField, () => Weekdays.getByteCodeForWeekdays(ag.weekdays));
    objectMap.putIfAbsent(
        startTimeDBField, () => ag.startTime.millisecondsSinceEpoch);
    objectMap.putIfAbsent(
        endTimeDBField, () => ag.endTime.millisecondsSinceEpoch);
    return objectMap;
  }

  AG fromObjectMap(Map<String, Object?> objectMap) {
    int id = objectMap[PersistenceObject.idDBField] != null
        ? objectMap[PersistenceObject.idDBField] as int
        : -1;
    int maxPersons = objectMap[maxPersonsDBField] != null
        ? objectMap[maxPersonsDBField] as int
        : 0;
    String name =
        objectMap[nameDBField] != null ? objectMap[nameDBField] as String : "";
    String description = objectMap[descriptionDBField] != null
        ? objectMap[descriptionDBField] as String
        : "";
    List<String> weekdays = objectMap[weekdaysDBField] != null
        ? Weekdays.getWeekdaysFromByteCode(objectMap[weekdaysDBField] as int)
        : [];
    DateTime startTime = objectMap[startTimeDBField] != null
        ? DateTime.fromMillisecondsSinceEpoch(
            objectMap[startTimeDBField] as int)
        : DateTime.now();
    DateTime endTime = objectMap[endTimeDBField] != null
        ? DateTime.fromMillisecondsSinceEpoch(objectMap[endTimeDBField] as int)
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
}
