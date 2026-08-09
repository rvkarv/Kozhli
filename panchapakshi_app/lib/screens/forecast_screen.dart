import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/day_ruler_rules.dart';
import '../core/kozhli_success_rules.dart';
import '../core/moon_phase.dart';
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
    if (picked != null) setState(() => _startDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final loc = app.location;
    if (loc == null) {
      return const Scaffold(body: Center(child: Text('இடம் தேர்வு செய்யவும்')));
    }

    final dateFmt = DateFormat('EEE, d MMM yyyy');
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101010),
        foregroundColor: Colors.white,
        title: const Text('Future Prediction'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_calendar, color: Color(0xFFE4AD3C)),
            onPressed: () => _pickDate(context),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        itemCount: _daysToShow + 1,
        itemBuilder: (context, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Color(0xFFE4AD3C), size: 18),
                  const SizedBox(width: 8),
                  Text('தொடக்க தேதி: ${dateFmt.format(_startDate)}', style: const TextStyle(color: Colors.white)),
                ],
              ),
            );
          }
          final date = _startDate.add(Duration(days: i - 1));
          return _DayCard(
            date: date,
            bird: app.bird,
            lat: loc.lat,
            lng: loc.lng,
            dateFmt: dateFmt,
          );
        },
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

  const _DayCard({
    required this.date,
    required this.bird,
    required this.lat,
    required this.lng,
    required this.dateFmt,
  });

  @override
  Widget build(BuildContext context) {
    final timeFmt = DateFormat('hh:mm:ss a');
    final offset = LocationService.locationOffset(lng);
    final dateAtLocation = DateTime.utc(date.year, date.month, date.day, 12).add(offset);
    final window = LocationService.buildDayWindow(
      nowAtLocation: dateAtLocation,
      lat: lat,
      lng: lng,
      offsetOverride: offset,
    );
    final paksham = MoonPhase.paskhamFor(dateAtLocation.subtract(offset));
    final ruler = DayRulerRules.forWeekday(date.weekday, paksham);
    final isAuthority = ruler.ruler == bird;
    final isPadu = ruler.subordinate == bird;

    final dayWindows = isAuthority && !isPadu
        ? KozhliSuccessRules.windowsForPeriod(
            periodStart: window.sunrise,
            periodEnd: window.sunset,
            paksham: paksham,
            dayNight: DayNight.day,
            rulingWeekday: date.weekday,
            paduDay: isPadu,
          )
        : const <KozhliSuccessWindow>[];

    final nightWindows = isAuthority && !isPadu
        ? KozhliSuccessRules.windowsForPeriod(
            periodStart: window.sunset,
            periodEnd: window.nextSunrise,
            paksham: paksham,
            dayNight: DayNight.night,
            rulingWeekday: date.weekday,
            paduDay: isPadu,
          )
        : const <KozhliSuccessWindow>[];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPadu
              ? const Color(0xFFE65353)
              : isAuthority
                  ? const Color(0xFFE4AD3C)
                  : const Color(0xFF414141),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dateFmt.format(date), style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            '${paksham == Paksham.valarpirai ? 'வளர்பிறை' : 'தேய்பிறை'}  •  உதயம் ${timeFmt.format(window.sunrise)}  •  அஸ்தமனம் ${timeFmt.format(window.sunset)}',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(height: 8),
          Text(
            'இன்றைய அதிகார பட்சி: ${ruler.ruler.tamil}  •  கோழியுடன்: ${_relationship(ruler, bird)}',
            style: const TextStyle(color: Color(0xFFE4AD3C), fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 10),
          if (isPadu)
            _PredictionBanner(
              color: const Color(0xFFE65353),
              title: 'KOZHLI படுபட்சி',
              value: '0% SUCCESS — தவிர்க்கவும்',
            )
          else if (isAuthority) ...[
            const _PredictionBanner(
              color: Color(0xFF80D94E),
              title: 'KOZHLI அதிகார நாள்',
              value: 'அரசு 100%  •  ஊண் 75%  •  நடை 50%',
            ),
            const SizedBox(height: 8),
            if (dayWindows.isNotEmpty) ...[
              const Text('☀️ பகல் வெற்றி நேரங்கள்', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              ...dayWindows.map((w) => _WindowRow(window: w, timeFmt: timeFmt)),
            ],
            if (nightWindows.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('🌙 இரவு வெற்றி நேரங்கள்', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              ...nightWindows.map((w) => _WindowRow(window: w, timeFmt: timeFmt)),
            ],
          ] else
            const _PredictionBanner(
              color: Color(0xFF9B8DFF),
              title: 'சாதாரண நாள்',
              value: 'KOZHLI அதிகார பட்சி இல்லை',
            ),
        ],
      ),
    );
  }

  static String _relationship(DayRulerInfo info, Pakshi bird) {
    if (info.ruler == bird) return 'சுயம்';
    if (info.subordinate == bird) return 'படுபட்சி';
    if (info.enemies.contains(bird)) return 'பகை பட்சி';
    if (info.friend == bird) return 'நட்பு பட்சி';
    return 'நடுநிலை';
  }
}

class _PredictionBanner extends StatelessWidget {
  final Color color;
  final String title;
  final String value;
  const _PredictionBanner({required this.color, required this.title, required this.value});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: color.withOpacity(.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(.65)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
      const SizedBox(height: 3),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 14)),
    ]),
  );
}

class _WindowRow extends StatelessWidget {
  final KozhliSuccessWindow window;
  final DateFormat timeFmt;
  const _WindowRow({required this.window, required this.timeFmt});

  @override
  Widget build(BuildContext context) {
    final color = switch (window.percent) {
      100 => const Color(0xFF80D94E),
      75 => const Color(0xFFB9E45C),
      50 => const Color(0xFFE4AD3C),
      _ => const Color(0xFFE65353),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text('${timeFmt.format(window.start)} – ${timeFmt.format(window.end)}', style: const TextStyle(color: Colors.white70, fontSize: 12))),
          Text(window.activity.tamil, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Text('${window.percent}%', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
