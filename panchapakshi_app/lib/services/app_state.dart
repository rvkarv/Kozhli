import 'dart:async';
import 'package:flutter/foundation.dart';

import '../core/panchapakshi_engine.dart';
import '../models/pakshi.dart';
import '../models/panchapakshi_state.dart';
import '../services/location_service.dart';

/// Holds the selected location + selected bird, and republishes a fresh
/// [PanchapakshiState] every second. UI widgets listen via Provider.
class AppState extends ChangeNotifier {
  ResolvedLocation? location;
  Pakshi bird = Pakshi.kozhi; // Master app = கோழி
  PanchapakshiState? state;
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

  void _startTicking() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _recompute());
  }

  void _recompute() {
    final loc = location;
    if (loc == null) return;
    final now = DateTime.now();
    final window = LocationService.buildDayWindow(date: now, lat: loc.lat, lng: loc.lng);

    state = PanchapakshiEngine.compute(
      bird: bird,
      nowLocal: now,
      sunrise: window.sunrise,
      sunset: window.sunset,
      nextSunrise: window.nextSunrise,
      previousSunset: window.previousSunset,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
