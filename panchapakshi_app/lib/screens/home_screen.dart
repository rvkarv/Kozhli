import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/pakshi.dart';
import '../services/app_state.dart';
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
  int _navIndex = 0;

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

    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(112),
        child: _KozhliHeader(
          app: app,
          onMenu: () => _showMenu(context),
        ),
      ),
      body: s == null
          ? const Center(child: CircularProgressIndicator())
          : Theme(
              data: Theme.of(context).copyWith(
                brightness: Brightness.dark,
                scaffoldBackgroundColor: const Color(0xFF101010),
                cardColor: const Color(0xFF171717),
              ),
              child: SafeArea(
                top: false,
                child: RefreshIndicator(
                onRefresh: app.isLive ? app.useGps : () async => app.setOverrideDateTime(null),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    _SelectionStrip(app: app),
                    const SizedBox(height: 12),
                    _DayStatusRow(state: s),
                    const SizedBox(height: 12),
                    _CurrentActivityCard(state: s),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _AntharamCard(state: s, next: false)),
                        const SizedBox(width: 10),
                        Expanded(child: _AntharamCard(state: s, next: true)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _SuccessCard(state: s),
                    const SizedBox(height: 12),
                    if (app.currentMoon != null)
                      _MoonCard(app: app),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ThaaraiCard(
                            title: 'தாராபலம் (பிறந்த ராசி நட்சத்திரத்திற்கு)',
                            thaarai: app.thaarai,
                            onSetup: () => _openBirthDetails(context),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ThaaraiCard(
                            title: 'தாராபலம் (பிறந்த லக்ன நட்சத்திரத்திற்கு)',
                            thaarai: app.thaaraiLagna,
                            onSetup: () => _openBirthDetails(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _GowriHoraiRow(state: s),
                    const SizedBox(height: 12),
                    _SunCard(state: s),
                    const SizedBox(height: 12),
                    _LocationCard(app: app),
                  ],
                ),
                ),
              ),
            ),
      bottomNavigationBar: _BottomBar(
        index: _navIndex,
        onTap: (index) {
          setState(() => _navIndex = index);
          if (index == 1 && app.location != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ForecastScreen()),
            );
          } else if (index == 4) {
            _openBirthDetails(context);
          } else if (index != 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('இந்த பகுதி அடுத்த கட்டத்தில் இணைக்கப்படும்.')),
            );
          }
        },
      ),
    );
  }

  void _openBirthDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BirthDetailsScreen()),
    );
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF191919),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.location_on, color: Color(0xFFE4AD3C)),
              title: const Text('இடத்தை மாற்று', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month, color: Color(0xFFE4AD3C)),
              title: const Text('Future Prediction', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ForecastScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _KozhliHeader extends StatelessWidget {
  final AppState app;
  final VoidCallback onMenu;

  const _KozhliHeader({required this.app, required this.onMenu});

  @override
  Widget build(BuildContext context) {
    final s = app.state;
    final time = s == null ? '--:--:--' : DateFormat('HH:mm:ss').format(s.asOf);
    final phase = s?.paksham == Paksham.valarpirai ? 'வளர்பிறை' : 'தேய்பிறை';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF090909), Color(0xFF17130C), Color(0xFF0D0D0D)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
          child: Row(
            children: [
              IconButton(
                onPressed: onMenu,
                icon: const Icon(Icons.menu, size: 34, color: Colors.white),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 58,
                height: 70,
                child: Image.asset(
                  'assets/kozhi.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Text('🐓', style: TextStyle(fontSize: 42)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'KOZHLI',
                      style: TextStyle(
                        color: Color(0xFFE7B54A),
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Text(
                      'PANCHAPAKSHI',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$phase  $time',
                      style: const TextStyle(
                        color: Color(0xFFF0C96A),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ForecastScreen()),
                ),
                icon: const Icon(Icons.calendar_month, color: Color(0xFFE4AD3C)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionStrip extends StatelessWidget {
  final AppState app;
  const _SelectionStrip({required this.app});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _Selector(title: 'பிறந்த ராசி நட்சத்திரம்', value: app.birthNakshatra ?? 'தேர்வு செய்யவும்')),
        const SizedBox(width: 8),
        Expanded(child: _Selector(title: 'பிறந்த பக்ஷம்', value: app.state?.paksham == Paksham.valarpirai ? 'வளர்பிறை' : 'தேய்பிறை')),
        const SizedBox(width: 8),
        Expanded(child: _Selector(title: 'பிறந்த லக்ன நட்சத்திரம்', value: app.birthLagnaNakshatra ?? 'தேர்வு செய்யவும்')),
      ],
    );
  }
}

class _Selector extends StatelessWidget {
  final String title;
  final String value;
  const _Selector({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF5D5D5D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 10)),
          const Spacer(),
          Row(
            children: [
              Expanded(child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
              const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 20),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayStatusRow extends StatelessWidget {
  final dynamic state;
  const _DayStatusRow({required this.state});

  @override
  Widget build(BuildContext context) {
    final isPadu = state.isKozhliPaduDay as bool;
    final isAuthority = state.isKozhliAuthorityDay as bool;
    return Row(
      children: [
        Expanded(
          child: _StatusCard(
            icon: isAuthority ? Icons.arrow_upward : Icons.arrow_downward,
            title: 'கோழி அதிகார நாள்',
            value: isAuthority ? 'கோழி' : 'இல்லை',
            good: isAuthority,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatusCard(
            icon: isPadu ? Icons.arrow_downward : Icons.shield_outlined,
            title: 'கோழி படுபட்சி நாள்',
            value: isPadu ? '0% — தவிர்க்கவும்' : 'இல்லை',
            good: !isPadu,
          ),
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool good;
  const _StatusCard({required this.icon, required this.title, required this.value, required this.good});

  @override
  Widget build(BuildContext context) {
    final color = good ? const Color(0xFFE4AD3C) : const Color(0xFFE95A5A);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(.65)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 1.5)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                const SizedBox(height: 3),
                Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentActivityCard extends StatelessWidget {
  final dynamic state;
  const _CurrentActivityCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final color = _activityColor(state.jamamActivity);
    final timeFmt = DateFormat('hh:mm a');
    return _Panel(
      borderColor: const Color(0xFFE4AD3C),
      child: Row(
        children: [
          _BirdCircle(bird: Pakshi.kozhi, color: color),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('கோழி தற்போதைய தொழில்', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 4),
                Text(state.jamamActivity.tamil, style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 3),
                Text('${timeFmt.format(state.jamamStart)} – ${timeFmt.format(state.jamamEnd)}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white70, size: 30),
        ],
      ),
    );
  }
}

class _AntharamCard extends StatelessWidget {
  final dynamic state;
  final bool next;
  const _AntharamCard({required this.state, required this.next});

  @override
  Widget build(BuildContext context) {
    final bird = next ? state.nextAntharamBird as Pakshi : state.antharamBird as Pakshi;
    final activity = next ? state.nextActivity : state.antharamActivity;
    final timeFmt = DateFormat('hh:mm a');
    final start = next ? state.nextActivityStart as DateTime : state.antharamStart as DateTime;
    final end = next ? null : state.antharamEnd as DateTime;
    return _Panel(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(next ? 'அடுத்த அந்தர பட்சி' : 'தற்போதைய அந்தர பட்சி', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 7),
          Row(
            children: [
              _BirdCircle(bird: bird, color: _activityColor(activity), small: true),
              const SizedBox(width: 8),
              Expanded(child: Text('${bird.tamil} – ${activity.tamil}', style: TextStyle(color: _activityColor(activity), fontSize: 16, fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 7),
          Text(end == null ? 'Starts ${timeFmt.format(start)}' : '${timeFmt.format(start)} – ${timeFmt.format(end)}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }
}

class _SuccessCard extends StatelessWidget {
  final dynamic state;
  const _SuccessCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final isPadu = state.isKozhliPaduDay as bool;
    final percent = state.successPercent as int;
    final color = isPadu
        ? const Color(0xFFE65353)
        : percent == 100
            ? const Color(0xFF80D94E)
            : percent == 75
                ? const Color(0xFFB9E45C)
                : percent == 50
                    ? const Color(0xFFE4AD3C)
                    : const Color(0xFF9B8DFF);

    return _Panel(
      borderColor: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isPadu ? 'KOZHLI படுபட்சி' : 'KOZHLI வெற்றி நிலை', style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 4),
          Text(isPadu ? '0% Success / Avoid' : (percent > 0 ? '$percent% Success' : 'சாதாரண காலம்'), style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(
            'இன்றைய அதிகார பட்சி: ${state.authorityBird.tamil}  •  கோழியுடன்: ${state.authorityRelationship}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          if (state.isKozhliAuthorityDay as bool && !isPadu) ...[
            const SizedBox(height: 8),
            const Text('அரசு 100%  •  ஊண் 75%  •  நடை 50%', style: TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ],
      ),
    );
  }
}

class _MoonCard extends StatelessWidget {
  final AppState app;
  const _MoonCard({required this.app});

  @override
  Widget build(BuildContext context) {
    final moon = app.currentMoon!;
    return _Panel(
      borderColor: const Color(0xFF76508F),
      child: Row(
        children: [
          const _StarCircle(),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('தற்போதைய நட்சத்திரம்', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 4),
                Text('${moon.nakshatraName} – பாதம் ${moon.pada}', style: const TextStyle(color: Color(0xFFC49BFF), fontSize: 20, fontWeight: FontWeight.bold)),
                Text('ராசி: ${moon.rasiName}', style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GowriHoraiRow extends StatelessWidget {
  final dynamic state;
  const _GowriHoraiRow({required this.state});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _MiniInfo(title: 'தற்போதைய கௌரி நல்ல நேரம்', value: state.gowriName, good: state.gowriIsGood)),
        const SizedBox(width: 10),
        Expanded(child: _MiniInfo(title: 'தற்போதைய கிரக ஓரை', value: state.horaiPlanet, good: null)),
      ],
    );
  }
}

class _MiniInfo extends StatelessWidget {
  final String title;
  final String value;
  final bool? good;
  const _MiniInfo({required this.title, required this.value, required this.good});

  @override
  Widget build(BuildContext context) {
    final color = good == true ? const Color(0xFF9DDC61) : const Color(0xFFE4AD3C);
    return _Panel(
      borderColor: color.withOpacity(.65),
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 5),
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}

class _SunCard extends StatelessWidget {
  final dynamic state;
  const _SunCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final f = DateFormat('hh:mm:ss a');
    return _Panel(
      borderColor: const Color(0xFF9D6F2A),
      child: Row(
        children: [
          const Icon(Icons.wb_sunny_outlined, color: Color(0xFFE4AD3C), size: 34),
          const SizedBox(width: 12),
          Expanded(child: Text('சூரிய உதயம்\n${f.format(state.sunrise)}', style: const TextStyle(color: Colors.white, fontSize: 14))),
          Expanded(child: Text('சூரிய அஸ்தமனம்\n${f.format(state.sunset)}', style: const TextStyle(color: Colors.white, fontSize: 14))),
        ],
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final AppState app;
  const _LocationCard({required this.app});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Row(children: [
        const Icon(Icons.location_on, color: Color(0xFFE4AD3C)),
        const SizedBox(width: 8),
        Expanded(child: Text(app.location?.label ?? 'இடம் தேர்வு செய்யப்படவில்லை', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
        TextButton(onPressed: app.useGps, child: const Text('GPS')),
        TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LocationPickerScreen())), child: const Text('தேடு')),
      ]),
    );
  }
}

class _BirdCircle extends StatelessWidget {
  final Pakshi bird;
  final Color color;
  final bool small;
  const _BirdCircle({required this.bird, required this.color, this.small = false});

  @override
  Widget build(BuildContext context) {
    final size = small ? 48.0 : 66.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 1.4), color: color.withOpacity(.08)),
      child: Center(child: Text(bird == Pakshi.kozhi ? '🐓' : bird.tamil.substring(0, 1), style: TextStyle(fontSize: small ? 24 : 32))),
    );
  }
}

class _StarCircle extends StatelessWidget {
  const _StarCircle();
  @override
  Widget build(BuildContext context) => Container(
    width: 62,
    height: 62,
    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF8A58A8))),
    child: const Center(child: Text('✦', style: TextStyle(color: Color(0xFFC49BFF), fontSize: 32))),
  );
}

class _Panel extends StatelessWidget {
  final Widget child;
  final Color borderColor;
  final EdgeInsetsGeometry padding;
  const _Panel({required this.child, this.borderColor = const Color(0xFF3F3F3F), this.padding = const EdgeInsets.all(14)});

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: const Color(0xFF171717),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: borderColor.withOpacity(.75)),
      boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 3))],
    ),
    child: child,
  );
}

Color _activityColor(Thozhil activity) {
  switch (activity) {
    case Thozhil.arasu:
      return const Color(0xFF8CDE4F);
    case Thozhil.oon:
      return const Color(0xFFB8E35E);
    case Thozhil.nadai:
      return const Color(0xFFE4AD3C);
    case Thozhil.thuyil:
      return const Color(0xFFE07D58);
    case Thozhil.saavu:
      return const Color(0xFFE65353);
  }
}

class _BottomBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const _BottomBar({required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.home, 'டாஷ்போர்டு'),
      (Icons.calendar_month, 'நாட்காட்டி'),
      (Icons.star_border, 'நல்ல நேரம்'),
      (Icons.history, 'வரலாறு'),
      (Icons.settings, 'அமைப்புகள்'),
    ];
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(top: BorderSide(color: Color(0xFF343434))),
      ),
      child: SafeArea(
        child: Row(
          children: List.generate(items.length, (i) {
            final selected = i == index;
            return Expanded(
              child: InkWell(
                onTap: () => onTap(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(items[i].$1, color: selected ? const Color(0xFFE4AD3C) : Colors.white70, size: 28),
                      const SizedBox(height: 3),
                      Text(items[i].$2, style: TextStyle(color: selected ? const Color(0xFFE4AD3C) : Colors.white70, fontSize: 10)),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
