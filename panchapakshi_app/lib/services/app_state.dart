import 'dart:async';
import 'package:flutter/foundation.dart';

import '../core/nakshatra_calculator.dart';
import '../core/panchapakshi_engine.dart';
import '../core/panchapakshi_rules.dart';
import '../core/thaarai_calculator.dart';
import '../models/pakshi.dart';
import '../models/panchapakshi_state.dart';
import '../services/location_service.dart';

class AppState extends ChangeNotifier {
  ResolvedLocation? location;

  // Falls back to à®•à¯‹à®´à®¿ only until birth details + birth paksham are set.
  Pakshi bird = Pakshi.kozhi;

  PanchapakshiState? state;

  // Manual: set once via BirthDetailsScreen.
  // à®ªà®¿à®±à®¨à¯à®¤ à®°à®¾à®šà®¿ à®¨à®Ÿà¯à®šà®¤à¯à®¤à®¿à®°à®®à¯ (Birth Rasi Nakshatra)
  String? birthNakshatra;
  // à®ªà®¿à®±à®¨à¯à®¤ à®²à®•à¯à®©à®®à¯ à®¨à®Ÿà¯à®šà®¤à¯à®¤à®¿à®°à®®à¯ (Birth Lagna Nakshatra)
  String? birthLagnaNakshatra;
  // à®ªà®¿à®±à®¨à¯à®¤ à®ªà®Ÿà¯à®šà®®à¯ (Birth Paksham â€” waxing/waning at time of birth).
  // This, together with birthNakshatra, determines the person's ruling
  // bird via PanchapakshiRules.birdForStar().
  Paksham? birthPaksham;

  // Automatic: recalculated every tick from real Moon position.
  MoonPosition? currentMoon;

  /// Thaarai measured from the birth RASI nakshatra against today's
  /// transiting star. (e.g. à®ªà¯‚à®°à®®à¯ -> à®ªà®¿à®°à®¤à¯à®¤à®¿à®¯à®•à¯à®•à¯ à®¤à®¾à®°à¯ˆ)
  ThaaraiResult? get thaaraiFromRasi => ThaaraiCalculator.compute(
        birthNakshatra: birthNakshatra,
        todayNakshatra: currentMoon?.nakshatraName,
      );

  /// Thaarai measured from the birth LAGNA nakshatra against today's
  /// transiting star. (e.g. à®†à®¯à®¿à®²à¯à®¯à®®à¯ -> à®µà®¤à¯ˆ à®¤à®¾à®°à¯ˆ)
  ThaaraiResult? get thaaraiFromLagna => ThaaraiCalculator.compute(
        birthNakshatra: birthLagnaNakshatra,
        todayNakshatra: currentMoon?.nakshatraName,
      );

  /// Kept for backward compatibility with any existing widget that reads
  /// `.thaarai` â€” same as [thaaraiFromRasi].
  ThaaraiResult? get thaarai => thaaraiFromRasi;

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
    _recomputeBird();
    _recompute();
    notifyListeners();
  }

  void setBirthLagnaNakshatra(String star) {
    birthLagnaNakshatra = star;
    notifyListeners();
  }

  void setBirthPaksham(Paksham paksham) {
    birthPaksham = paksham;
    _recomputeBird();
    _recompute();
    notifyListeners();
  }

  /// Works out the person's ruling bird from their birth star + birth
  /// paksham (PanchapakshiRules Table 5). Falls back to à®•à¯‹à®´à®¿ (unchanged)
  /// until both pieces of birth data are set.
  void _recomputeBird() {
    final star = birthNakshatra;
    final paksham = birthPaksham;
    if (star == null || paksham == null) return;
    final starIndex = PanchapakshiRules.nakshatraNames.indexOf(star);
    if (starIndex == -1) return;
    bird = PanchapakshiRules.birdForStar(starIndex, paksham);
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
    // the device's own local "now" directly â€” no manual offset math.
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
