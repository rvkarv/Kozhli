import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

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
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  static const int _daysToShow = 7;

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final loc = app.location!;
    final dateFmt = DateFormat('EEE, d MMM yyyy');
    final timeFmt = DateFormat('hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('முன்னறிவிப்பு (Forecast)'),
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
                const Icon(Icons.calendar_today, size: 18),
                const SizedBox(width: 8),
                Text('தொடக்க தேதி: ${dateFmt.format(_startDate)}'),
                const Spacer(),
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
                final date = _startDate.add(Duration(days: i));
                return _DayCard(
                  date: date,
                  bird: app.bird,
                  lat: loc.lat,
                  lng: loc.lng,
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
  final DateFormat dateFmt;
  final DateFormat timeFmt;

  const _DayCard({
    required this.date,
    required this.bird,
    required this.lat,
    required this.lng,
    required this.dateFmt,
    required this.timeFmt,
  });

  @override
  Widget build(BuildContext context) {
    final offset = LocationService.locationOffset(lng);
    final dateAtLocation =
        DateTime.utc(date.year, date.month, date.day, 12).add(offset);

    final window = LocationService.buildDayWindow(
      nowAtLocation: dateAtLocation,
      lat: lat,
      lng: lng,
    );
    final paksham = MoonPhase.paskhamFor(dateAtLocation.subtract(offset));

    final dayLength = window.sunset.difference(window.sunrise);
    final dayJamamDuration = Duration(microseconds: dayLength.inMicroseconds ~/ 5);
    final nightLength = window.nextSunrise.difference(window.sunset);
    final nightJamamDuration = Duration(microseconds: nightLength.inMicroseconds ~/ 5);

    final dayRows = List.generate(5, (j) {
      final jStart = window.sunrise.add(dayJamamDuration * j);
      final jEnd = jStart.add(dayJamamDuration);
      final activity = PanchapakshiRules.activityFor(
        bird: bird,
        jamam: j + 1,
        paksham: paksham,
        dayNight: DayNight.day,
        dateTimeWeekday: window.sunrise.weekday,
      );
      return '${timeFmt.format(jStart)}–${timeFmt.format(jEnd)}: ${activity.tamil} (${activity.english})';
    });

    final nightRows = List.generate(5, (j) {
      final jStart = window.sunset.add(nightJamamDuration * j);
      final jEnd = jStart.add(nightJamamDuration);
      final activity = PanchapakshiRules.activityFor(
        bird: bird,
        jamam: j + 1,
        paksham: paksham,
        dayNight: DayNight.night,
        dateTimeWeekday: window.sunrise.weekday,
      );
      return '${timeFmt.format(jStart)}–${timeFmt.format(jEnd)}: ${activity.tamil} (${activity.english})';
    });

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateFmt.format(date),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(
              '${paksham == Paksham.valarpirai ? "வளர்பிறை" : "தேய்பிறை"} · '
              'சூரிய உதயம் ${timeFmt.format(window.sunrise)} · '
              'அஸதமனம் ${timeFmt.format(window.sunset)}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const Divider(),
            const Text('☀️ பகல் (Day)', style: TextStyle(fontWeight: FontWeight.bold)),
            ...dayRows.map((r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(r, style: const TextStyle(fontSize: 13)),
                )),
            const SizedBox(height: 8),
            const Text('🌙 இரவு (Night)', style: TextStyle(fontWeight: FontWeight.bold)),
            ...nightRows.map((r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(r, style: const TextStyle(fontSize: 13)),
                )),
          ],
        ),
      ),
    );
  }
}
