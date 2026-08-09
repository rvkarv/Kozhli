import 'pakshi.dart';

class PanchapakshiState {
  final DateTime asOf;
  final Pakshi bird;
  final Paksham paksham;
  final DayNight dayNight;

  final DateTime sunrise;
  final DateTime sunset;
  final DateTime nextSunrise;

  final int rulingWeekday;
  final Pakshi authorityBird;
  final String authorityRelationship;
  final bool isKozhliAuthorityDay;
  final bool isKozhliPaduDay;
  final int successPercent;
  final String successLabel;

  final int jamam;
  final Thozhil jamamActivity;
  final DateTime jamamStart;
  final DateTime jamamEnd;

  final int antharam;
  final Pakshi antharamBird;
  final Thozhil antharamActivity;
  final DateTime antharamStart;
  final DateTime antharamEnd;

  final Duration remaining;
  final Thozhil nextActivity;
  final DateTime nextActivityStart;
  final Pakshi nextAntharamBird;

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
    required this.rulingWeekday,
    required this.authorityBird,
    required this.authorityRelationship,
    required this.isKozhliAuthorityDay,
    required this.isKozhliPaduDay,
    required this.successPercent,
    required this.successLabel,
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
    required this.nextAntharamBird,
    required this.gowriName,
    required this.gowriIsGood,
    required this.horaiPlanet,
  });
}
