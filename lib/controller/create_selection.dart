import 'package:ag_selector/controller/persistence/persistence_manager.dart';
import 'package:ag_selector/model/ag.dart';
import 'package:ag_selector/model/person.dart';
import 'package:ag_selector/model/person_ag_preference.dart';
import 'package:ag_selector/util/string_utils.dart';
import 'package:flutter/material.dart';

class CreateSelection {

  bool allPersonsGotAgs = true;

  Future<Map<Person, Map<String, AG>>> createSelection(
      PersistenceManager persistenceManager,
      List<Person> persons,
      List<AG> ags,
      int numberOfPreferences, BuildContext context) async {
    
    allPersonsGotAgs = true;

    Map<Person, Map<String, AG>> selection = <Person, Map<String, AG>>{};

    selection = await _tryAllFirstChoice(persistenceManager, persons, ags);

    if (selection.isEmpty) {
      selection = await _tryScoring(
          persistenceManager, persons, ags, numberOfPreferences);
    }

    if(!allPersonsGotAgs){
      showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('WARNUNG!'),
          content: const Text('Nicht alle Personen haben immer ein AG bekommen!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Ok'),
            ),
          ],
        );
      },
    );
    }

    return selection;
  }

  Future<Map<Person, Map<String, AG>>> _tryAllFirstChoice(
      PersistenceManager persistenceManager,
      List<Person> persons,
      List<AG> ags) async {
    Map<Person, Map<String, AG>> selection = <Person, Map<String, AG>>{};

    //max person tracker for tracking, if the ag still has slots left
    Map<int, int> maxPersonTracker = getMaxPersonTracker(ags);

    //get all relevant weekdays
    Set<String> relevantWeekdays = getRelevantWeekdays(persons, ags);

    //loop through relevant weekdays
    for (String weekday in relevantWeekdays) {
      for (Person person in persons) {
        List<PersonAgPreference> personAgPreferences =
            await persistenceManager.getPersonAgPreferences(person);
        if (personAgPreferences.isNotEmpty) {
          for (PersonAgPreference personAgPreference in personAgPreferences) {
            if (personAgPreference.weekday == weekday &&
                personAgPreference.preferenceNumber == 1) {
              AG preferedAG = personAgPreference.ag;
              //if the ag is already full or the ag does not exist in the tracker, return a emtpy map
              if (maxPersonTracker.keys.contains(preferedAG.id) &&
                  maxPersonTracker[preferedAG.id]! > 0) {
                //if the ag still has slots left, put the person into it
                selection =
                    putInSelection(selection, person, weekday, preferedAG);
                //decrement maxPersonTracker
                maxPersonTracker[preferedAG.id] =
                    maxPersonTracker[preferedAG.id]! - 1;
              } else {
                return <Person, Map<String, AG>>{};
              }
            }
          }
        } else {
          return <Person, Map<String, AG>>{};
        }
      }
      //reset maxPersonTracker for the next weekday
      maxPersonTracker = getMaxPersonTracker(ags);
    }

    return selection;
  }

  /// the idea is a round based system on the weekdays. So starting with monday.
  /// Persons who got a AG with a high preference get a Score Value subtracted
  /// and Persons who got a low preference AG get a Score Value added. In the next round,
  /// the AGs are distributed based on the scores until all relevant weekdays are
  /// finished.
  Future<Map<Person, Map<String, AG>>> _tryScoring(
      PersistenceManager persistenceManager,
      List<Person> persons,
      List<AG> ags,
      int numberOfPreferences) async {
    Map<Person, Map<String, AG>> selection = <Person, Map<String, AG>>{};

    //shuffle persons, to give everybody the chance to be the first.
    persons.shuffle();

    //max person tracker for tracking, if the ag still has slots left
    Map<int, int> maxPersonTracker = getMaxPersonTracker(ags);

    //get all relevant weekdays
    Set<String> relevantWeekdays = getRelevantWeekdays(persons, ags);

    //scoring map
    Map<Person, int> preferenceScoring = <Person, int>{};
    for (Person person in persons) {
      preferenceScoring[person] = 0;
    }

    //loop through relevant weekdays
    for (String weekday in relevantWeekdays) {
      //loop through all persons
      for (Person person in persons) {
        //get all ag preferences for a person
        //and filter them to be just the ones with the current weekday
        List<PersonAgPreference> personAgPreferences =
            getPersonAGPreferencesWithWeekday(
                await persistenceManager.getPersonAgPreferences(person),
                weekday);
        AG? ag =
            getMostPossiblePreferedAG(maxPersonTracker, personAgPreferences);
        //didnt get an AG, so the persons score gets to be very high
        if (ag == null) {
          selection =
              putInSelection(selection, person, weekday, AG.createEmptyAG());
          preferenceScoring[person] =
              preferenceScoring[person]! + numberOfPreferences;
          allPersonsGotAgs = false;
        } else {
          int preferenceNumber = getPersonPreferenceForAG(ag, personAgPreferences);
          selection = putInSelection(selection, person, weekday, ag);
          preferenceScoring[person] =
              preferenceScoring[person]! - (numberOfPreferences - preferenceNumber);
          //increment maxPersonTracker for AG
          maxPersonTracker[ag.id] = maxPersonTracker[ag.id]! - 1;
        }
      }
      //reset maxPersonTracker for the next weekday
      maxPersonTracker = getMaxPersonTracker(ags);
      //reorganize Person list by scores
      persons = sortPersonsByScore(preferenceScoring);
    }

    return selection;
  }

  Map<Person, Map<String, AG>> putInSelection(
      Map<Person, Map<String, AG>> selection,
      Person person,
      String weekday,
      AG ag) {
    if (selection.keys.contains(person)) {
      selection[person]!.putIfAbsent(weekday, () => ag);
    } else {
      selection.putIfAbsent(person, () => {weekday: ag});
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

  //get most prefered AG
  AG? getMostPossiblePreferedAG(
      Map<int, int> maxPersonTracker, List<PersonAgPreference> agPreferences) {
    //sort List by preferenceNumber, so that it looks for the most prefered AG first
    agPreferences
        .sort((a, b) => a.preferenceNumber.compareTo(b.preferenceNumber));
    for (PersonAgPreference personAgPreference in agPreferences) {
      //current ag
      AG ag = personAgPreference.ag;
      //if there is still room in that AG
      //return it
      if (maxPersonTracker[ag.id] != null && maxPersonTracker[ag.id]! > 0) {
        return ag;
      }
    }
    return null;
  }

  //get the preferenceNumber for a ag for a person
  int getPersonPreferenceForAG(AG ag, List<PersonAgPreference> agPreferences){
    int preference = -1;
    for(PersonAgPreference personAgPreference in agPreferences){
      if(personAgPreference.ag.id == ag.id){
        return personAgPreference.preferenceNumber;
      }
    }
    return preference;
  }

  //get all PersonAGPreferences, that have a specific weekday
  List<PersonAgPreference> getPersonAGPreferencesWithWeekday(
      List<PersonAgPreference> personAGPreferences, String weekday) {
    List<PersonAgPreference> personAGPreferencesWithWeekday = [];
    for (PersonAgPreference personAgPreference in personAGPreferences) {
      if (personAgPreference.weekday == weekday) {
        personAGPreferencesWithWeekday.add(personAgPreference);
      }
    }
    return personAGPreferencesWithWeekday;
  }

  //get all relevant weekdays
  Set<String> getRelevantWeekdays(List<Person> persons, List<AG> ags) {
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
  Map<int, int> getMaxPersonTracker(ags) {
    Map<int, int> maxPersonTracker = {};
    for (AG ag in ags) {
      maxPersonTracker[ag.id] = ag.maxPersons;
    }
    return maxPersonTracker;
  }
}
