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
                  style: const TextStyle(
                    color: Colors.red,
                  ),
                ),

              if (s != null) ...[
                Center(
                  child: Column(
                    children: [
                      Text(
                        s.dayNight == DayNight.day
                            ? '☀️ பகல் (Day)'
                            : '🌙 இரவு (Night)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

                ActivityCard(
                  title:
                      'இப்போதைய தொழில் (Current — ஜாமம் ${s.jamam})',
                  activity: s.jamamActivity,
                  subtitle:
                      '${timeFmt.format(s.jamamStart)} – '
                      '${timeFmt.format(s.jamamEnd)}',
                ),

                const SizedBox(height: 10),

                ActivityCard(
                  title:
                      'அந்தரப் பட்சி (${s.antharamBird.tamil} - அந்தரம் ${s.antharam})',
                  activity: s.antharamActivity,
                  subtitle:
                      '${timeFmt.format(s.antharamStart)} – '
                      '${timeFmt.format(s.antharamEnd)}',
                ),

                const SizedBox(height: 10),

                ActivityCard(
                  title:
                      'அடுத்த அந்தர பட்சி (${s.nextAntharamBird.tamil})',
                  activity: s.nextActivity,
                  subtitle:
                      'தொடங்கும் நேரம்: '
                      '${timeFmt.format(s.nextActivityStart)}',
                ),

                const SizedBox(height: 20),

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

                /*
                 * IMPORTANT:
                 *
                 * Do NOT use DateTime.now().weekday here.
                 *
                 * s.asOf is the calculation date/time produced by
                 * PanchapakshiEngine.
                 *
                 * Therefore:
                 *
                 * Current mode  -> current local weekday
                 * Future mode   -> selected local weekday
                 * Past mode     -> selected local weekday
                 *
                 * This keeps the Day Ruler synchronized with the
                 * Panchapakshi calculation engine.
                 */
                DayRulerCard(
                  bird: app.bird,
                  info: DayRulerRules.forWeekday(
                    s.asOf.weekday,
                    s.paksham,
                  ),
                ),

                const SizedBox(height: 20),

                if (app.currentMoon != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'தற்போதைய நட்சத்திரம்',
                            style:
                                Theme.of(context).textTheme.titleSmall,
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

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'சூரிய அட்டவணை (Sun times)',
                          style:
                              Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'சூரிய உதயம்: '
                          '${timeFmt.format(s.sunrise)}',
                        ),
                        Text(
                          'சூரிய அஸ்தமனம்: '
                          '${timeFmt.format(s.sunset)}',
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
            app.location?.label ??
                'இடம் தேர்வு செய்யப்படவில்லை',
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
          crossAxisAlignment:
              CrossAxisAlignment.start,
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
