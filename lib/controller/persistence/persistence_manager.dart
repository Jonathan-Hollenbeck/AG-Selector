import 'dart:async';

import 'package:ag_selector/controller/persistence/persistence_ag.dart';
import 'package:ag_selector/controller/persistence/persistence_person.dart';
import 'package:ag_selector/controller/persistence/persistence_person_ag_preferences.dart';
import 'package:ag_selector/controller/persistence/persistence_settings.dart';
import 'package:ag_selector/model/ag.dart';
import 'package:ag_selector/model/persistence_object.dart';
import 'package:ag_selector/model/person.dart';
import 'package:ag_selector/model/person_ag_preference.dart';
import 'package:ag_selector/model/settings.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class PersistenceManager {
  Database? database;

  static const String defaultDatabaseName = "ag_selector.db";

  late PersistenceAg persistenceAg;
  late PersistencePerson persistencePerson;
  late PersistencePersonAgPreferences persistencePersonAgPreferences;
  late PersistenceSettings persistenceSettings;

  PersistenceManager() {
    sqfliteFfiInit();
    databaseFactory = getDatabaseFactory();
    persistenceAg = PersistenceAg();
    persistencePerson = PersistencePerson();
    persistencePersonAgPreferences = PersistencePersonAgPreferences();
    persistenceSettings = PersistenceSettings();
  }

  ///AG

  Future<List<AG>> loadAgs() async {
    List<AG> ags = await persistenceAg.load(database);
    ags.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return ags;
  }

  Future<int> insertAG(AG ag) async {
    int id = await persistenceAg.insert(database, ag);
    return id;
  }

  Future<int> deleteAG(AG ag) async {
    int numberOfRowsAffected = await persistenceAg.delete(database, ag);
    deletePersonAgPreferenceForAG(ag);
    return numberOfRowsAffected;
  }

  void updateAG(AG ag) {
    persistenceAg.update(database, ag);
  }

  ///Person

  Future<List<Person>> loadPersons() async {
    List<Person> persons = await persistencePerson.load(database);
    persons
        .sort((a, b) => a.house.toLowerCase().compareTo(b.house.toLowerCase()));
    return persons;
  }

  Future<List<Person>> loadPersonsFilter(
      String house, String schoolClass) async {
    List<Person> persons =
        await persistencePerson.loadFilter(database, house, schoolClass);
    persons
        .sort((a, b) => a.house.toLowerCase().compareTo(b.house.toLowerCase()));
    return persons;
  }

  Future<int> insertPerson(Person person) async {
    int id = await persistencePerson.insert(database, person);
    return id;
  }

  Future<int> deletePerson(Person person) async {
    int numberOfRowsAffected = await persistencePerson.delete(database, person);
    deletePersonAgPreferencesForPerson(person);
    return numberOfRowsAffected;
  }

  void updatePerson(Person person) {
    persistencePerson.update(database, person);
  }

  ///PersonAgPreferences

  Future<int> insertPersonAgPreference(
      PersonAgPreference personAgPreference) async {
    int id = await persistencePersonAgPreferences.insert(
        database, personAgPreference);
    return id;
  }

  Future<List<PersonAgPreference>> getPersonAgPreferences(Person person) async {
    List<PersonAgPreference> agPreferencesByWeekday =
        await persistencePersonAgPreferences.getPersonAgPreferencesForPerson(
            database, person, persistenceAg, persistencePerson);
    return agPreferencesByWeekday;
  }

  Future<int> deletePersonAgPreferenceForAG(AG ag) async {
    int numberOfRowsAffected = await persistencePersonAgPreferences
        .deletePersonAgPreferencesForAG(database, ag);
    return numberOfRowsAffected;
  }

  Future<int> deletePersonAgPreferencesForPerson(Person person) async {
    int numberOfRowsAffected = await persistencePersonAgPreferences
        .deletePersonAgPreferencesForPerson(database, person);
    return numberOfRowsAffected;
  }

  ///Settings

  Future<Settings> loadSettings() async {
    Settings settings = await persistenceSettings.load(database);
    return settings;
  }

  void insertSettings(Settings settings) async {
    persistenceSettings.insertAllSettings(database, settings);
  }

  ///Database
  Future<void> initDatabase() async {
    if (database != null && database!.isOpen) {
      int millisecondsSinceEpoch = DateTime.now().millisecondsSinceEpoch;

      //create AGS Table
      await database!.execute('''
        CREATE TABLE IF NOT EXISTS ${PersistenceSettings.tableName} (
          ${PersistenceObject.idDBField} INTEGER PRIMARY KEY AUTOINCREMENT,
          ${PersistenceSettings.keyDBField} TEXT NOT NULL,
          ${PersistenceSettings.valueDBField} TEXT NOT NULL
        )
      ''');

      //create AGS Table
      await database!.execute('''
        CREATE TABLE IF NOT EXISTS ${PersistenceAg.tableName} (
          ${PersistenceObject.idDBField} INTEGER PRIMARY KEY AUTOINCREMENT,
          ${PersistenceAg.nameDBField} TEXT NOT NULL,
          ${PersistenceAg.descriptionDBField} TEXT NOT NULL,
          ${PersistenceAg.maxPersonsDBField} INTEGER NOT NULL,
          ${PersistenceAg.weekdaysDBField} INTEGER NOT NULL,
          ${PersistenceAg.startTimeDBField} INTEGER NOT NULL DEFAULT $millisecondsSinceEpoch,
          ${PersistenceAg.endTimeDBField} INTEGER NOT NULL DEFAULT $millisecondsSinceEpoch
        )
      ''');

      //create Persons Table
      await database!.execute('''
        CREATE TABLE IF NOT EXISTS ${PersistencePerson.tableName}(
          ${PersistenceObject.idDBField} INTEGER PRIMARY KEY AUTOINCREMENT,
          ${PersistencePerson.nameDBField} TEXT NOT NULL,
          ${PersistencePerson.houseDBField} TEXT NOT NULL,
          ${PersistencePerson.schoolClassDBField} TEXT NOT NULL,
          ${PersistencePerson.weekdaysPresentDBField} INTEGER NOT NULL
        )
      ''');

      //create Person Preference Table
      await database!.execute('''
        CREATE TABLE IF NOT EXISTS ${PersistencePersonAgPreferences.tableName} (
          ${PersistenceObject.idDBField} INTEGER PRIMARY KEY AUTOINCREMENT,
          ${PersistencePersonAgPreferences.agIdDBField} INTEGER NOT NULL,
          ${PersistencePersonAgPreferences.personIdDBField} INTEGER NOT NULL,
          ${PersistencePersonAgPreferences.weekdayDBField} TEXT NOT NULL,
          ${PersistencePersonAgPreferences.preferenceNumberDBField} INTEGER NOT NULL,
          FOREIGN KEY (${PersistencePersonAgPreferences.agIdDBField}) REFERENCES ${PersistenceAg.tableName}(${PersistenceObject.idDBField}),
          FOREIGN KEY (${PersistencePersonAgPreferences.personIdDBField}) REFERENCES ${PersistencePerson.tableName}(${PersistenceObject.idDBField})
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
    //else its the default for all other platforms
  }
}
