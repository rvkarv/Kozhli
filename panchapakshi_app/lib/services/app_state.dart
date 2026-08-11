import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/moon_nakshatra_window.dart';
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

  // Current Nakshatra start/end, calculated from the same Moon engine.
  MoonNakshatraWindow? currentMoonWindow;

  // Local display offset for the selected location at the current calculation
  // instant. The IANA-derived offset is used here as the dashboard display conversion.
  Duration? currentLocationOffset;

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

    // A GPS-derived location can become stale when the user travels. Refresh
    // it from the device GPS instead of treating the cached coordinates as
    // the current place. A manually selected place remains persistent.
    if (last != null && !last.isDeviceLocal) {
      location = last;
      _recompute();
      _startTicking();
      notifyListeners();
      return;
    }

    try {
      location = await LocationService.getGpsLocation();
      _recompute();
      _startTicking();
      notifyListeners();
      return;
    } catch (_) {
      // If GPS is unavailable, keep the previous GPS-derived location as a
      // safe fallback rather than losing the last usable place entirely.
      if (last != null) {
        location = last;
        _recompute();
        _startTicking();
        notifyListeners();
      }
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

    final override = overridePickedLocal;

    late DateTime nowAtLocation;
    late DateTime nowUtc;
    late Duration offset;

    if (override != null) {
      // Future/Past mode: override is explicitly a wall-clock value at the
      // selected place. IANA rules determine the offset for that date/time.
      offset = LocationService.effectiveOffset(
        loc,
        localDateTime: override,
      );

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
      // Live mode: start from one true UTC instant, then convert that instant
      // through the SELECTED PLACE'S IANA timezone. Never interpret the
      // device's local clock as the selected place's clock.
      nowUtc = DateTime.now().toUtc();
      final local = LocationService.currentLocalDateTime(
        loc,
        utcNow: nowUtc,
      );

      offset = local.timeZoneOffset;
      nowAtLocation = DateTime.utc(
        local.year,
        local.month,
        local.day,
        local.hour,
        local.minute,
        local.second,
      );
    }

    currentLocationOffset = offset;

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

    // Moon/Nakshatra calculation is based on the selected calculation
    // instant, not the device's current date when Future/Past mode is active.
    final newMoon = NakshatraCalculator.computeCurrent(nowUtc);
    final starChanged = currentMoon?.nakshatraIndex1to27 !=
        newMoon.nakshatraIndex1to27;
    currentMoon = newMoon;

    final cachedMoonWindow = currentMoonWindow;
    final outsideCachedWindow = cachedMoonWindow == null ||
        nowUtc.isBefore(cachedMoonWindow.startUtc) ||
        !nowUtc.isBefore(cachedMoonWindow.endUtc);

    if (starChanged || outsideCachedWindow) {
      currentMoonWindow = MoonNakshatraWindow.forUtc(nowUtc);
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
