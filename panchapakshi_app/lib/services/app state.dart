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

  // Automatic: recalculated every tick from real Moon position.
  MoonPosition? currentMoon;

  ThaaraiResult? get thaarai => ThaaraiCalculator.compute(
        birthNakshatra: birthNakshatra,
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

  void _startTicking() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _recompute());
  }

  void _recompute() {
    final loc = location;
    if (loc == null) return;

    // NOTE: buildDayWindow assumes the device's local clock matches the
    // selected place (see location_service.dart doc comment). So we use
    // the device's own local "now" directly — no manual offset math.
    final nowLocal = DateTime.now();
    final nowUtc = nowLocal.toUtc();

    final window = LocationService.buildDayWindow(
      date: nowLocal,
      lat: loc.lat,
      lng: loc.lng,
    );

    state = PanchapakshiEngine.compute(
      bird: bird,
      nowLocal: nowLocal,
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
