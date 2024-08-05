import 'package:ag_selector/controller/persistence/persistence_ag.dart';
import 'package:ag_selector/controller/persistence/persistence_person.dart';
import 'package:ag_selector/model/ag.dart';
import 'package:ag_selector/model/persistence_object.dart';
import 'package:ag_selector/model/person.dart';
import 'package:ag_selector/model/person_ag_preference.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class PersistencePersonAgPreferences {
  static const String tableName = "PersonPreferences";

  //Database field names:
  static const String agIdDBField = "agId";
  static const String personIdDBField = "personId";
  static const String preferenceNumberDBField = "preferenceNumber";
  static const String weekdayDBField = "weekday";

  Future<int> insert(
      Database? database, PersonAgPreference personAgPreference) async {
    int id = -1;
    if (database != null && database.isOpen) {
      Map<String, Object> objectMap = toObjectMap(personAgPreference, false);
      id = await database.insert(tableName, objectMap);
    }
    return id;
  }

  Future<List<PersonAgPreference>> getPersonAgPreferencesForPerson(
      Database? database,
      Person person,
      PersistenceAg persistenceAg,
      PersistencePerson persistencePerson) async {
    List<PersonAgPreference> personAGPreferences = [];
    if (database != null && database.isOpen) {
      final List<Map<String, Object?>> personAGPreferencesMap = await database
          .query(tableName,
              where: '$personIdDBField = ?', whereArgs: [person.id]);
      for (Map<String, Object?> personAGPreferencesEntry
          in personAGPreferencesMap) {
        PersonAgPreference? newPersonAGPreference = await fromObjectMap(
            database,
            personAGPreferencesEntry,
            persistenceAg,
            persistencePerson);
        if (newPersonAGPreference != null) {
          personAGPreferences.add(newPersonAGPreference);
        }
      }
    }
    return personAGPreferences;
  }

  Future<int> deletePersonAgPreferencesForAG(Database? database, AG ag) {
    Future<int> numberOfRowsAffected = Future(() => 0);
    if (database != null && database.isOpen) {
      numberOfRowsAffected = database
          .delete(tableName, where: "$agIdDBField = ?", whereArgs: [ag.id]);
    }
    return numberOfRowsAffected;
  }

  Future<int> deletePersonAgPreferencesForPerson(
      Database? database, Person person) {
    Future<int> numberOfRowsAffected = Future(() => 0);
    if (database != null && database.isOpen) {
      numberOfRowsAffected = database.delete(tableName,
          where: "$personIdDBField = ?", whereArgs: [person.id]);
    }
    return numberOfRowsAffected;
  }

  Map<String, Object> toObjectMap(
      PersonAgPreference personAGPreferences, bool withId) {
    Map<String, Object> objectMap = {};
    if (withId == true) {
      objectMap.putIfAbsent(
          PersistenceObject.idDBField, () => personAGPreferences.id);
    }
    objectMap.putIfAbsent(personIdDBField, () => personAGPreferences.person.id);
    objectMap.putIfAbsent(agIdDBField, () => personAGPreferences.ag.id);
    objectMap.putIfAbsent(weekdayDBField, () => personAGPreferences.weekday);
    objectMap.putIfAbsent(
        preferenceNumberDBField, () => personAGPreferences.preferenceNumber);
    return objectMap;
  }

  Future<PersonAgPreference?> fromObjectMap(
      Database? database,
      Map<String, Object?> objectMap,
      PersistenceAg persistenceAg,
      PersistencePerson persistencePerson) async {
    int id = objectMap[PersistenceObject.idDBField] != null
        ? objectMap[PersistenceObject.idDBField] as int
        : -1;
    int personId = objectMap[personIdDBField] != null
        ? objectMap[personIdDBField] as int
        : -1;
    int agId =
        objectMap[agIdDBField] != null ? objectMap[agIdDBField] as int : -1;
    String weekday = objectMap[weekdayDBField] != null
        ? objectMap[weekdayDBField] as String
        : "";
    int preferenceNumber = objectMap[preferenceNumberDBField] != null
        ? objectMap[preferenceNumberDBField] as int
        : -1;

    if (database != null && database.isOpen) {
      Person? person = await persistencePerson.getById(database, personId);
      AG? ag = await persistenceAg.getById(database, agId);
      if (person != null && ag != null) {
        PersonAgPreference newPersonAGPreference = PersonAgPreference(
            id: id,
            ag: ag,
            person: person,
            weekday: weekday,
            preferenceNumber: preferenceNumber);
        return newPersonAGPreference;
      }
    }
    return null;
  }
}
