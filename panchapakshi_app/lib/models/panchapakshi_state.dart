import 'pakshi.dart';

/// One fully-computed real-time snapshot for the selected bird/location.
class PanchapakshiState {
  final DateTime asOf;
  final Pakshi bird;
  final Paksham paksham;
  final DayNight dayNight;

  final DateTime sunrise;
  final DateTime sunset;
  final DateTime nextSunrise; // for night-jamam math

  final int jamam; // 1..5
  final Thozhil jamamActivity;
  final DateTime jamamStart;
  final DateTime jamamEnd;

  final int antharam; // 1..5 (sub-division of the jamam)
  final Pakshi antharamBird; // the "guest" bird active this antharam
  final Thozhil antharamActivity;
  final DateTime antharamStart;
  final DateTime antharamEnd;

  final Duration remaining; // time left in current antharam
  final Thozhil nextActivity;
  final DateTime nextActivityStart;

  final String gowriName;
  final bool gowriIsGood;
  final String horaiPlanet;

  const PanchapakshiState({
    required this.asOf,
    required this.bird,
    required this.paksham,
    required this.dayNight,
    required this.sunrise,
    required this.sunset,
    required this.nextSunrise,
    required this.jamam,
    required this.jamamActivity,
    required this.jamamStart,
    required this.jamamEnd,
    required this.antharam,
    required this.antharamBird,
    required this.antharamActivity,
    required this.antharamStart,
    required this.antharamEnd,
    required this.remaining,
    required this.nextActivity,
    required this.nextActivityStart,
    required this.gowriName,
    required this.gowriIsGood,
    required this.horaiPlanet,
  });
}
