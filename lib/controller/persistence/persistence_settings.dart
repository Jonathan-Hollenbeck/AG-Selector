import 'package:ag_selector/model/settings.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class PersistenceSettings {
  static const String tableName = "Settings";

  //Database field names:
  static const String keyDBField = "key";
  static const String valueDBField = "value";

  Future<Settings?> load(Database? database) async {
    Settings? settings;
    if (database != null && database.isOpen) {
      final List<Map<String, Object?>> settingsMap =
          await database.query(tableName);
      settings = fromObjectMap(settingsMap.first);
    }
    return settings;
  }

  Future<int> insert(Database? database, String key, String value) async {
    int id = -1;
    if (database != null && database.isOpen) {
      Map<String, Object> objectMap = toObjectMap(key, value, false);
      id = await database.insert(tableName, objectMap);
    }
    return id;
  }

  Future<int> delete(Database? database, String key) async {
    Future<int> numberOfRowsAffected = Future(() => 0);
    if (database != null && database.isOpen) {
      numberOfRowsAffected = database.delete(tableName,
          where: "$keyDBField = ?", whereArgs: [key]);
    }
    return numberOfRowsAffected;
  }

  void update(Database? database, String key, String value) {
    if (database != null && database.isOpen) {
      database.update(tableName, toObjectMap(key, value, true), where: '$keyDBField = ?', whereArgs: [key]);
    }
  }

  Settings? fromObjectMap(Map<String, Object?>){

  }

  Map<String, Object> toObjectMap(String key, String value, bool withId){

  }
}
