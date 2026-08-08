import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/day_ruler_rules.dart';
import '../core/moon_phase.dart';
import '../core/panchapakshi_rules.dart';
import '../models/pakshi.dart';
import '../services/app_state.dart';
import '../services/location_service.dart';

class ForecastScreen extends StatefulWidget {
  const ForecastScreen({super.key});

  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen> {
  DateTime _startDate =
      DateTime.now().add(const Duration(days: 1));

  static const int _daysToShow = 7;

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate:
          DateTime.now().subtract(const Duration(days: 365)),
      lastDate:
          DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final loc = app.location;

    if (loc == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Location not selected',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    final dateFmt = DateFormat('EEE, d MMM yyyy');
    final timeFmt = DateFormat('hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'முன்னறிவிப்பு (Forecast)',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_calendar),
            tooltip: 'தேதி தேர்வு (Pick date)',
            onPressed: () => _pickDate(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'தொடக்க தேதி: ${dateFmt.format(_startDate)}',
                  ),
                ),
                TextButton(
                  onPressed: () => _pickDate(context),
                  child: const Text('மாற்று'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _daysToShow,
              itemBuilder: (context, i) {
                final date =
                    _startDate.add(Duration(days: i));

                return _DayCard(
                  date: date,
                  bird: app.bird,
                  lat: loc.lat,
                  lng: loc.lng,
                  location: loc,
                  dateFmt: dateFmt,
                  timeFmt: timeFmt,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  final DateTime date;
  final Pakshi bird;
  final double lat;
  final double lng;
  final ResolvedLocation location;
  final DateFormat dateFmt;
  final DateFormat timeFmt;

  const _DayCard({
    required this.date,
    required this.bird,
    required this.lat,
    required this.lng,
    required this.location,
    required this.dateFmt,
    required this.timeFmt,
  });

  @override
  Widget build(BuildContext context) {
    /*
     * IMPORTANT:
     *
     * `date` represents the calendar date at the SELECTED LOCATION.
     *
     * Do not use:
     *
     *   LocationService.locationOffset(lng)
     *
     * because that is a fixed longitude-based offset and does not
     * correctly handle IANA timezone rules / DST.
     *
     * Instead, calculate the offset for THIS PARTICULAR DATE.
     */

    final localNoon = DateTime.utc(
      date.year,
      date.month,
      date.day,
      12,
    );

    final offset = LocationService.effectiveOffset(
      location,
      localDateTime: localNoon,
    );

    /*
     * The calculation engine uses DateTime values whose numeric
     * fields represent the selected location's wall-clock time.
     *
     * Therefore localNoon remains a UTC DateTime intentionally.
     */

    final dateAtLocation = localNoon;

    /*
     * Convert the selected local wall-clock time to the actual
     * UTC instant for Moon/Paksham calculations.
     */
    final dateUtc = dateAtLocation.subtract(offset);

    /*
     * Resolve the IANA timezone for the selected location.
     *
     * This ensures sunrise/sunset calculations use the same
     * timezone context as the rest of the application.
     */
    final timeZoneId =
        LocationService.timezoneIdForLocation(location);

    final window = LocationService.buildDayWindow(
      nowAtLocation: dateAtLocation,
      lat: lat,
      lng: lng,
      offsetOverride: offset,
      timeZoneId: timeZoneId,
    );

    /*
     * Moon phase must be calculated from the actual UTC instant,
     * not from the device timezone.
     */
    final paksham =
        MoonPhase.paskhamFor(dateUtc);

    /*
     * The weekday belongs to the selected location's calendar
     * date. `window.sunrise` represents that same local calendar
     * context.
     */
    final dayRuler = DayRulerRules.forWeekday(
      window.sunrise.weekday,
      paksham,
    );

    /*
     * Divide daylight into five equal Jamams.
     */
    final dayLength =
        window.sunset.difference(window.sunrise);

    final dayJamDuration = Duration(
      microseconds:
          dayLength.inMicroseconds ~/ 5,
    );

    /*
     * Divide nighttime into five equal Jamams.
     */
    final nightLength =
        window.nextSunrise.difference(window.sunset);

    final nightJamDuration = Duration(
      microseconds:
          nightLength.inMicroseconds ~/ 5,
    );

    /*
     * Day Jamams
     */
    final dayRows = List.generate(5, (j) {
      final jStart =
          window.sunrise.add(dayJamDuration * j);

      final jEnd =
          jStart.add(dayJamDuration);

      final activity =
          PanchapakshiRules.activityFor(
        bird: bird,
        jamam: j + 1,
        paksham: paksham,
        dayNight: DayNight.day,
        dateTimeWeekday:
            window.sunrise.weekday,
      );

      return '${timeFmt.format(jStart)}–'
          '${timeFmt.format(jEnd)}: '
          '${activity.tamil} '
          '(${activity.english})';
    });

    /*
     * Night Jamams
     */
    final nightRows = List.generate(5, (j) {
      final jStart =
          window.sunset.add(nightJamDuration * j);

      final jEnd =
          jStart.add(nightJamDuration);

      final activity =
          PanchapakshiRules.activityFor(
        bird: bird,
        jamam: j + 1,
        paksham: paksham,
        dayNight: DayNight.night,
        dateTimeWeekday:
            window.sunrise.weekday,
      );

      return '${timeFmt.format(jStart)}–'
          '${timeFmt.format(jEnd)}: '
          '${activity.tamil} '
          '(${activity.english})';
    });

    final isAuthorityDay =
        dayRuler.ruler == bird;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              dateFmt.format(date),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            Text(
              '${paksham == Paksham.valarpirai ? "வளர்பிறை" : "தேய்பிறை"} · '
              'சூரிய உதயம் ${timeFmt.format(window.sunrise)} · '
              'அஸ்தமனம் ${timeFmt.format(window.sunset)}',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              'அன்றைய அதிகார பட்சி: '
              '${dayRuler.ruler.tamil}'
              '${isAuthorityDay ? " (இன்று ${bird.tamil} அதிகார நாள்!)" : ""}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isAuthorityDay
                    ? Colors.green
                    : Colors.deepPurple,
              ),
            ),

            const Divider(),

            const Text(
              '☀️ பகல் (Day)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            ...dayRows.map(
              (row) => Padding(
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 2,
                ),
                child: Text(
                  row,
                  style: const TextStyle(
                    fontSize: 13,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              '🌙 இரவு (Night)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            ...nightRows.map(
              (row) => Padding(
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 2,
                ),
                child: Text(
                  row,
                  style: const TextStyle(
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
