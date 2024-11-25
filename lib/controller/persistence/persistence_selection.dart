import 'package:ag_selector/controller/persistence/persistence_manager.dart';
import 'package:ag_selector/model/ag.dart';
import 'package:ag_selector/model/persistence_object.dart';
import 'package:ag_selector/model/person.dart';
import 'package:ag_selector/model/selection_object.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class PersistenceSelection {
  static const String tableName = "Selection";

  //Database field names:
  static const String personIdDBField = "personId";
  static const String agIdDBField = "agId";
  static const String weekdayDBField = "weekday";

  Future<List<SelectionObject>> load(Database? database, PersistenceManager persistenceManager) async {
    List<SelectionObject> selection = [];
    if (database != null && database.isOpen) {
      final List<Map<String, Object?>> selectionMap =
          await database.query(tableName);
      for (Map<String, Object?> selectionEntry in selectionMap) {
        SelectionObject? newSelection = await fromObjectMap(selectionEntry, persistenceManager);
        if(newSelection != null){
          selection.add(newSelection);
        }
      }
    }
    return selection;
  }

  Future<List<SelectionObject>> insertAll(Database? database, List<SelectionObject> selection) async {
    if (database != null && database.isOpen) {
      for(SelectionObject selectionObject in selection){
        Map<String, Object> objectMap = toObjectMap(selectionObject, false);
        selectionObject.id = await database.insert(tableName, objectMap);
      }
    }
    return selection;
  }

  void deleteAll(Database? database) async {
    if (database != null && database.isOpen) {
      database.delete(tableName);
    }
  }

  Map<String, Object> toObjectMap(SelectionObject selectionObject, bool withId) {
    Map<String, Object> objectMap = {};
    if (withId == true) {
      objectMap.putIfAbsent(PersistenceObject.idDBField, () => selectionObject.id);
    }
    objectMap.putIfAbsent(personIdDBField, () => selectionObject.person.id);
    objectMap.putIfAbsent(weekdayDBField, () => selectionObject.weekday);
    objectMap.putIfAbsent(agIdDBField, () => selectionObject.ag.id);
    return objectMap;
  }

  Future<SelectionObject?> fromObjectMap(Map<String, Object?> objectMap, PersistenceManager persistenceManager) async {
    int id = objectMap[PersistenceObject.idDBField] != null
        ? objectMap[PersistenceObject.idDBField] as int
        : -1;
    int personId = objectMap[personIdDBField] as int;
    Person? person = await persistenceManager.loadPersonById(personId);

    int agId = objectMap[agIdDBField] as int;
    AG? ag = await persistenceManager.loadAgById(agId);

    if(person == null || ag == null){
      return null;
    }

    String weekday = objectMap[weekdayDBField] as String;
    return SelectionObject(id: id, weekday: weekday, person: person, ag: ag);
  }
}
