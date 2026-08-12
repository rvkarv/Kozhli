import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/day_ruler_rules.dart';
import '../core/moon_nakshatra_window.dart';
import '../core/nakshatra_calculator.dart';
import '../core/thaarai_calculator.dart';
import '../models/pakshi.dart';
import '../models/panchapakshi_state.dart';
import '../services/app_state.dart';
import '../services/location_service.dart';
import 'birth_details_screen.dart';
import 'forecast_screen.dart';
import 'location_picker_screen.dart';

/// Main live dashboard.
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
  static const _danger = Color(0xFFC00000);
  static const _muted = Color(0xFFB5B5B5);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final app = context.read<AppState>();
      await app.tryRestoreLastLocation();
      if (app.location == null) await app.useGps();
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
                Text('KOZHLI', style: TextStyle(color: _gold, fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                Text('PANCHAPAKSHI', style: TextStyle(color: Colors.white, fontSize: 11, letterSpacing: 1.6)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Search City / இடம் தேடு',
            icon: const Icon(Icons.language, color: _gold),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LocationPickerScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month, color: _gold),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForecastScreen())),
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
                    _HeaderStatus(state: s, location: app.location?.label, timeFmt: timeFmt),
                    const SizedBox(height: 10),
                    _BirthSummary(
                      birthNakshatra: app.birthNakshatra,
                      birthLagnaNakshatra: app.birthLagnaNakshatra,
                      onEdit: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BirthDetailsScreen())),
                    ),
                    const SizedBox(height: 10),
                    if (app.currentMoon != null)
                      _CurrentAstroCard(
                        moon: app.currentMoon!,
                        window: app.currentMoonWindow,
                        location: app.location,
                      ),
                    const SizedBox(height: 10),
                    _PanchapakshiCard(state: s, timeFmt: timeFmt),
                    const SizedBox(height: 10),
                    _ThaaraiSummaryCard(
                      rasiThaarai: app.thaarai,
                      lagnaThaarai: app.thaaraiLagna,
                      onSetup: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BirthDetailsScreen())),
                    ),
                    const SizedBox(height: 10),
                    _TimingSummary(state: s, timeFmt: timeFmt),
                    const SizedBox(height: 10),
                    _SunPanel(sunrise: s.sunrise, sunset: s.sunset, timeFmt: timeFmt),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: _BottomNav(
        selected: _selectedNav,
        onSelected: (index) {
          setState(() => _selectedNav = index);
          if (index == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ForecastScreen()));
          } else if (index == 4) {
            _showMenu(context, app);
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
              title: const Text('GPS / தற்போதைய இடம்', style: TextStyle(color: Colors.white)),
              onTap: () async { Navigator.pop(context); await app.useGps(); },
            ),
            ListTile(
              leading: const Icon(Icons.search, color: _gold),
              title: const Text('நகரம் தேடு / இடம் தேர்வு செய்', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LocationPickerScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.translate, color: _gold),
              title: const Text('மொழி / Language', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                final selected = await showDialog<Locale>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Language / மொழி'),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          _LanguageChoice('தமிழ்', Locale('ta')),
                          _LanguageChoice('हिन्दी', Locale('hi')),
                          _LanguageChoice('తెలుగు', Locale('te')),
                          _LanguageChoice('ಕನ್ನಡ', Locale('kn')),
                          _LanguageChoice('മലയാളം', Locale('ml')),
                          _LanguageChoice('मराठी', Locale('mr')),
                          _LanguageChoice('বাংলা', Locale('bn')),
                          _LanguageChoice('ગુજરાતી', Locale('gu')),
                          _LanguageChoice('ਪੰਜਾਬੀ', Locale('pa')),
                          _LanguageChoice('অসমীয়া', Locale('as')),
                          _LanguageChoice('ଓଡ଼ିଆ', Locale('or')),
                          _LanguageChoice('اردو', Locale('ur')),
                          _LanguageChoice('Kashmiri / कश्मीरी', Locale('ks')),
                          _LanguageChoice('Konkani / कोंकणी', Locale('kok')),
                          _LanguageChoice('Meitei / মৈতৈলোন্', Locale('mni')),
                          _LanguageChoice('Sanskrit / संस्कृतम्', Locale('sa')),
                          _LanguageChoice('Nepali / नेपाली', Locale('ne')),
                          _LanguageChoice('Maithili / मैथिली', Locale('mai')),
                          _LanguageChoice('Dogri / डोगरी', Locale('doi')),
                          _LanguageChoice('Bodo / बड़ो', Locale('brx')),
                          _LanguageChoice('Santali / ᱥᱟᱱᱛᱟᱲᱤ', Locale('sat')),
                          _LanguageChoice('Sindhi / सिन्धी', Locale('sd')),
                          _LanguageChoice('English', Locale('en')),
                        ],
                      ),
                    ),
                  ),
                );
                if (selected != null) app.setLocale(selected);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageChoice extends StatelessWidget {
  final String label;
  final Locale locale;
  const _LanguageChoice(this.label, this.locale);
  @override
  Widget build(BuildContext context) => ListTile(title: Text(label), onTap: () => Navigator.pop(context, locale));
}

class _HeaderStatus extends StatelessWidget {
  final PanchapakshiState state;
  final String? location;
  final DateFormat timeFmt;
  const _HeaderStatus({required this.state, required this.location, required this.timeFmt});
  @override
  Widget build(BuildContext context) {
    return _DarkCard(
      borderColor: _HomeScreenState._gold.withOpacity(.45),
      child: Row(
        children: [
          const Icon(Icons.access_time, color: _HomeScreenState._gold, size: 21),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_weekdayTamil(state.rulingWeekday)}  ${state.dayNight == DayNight.day ? '☀️ பகல்' : '🌙 இரவு'}  ${timeFmt.format(state.asOf)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                if (location != null) Text(location!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _HomeScreenState._muted, fontSize: 11)),
              ],
            ),
          ),
          Text(state.paksham == Paksham.valarpirai ? 'வளர்பிறை' : 'தேய்பிறை', style: const TextStyle(color: _HomeScreenState._gold, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _BirthSummary extends StatelessWidget {
  final String? birthNakshatra;
  final String? birthLagnaNakshatra;
  final VoidCallback onEdit;
  const _BirthSummary({required this.birthNakshatra, required this.birthLagnaNakshatra, required this.onEdit});
  @override
  Widget build(BuildContext context) {
    return _DarkCard(
      child: Row(
        children: [
          Expanded(child: _MiniValue(label: 'பிறந்த ராசி நட்சத்திரம்', value: birthNakshatra ?? '—')),
          const _Divider(),
          Expanded(child: _MiniValue(label: 'பிறந்த லக்ன நட்சத்திரம்', value: birthLagnaNakshatra ?? '—')),
          IconButton(onPressed: onEdit, icon: const Icon(Icons.edit, color: _HomeScreenState._gold, size: 18)),
        ],
      ),
    );
  }
}

class _CurrentAstroCard extends StatelessWidget {
  final MoonPosition moon;
  final MoonNakshatraWindow? window;
  final ResolvedLocation? location;

  const _CurrentAstroCard({required this.moon, required this.window, required this.location});

  DateTime _localBoundary(DateTime utc) {
    if (location == null) return utc.toLocal();
    final offset = LocationService.effectiveOffset(location!, utcNow: utc);
    final local = utc.add(offset);
    return DateTime(local.year, local.month, local.day, local.hour, local.minute, local.second, local.millisecond, local.microsecond);
  }

  @override
  Widget build(BuildContext context) {
    final boundaryFmt = DateFormat('dd-MMM hh:mm:ss a');
    return _DarkCard(
      borderColor: _HomeScreenState._purple.withOpacity(.65),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _HomeScreenState._purple.withOpacity(.7))),
            alignment: Alignment.center,
            child: const Text('✦', style: TextStyle(color: _HomeScreenState._purple, fontSize: 30)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('தற்போதைய நட்சத்திரம்', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 2),
                Text('${moon.nakshatraName} — பாதம் ${moon.pada}', style: const TextStyle(color: _HomeScreenState._purple, fontSize: 21, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('ராசி: ${moon.rasiName}', style: const TextStyle(color: Colors.white, fontSize: 13)),
                if (window != null) ...[
                  const SizedBox(height: 7),
                  Text('நட்சத்திரம் தொடக்கம்: ${boundaryFmt.format(_localBoundary(window!.startUtc))}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                  Text('நட்சத்திரம் முடிவு: ${boundaryFmt.format(_localBoundary(window!.endUtc))}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                  Text('பாதம் ${moon.pada} தொடக்கம்: ${boundaryFmt.format(_localBoundary(window!.padaStartUtc))}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                  Text('பாதம் ${moon.pada} முடிவு: ${boundaryFmt.format(_localBoundary(window!.padaEndUtc))}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PanchapakshiCard extends StatelessWidget {
  final PanchapakshiState state;
  final DateFormat timeFmt;
  const _PanchapakshiCard({required this.state, required this.timeFmt});
  @override
  Widget build(BuildContext context) {
    final ruler = DayRulerRules.forWeekday(state.rulingWeekday, state.paksham);
    return Column(
      children: [
        _DarkCard(
          borderColor: _HomeScreenState._gold.withOpacity(.65),
          child: Row(
            children: [
              Container(width: 62, height: 62, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _HomeScreenState._gold.withOpacity(.7), width: 2)), alignment: Alignment.center, child: const Text('🐓', style: TextStyle(fontSize: 32))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('கோழி தற்போதைய தொழில்  •  ஜாமம் ${state.jamam}', style: const TextStyle(color: Colors.white, fontSize: 14)),
                const SizedBox(height: 3),
                Text(state.jamamActivity.tamil, style: TextStyle(color: _activityColor(state.jamamActivity), fontSize: 23, fontWeight: FontWeight.bold)),
                Text('${timeFmt.format(state.jamamStart)} – ${timeFmt.format(state.jamamEnd)}', style: const TextStyle(color: Colors.white, fontSize: 13)),
              ])),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _AntharamCard(title: 'தற்போதைய அந்தர பட்சி', bird: state.antharamBird, activity: state.antharamActivity, start: state.antharamStart, end: state.antharamEnd, accent: Colors.redAccent, timeFmt: timeFmt)),
          const SizedBox(width: 8),
          Expanded(child: _AntharamCard(title: 'அடுத்த அந்தர பட்சி', bird: state.nextAntharamBird, activity: state.nextActivity, start: state.nextActivityStart, end: null, accent: _HomeScreenState._green, timeFmt: timeFmt)),
        ]),
        const SizedBox(height: 8),
        _DarkCard(
          borderColor: _HomeScreenState._cyan.withOpacity(.45),
          child: Row(children: [
            Expanded(child: _AuthorityMini(title: 'அதிகார பட்சி', bird: ruler.ruler, mine: ruler.ruler == Pakshi.kozhi)),
            const _Divider(),
            Expanded(child: _AuthorityMini(title: 'படுபட்சி', bird: ruler.subordinate, mine: ruler.subordinate == Pakshi.kozhi)),
          ]),
        ),
      ],
    );
  }
}

class _AntharamCard extends StatelessWidget {
  final String title;
  final Pakshi bird;
  final Thozhil activity;
  final DateTime start;
  final DateTime? end;
  final Color accent;
  final DateFormat timeFmt;
  const _AntharamCard({required this.title, required this.bird, required this.activity, required this.start, required this.end, required this.accent, required this.timeFmt});
  @override
  Widget build(BuildContext context) {
    return _DarkCard(
      borderColor: accent.withOpacity(.45),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
        const SizedBox(height: 6),
        Text('${bird.tamil} — ${activity.tamil}', style: TextStyle(color: _activityColor(activity), fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(end == null ? 'தொடங்கும் நேரம்: ${timeFmt.format(start)}' : '${timeFmt.format(start)} – ${timeFmt.format(end!)}', style: const TextStyle(color: Colors.white, fontSize: 11)),
        const SizedBox(height: 5),
        _RelationChip(label: _kozhliRelationship(bird), color: _relationshipColor(bird)),
      ]),
    );
  }
}

class _AuthorityMini extends StatelessWidget {
  final String title;
  final Pakshi bird;
  final bool mine;
  const _AuthorityMini({required this.title, required this.bird, required this.mine});
  @override
  Widget build(BuildContext context) {
    final isPadu = title == 'படுபட்சி';
    final roleColor = isPadu ? _HomeScreenState._danger : _HomeScreenState._muted;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(children: [
        Icon(mine ? Icons.arrow_upward : Icons.arrow_downward, color: mine ? _HomeScreenState._green : _HomeScreenState._muted, size: 22),
        const SizedBox(width: 7),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(color: roleColor, fontSize: 10, fontWeight: isPadu ? FontWeight.bold : FontWeight.normal)),
          Text(bird.tamil, style: TextStyle(color: isPadu ? _HomeScreenState._danger : Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        ])),
      ]),
    );
  }
}

class _ThaaraiSummaryCard extends StatelessWidget {
  final ThaaraiResult? rasiThaarai;
  final ThaaraiResult? lagnaThaarai;
  final VoidCallback onSetup;
  const _ThaaraiSummaryCard({required this.rasiThaarai, required this.lagnaThaarai, required this.onSetup});
  @override
  Widget build(BuildContext context) {
    return _DarkCard(
      borderColor: const Color(0xFFB8E37A).withOpacity(.55),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.auto_awesome, color: Color(0xFFB8E37A), size: 20),
          const SizedBox(width: 7),
          const Expanded(child: Text('தாரை', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold))),
          TextButton(onPressed: onSetup, child: const Text('மாற்று')),
        ]),
        const Divider(color: Color(0xFF303030)),
        _ThaaraiLine(label: 'பிறந்த ராசி நட்சத்திரம்', result: rasiThaarai, accent: const Color(0xFFB8E37A)),
        const SizedBox(height: 10),
        _ThaaraiLine(label: 'பிறந்த லக்ன நட்சத்திரம்', result: lagnaThaarai, accent: _HomeScreenState._cyan),
      ]),
    );
  }
}

class _ThaaraiLine extends StatelessWidget {
  final String label;
  final ThaaraiResult? result;
  final Color accent;
  const _ThaaraiLine({required this.label, required this.result, required this.accent});
  @override
  Widget build(BuildContext context) {
    if (result == null) return Row(children: [Expanded(child: Text('$label: அமைக்கப்படவில்லை', style: const TextStyle(color: Colors.white70, fontSize: 12)))]);
    final t = result!;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: _HomeScreenState._muted, fontSize: 11)),
      const SizedBox(height: 2),
      Text('${t.birthNakshatra} → ${t.todayNakshatra}', style: TextStyle(color: _thaaraiColor(t.ordinalFromBirth), fontSize: 14, fontWeight: FontWeight.w600)),
      const SizedBox(height: 2),
      Text('${t.ordinalFromBirth} — ${t.category.tamil}', style: TextStyle(color: _thaaraiColor(t.ordinalFromBirth), fontSize: 17, fontWeight: FontWeight.bold)),
      const SizedBox(height: 2),
      Text(t.category.effect, style: TextStyle(color: _thaaraiColor(t.ordinalFromBirth), fontSize: 11)),
    ]);
  }
}

class _TimingSummary extends StatelessWidget {
  final PanchapakshiState state;
  final DateFormat timeFmt;
  const _TimingSummary({required this.state, required this.timeFmt});
  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: _TimePanel(title: 'தற்போதைய கௌரி நல்ல நேரம்', value: state.gowriName, start: state.gowriStart, end: state.gowriEnd, accent: state.gowriIsGood ? _HomeScreenState._green : Colors.redAccent, icon: Icons.auto_awesome, timeFmt: timeFmt)),
      const SizedBox(width: 8),
      Expanded(child: _TimePanel(title: 'தற்போதைய கிரக ஓரை', value: state.horaiPlanet, start: state.horaiStart, end: state.horaiEnd, accent: _HomeScreenState._cyan, icon: Icons.nightlight_round, timeFmt: timeFmt)),
    ]);
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
  const _TimePanel({required this.title, required this.value, required this.start, required this.end, required this.accent, required this.icon, required this.timeFmt});
  @override
  Widget build(BuildContext context) {
    return _DarkCard(
      borderColor: accent.withOpacity(.45),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, color: accent, size: 19), const SizedBox(width: 5), Expanded(child: Text(title, style: const TextStyle(color: _HomeScreenState._gold, fontWeight: FontWeight.w600, fontSize: 12)))]),
        const SizedBox(height: 7),
        Text(value, style: TextStyle(color: accent, fontSize: 19, fontWeight: FontWeight.bold)),
        const SizedBox(height: 3),
        Text('${timeFmt.format(start)} – ${timeFmt.format(end)}', style: const TextStyle(color: Colors.white, fontSize: 11)),
      ]),
    );
  }
}

class _SunPanel extends StatelessWidget {
  final DateTime sunrise;
  final DateTime sunset;
  final DateFormat timeFmt;
  const _SunPanel({required this.sunrise, required this.sunset, required this.timeFmt});
  @override
  Widget build(BuildContext context) {
    return _DarkCard(
      child: Row(children: [
        const Icon(Icons.wb_sunny_outlined, color: _HomeScreenState._gold),
        const SizedBox(width: 8),
        Expanded(child: Text('உதயம்  ${timeFmt.format(sunrise)}', style: const TextStyle(color: Colors.white, fontSize: 12))),
        Expanded(child: Text('அஸ்தமனம்  ${timeFmt.format(sunset)}', style: const TextStyle(color: Colors.white, fontSize: 12))),
      ]),
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
    const icons = [Icons.home, Icons.calendar_month, Icons.star_border, Icons.history, Icons.settings];
    return Container(
      decoration: const BoxDecoration(color: Color(0xFF151515), border: Border(top: BorderSide(color: Color(0xFF303030)))),
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: SafeArea(
        top: false,
        child: Row(children: List.generate(labels.length, (index) {
          final active = index == selected;
          return Expanded(child: InkWell(
            onTap: () => onSelected(index),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(icons[index], color: active ? _HomeScreenState._gold : Colors.white70, size: 25),
              const SizedBox(height: 3),
              Text(labels[index], style: TextStyle(color: active ? _HomeScreenState._gold : Colors.white70, fontSize: 10)),
            ]),
          ));
        })),
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
      decoration: BoxDecoration(color: const Color(0xFF141414), borderRadius: BorderRadius.circular(14), border: Border.all(color: borderColor ?? const Color(0xFF2C2C2C))),
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _HomeScreenState._muted, fontSize: 10)),
        const SizedBox(height: 5),
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => Container(width: 1, height: 42, color: const Color(0xFF333333));
}

class _RelationChip extends StatelessWidget {
  final String label;
  final Color color;
  const _RelationChip({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(.10), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(.55))),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

String _kozhliRelationship(Pakshi bird) {
  switch (bird) {
    case Pakshi.kozhi:
      return 'சுயம்';
    case Pakshi.mayil:
    case Pakshi.kaagam:
      return 'நட்பு';
    case Pakshi.vallooru:
    case Pakshi.aandhai:
      return 'பகை';
  }
}

Color _relationshipColor(Pakshi bird) {
  switch (bird) {
    case Pakshi.vallooru:
    case Pakshi.aandhai:
      return _HomeScreenState._danger;
    case Pakshi.kozhi:
    case Pakshi.mayil:
    case Pakshi.kaagam:
      return _HomeScreenState._green;
  }
}

Color _activityColor(Thozhil activity) {
  switch (activity) {
    case Thozhil.thuyil:
    case Thozhil.saavu:
      return _HomeScreenState._danger;
    case Thozhil.oon:
    case Thozhil.nadai:
    case Thozhil.arasu:
      return _HomeScreenState._green;
  }
}

Color _thaaraiColor(int ordinal) {
  const red = {1, 3, 5, 7, 9, 10, 12, 14, 16, 18, 19, 21, 23, 25};
  return red.contains(ordinal) ? _HomeScreenState._danger : _HomeScreenState._green;
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
