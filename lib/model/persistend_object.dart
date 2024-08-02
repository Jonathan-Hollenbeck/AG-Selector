abstract class PersistendObject {
  static const String idDBField = "id";

  int id = -1;

  Map<String, Object> toObjectMap(bool withId);
}
