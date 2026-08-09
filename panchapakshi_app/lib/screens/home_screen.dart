import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/day_ruler_rules.dart';
import '../models/pakshi.dart';
import '../services/app_state.dart';
import '../widgets/activity_card.dart';
import '../widgets/countdown_ring.dart';
import '../widgets/day_ruler_card.dart';
import '../widgets/prediction_bar.dart';
import '../widgets/thaarai_card.dart';
import 'birth_details_screen.dart';
import 'forecast_screen.dart';
import 'location_picker_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final app = context.read<AppState>();

      await app.tryRestoreLastLocation();

      if (app.location == null) {
        await app.useGps();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final s = app.state;
    final timeFmt = DateFormat('hh:mm:ss a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('கோழி பட்சி'),
        actions: [
          PopupMenuButton<Locale>(
            icon: const Icon(Icons.language),
            tooltip: 'Language / மொழி',
            onSelected: (locale) => app.setLocale(locale),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: Locale('en'),
                child: Text('English'),
              ),
              PopupMenuItem(
                value: Locale('ta'),
                child: Text('தமிழ்'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Tomorrow / Week ahead',
            onPressed: app.location == null
                ? null
                : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ForecastScreen(),
                      ),
                    ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: app.useGps,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _LocationBar(app: app),
              const SizedBox(height: 12),

              const PredictionBar(),

              const SizedBox(height: 12),

              if (app.loading)
                const Center(
                  child: CircularProgressIndicator(),
                ),

              if (app.error != null)
                Text(
                  app.error!,
                  style: const TextStyle(color: Colors.red),
                ),

              if (s != null) ...[
                // ---------------------------------------------------------
                // DAY / NIGHT + PAKSHAM
                // ---------------------------------------------------------
                Center(
                  child: Column(
                    children: [
                      Text(
                        '${_weekdayTamil(s.rulingWeekday)}  •  '
                        '${s.dayNight == DayNight.day ? '☀️ பகல்' : '🌙 இரவு'}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s.paksham == Paksham.valarpirai
                            ? 'வளர்பிறை (Waxing)'
                            : 'தேய்பிறை (Waning)',
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ---------------------------------------------------------
                // PANCHAPAKSHI AUTHORITY / PADU SUMMARY
                // ---------------------------------------------------------
                _AuthoritySummary(
                  bird: app.bird,
                  rulingWeekday: s.rulingWeekday,
                  paksham: s.paksham,
                  authorityBird: s.authorityBird,
                  isAuthorityDay: s.isKozhliAuthorityDay,
                  isPaduDay: s.isKozhliPaduDay,
                  authorityRelationship: s.authorityRelationship,
                  successPercent: s.successPercent,
                  successLabel: s.successLabel,
                ),

                const SizedBox(height: 16),

                // ---------------------------------------------------------
                // COUNTDOWN
                // ---------------------------------------------------------
                Center(
                  child: CountdownRing(
                    remaining: s.remaining.isNegative
                        ? Duration.zero
                        : s.remaining,
                    totalAntharamDuration:
                        s.antharamEnd.difference(s.antharamStart),
                    label: 'அந்தரம் ${s.antharam} முடிய',
                  ),
                ),

                const SizedBox(height: 20),

                // ---------------------------------------------------------
                // CURRENT JAMAM
                // ---------------------------------------------------------
                ActivityCard(
                  title: 'இப்போதைய தொழில் (Current — ஜாமம் ${s.jamam})',
                  activity: s.jamamActivity,
                  subtitle:
                      '${timeFmt.format(s.jamamStart)} – '
                      '${timeFmt.format(s.jamamEnd)}',
                ),

                const SizedBox(height: 10),

                // ---------------------------------------------------------
                // CURRENT ANTHARAM
                // ---------------------------------------------------------
                ActivityCard(
                  title:
                      'அந்தரப் பட்சி (${s.antharamBird.tamil} - அந்தரம் ${s.antharam})',
                  activity: s.antharamActivity,
                  subtitle:
                      '${timeFmt.format(s.antharamStart)} – '
                      '${timeFmt.format(s.antharamEnd)}',
                ),

                const SizedBox(height: 8),

                // Explicit relationship for current antharam bird.
                _RelationshipCard(
                  title: 'தற்போதைய அந்தர பட்சி உறவு',
                  bird: s.antharamBird,
                  relationship: _relationshipForBird(
                    rulingWeekday: s.rulingWeekday,
                    paksham: s.paksham,
                    bird: s.antharamBird,
                  ),
                ),

                const SizedBox(height: 10),

                // ---------------------------------------------------------
                // NEXT ANTHARAM
                // ---------------------------------------------------------
                ActivityCard(
                  title: 'அடுத்த அந்தர பட்சி (${s.nextAntharamBird.tamil})',
                  activity: s.nextActivity,
                  subtitle:
                      'தொடங்கும் நேரம்: '
                      '${timeFmt.format(s.nextActivityStart)}',
                ),

                const SizedBox(height: 8),

                // Explicit relationship for next antharam bird.
                _RelationshipCard(
                  title: 'அடுத்த அந்தர பட்சி உறவு',
                  bird: s.nextAntharamBird,
                  relationship: _relationshipForBird(
                    rulingWeekday: s.rulingWeekday,
                    paksham: s.paksham,
                    bird: s.nextAntharamBird,
                  ),
                ),

                const SizedBox(height: 20),

                // ---------------------------------------------------------
                // GOWRI / HORAI
                // ---------------------------------------------------------
                Row(
                  children: [
                    Expanded(
                      child: _InfoTile(
                        title: 'கௌரி',
                        value: s.gowriName,
                        good: s.gowriIsGood,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InfoTile(
                        title: 'ஓரை (Horai)',
                        value: s.horaiPlanet,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ---------------------------------------------------------
                // DAY RULER CARD
                // IMPORTANT:
                // Use s.rulingWeekday instead of DateTime.now().weekday.
                // ---------------------------------------------------------
                DayRulerCard(
                  bird: app.bird,
                  info: DayRulerRules.forWeekday(
                    s.rulingWeekday,
                    s.paksham,
                  ),
                ),

                const SizedBox(height: 20),

                // ---------------------------------------------------------
                // CURRENT MOON / NAKSHATRA
                // ---------------------------------------------------------
                if (app.currentMoon != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'தற்போதைய நட்சத்திரம்',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${app.currentMoon!.nakshatraName} – '
                            'பாதம் ${app.currentMoon!.pada}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'ராசி: ${app.currentMoon!.rasiName}',
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                // ---------------------------------------------------------
                // THAARAI - BIRTH RASI
                // ---------------------------------------------------------
                ThaaraiCard(
                  title: 'தாராபலம் (பிறந்த ராசி நட்சத்திரத்திற்கு)',
                  thaarai: app.thaarai,
                  onSetup: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BirthDetailsScreen(),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ---------------------------------------------------------
                // THAARAI - LAGNA
                // ---------------------------------------------------------
                ThaaraiCard(
                  title: 'தாராபலம் (பிறந்த லக்னம் நட்சத்திரத்திற்கு)',
                  thaarai: app.thaaraiLagna,
                  onSetup: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BirthDetailsScreen(),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ---------------------------------------------------------
                // SUN TIMES
                // ---------------------------------------------------------
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'சூரிய அட்டவணை (Sun times)',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'சூரிய உதயம்: ${timeFmt.format(s.sunrise)}',
                        ),
                        Text(
                          'சூரிய அஸ்தமனம்: ${timeFmt.format(s.sunset)}',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================================================
// AUTHORITY / PADU SUMMARY
// ==========================================================================

class _AuthoritySummary extends StatelessWidget {
  final Pakshi bird;
  final int rulingWeekday;
  final Paksham paksham;
  final Pakshi authorityBird;
  final bool isAuthorityDay;
  final bool isPaduDay;
  final String authorityRelationship;
  final int successPercent;
  final String successLabel;

  const _AuthoritySummary({
    required this.bird,
    required this.rulingWeekday,
    required this.paksham,
    required this.authorityBird,
    required this.isAuthorityDay,
    required this.isPaduDay,
    required this.authorityRelationship,
    required this.successPercent,
    required this.successLabel,
  });

  @override
  Widget build(BuildContext context) {
    final rulerInfo = DayRulerRules.forWeekday(
      rulingWeekday,
      paksham,
    );

    final authorityBird = rulerInfo.ruler;
    final paduBird = rulerInfo.subordinate;

    final authorityColor = isAuthorityDay
        ? Colors.green
        : Colors.deepPurple;

    final paduColor = isPaduDay
        ? Colors.red
        : Colors.deepPurple;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'இன்றைய பஞ்சபட்சி நிலை',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'இன்றைய கிழமை: ${_weekdayTamil(rulingWeekday)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _StatusTile(
                    title: 'அதிகார பட்சி',
                    value: authorityBird.tamil,
                    color: authorityColor,
                    subtitle: authorityBird == bird
                        ? 'கோழிக்கு அதிகாரம்'
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatusTile(
                    title: 'படு பட்சி',
                    value: paduBird.tamil,
                    color: paduColor,
                    subtitle: paduBird == bird
                        ? 'கோழி படுபட்சி'
                        : null,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            _DetailLine(
              label: 'கோழி உறவு',
              value: authorityRelationship,
            ),

            const SizedBox(height: 4),

            _DetailLine(
              label: 'வெற்றி',
              value: '$successPercent% — $successLabel',
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================================================
// STATUS TILE
// ==========================================================================

class _StatusTile extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final String? subtitle;

  const _StatusTile({
    required this.title,
    required this.value,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 11,
                color: color,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ==========================================================================
// RELATIONSHIP CARD
// ==========================================================================

class _RelationshipCard extends StatelessWidget {
  final String title;
  final Pakshi bird;
  final String relationship;

  const _RelationshipCard({
    required this.title,
    required this.bird,
    required this.relationship,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blueGrey.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '$title: ${bird.tamil}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              relationship,
              style: const TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================================================
// DETAIL LINE
// ==========================================================================

class _DetailLine extends StatelessWidget {
  final String label;
  final String value;

  const _DetailLine({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

// ==========================================================================
// RELATIONSHIP CALCULATOR
// ==========================================================================

String _relationshipForBird({
  required int rulingWeekday,
  required Paksham paksham,
  required Pakshi bird,
}) {
  final info = DayRulerRules.forWeekday(
    rulingWeekday,
    paksham,
  );

  if (info.ruler == bird) {
    return 'சுயம்';
  }

  if (info.subordinate == bird) {
    return 'படுபட்சி';
  }

  if (info.enemies.contains(bird)) {
    return 'பகை பட்சி';
  }

  if (info.friend == bird) {
    return 'நட்பு';
  }

  return 'நடுநிலை';
}

// ==========================================================================
// TAMIL WEEKDAY
// ==========================================================================

String _weekdayTamil(int weekday) {
  switch (weekday) {
    case DateTime.monday:
      return 'திங்கள்';
    case DateTime.tuesday:
      return 'செவ்வாய்';
    case DateTime.wednesday:
      return 'புதன்';
    case DateTime.thursday:
      return 'வியாழன்';
    case DateTime.friday:
      return 'வெள்ளி';
    case DateTime.saturday:
      return 'சனி';
    case DateTime.sunday:
      return 'ஞாயிறு';
    default:
      return '';
  }
}

// ==========================================================================
// LOCATION BAR
// ==========================================================================

class _LocationBar extends StatelessWidget {
  final AppState app;

  const _LocationBar({
    required this.app,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.place,
          color: Colors.deepPurple,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            app.location?.label ?? 'இடம் தேர்வு செய்யப்படவில்லை',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        TextButton.icon(
          onPressed: app.useGps,
          icon: const Icon(
            Icons.gps_fixed,
            size: 18,
          ),
          label: const Text('GPS'),
        ),
        TextButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const LocationPickerScreen(),
            ),
          ),
          icon: const Icon(
            Icons.search,
            size: 18,
          ),
          label: const Text('தேடு'),
        ),
      ],
    );
  }
}

// ==========================================================================
// INFO TILE
// ==========================================================================

class _InfoTile extends StatelessWidget {
  final String title;
  final String value;
  final bool? good;

  const _InfoTile({
    required this.title,
    required this.value,
    this.good,
  });

  @override
  Widget build(BuildContext context) {
    final color = good == null
        ? Colors.blueGrey
        : (good! ? Colors.green : Colors.red);

    return Card(
      color: color.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
