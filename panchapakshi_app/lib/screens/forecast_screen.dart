import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/moon_phase.dart';
import '../core/panchapakshi_rules.dart';
import '../models/pakshi.dart';
import '../services/app_state.dart';
import '../services/location_service.dart';

/// Shows, for each of the next 7 days, the day-time Jamam boundaries and
/// activity for the selected bird — i.e. "tomorrow, a week after,
/// changing date/month/year accordingly" from the spec.
class ForecastScreen extends StatelessWidget {
  const ForecastScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final loc = app.location!;
    final today = DateTime.now();
    final dateFmt = DateFormat('EEE, d MMM yyyy');
    final timeFmt = DateFormat('hh:mm a');

    return Scaffold(
      appBar: AppBar(title: const Text('வார முன்னறிவிப்பு (7-day forecast)')),
      body: ListView.builder(
        itemCount: 7,
        itemBuilder: (context, i) {
          final date = today.add(Duration(days: i + 1));
          final window = LocationService.buildDayWindow(
              date: date, lat: loc.lat, lng: loc.lng);
          final paksham = MoonPhase.paskhamFor(date.toUtc());
          final dayLength = window.sunset.difference(window.sunrise);
          final jamamDuration =
              Duration(microseconds: dayLength.inMicroseconds ~/ 5);

          final rows = List.generate(5, (j) {
            final jStart = window.sunrise.add(jamamDuration * j);
            final jEnd = jStart.add(jamamDuration);
            final activity = PanchapakshiRules.activityFor(
              bird: app.bird,
              jamam: j + 1,
              paksham: paksham,
              dayNight: DayNight.day,
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
                    'அஸ்தமனம் ${timeFmt.format(window.sunset)}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const Divider(),
                  ...rows.map((r) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(r, style: const TextStyle(fontSize: 13)),
                      )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
