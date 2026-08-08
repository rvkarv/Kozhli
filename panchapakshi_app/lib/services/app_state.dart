import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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

  Locale locale = const Locale('ta');

  void setLocale(Locale newLocale) {
    locale = newLocale;
    notifyListeners();
  }

  // Manual: set once via BirthDetailsScreen.
  String? birthNakshatra;

  String? birthLagnaNakshatra;

  // Automatic: recalculated every tick from real Moon position.
  MoonPosition? currentMoon;

  // Future/Past prediction:
  //
  // When set, the dashboard freezes on this date/time interpreted
  // as the wall-clock time at the SELECTED PLACE.
  //
  // Null = live "now".
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

  /// [pickedLocal] is the date/time selected by the user.
  ///
  /// It is interpreted as the wall-clock date/time at the currently
  /// selected place, NOT the device timezone.
  ///
  /// Pass null to return to live "now" mode.
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

    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _recompute(),
    );
  }

  void _recompute() {
    final loc = location;

    if (loc == null) {
      return;
    }

    /*
     * IMPORTANT TIMEZONE LOGIC
     *
     * For Future/Past mode, the offset MUST be calculated using the
     * selected local date/time. This allows IANA timezone rules to
     * determine whether DST was active on that particular date.
     *
     * For live mode, the current date/time is used.
     */
    final override = overridePickedLocal;

    final offset = LocationService.effectiveOffset(
      loc,
      localDateTime: override,
    );

    late DateTime nowAtLocation;
    late DateTime nowUtc;

    if (override != null) {
      /*
       * override is a wall-clock time at the selected place.
       *
       * We intentionally construct it as a UTC DateTime here so that
       * the existing calculation engine receives a date/time whose
       * numeric fields represent the selected local wall clock.
       *
       * The actual UTC instant is then obtained by applying the
       * date-specific IANA timezone offset calculated above.
       */
      nowAtLocation = DateTime.utc(
        override.year,
        override.month,
        override.day,
        override.hour,
        override.minute,
        override.second,
      );

      nowUtc = nowAtLocation.subtract(offset);
    } else {
      /*
       * Live mode:
       *
       * Start from the actual UTC clock and convert it using the
       * selected place's current IANA timezone offset.
       */
      nowUtc = DateTime.now().toUtc();

      nowAtLocation = nowUtc.add(offset);
    }

    /*
     * Resolve the IANA timezone once for the selected location.
     *
     * buildDayWindow receives it so sunrise/sunset calculations use
     * the same location timezone context.
     */
    final timeZoneId = LocationService.timezoneIdForLocation(loc);

    final window = LocationService.buildDayWindow(
      nowAtLocation: nowAtLocation,
      lat: loc.lat,
      lng: loc.lng,
      offsetOverride: offset,
      timeZoneId: timeZoneId,
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

    /*
     * Moon/Nakshatra calculation is based on the selected calculation
     * instant, not the device's current date when Future/Past mode is
     * active.
     */
    currentMoon = NakshatraCalculator.computeCurrent(nowUtc);

    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
