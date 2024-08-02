import 'dart:async';

import 'package:ag_selector/model/ag.dart';
import 'package:ag_selector/model/persistend_object.dart';
import 'package:ag_selector/model/person.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class PersistendManager {
  Database? database;

  static const String agIdDBField = "agId";
  static const String personIdDBField = "personId";
  static const String preferenceNumberDBField = "preferenceNumber";
  static const String weekdayDBField = "weekday";

  static const String agsTableName = "AGs";
  static const String personsTableName = "Persons";
  static const String personPreferencesTableName = "PersonPreferences";
  static const String settingsTableName = "Settings";
  static const String defaultDatabaseName = "ag_selector.db";

  PersistendManager() {
    sqfliteFfiInit();
    databaseFactory = getDatabaseFactory();
  }

  Future<List<AG>> loadAgs() async {
    List<AG> ags = [];
    if (database != null && database!.isOpen) {
      final List<Map<String, Object?>> agsMap =
          await database!.query(agsTableName);
      for (Map<String, Object?> agEntry in agsMap) {
        AG newAG = AG.fromObjectMap(agEntry);
        ags.add(newAG);
      }
    }
    return ags;
  }

  Future<List<Person>> loadPersons() async {
    List<Person> persons = [];
    if (database != null && database!.isOpen) {
      final List<Map<String, Object?>> personsMap =
          await database!.query(personsTableName);
      for (Map<String, Object?> personEntry in personsMap) {
        Person newPerson = Person.fromObjectMap(personEntry);
        persons.add(newPerson);
      }
    }
    return persons;
  }

  void insertPersonAGPairIntoPersonPreferenceTable(int personId, int agId) {}

  Map<String, Map<int, AG>> getAGPreferencesForPersonFromPersonPreferenceTable(
      int personId) async {
    List<AG> ags = [];
    if (database != null && database!.isOpen) {
      //get all ag ids for the given person id
      final List<Map<String, Object?>> agsIdMap = await database!.query(
          personPreferencesTableName,
          columns: [agIdDBField, preferenceNumberDBField, weekdayDBField],
          where: "$personIdDBField = ?",
          whereArgs: [personId]);
      Map<int, Map<int, 
      //put all the ids in a sql list string
      String agsIds = "";
      for (Map<String, Object?> agIdEntry in agsIdMap) {
        Object? agIdEntryId = agIdEntry[PersistendObject.idDBField];
        if (agIdEntryId is int) {
          agsIds += "$agIdEntryId,";
        }
      }
      //remove last comma
      if (agsIds.isNotEmpty) {
        agsIds.substring(0, agsIds.length - 1);
      }
      //get all ags where the id is in the ag id list
      final List<Map<String, Object?>> agsMap = await database!.query(
          agsTableName,
          columns: [PersistendObject.idDBField],
          where: "${PersistendObject.idDBField} IN ($agsIds)",
          whereArgs: [personId]);

      for (Map<String, Object?> agEntry in agsMap) {
        AG newAG = AG.fromObjectMap(agEntry);
        ags.add(newAG);
      }
    }
    Map<String, Map<int, AG>> agPreferencesByWeekday = <String, Map<int, AG>>{};
    return agPreferencesByWeekday;
  }

  void deleteAGFromPersonPreferenceTable(int agId) {}

  void deletePersonFromPersonPreferenceTable(int personId) {}

  Future<int> addPersistendObject(
      String tableName, PersistendObject persistendObject) async {
    int id = -1;
    if (database != null && database!.isOpen) {
      Map<String, Object> objectMap = persistendObject.toObjectMap(false);
      id = await database!.insert(agsTableName, objectMap);
    }
    return id;
  }

  Future<int> deletePersistendObject(
      String tableName, PersistendObject persistendObject) async {
    Future<int> numberOfRowsAffected = Future(() => 0);
    if (database != null && database!.isOpen) {
      numberOfRowsAffected = database!.delete(tableName,
          where: "${PersistendObject.idDBField} = ?",
          whereArgs: [persistendObject.id]);
    }
    return numberOfRowsAffected;
  }

  void editPersistendObject(
      String tableName, PersistendObject persistendObject) {
    if (database != null && database!.isOpen) {
      database!.update(tableName, persistendObject.toObjectMap(true));
    }
  }

  Future<void> initDatabase() async {
    if (database != null && database!.isOpen) {
      int millisecondsSinceEpoch = DateTime.now().millisecondsSinceEpoch;

      print("creating Settings Table");
      //create AGS Table
      await database!.execute('''
        CREATE TABLE IF NOT EXISTS $settingsTableName (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          description TEXT NOT NULL,
          value TEXT NOT NULL
        )
      ''');

      print("creating AGs Table");
      //create AGS Table
      await database!.execute('''
        CREATE TABLE IF NOT EXISTS $agsTableName (
          ${PersistendObject.idDBField} INTEGER PRIMARY KEY AUTOINCREMENT,
          ${AG.nameDBField} TEXT NOT NULL,
          ${AG.descriptionDBField} TEXT NOT NULL,
          ${AG.maxPersonsDBField} INTEGER NOT NULL,
          ${AG.weekdaysDBField} INTEGER NOT NULL,
          ${AG.startTimeDBField} INTEGER NOT NULL DEFAULT $millisecondsSinceEpoch,
          ${AG.endTimeDBField} INTEGER NOT NULL DEFAULT $millisecondsSinceEpoch
        )
      ''');

      print("creating Persons Table");
      //create Persons Table
      await database!.execute('''
        CREATE TABLE IF NOT EXISTS $personsTableName (
          ${PersistendObject.idDBField} INTEGER PRIMARY KEY AUTOINCREMENT,
          ${Person.nameDBField} TEXT NOT NULL,
          ${Person.houseDBField} TEXT NOT NULL,
          ${Person.schoolClassDBField} TEXT NOT NULL,
          ${Person.weekdaysPresentDBField} INTEGER NOT NULL
        )
      ''');

      print("creating Person Preference Table");
      //create Person Preference Table
      await database!.execute('''
        CREATE TABLE IF NOT EXISTS $personPreferencesTableName (
          ${PersistendObject.idDBField} INTEGER PRIMARY KEY AUTOINCREMENT,
          $agIdDBField INTEGER NOT NULL,
          $personIdDBField INTEGER NOT NULL,
          $weekdayDBField TEXT NOT NULL,
          $preferenceNumberDBField INTEGER NOT NULL,
          FOREIGN KEY ($agIdDBField) REFERENCES AGs(${PersistendObject.idDBField}),
          FOREIGN KEY ($personIdDBField) REFERENCES Persons(${PersistendObject.idDBField})
        )
      ''');
    }
  }

  void bindDatabase(Future<String> path, String databaseName) async {
    final String resolvedPath = await path;
    String fullPath = "$resolvedPath/$databaseName";
    database = await openDatabase(fullPath);
    await initDatabase();
  }

  void unbindDatabase() {
    if (database != null && database!.isOpen) {
      database!.close();
    }
  }

  Future<String> getDefaultDatabasePath() {
    return getDatabasesPath();
  }

  DatabaseFactory? getDatabaseFactory() {
    if (kIsWeb) {
      // Use web factory for web platform
      return databaseFactoryFfiWeb;
    } else {
      // Use sqfliteFfi factory for Windows platform
      return databaseFactoryFfi; // Assuming you're using sqflite_common_ffi
    }
  }
}
