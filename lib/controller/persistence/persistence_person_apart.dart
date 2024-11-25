import 'package:ag_selector/controller/persistence/persistence_manager.dart';
import 'package:ag_selector/model/person.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class PersistencePersonApart {
  static const String tableName = "PersonsApart";

  //Database field names:
  static const String personAIdDBField = "personAId";
  static const String personBIdDBField = "personBId";

  Future<Map<Person, Set<Person>>> load(Database? database, PersistenceManager persistenceManager) async {
    Map<Person, Set<Person>> personApartMap = {};
    if (database != null && database.isOpen) {
      final List<Map<String, Object?>> objectMap =
          await database.query(tableName);
      for (Map<String, Object?> entry in objectMap) {
        List<Person>? newEntry = await fromObjectMap(entry, persistenceManager);
        if(newEntry != null){
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
    }
    return personApartMap;
  }

  Future<List<Person>> loadForPerson(Database? database, Person person, PersistenceManager persistenceManager) async {
    List<Person> personsApart = [];
    if (database != null && database.isOpen) {
      final List<Map<String, Object?>> objectMap =
          await database.query(tableName,
            where: "$personAIdDBField = ? OR $personBIdDBField = ?", whereArgs: [person.id, person.id]);
      for (Map<String, Object?> entry in objectMap) {
        List<Person>? newEntry = await fromObjectMap(entry, persistenceManager);
        if(newEntry != null){
          Person newPerson = newEntry[0] == person ? newEntry[0] : newEntry[1];
          personsApart.add(newPerson);
        }
      }
    }
    return personsApart;
  }

  void insertAll(Database? database, Person personA, List<Person> persons) async {
    if (database != null && database.isOpen) {
      for(Person personB in persons){
        Map<String, Object> objectMap = toObjectMap(personA, personB);
        await database.insert(tableName, objectMap);
      }
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

  Future<List<Person>?> fromObjectMap(Map<String, Object?> objectMap, PersistenceManager persistenceManager) async {
    int personAId = objectMap[personAIdDBField] as int;
    int personBId = objectMap[personBIdDBField] as int;

    Person? personA = await persistenceManager.loadPersonById(personAId);
    Person? personB = await persistenceManager.loadPersonById(personBId);

    if(personA == null || personB == null){
      return null;
    }

    return [personA, personB];
  }
}
