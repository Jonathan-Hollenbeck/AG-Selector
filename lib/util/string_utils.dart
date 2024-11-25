import 'package:ag_selector/model/person.dart';

class StringUtils {
  static String stringListToString(List<String> list) {
    String result = "";
    if (list.isNotEmpty) {
      result = list[0];
    } else {
      return "";
    }
    for (int i = 1; i < list.length; i++) {
      String weekday = list[i];
      result += ", $weekday";
    }
    return result;
  }

  static String timeToString(int hour, int minute) {
    String hourString = hour.toString();
    String minuteString = minute.toString();

    if (hourString.length < 2) {
      hourString = "0$hourString";
    }
    if (minuteString.length < 2) {
      minuteString = "0$minuteString";
    }

    return "$hourString:$minuteString";
  }

  static List<String> copyStringList(List<String> list) {
    List<String> copy = [];
    for (String s in list) {
      copy.add(s);
    }
    return copy;
  }

  static List<String> getStringListPlusEmpty(List<String> list) {
    List<String> listPlusEmpty = StringUtils.copyStringList(list);
    listPlusEmpty.add("");
    return listPlusEmpty;
  }

  static List<String> intListToStringList(List<int> intList) {
    List<String> stringList = [];
    for (int i in intList) {
      stringList.add("$i");
    }
    return stringList;
  }

  static List<String> getIntersectionBetweenTwoLists(
      List<String> list1, List<String> list2) {
    List<String> intersection = [];
    for (String s in list1) {
      if (list2.contains(s)) {
        intersection.add(s);
      }
    }
    return intersection;
  }
  static String combineHouseAndClass(Person person){
    return "${person.schoolClass}${person.house}${person.name}";
  }
}
