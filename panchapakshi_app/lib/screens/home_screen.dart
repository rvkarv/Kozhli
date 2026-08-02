import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/panchapakshi_rules.dart';
import '../core/thaarai_calculator.dart';
import '../models/pakshi.dart';
import '../services/app_state.dart';
import '../widgets/activity_card.dart';
import '../widgets/countdown_ring.dart';
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

    final gowriSlot =
        s != null ? PanchapakshiRules.gowriSlotFor(s.asOf) : null;
    final horaiSlot =
        s != null ? PanchapakshiRules.horaiSlotFor(s.asOf) : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('கோழி பட்சி'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Tomorrow / Week ahead',
            onPressed: app.location == null
                ? null
                : () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ForecastScreen()),
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
              if (app.loading) const Center(child: CircularProgressIndicator()),
              if (app.error != null)
                Text(app.error!, style: const TextStyle(color: Colors.red)),
              if (s != null) ...[
                Center(
                  child: Column(
                    children: [
                      Text(
                        s.dayNight == DayNight.day ? '☀️ பகல் (Day)' : '🌙 இரவு (Night)',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        s.paksham == Paksham.valarpirai
                            ? 'வளர்பிறை (Waxing)'
                            : 'தேய்பிறை (Waning)',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: CountdownRing(
                    remaining: s.remaining.isNegative ? Duration.zero : s.remaining,
                    totalAntharamDuration: s.antharamEnd.difference(s.antharamStart),
                    label: 'அந்தரம் ${s.antharam} முடிய',
                  ),
                ),
                const SizedBox(height: 20),
                ActivityCard(
                  title: 'இப்போதைய தொழில் (Current — ஜாமம் ${s.jamam})',
                  activity: s.jamamActivity,
                  subtitle:
                      '${timeFmt.format(s.jamamStart)} – ${timeFmt.format(s.jamamEnd)}',
                ),
                const SizedBox(height: 10),
                ActivityCard(
                  title: 'அந்தரப் பட்சி (${s.antharamBird.tamil} - அந்தரம் ${s.antharam})',
                  activity: s.antharamActivity,
                  subtitle:
                      '${timeFmt.format(s.antharamStart)} – ${timeFmt.format(s.antharamEnd)}',
                ),
                const SizedBox(height: 10),
                ActivityCard(
                  title: 'அடுத்த தொழில் (Next)',
                  activity: s.nextActivity,
                  subtitle: 'தொடங்கும் நேரம்: ${timeFmt.format(s.nextActivityStart)}',
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _InfoTile(
                        title: 'கௌரி',
                        value: gowriSlot?.label ?? s.gowriName,
                        good: s.gowriIsGood,
                        subtitle: gowriSlot == null
                            ? null
                            : '${timeFmt.format(gowriSlot.start)} – ${timeFmt.format(gowriSlot.end)}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InfoTile(
                        title: 'ஓரை (Horai)',
                        value: horaiSlot?.planet ?? s.horaiPlanet,
                        subtitle: horaiSlot == null
                            ? null
                            : '${timeFmt.format(horaiSlot.start)} – ${timeFmt.format(horaiSlot.end)}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ---- தாராபலம் (Thaarai) ----
                if (app.thaaraiFromRasi != null || app.thaaraiFromLagna != null) ...[
                  Text('தாராபலம் (Thaarai)',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  if (app.thaaraiFromRasi != null)
                    _ThaaraiCard(
                      label: 'பிறந்த ராசி நட்சத்திரத்திற்கு',
                      result: app.thaaraiFromRasi!,
                    ),
                  if (app.thaaraiFromRasi != null && app.thaaraiFromLagna != null)
                    const SizedBox(height: 8),
                  if (app.thaaraiFromLagna != null)
                    _ThaaraiCard(
                      label: 'பிறந்த லக்னம் நட்சத்திரத்திற்கு',
                      result: app.thaaraiFromLagna!,
                    ),
                  const SizedBox(height: 20),
                ] else if (app.birthNakshatra == null) ...[
                  Card(
                    color: Colors.amber.withOpacity(0.1),
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'தாராபலம் காண பிறந்த விவரங்களை உள்ளிடவும் (Set your '
                        'birth details to see Thaarai).',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('சூரிய அட்டவணை (Sun times)',
                            style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 6),
                        Text('சூரிய உதயம்: ${timeFmt.format(s.sunrise)}'),
                        Text('சூரிய அஸ்தமனம்: ${timeFmt.format(s.sunset)}'),
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
  const _LocationBar({required this.app});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.place, color: Colors.deepPurple),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            app.location?.label ?? 'இடம் தேர்வு செய்யப்படவில்லை',
            style: const TextStyle(fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        TextButton.icon(
          onPressed: app.useGps,
          icon: const Icon(Icons.gps_fixed, size: 18),
          label: const Text('GPS'),
        ),
        TextButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
          ),
          icon: const Icon(Icons.search, size: 18),
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
  final String? subtitle;
  const _InfoTile({
    required this.title,
    required this.value,
    this.good,
    this.subtitle,
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
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(value,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ],
        ),
      ),
    );
  }
}

class _ThaaraiCard extends StatelessWidget {
  final String label;
  final ThaaraiResult result;
  const _ThaaraiCard({required this.label, required this.result});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(result.category.tamil,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(result.category.effect, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
