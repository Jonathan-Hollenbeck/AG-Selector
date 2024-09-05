class Weekdays {
  static const String monday = "Montag";
  static const String tuesday = "Dienstag";
  static const String wednesday = "Mittwoch";
  static const String thursday = "Donnerstag";
  static const String friday = "Freitag";
  static const String saturday = "Samstag";
  static const String sunday = "Sonntag";

  static String weekdaysToShortString(List<String> weekdays) {
    String weekdaysToShortString = "";

    for (String weekday in weekdays) {
      switch (weekday) {
        case monday:
          weekdaysToShortString += "Mo, ";
          break;
        case tuesday:
          weekdaysToShortString += "Di, ";
          break;
        case wednesday:
          weekdaysToShortString += "Mi, ";
          break;
        case thursday:
          weekdaysToShortString += "Do, ";
          break;
        case friday:
          weekdaysToShortString += "Fr, ";
          break;
        case saturday:
          weekdaysToShortString += "Sa, ";
          break;
        case sunday:
          weekdaysToShortString += "So, ";
          break;
        default:
      }
    }
    if (weekdaysToShortString.length >= 2) {
      return weekdaysToShortString.substring(
          0, weekdaysToShortString.length - 2);
    }
    return "";
  }

  static List<String> getWeekdaysFromByteCode(int bytecode) {
    List<String> weekdays = [];
    //check monday
    int mask = 1 << 0;
    if (bytecode & mask != 0) {
      weekdays.add(monday);
    }
    //check tuesday
    mask = 1 << 1;
    if (bytecode & mask != 0) {
      weekdays.add(tuesday);
    }
    //check wednesday
    mask = 1 << 2;
    if (bytecode & mask != 0) {
      weekdays.add(wednesday);
    }
    //check thursday
    mask = 1 << 3;
    if (bytecode & mask != 0) {
      weekdays.add(thursday);
    }
    //check friday
    mask = 1 << 4;
    if (bytecode & mask != 0) {
      weekdays.add(friday);
    }
    //check saturday
    mask = 1 << 5;
    if (bytecode & mask != 0) {
      weekdays.add(saturday);
    }
    //check sunday
    mask = 1 << 6;
    if (bytecode & mask != 0) {
      weekdays.add(sunday);
    }
    return weekdays;
  }

  static int getByteCodeForWeekdays(List<String> weekdays) {
    int bytecode = 0;
    for (String weekday in weekdays) {
      bytecode += getByteCodeForWeekday(weekday);
    }
    return bytecode;
  }

  static int getByteCodeForWeekday(String weekday) {
    switch (weekday) {
      case monday:
        return 1;
      case tuesday:
        return 2;
      case wednesday:
        return 4;
      case thursday:
        return 8;
      case friday:
        return 16;
      case saturday:
        return 32;
      case sunday:
        return 64;
      default:
        return 0;
    }
  }
}
