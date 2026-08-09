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
        title: const Text(
          'கோழி பட்சி',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
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
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ForecastScreen(),
                      ),
                    );
                  },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: app.useGps,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              /*
               * -----------------------------------------------------------
               * LOCATION
               * -----------------------------------------------------------
               */
              _LocationBar(app: app),

              const SizedBox(height: 10),

              /*
               * -----------------------------------------------------------
               * CURRENT / FUTURE / PAST DATE-TIME CONTROL
               * -----------------------------------------------------------
               *
               * This widget must remain on the Dashboard because it
               * controls AppState.overridePickedLocal.
               */
              const PredictionBar(),

              const SizedBox(height: 12),

              if (app.loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),

              if (app.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    app.error!,
                    style: const TextStyle(
                      color: Colors.red,
                    ),
                  ),
                ),

              if (s != null) ...[
                /*
                 * ---------------------------------------------------------
                 * DAY / NIGHT + PAKSHAM
                 * ---------------------------------------------------------
                 */
                _PeriodHeader(
                  dayNight: s.dayNight,
                  paksham: s.paksham,
                ),

                const SizedBox(height: 14),

                /*
                 * ---------------------------------------------------------
                 * MAIN COUNTDOWN
                 * ---------------------------------------------------------
                 *
                 * The countdown remains the main visual focus of the
                 * Panchapakshi Dashboard.
                 */
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

                const SizedBox(height: 16),

                /*
                 * ---------------------------------------------------------
                 * CURRENT JAMAM
                 * ---------------------------------------------------------
                 */
                _SectionHeading(
                  icon: Icons.wb_sunny_outlined,
                  title: 'தற்போதைய ஜாமம்',
                ),

                const SizedBox(height: 6),

                ActivityCard(
                  title:
                      'இப்போதைய தொழில் (Current — ஜாமம் ${s.jamam})',
                  activity: s.jamamActivity,
                  subtitle:
                      '${timeFmt.format(s.jamamStart)} – '
                      '${timeFmt.format(s.jamamEnd)}',
                ),

                const SizedBox(height: 12),

                /*
                 * ---------------------------------------------------------
                 * CURRENT ANTHARAM
                 * ---------------------------------------------------------
                 */
                _SectionHeading(
                  icon: Icons.access_time,
                  title: 'தற்போதைய அந்தரம்',
                ),

                const SizedBox(height: 6),

                ActivityCard(
                  title:
                      'அந்தரப் பட்சி (${s.antharamBird.tamil} - அந்தரம் ${s.antharam})',
                  activity: s.antharamActivity,
                  subtitle:
                      '${timeFmt.format(s.antharamStart)} – '
                      '${timeFmt.format(s.antharamEnd)}',
                ),

                const SizedBox(height: 12),

                /*
                 * ---------------------------------------------------------
                 * NEXT ANTHARAM
                 * ---------------------------------------------------------
                 */
                _SectionHeading(
                  icon: Icons.skip_next,
                  title: 'அடுத்த அந்தரப் பட்சி',
                ),

                const SizedBox(height: 6),

                ActivityCard(
                  title:
                      'அடுத்த அந்தரப் பட்சி (${s.nextAntharamBird.tamil})',
                  activity: s.nextActivity,
                  subtitle:
                      'தொடங்கும் நேரம்: '
                      '${timeFmt.format(s.nextActivityStart)}',
                ),

                const SizedBox(height: 16),

                /*
                 * ---------------------------------------------------------
                 * GOWRI + HORAI
                 * ---------------------------------------------------------
                 */
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _InfoTile(
                        title: 'கௌரி',
                        value: s.gowriName,
                        good: s.gowriIsGood,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _InfoTile(
                        title: 'ஓரை (Horai)',
                        value: s.horaiPlanet,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                /*
                 * ---------------------------------------------------------
                 * DAY RULER
                 * ---------------------------------------------------------
                 *
                 * IMPORTANT:
                 * Use s.asOf.weekday rather than DateTime.now().weekday.
                 *
                 * This keeps Current/Future/Past calculations synchronized
                 * with the selected calculation date.
                 */
                _SectionHeading(
                  icon: Icons.shield_outlined,
                  title: 'அன்றைய அதிகாரப் பட்சி',
                ),

                const SizedBox(height: 6),

                DayRulerCard(
                  bird: app.bird,
                  info: DayRulerRules.forWeekday(
                    s.asOf.weekday,
                    s.paksham,
                  ),
                ),

                const SizedBox(height: 18),

                /*
                 * ---------------------------------------------------------
                 * SUNRISE / SUNSET
                 * ---------------------------------------------------------
                 */
                _SunTimesCard(
                  sunrise: s.sunrise,
                  sunset: s.sunset,
                  timeFmt: timeFmt,
                ),

                const SizedBox(height: 18),

                /*
                 * ---------------------------------------------------------
                 * NAKSHATRA
                 * ---------------------------------------------------------
                 *
                 * Kept below the main Panchapakshi section.
                 *
                 * Detailed astrology validation will be handled separately.
                 */
                if (app.currentMoon != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
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
                          const SizedBox(height: 2),
                          Text(
                            'ராசி: ${app.currentMoon!.rasiName}',
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 18),

                /*
                 * ---------------------------------------------------------
                 * THAARAI — BIRTH RASI NAKSHATRA
                 * ---------------------------------------------------------
                 */
                ThaaraiCard(
                  title: 'தாராபலம் (பிறந்த ராசி நட்சத்திரத்திற்கு)',
                  thaarai: app.thaarai,
                  onSetup: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BirthDetailsScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 10),

                /*
                 * ---------------------------------------------------------
                 * THAARAI — BIRTH LAGNA NAKSHATRA
                 * ---------------------------------------------------------
                 */
                ThaaraiCard(
                  title: 'தாராபலம் (பிறந்த லக்னம் நட்சத்திரத்திற்கு)',
                  thaarai: app.thaaraiLagna,
                  onSetup: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BirthDetailsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/* ==========================================================================
 * PERIOD HEADER
 * ========================================================================== */

class _PeriodHeader extends StatelessWidget {
  final DayNight dayNight;
  final Paksham paksham;

  const _PeriodHeader({
    required this.dayNight,
    required this.paksham,
  });

  @override
  Widget build(BuildContext context) {
    final isDay = dayNight == DayNight.day;

    return Column(
      children: [
        Text(
          isDay ? '☀️ பகல் (Day)' : '🌙 இரவு (Night)',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          paksham == Paksham.valarpirai
              ? 'வளர்பிறை (Waxing)'
              : 'தேய்பிறை (Waning)',
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

/* ==========================================================================
 * SECTION HEADING
 * ========================================================================== */

class _SectionHeading extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeading({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 19,
          color: Colors.deepPurple,
        ),
        const SizedBox(width: 7),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/* ==========================================================================
 * LOCATION BAR
 * ========================================================================== */

class _LocationBar extends StatelessWidget {
  final AppState app;

  const _LocationBar({
    required this.app,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 6,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.place,
              color: Colors.deepPurple,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                app.location?.label ??
                    'இடம் தேர்வு செய்யப்படவில்லை',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: app.useGps,
              child: const Text('GPS'),
            ),
            IconButton(
              tooltip: 'இடம் தேர்வு',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LocationPickerScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.search),
            ),
          ],
        ),
      ),
    );
  }
}

/* ==========================================================================
 * INFORMATION TILE
 * ========================================================================== */

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
      elevation: 2,
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
            const SizedBox(height: 4),
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

/* ==========================================================================
 * SUN TIMES
 * ========================================================================== */

class _SunTimesCard extends StatelessWidget {
  final DateTime sunrise;
  final DateTime sunset;
  final DateFormat timeFmt;

  const _SunTimesCard({
    required this.sunrise,
    required this.sunset,
    required this.timeFmt,
  });

  @override
  Widget build(BuildContext context) {
    final dayDuration = sunset.difference(sunrise);

    final totalMinutes = dayDuration.inMinutes;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'சூரிய அட்டவணை',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.wb_sunny_outlined,
                  size: 19,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'சூரிய உதயம்',
                    style: const TextStyle(
                      fontSize: 13,
                    ),
                  ),
                ),
                Text(
                  timeFmt.format(sunrise),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.nights_stay_outlined,
                  size: 19,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'சூரிய அஸ்தமனம்',
                    style: const TextStyle(
                      fontSize: 13,
                    ),
                  ),
                ),
                Text(
                  timeFmt.format(sunset),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 18),
            Row(
              children: [
                const Icon(
                  Icons.timelapse,
                  size: 19,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'பகல் நேரம்',
                    style: const TextStyle(
                      fontSize: 13,
                    ),
                  ),
                ),
                Text(
                  '${hours.toString().padLeft(2, '0')}:'
                  '${minutes.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
