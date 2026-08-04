import 'dart:async';
import 'package:flutter/foundation.dart';

import '../core/nakshatra_calculator.dart';
import '../core/panchapakshi_engine.dart';
import '../core/thaarai_calculator.dart';
import '../models/pakshi.dart';
import '../models/panchapakshi_state.dart';
import '../services/location_service.dart';

class AppState extends ChangeNotifier {
  ResolvedLocation? location;
  Pakshi bird = Pakshi.kozhi;
  PanchapakshiState? state;

  // Manual: set once via BirthDetailsScreen.
  String? birthNakshatra;
  String? birthLagnaNakshatra;

  // Automatic: recalculated every tick from real Moon position.
  MoonPosition? currentMoon;

  // Future/Past prediction: when set, the dashboard freezes on this
  // date/time (interpreted as the SELECTED PLACE's own local wall
  // clock) instead of updating live. Null = live "now".
  DateTime? overridePickedLocal;
  bool get isLive => overridePickedLocal == null;

  ThaaraiResult? get thaarai => ThaaraiCalculator.compute(
        birthNakshatra: birthNakshatra,
        todayNakshatra: currentMoon?.nakshatraName,
      );

  ThaaraiResult? get thaaraiLagna => ThaaraiCalculator.compute(
        birthNakshatra: birthLagnaNakshatra,
        todayNakshatra: currentMoon?.nakshatraName,
      );

  String? error;
  bool loading = false;

  Timer? _ticker;

  Future<void> useGps() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      location = await LocationService.getGpsLocation();
      _recompute();
      _startTicking();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> useManualLocation(ResolvedLocation loc) async {
    location = loc;
    error = null;
    _recompute();
    _startTicking();
    notifyListeners();
  }

  Future<void> tryRestoreLastLocation() async {
    final last = await LocationService.lastKnown();
    if (last != null) {
      location = last;
      _recompute();
      _startTicking();
      notifyListeners();
    }
  }

  void setBirthNakshatra(String star) {
    birthNakshatra = star;
    notifyListeners();
  }

  void setBirthLagnaNakshatra(String star) {
    birthLagnaNakshatra = star;
    notifyListeners();
  }

  /// [pickedLocal] is the date/time the user chose, interpreted as the
  /// wall clock at the currently selected place. Pass null to return
  /// to live "now" mode.
  void setOverrideDateTime(DateTime? pickedLocal) {
    overridePickedLocal = pickedLocal;
    if (pickedLocal == null) {
      _startTicking();
    } else {
      _ticker?.cancel();
    }
    _recompute();
    notifyListeners();
  }

  void _startTicking() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _recompute());
  }

  void _recompute() {
    final loc = location;
    if (loc == null) return;

    final offset = LocationService.locationOffset(loc.lng);

    late DateTime nowAtLocation;
    late DateTime nowUtc;
    final override = overridePickedLocal;
    if (override != null) {
      nowAtLocation = DateTime.utc(
        override.year, override.month, override.day, override.hour, override.minute,
      );
      nowUtc = nowAtLocation.subtract(offset);
    } else {
      nowUtc = DateTime.now().toUtc();
      nowAtLocation = nowUtc.add(offset);
    }

    final window = LocationService.buildDayWindow(
      nowAtLocation: nowAtLocation,
      lat: loc.lat,
      lng: loc.lng,
    );

    state = PanchapakshiEngine.compute(
      bird: bird,
      nowLocal: nowAtLocation,
      nowUtc: nowUtc,
      sunrise: window.sunrise,
      sunset: window.sunset,
      nextSunrise: window.nextSunrise,
      previousSunset: window.previousSunset,
    );

    currentMoon = NakshatraCalculator.computeCurrent(nowUtc);

    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
