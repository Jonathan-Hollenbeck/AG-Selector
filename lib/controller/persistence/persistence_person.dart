import 'package:ag_selector/model/persistence_object.dart';
import 'package:ag_selector/model/person.dart';
import 'package:ag_selector/model/weekdays.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class PersistencePerson {
  static const String tableName = "Persons";

  //Database field names:
  static const String nameDBField = "name";
  static const String houseDBField = "description";
  static const String schoolClassDBField = "maxPersons";
  static const String weekdaysPresentDBField = "weekdays";

  Future<Person?> getById(Database? database, int id) async {
    Person? person;
    if (database != null && database.isOpen) {
      final List<Map<String, Object?>> personsMap = await database.query(tableName,
          where: '${PersistenceObject.idDBField} = ?', whereArgs: [id]);
      person = fromObjectMap(personsMap.first);
    }
    return person;
  }

  Future<List<Person>> load(Database? database) async {
    List<Person> persons = [];
    if (database != null && database.isOpen) {
      final List<Map<String, Object?>> personsMap =
          await database.query(tableName);
      for (Map<String, Object?> personEntry in personsMap) {
        Person newPerson = fromObjectMap(personEntry);
        persons.add(newPerson);
      }
    }
    return persons;
  }

  Future<int> insert(Database? database, Person person) async {
    int id = -1;
    if (database != null && database.isOpen) {
      Map<String, Object> objectMap = toObjectMap(person, false);
      id = await database.insert(tableName, objectMap);
    }
    return id;
  }

  Future<int> delete(Database? database, Person person) async {
    Future<int> numberOfRowsAffected = Future(() => 0);
    if (database != null && database.isOpen) {
      numberOfRowsAffected = database.delete(tableName,
          where: "${PersistenceObject.idDBField} = ?", whereArgs: [person.id]);
    }
    return numberOfRowsAffected;
  }

  void update(Database? database, Person person) {
    if (database != null && database.isOpen) {
      database.update(tableName, toObjectMap(person, true));
    }
  }

  Map<String, Object> toObjectMap(Person person, bool withId) {
    Map<String, Object> objectMap = {};
    if (withId == true) {
      objectMap.putIfAbsent(PersistenceObject.idDBField, () => person.id);
    }
    objectMap.putIfAbsent(nameDBField, () => person.name);
    objectMap.putIfAbsent(houseDBField, () => person.house);
    objectMap.putIfAbsent(schoolClassDBField, () => person.schoolClass);
    objectMap.putIfAbsent(weekdaysPresentDBField,
        () => Weekdays.getByteCodeForWeekdays(person.weekdaysPresent));
    return objectMap;
  }

  Person fromObjectMap(Map<String, Object?> objectMap) {
    int id = objectMap[PersistenceObject.idDBField] != null
        ? objectMap[PersistenceObject.idDBField] as int
        : -1;
    String name = objectMap[nameDBField] != null
        ? objectMap[nameDBField] as String
        : "";
    String house = objectMap[houseDBField] != null
        ? objectMap[houseDBField] as String
        : "";
    String schoolClass = objectMap[schoolClassDBField] != null
        ? objectMap[schoolClassDBField] as String
        : "";
    List<String> weekdaysPresent =
        objectMap[weekdaysPresentDBField] != null
            ? Weekdays.getWeekdaysFromByteCode(
                objectMap[weekdaysPresentDBField] as int)
            : [];
    Person newPerson = Person(
        id: id,
        name: name,
        house: house,
        schoolClass: schoolClass,
        weekdaysPresent: weekdaysPresent);
    return newPerson;
  }
}
