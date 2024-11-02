import 'package:ag_selector/model/person.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class PersistencePersonApart {
  static const String tableName = "PersonsApart";

  //Database field names:
  static const String personAIdDBField = "personAId";
  static const String personBIdDBField = "personBId";

  Future<Map<int, Set<int>>> load(Database? database) async {
    Map<int, Set<int>> personApartMap = {};
    if (database != null && database.isOpen) {
      final List<Map<String, Object?>> objectMap =
          await database.query(tableName);
      for (Map<String, Object?> entry in objectMap) {
        List<int> newEntry = fromObjectMap(entry);
        //add for person A
        if(!personApartMap.containsKey(newEntry[0])){
          personApartMap[newEntry[0]] =  {};
        }
        personApartMap[newEntry[0]]!.add(newEntry[1]);
        //add for person B
        if(!personApartMap.containsKey(newEntry[1])){
          personApartMap[newEntry[1]] =  {};
        }
        personApartMap[newEntry[1]]!.add(newEntry[0]);
      }
    }
    return personApartMap;
  }

  void insert(Database? database, Person personA, Person personB) async {
    if (database != null && database.isOpen) {
      Map<String, Object> objectMap = toObjectMap(personA, personB);
      await database.insert(tableName, objectMap);
    }
  }

  Future<int> delete(Database? database, Person personA) async {
    Future<int> numberOfRowsAffected = Future(() => 0);
    if (database != null && database.isOpen) {
      numberOfRowsAffected = database.delete(tableName,
          where: "$personAIdDBField = ? OR $personBIdDBField = ?", whereArgs: [personA.id, personA.id]);
    }
    return numberOfRowsAffected;
  }

  Map<String, Object> toObjectMap(Person personA, Person personB) {
    Map<String, Object> objectMap = {};
    objectMap.putIfAbsent(personAIdDBField, () => personA.id);
    objectMap.putIfAbsent(personBIdDBField, () => personB.id);
    return objectMap;
  }

  List<int> fromObjectMap(Map<String, Object?> objectMap) {
    int personAId = objectMap[personAIdDBField] != null
        ? objectMap[personAIdDBField] as int
        : -1;
    int personBId = objectMap[personBIdDBField] != null
        ? objectMap[personBIdDBField] as int
        : -1;
    return [personAId, personBId];
  }
}
