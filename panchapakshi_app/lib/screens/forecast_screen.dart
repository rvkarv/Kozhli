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

  Future<void> _selectLanguage(BuildContext context, AppState app) async {
    final selected = await showDialog<Locale>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Language / மொழி'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('தமிழ்', style: TextStyle(fontSize: 18)),
              title: const Text('தமிழ்'),
              onTap: () => Navigator.pop(context, const Locale('ta')),
            ),
            ListTile(
              leading: const Text('EN', style: TextStyle(fontSize: 18)),
              title: const Text('English'),
              onTap: () => Navigator.pop(context, const Locale('en')),
            ),
          ],
        ),
      ),
    );
    if (selected != null) app.setLocale(selected);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final loc = app.location;
    final tamil = app.locale.languageCode == 'ta';

    if (loc == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF101010),
        body: Center(
          child: Text(
            tamil ? 'இடம் தேர்வு செய்யவும்' : 'Please select a location',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final dateFmt = DateFormat('EEE, d MMM yyyy');
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101010),
        foregroundColor: Colors.white,
        title: Text(tamil ? 'எதிர்கால கணிப்பு' : 'Future Prediction'),
        actions: [
          IconButton(
            tooltip: tamil ? 'மொழி தேர்வு' : 'Select language',
            icon: const Icon(Icons.translate, color: Color(0xFFE4AD3C)),
            onPressed: () => _selectLanguage(context, app),
          ),
          IconButton(
            tooltip: tamil ? 'தேதி தேர்வு' : 'Select date',
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
                  Text(
                    tamil
                        ? 'தொடக்க தேதி: ${dateFmt.format(_startDate)}'
                        : 'Start date: ${dateFmt.format(_startDate)}',
                    style: const TextStyle(color: Colors.white),
                  ),
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
            tamil: tamil,
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
  final bool tamil;

  const _DayCard({
    required this.date,
    required this.bird,
    required this.lat,
    required this.lng,
    required this.dateFmt,
    required this.tamil,
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
            '${paksham == Paksham.valarpirai ? (tamil ? 'வளர்பிறை' : 'Waxing') : (tamil ? 'தேய்பிறை' : 'Waning')}  •  ${tamil ? 'உதயம்' : 'Sunrise'} ${timeFmt.format(window.sunrise)}  •  ${tamil ? 'அஸ்தமனம்' : 'Sunset'} ${timeFmt.format(window.sunset)}',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(height: 8),
          Text(
            '${tamil ? 'இன்றைய அதிகார பட்சி' : 'Today’s authority bird'}: ${ruler.ruler.tamil}  •  ${tamil ? 'கோழியுடன்' : 'With Kozhli'}: ${_relationship(ruler.ruler)}',
            style: const TextStyle(color: Color(0xFFE4AD3C), fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 10),
          if (isPadu)
            _PredictionBanner(
              color: const Color(0xFFE65353),
              title: tamil ? 'KOZHLI படுபட்சி' : 'KOZHLI Padu Pakshi',
              value: tamil ? '0% வெற்றி — தவிர்க்கவும்' : '0% SUCCESS — Avoid',
            )
          else if (isAuthority) ...[
            _PredictionBanner(
              color: const Color(0xFF80D94E),
              title: tamil ? 'KOZHLI அதிகார நாள்' : 'KOZHLI Authority Day',
              value: tamil ? 'அரசு 100%  •  ஊண் 75%  •  நடை 50%' : 'Ruling 100%  •  Eating 75%  •  Walking 50%',
            ),
            const SizedBox(height: 8),
            if (dayWindows.isNotEmpty) ...[
              Text(tamil ? '☀️ பகல் வெற்றி நேரங்கள்' : '☀️ Day success periods', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              ...dayWindows.map((w) => _WindowRow(window: w, timeFmt: timeFmt, tamil: tamil)),
            ],
            if (nightWindows.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(tamil ? '🌙 இரவு வெற்றி நேரங்கள்' : '🌙 Night success periods', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              ...nightWindows.map((w) => _WindowRow(window: w, timeFmt: timeFmt, tamil: tamil)),
            ],
          ] else
            _PredictionBanner(
              color: const Color(0xFF9B8DFF),
              title: tamil ? 'சாதாரண நாள்' : 'Normal Day',
              value: tamil ? 'KOZHLI அதிகார பட்சி இல்லை' : 'KOZHLI is not the authority bird',
            ),
        ],
      ),
    );
  }

  // The relationship label is always from the fixed KOZHLI reference bird.
  // It must NOT be derived from the day's subordinate/enemy fields.
  static String _relationship(Pakshi authorityBird) {
    switch (authorityBird) {
      case Pakshi.kozhi:
        return 'சுயம்';
      case Pakshi.mayil:
        return 'நட்பு பட்சி';
      case Pakshi.kaagam:
        return 'படுபட்சி';
      case Pakshi.vallooru:
      case Pakshi.aandhai:
        return 'பகை பட்சி';
    }
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
  final bool tamil;
  const _WindowRow({required this.window, required this.timeFmt, required this.tamil});

  @override
  Widget build(BuildContext context) {
    final color = switch (window.percent) {
      100 => const Color(0xFF80D94E),
      75 => const Color(0xFFB9E45C),
      50 => const Color(0xFFE4AD3C),
      _ => const Color(0xFFE65353),
    };
    final activity = tamil ? window.activity.tamil : window.activity.english;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text('${timeFmt.format(window.start)} – ${timeFmt.format(window.end)}', style: const TextStyle(color: Colors.white70, fontSize: 12))),
          Text(activity, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Text('${window.percent}%', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
