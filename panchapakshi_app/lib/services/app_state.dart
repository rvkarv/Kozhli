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

  String? birthNakshatra;

  String? birthLagnaNakshatra;

  MoonPosition? currentMoon;

  MoonNakshatraWindow? currentMoonWindow;

  Duration? currentLocationOffset;

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

    // Keep the selected place across app restarts. This is especially
    // important when the phone itself is in India but the selected test place
    // is Lafayette, Louisiana (or another location in a different timezone).
    await LocationService.rememberLocation(loc);

    _recompute();
    _startTicking();
    notifyListeners();
  }

  Future<void> tryRestoreLastLocation() async {
    final last = await LocationService.lastKnown();

    // A GPS-derived location can become stale when the user travels. Refresh
    // it from the device GPS instead of treating cached coordinates as the
    // current place. A manually selected place remains persistent.
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

  /// [pickedLocal] is a wall-clock date/time at the selected place.
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

  /// Convert a DateTime carrying selected-location clock fields into a true
  /// wall-clock DateTime. Local calculation code must compare clock fields
  /// (09:17 AM vs 06:33 AM), not UTC instants with the timezone offset baked
  /// into them. This is especially important when the device is in India and
  /// the selected place is in the US.
  DateTime _wallClock(DateTime value) {
    return DateTime(
      value.year,
      value.month,
      value.day,
      value.hour,
      value.minute,
      value.second,
      value.millisecond,
      value.microsecond,
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
      offset = LocationService.effectiveOffset(
        loc,
        localDateTime: override,
      );

      // The override is already a selected-location wall-clock value.
      nowAtLocation = _wallClock(override);

      // Convert that selected-location wall clock to the real UTC instant
      // using the date-specific IANA offset (including DST).
      nowUtc = DateTime.utc(
        override.year,
        override.month,
        override.day,
        override.hour,
        override.minute,
        override.second,
        override.millisecond,
        override.microsecond,
      ).subtract(offset);
    } else {
      // Live mode always starts from the actual UTC instant. Convert that
      // instant through the selected location's IANA timezone, then strip
      // timezone metadata so all solar/Panchapakshi comparisons are purely
      // selected-location wall-clock comparisons.
      nowUtc = DateTime.now().toUtc();
      final local = LocationService.currentLocalDateTime(
        loc,
        utcNow: nowUtc,
      );

      nowAtLocation = _wallClock(local);
      offset = local.timeZoneOffset;
    }

    currentLocationOffset = offset;

    final timeZoneId = LocationService.timezoneIdForLocation(loc);

    final rawWindow = LocationService.buildDayWindow(
      nowAtLocation: nowAtLocation,
      lat: loc.lat,
      lng: loc.lng,
      offsetOverride: offset,
      timeZoneId: timeZoneId,
    );

    // SunCalculator returns UTC instants and buildDayWindow applies the
    // selected-location offset. For the Panchapakshi engine we need the
    // resulting LOCAL clock values, not DateTime instants. Strip the UTC
    // metadata before comparing them with nowAtLocation.
    final window = DayWindow(
      sunrise: _wallClock(rawWindow.sunrise),
      sunset: _wallClock(rawWindow.sunset),
      nextSunrise: _wallClock(rawWindow.nextSunrise),
      previousSunset: _wallClock(rawWindow.previousSunset),
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
