import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/day_ruler_rules.dart';
import '../core/nakshatra_calculator.dart';
import '../core/thaarai_calculator.dart';
import '../models/pakshi.dart';
import '../models/panchapakshi_state.dart';
import '../services/app_state.dart';
import 'birth_details_screen.dart';
import 'forecast_screen.dart';
import 'location_picker_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedNav = 0;

  static const _bg = Color(0xFF080808);
  static const _panel = Color(0xFF141414);
  static const _gold = Color(0xFFE8A83A);
  static const _purple = Color(0xFFB77BFF);
  static const _cyan = Color(0xFF63D7E6);
  static const _green = Color(0xFF9BE34A);
  static const _muted = Color(0xFFB5B5B5);

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
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, size: 30, color: Colors.white),
          onPressed: () => _showMenu(context, app),
        ),
        titleSpacing: 0,
        title: const Row(
          children: [
            Text('🐓', style: TextStyle(fontSize: 28)),
            SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KOZHLI',
                  style: TextStyle(
                    color: _gold,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'PANCHAPAKSHI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    letterSpacing: 1.6,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.language, color: _gold),
            onPressed: () => app.setLocale(
              app.locale.languageCode == 'ta'
                  ? const Locale('en')
                  : const Locale('ta'),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month, color: _gold),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ForecastScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: s == null
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: app.useGps,
                color: _gold,
                backgroundColor: _panel,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 18),
                  children: [
                    _HeaderStatus(
                      state: s,
                      location: app.location?.label,
                      timeFmt: timeFmt,
                    ),
                    const SizedBox(height: 12),
                    _BirthSummary(
                      birthNakshatra: app.birthNakshatra,
                      birthLagnaNakshatra: app.birthLagnaNakshatra,
                      paksham: s.paksham,
                      onEdit: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BirthDetailsScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _DayAuthorityRow(
                      weekday: s.rulingWeekday,
                      paksham: s.paksham,
                      bird: app.bird,
                    ),
                    const SizedBox(height: 12),
                    _JamamCard(
                      activity: s.jamamActivity,
                      jamam: s.jamam,
                      start: s.jamamStart,
                      end: s.jamamEnd,
                      timeFmt: timeFmt,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _AntharamPanel(
                            title: 'தற்போதைய அந்தர பட்சி',
                            bird: s.antharamBird,
                            activity: s.antharamActivity,
                            start: s.antharamStart,
                            end: s.antharamEnd,
                            relation: _kozhliRelationship(s.antharamBird),
                            timeFmt: timeFmt,
                            accent: Colors.redAccent,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _AntharamPanel(
                            title: 'அடுத்த அந்தர பட்சி',
                            bird: s.nextAntharamBird,
                            activity: s.nextActivity,
                            start: s.nextActivityStart,
                            end: null,
                            relation: _kozhliRelationship(s.nextAntharamBird),
                            timeFmt: timeFmt,
                            accent: _green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (app.currentMoon != null)
                      _NakshatraPanel(moon: app.currentMoon!),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _ThaaraiPanel(
                            title: 'தாராபலம் (பிறந்த ராசி\nநட்சத்திரத்திற்கு)',
                            result: app.thaarai,
                            accent: const Color(0xFFB8E37A),
                            onSetup: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const BirthDetailsScreen(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ThaaraiPanel(
                            title: 'தாராபலம் (பிறந்த லக்ன\nநட்சத்திரத்திற்கு)',
                            result: app.thaaraiLagna,
                            accent: _cyan,
                            onSetup: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const BirthDetailsScreen(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _TimePanel(
                            title: 'தற்போதைய கௌரி நல்ல நேரம்',
                            value: s.gowriName,
                            start: s.gowriStart,
                            end: s.gowriEnd,
                            accent: s.gowriIsGood ? _green : Colors.redAccent,
                            icon: Icons.auto_awesome,
                            timeFmt: timeFmt,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _TimePanel(
                            title: 'தற்போதைய கிரக ஓரை',
                            value: s.horaiPlanet,
                            start: s.horaiStart,
                            end: s.horaiEnd,
                            accent: _cyan,
                            icon: Icons.nightlight_round,
                            timeFmt: timeFmt,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _SunPanel(
                      sunrise: s.sunrise,
                      sunset: s.sunset,
                      timeFmt: timeFmt,
                    ),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: _BottomNav(
        selected: _selectedNav,
        onSelected: (index) {
          setState(() => _selectedNav = index);
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ForecastScreen()),
            );
          }
        },
      ),
    );
  }

  void _showMenu(BuildContext context, AppState app) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _panel,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.gps_fixed, color: _gold),
              title: const Text(
                'GPS / தற்போதைய இடம்',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () async {
                Navigator.pop(context);
                await app.useGps();
              },
            ),
            ListTile(
              leading: const Icon(Icons.search, color: _gold),
              title: const Text(
                'இடம் தேடு',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LocationPickerScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderStatus extends StatelessWidget {
  final PanchapakshiState state;
  final String? location;
  final DateFormat timeFmt;

  const _HeaderStatus({
    required this.state,
    required this.location,
    required this.timeFmt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF101010),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF33291B)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.access_time,
            color: _HomeScreenState._gold,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_weekdayTamil(state.rulingWeekday)}  ${state.dayNight == DayNight.day ? '☀️ பகல்' : '🌙 இரவு'}  ${timeFmt.format(state.asOf)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (location != null)
                  Text(
                    location!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _HomeScreenState._muted,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            state.paksham == Paksham.valarpirai ? 'வளர்பிறை' : 'தேய்பிறை',
            style: const TextStyle(
              color: _HomeScreenState._gold,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _BirthSummary extends StatelessWidget {
  final String? birthNakshatra;
  final String? birthLagnaNakshatra;
  final Paksham paksham;
  final VoidCallback onEdit;

  const _BirthSummary({
    required this.birthNakshatra,
    required this.birthLagnaNakshatra,
    required this.paksham,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return _DarkCard(
      child: Row(
        children: [
          Expanded(
            child: _MiniValue(
              label: 'பிறந்த ராசி நட்சத்திரம்',
              value: birthNakshatra ?? '—',
            ),
          ),
          const _Divider(),
          Expanded(
            child: _MiniValue(
              label: 'பிறந்த பக்ஷம்',
              value: paksham == Paksham.valarpirai ? 'வளர்பிறை' : 'தேய்பிறை',
            ),
          ),
          const _Divider(),
          Expanded(
            child: _MiniValue(
              label: 'பிறந்த லக்ன நட்சத்திரம்',
              value: birthLagnaNakshatra ?? '—',
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit, color: _HomeScreenState._gold, size: 18),
          ),
        ],
      ),
    );
  }
}

class _DayAuthorityRow extends StatelessWidget {
  final int weekday;
  final Paksham paksham;
  final Pakshi bird;

  const _DayAuthorityRow({
    required this.weekday,
    required this.paksham,
    required this.bird,
  });

  @override
  Widget build(BuildContext context) {
    final info = DayRulerRules.forWeekday(weekday, paksham);
    return Row(
      children: [
        Expanded(
          child: _AuthorityCard(
            title: 'கோழி அதிகார நாள்',
            topLabel: 'அதிகார பட்சி',
            bird: info.ruler,
            isMine: info.ruler == bird,
            color: _HomeScreenState._purple,
            weekday: _weekdayTamil(weekday),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _AuthorityCard(
            title: 'கோழி படுபட்சி நாள்',
            topLabel: 'படுபட்சி',
            bird: info.subordinate,
            isMine: info.subordinate == bird,
            color: _HomeScreenState._cyan,
            weekday: _weekdayTamil(weekday),
          ),
        ),
      ],
    );
  }
}

class _AuthorityCard extends StatelessWidget {
  final String title;
  final String topLabel;
  final Pakshi bird;
  final bool isMine;
  final Color color;
  final String weekday;

  const _AuthorityCard({
    required this.title,
    required this.topLabel,
    required this.bird,
    required this.isMine,
    required this.color,
    required this.weekday,
  });

  @override
  Widget build(BuildContext context) {
    return _DarkCard(
      borderColor: color.withOpacity(.55),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _HomeScreenState._gold,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isMine ? Icons.arrow_upward : Icons.arrow_downward,
                color: color,
                size: 26,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  bird.tamil,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: Color(0xFF303030)),
          Text(
            '$topLabel  •  $weekday',
            style: const TextStyle(
              color: _HomeScreenState._muted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _JamamCard extends StatelessWidget {
  final Thozhil activity;
  final int jamam;
  final DateTime start;
  final DateTime end;
  final DateFormat timeFmt;

  const _JamamCard({
    required this.activity,
    required this.jamam,
    required this.start,
    required this.end,
    required this.timeFmt,
  });

  @override
  Widget build(BuildContext context) {
    return _DarkCard(
      borderColor: _HomeScreenState._gold.withOpacity(.65),
      child: Row(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _HomeScreenState._gold.withOpacity(.65),
                width: 2,
              ),
            ),
            alignment: Alignment.center,
            child: const Text('🐓', style: TextStyle(fontSize: 38)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'கோழி தற்போதைய தொழில்  •  ஜாமம் $jamam',
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  activity.tamil,
                  style: const TextStyle(
                    color: _HomeScreenState._green,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${timeFmt.format(start)} – ${timeFmt.format(end)}',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white70, size: 30),
        ],
      ),
    );
  }
}

class _AntharamPanel extends StatelessWidget {
  final String title;
  final Pakshi bird;
  final Thozhil activity;
  final DateTime start;
  final DateTime? end;
  final String relation;
  final DateFormat timeFmt;
  final Color accent;

  const _AntharamPanel({
    required this.title,
    required this.bird,
    required this.activity,
    required this.start,
    required this.end,
    required this.relation,
    required this.timeFmt,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return _DarkCard(
      borderColor: accent.withOpacity(.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            '${bird.tamil} – ${activity.tamil}',
            style: TextStyle(color: accent, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            end == null
                ? 'தொடங்கும் நேரம்: ${timeFmt.format(start)}'
                : '${timeFmt.format(start)} – ${timeFmt.format(end!)}',
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          const SizedBox(height: 6),
          _RelationChip(label: relation, color: accent),
        ],
      ),
    );
  }
}

class _NakshatraPanel extends StatelessWidget {
  final MoonPosition moon;

  const _NakshatraPanel({required this.moon});

  @override
  Widget build(BuildContext context) {
    return _DarkCard(
      borderColor: _HomeScreenState._purple.withOpacity(.65),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _HomeScreenState._purple.withOpacity(.7)),
            ),
            alignment: Alignment.center,
            child: const Text(
              '✦',
              style: TextStyle(color: _HomeScreenState._purple, fontSize: 34),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'தற்போதைய நட்சத்திரம்',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 3),
                Text(
                  '${moon.nakshatraName} – பாதம் ${moon.pada}',
                  style: const TextStyle(
                    color: _HomeScreenState._purple,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'ராசி: ${moon.rasiName}',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThaaraiPanel extends StatelessWidget {
  final String title;
  final ThaaraiResult? result;
  final Color accent;
  final VoidCallback onSetup;

  const _ThaaraiPanel({
    required this.title,
    required this.result,
    required this.accent,
    required this.onSetup,
  });

  @override
  Widget build(BuildContext context) {
    return _DarkCard(
      borderColor: accent.withOpacity(.55),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 13)),
          const SizedBox(height: 8),
          if (result == null)
            TextButton(onPressed: onSetup, child: const Text('அமைக்கவும்'))
          else ...[
            Text(
              result!.category.tamil,
              style: TextStyle(color: accent, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              result!.category.effect,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _TimePanel extends StatelessWidget {
  final String title;
  final String value;
  final DateTime start;
  final DateTime end;
  final Color accent;
  final IconData icon;
  final DateFormat timeFmt;

  const _TimePanel({
    required this.title,
    required this.value,
    required this.start,
    required this.end,
    required this.accent,
    required this.icon,
    required this.timeFmt,
  });

  @override
  Widget build(BuildContext context) {
    return _DarkCard(
      borderColor: accent.withOpacity(.45),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _HomeScreenState._gold,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(color: accent, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '${timeFmt.format(start)} – ${timeFmt.format(end)}',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SunPanel extends StatelessWidget {
  final DateTime sunrise;
  final DateTime sunset;
  final DateFormat timeFmt;

  const _SunPanel({
    required this.sunrise,
    required this.sunset,
    required this.timeFmt,
  });

  @override
  Widget build(BuildContext context) {
    return _DarkCard(
      child: Row(
        children: [
          const Icon(Icons.wb_sunny_outlined, color: _HomeScreenState._gold),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'சூரிய உதயம்  ${timeFmt.format(sunrise)}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          Expanded(
            child: Text(
              'சூரிய அஸ்தமனம்  ${timeFmt.format(sunset)}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelected;

  const _BottomNav({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    const labels = ['டாஷ்போர்டு', 'நாள்காட்டி', 'நல்ல நேரம்', 'வரலாறு', 'அமைப்புகள்'];
    const icons = [
      Icons.home,
      Icons.calendar_month,
      Icons.star_border,
      Icons.history,
      Icons.settings,
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF151515),
        border: Border(top: BorderSide(color: Color(0xFF303030))),
      ),
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(labels.length, (index) {
            final active = index == selected;
            return Expanded(
              child: InkWell(
                onTap: () => onSelected(index),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icons[index],
                      color: active ? _HomeScreenState._gold : Colors.white70,
                      size: 25,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      labels[index],
                      style: TextStyle(
                        color: active ? _HomeScreenState._gold : Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _DarkCard extends StatelessWidget {
  final Widget child;
  final Color? borderColor;

  const _DarkCard({required this.child, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor ?? const Color(0xFF2C2C2C)),
      ),
      child: child,
    );
  }
}

class _MiniValue extends StatelessWidget {
  final String label;
  final String value;

  const _MiniValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _HomeScreenState._muted, fontSize: 10),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 42, color: const Color(0xFF333333));
  }
}

class _RelationChip extends StatelessWidget {
  final String label;
  final Color color;

  const _RelationChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(.55)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

String _kozhliRelationship(Pakshi bird) {
  switch (bird) {
    case Pakshi.kozhi:
      return 'சுயம்';
    case Pakshi.mayil:
      return 'நட்பு';
    case Pakshi.kaagam:
      return 'படுபட்சி';
    case Pakshi.vallooru:
    case Pakshi.aandhai:
      return 'பகை பட்சி';
  }
}

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
