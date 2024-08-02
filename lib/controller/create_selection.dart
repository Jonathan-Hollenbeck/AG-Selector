import 'package:ag_selector/model/ag.dart';
import 'package:ag_selector/model/person.dart';
import 'package:ag_selector/util/string_utils.dart';

class CreateSelection {
  Map<Person, Map<String, AG>> createSelection(
      List<Person> persons, List<AG> ags, int numberOfPreferences) {
    Map<Person, Map<String, AG>> selection = <Person, Map<String, AG>>{};

    selection = _tryAllFirstChoice(persons, ags);

    if (selection.isEmpty) {
      selection = _tryScoring(persons, ags, numberOfPreferences);
    }

    return selection;
  }

  Map<Person, Map<String, AG>> _tryAllFirstChoice(
      List<Person> persons, List<AG> ags) {
    Map<Person, Map<String, AG>> selection = <Person, Map<String, AG>>{};

    //max person tracker for tracking, if the ag still has slots left
    Map<AG, int> maxPersonTracker = _getMaxPersonTracker(ags);

    //get all relevant weekdays
    Set<String> relevantWeekdays = _getRelevantWeekdays(persons, ags);

    //loop through relevant weekdays
    for (String weekday in relevantWeekdays) {
      for (Person person in persons) {
        Map<String, Map<int, AG>> agPreferencesByWeekday =
            person.agPreferencesByWeekday;
        if (agPreferencesByWeekday.keys.contains(weekday)) {
          AG? preferedAG = agPreferencesByWeekday[weekday]![0];
          //if no first choice was made, the method returns a emtpy map
          if (preferedAG != null) {
            //if the ag is already full, return a emtpy map
            if (maxPersonTracker[preferedAG]! > 0) {
              //if the ag still has slots left, put the person into it
              selection[person]![weekday] = preferedAG;
              maxPersonTracker[preferedAG] = maxPersonTracker[preferedAG]! - 1;
            } else {
              return <Person, Map<String, AG>>{};
            }
          } else {
            return <Person, Map<String, AG>>{};
          }
        }
      }
      //reset maxPersonTracker for the next weekday
      maxPersonTracker = _getMaxPersonTracker(ags);
    }

    return selection;
  }

  /// the idea is a round based system on the weekdays. So starting with monday.
  /// Persons who got a AG with a high preference get a Score Value subtracted
  /// and Persons who got a low preference AG get a Score Value added. In the next round,
  /// the AGs are distributed based on the scores until all relevant weekdays are
  /// finished.
  Map<Person, Map<String, AG>> _tryScoring(
      List<Person> persons, List<AG> ags, int numberOfPreferences) {
    Map<Person, Map<String, AG>> selection = <Person, Map<String, AG>>{};

    //shuffle persons, to give everybody the chance to be the first.
    persons.shuffle();

    //create value for manipulating score by numberOfPreferences
    int scoreManipulator = numberOfPreferences ~/ 2;

    //max person tracker for tracking, if the ag still has slots left
    Map<AG, int> maxPersonTracker = _getMaxPersonTracker(ags);

    //get all relevant weekdays
    Set<String> relevantWeekdays = _getRelevantWeekdays(persons, ags);

    //scoring map
    Map<Person, int> preferenceScoring = <Person, int>{};
    for (Person person in persons) {
      preferenceScoring[person] = 0;
    }

    //loop through relevant weekdays
    for (String weekday in relevantWeekdays) {
      //loop through all persons
      for (Person person in persons) {
        Map<String, Map<int, AG>> agPreferencesByWeekday =
            person.agPreferencesByWeekday;
        //if the preferences contain the current weekday
        if (agPreferencesByWeekday.keys.contains(weekday)) {
          Map<int, AG>? agPreferences = agPreferencesByWeekday[weekday];
          if (agPreferences != null) {
            int mostPossiblePreferedAGIndex =
                getMostPossiblePreferedAG(maxPersonTracker, agPreferences);
            //didnt get an AG, so the persons score gets to be very high
            if (mostPossiblePreferedAGIndex == -1) {
              selection[person] = {weekday: AG.createEmptyAG()};
              preferenceScoring[person] =
                  preferenceScoring[person]! + (scoreManipulator * 2);
            } else {
              //got an AG, so the score get calculated by the AG preference
              AG preferedPossibleAG =
                  agPreferences[mostPossiblePreferedAGIndex]!;
              selection[person] = {weekday: preferedPossibleAG};
              preferenceScoring[person] =
                  preferenceScoring[person]! - scoreManipulator;
              //increment maxPersonTracker for AG
              maxPersonTracker[preferedPossibleAG] =
                  maxPersonTracker[preferedPossibleAG]! - 1;
            }
          }
        }
      }
      //reset maxPersonTracker for the next weekday
      maxPersonTracker = _getMaxPersonTracker(ags);
      //reorganize Person list by scores
      persons = sortPersonsByScore(preferenceScoring);
    }

    return selection;
  }

  //sort Persons based on score
  List<Person> sortPersonsByScore(Map<Person, int> preferenceScoring) {
    List<MapEntry<Person, int>> sortedEntries = preferenceScoring.entries
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries.map((entry) => entry.key).toList();
  }

  //get most prefered AG by index
  int getMostPossiblePreferedAG(
      Map<AG, int> maxPersonTracker, Map<int, AG> agPreferences) {
    int currentIndex = -1;
    for (int i in agPreferences.keys) {
      //current ag
      AG currentAG = agPreferences[i]!;
      //if there is still room in that AG
      //and it is of higher preference then the current one,
      //set it as the current one
      if (maxPersonTracker[currentAG] != null &&
          maxPersonTracker[currentAG]! > 0) {
        if (i < currentIndex || currentIndex == -1) {
          currentIndex = i;
        }
      }
    }
    return currentIndex;
  }

  //get all relevant weekdays
  Set<String> _getRelevantWeekdays(List<Person> persons, List<AG> ags) {
    Set<String> relevantWeekdays = {};
    for (Person person in persons) {
      for (AG ag in ags) {
        List<String> weekdayIntersection =
            StringUtils.getIntersectionBetweenTwoLists(
                person.weekdaysPresent, ag.weekdays);
        relevantWeekdays.addAll(weekdayIntersection);
      }
    }

    return relevantWeekdays;
  }

  //max person tracker for tracking, if the ag still has slots left
  Map<AG, int> _getMaxPersonTracker(ags) {
    Map<AG, int> maxPersonTracker = <AG, int>{};
    for (AG ag in ags) {
      maxPersonTracker[ag] = ag.maxPersons;
    }
    return maxPersonTracker;
  }
}
