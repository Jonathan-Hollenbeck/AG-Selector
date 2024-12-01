import 'dart:async';
import 'dart:io';

import 'package:ag_selector/controller/persistence/persistence_ag.dart';
import 'package:ag_selector/controller/persistence/persistence_person.dart';
import 'package:ag_selector/controller/persistence/persistence_person_ag_preferences.dart';
import 'package:ag_selector/controller/persistence/persistence_person_apart.dart';
import 'package:ag_selector/controller/persistence/persistence_selection.dart';
import 'package:ag_selector/controller/persistence/persistence_settings.dart';
import 'package:ag_selector/model/ag.dart';
import 'package:ag_selector/model/persistence_object.dart';
import 'package:ag_selector/model/person.dart';
import 'package:ag_selector/model/person_ag_preference.dart';
import 'package:ag_selector/model/selection_object.dart';
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
  late PersistenceSelection persistenceSelection;
  late PersistencePersonApart persistencePersonApart;

  PersistenceManager() {
    if (Platform.isWindows) {
      sqfliteFfiInit();
    }
    databaseFactory = getDatabaseFactory();
    persistenceAg = PersistenceAg();
    persistencePerson = PersistencePerson();
    persistencePersonAgPreferences = PersistencePersonAgPreferences();
    persistenceSettings = PersistenceSettings();
    persistenceSelection = PersistenceSelection();
    persistencePersonApart = PersistencePersonApart();
  }

  ///AG

  Future<AG?> loadAgById(int agId) async {
    AG? ag = await persistenceAg.getById(database, agId);
    return ag;
  }

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

  Future<Person?> loadPersonById(int personId) async {
    Person? person = await persistencePerson.getById(database, personId);
    return person;
  }

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

  ///Persons Apart

  Future<Map<int, List<int>>> loadPersonsApart(){
    return persistencePersonApart.load(database, this);
  }

  Future<List<Person>> loadPersonApartForPerson(Person person){
    return persistencePersonApart.loadForPerson(database, person, this);
  }

  void insertAllPersonsApart(Person person, List<Person> persons){
    persistencePersonApart.insertAll(database, person, persons);
  }

  void deletePersonApart(Person person){
    persistencePersonApart.delete(database, person);
  }

  void updatePersonApart(Person person, List<Person> persons){
    deletePersonApart(person);
    insertAllPersonsApart(person, persons);
  }

  ///Selection

  Future<List<SelectionObject>> loadSelection() async {
    return await persistenceSelection.load(database, this);
  }

  void deleteSelection() async {
    persistenceSelection.deleteAll(database);
  }

  Future<List<SelectionObject>> insertAllSelection(List<SelectionObject> selection) async {
    return await persistenceSelection.insertAll(database, selection);
  }

  Future<List<SelectionObject>> updateAllSelection(List<SelectionObject> selection) async {
    deleteSelection();
    return await persistenceSelection.insertAll(database, selection);
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

      //create Person Apart Table
      await database!.execute('''
        CREATE TABLE IF NOT EXISTS ${PersistencePersonApart.tableName} (
          ${PersistencePersonApart.personAIdDBField} INTEGER NOT NULL,
          ${PersistencePersonApart.personBIdDBField} INTEGER NOT NULL,
          FOREIGN KEY (${PersistencePersonApart.personAIdDBField}) REFERENCES ${PersistencePerson.tableName}(${PersistenceObject.idDBField}),
          FOREIGN KEY (${PersistencePersonApart.personBIdDBField}) REFERENCES ${PersistencePerson.tableName}(${PersistenceObject.idDBField})
        )
      ''');

      //create Selection Table
      await database!.execute('''
        CREATE TABLE IF NOT EXISTS ${PersistenceSelection.tableName} (
          ${PersistenceObject.idDBField} INTEGER PRIMARY KEY AUTOINCREMENT,
          ${PersistenceSelection.personIdDBField} INTEGER NOT NULL,
          ${PersistenceSelection.agIdDBField} INTEGER NOT NULL,
          ${PersistenceSelection.weekdayDBField} TEXT NOT NULL,
          FOREIGN KEY (${PersistenceSelection.personIdDBField}) REFERENCES ${PersistencePerson.tableName}(${PersistenceObject.idDBField}),
          FOREIGN KEY (${PersistenceSelection.agIdDBField}) REFERENCES ${PersistenceAg.tableName}(${PersistenceObject.idDBField})
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
    } else if (Platform.isWindows || Platform.isLinux) {
      // Use sqfliteFfi factory for Windows platform
      return databaseFactoryFfi; // Assuming you're using sqflite_common_ffi
    }
    //else its the default for all other platforms
    return databaseFactory;
  }
}
