import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/day_ruler_rules.dart';
import '../models/pakshi.dart';
import '../models/panchapakshi_state.dart';
import '../services/app_state.dart';
import '../widgets/activity_card.dart';
import '../widgets/countdown_ring.dart';
import '../widgets/day_ruler_card.dart';
import '../widgets/thaarai_card.dart';
import 'birth_details_screen.dart';
import 'forecast_screen.dart';
import 'location_picker_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
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
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: app.useGps,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeader(app),
              const SizedBox(height: 12),
              if (app.loading) const Center(child: CircularProgressIndicator()),
              if (app.error != null)
                Text(app.error!, style: const TextStyle(color: Colors.red)),
              if (s != null) ...[
                _buildTimeBar(s),
                const SizedBox(height: 16),
                _buildBirthDetails(app),
                const SizedBox(height: 16),
                _buildRulingCards(s),
                const SizedBox(height: 12),
                _buildMainActivityCard(s, timeFmt),
                const SizedBox(height: 12),
                _buildAntharaCards(s, timeFmt),
                const SizedBox(height: 12),
                _buildNakshatramCard(app),
                const SizedBox(height: 12),
                _buildTharaCards(app),
                const SizedBox(height: 12),
                _buildTimingCards(s),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader(AppState app) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFD4A843).withOpacity(0.2),
          ),
          child: const Icon(Icons.emoji_nature, color: Color(0xFFD4A843)),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'KOZHLI',
              style: TextStyle(
                color: Color(0xFFD4A843),
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            Text(
              'PANCHAPAKSHI',
              style: TextStyle(
                color: Color(0xFFB0B0C3),
                fontSize: 12,
                letterSpacing: 3,
              ),
            ),
          ],
        ),
        const Spacer(),
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Color(0xFFD4A843).withOpacity(0.3),
                Colors.transparent,
              ],
            ),
          ),
          child: const Icon(
            Icons.emoji_nature,
            color: Color(0xFFD4A843),
            size: 40,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeBar(PanchapakshiState s) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            s.paksham == Paksham.valarpirai
                ? 'வளர்பிறை குறிப்பு '
                : 'தேய்பிறை குறிப்பு ',
            style: const TextStyle(
              color: Color(0xFFD4A843),
              fontSize: 14,
            ),
          ),
          StreamBuilder(
            stream: Stream.periodic(const Duration(seconds: 1)),
            builder: (context, snapshot) {
              final now = DateTime.now();
              final timeStr =
                  '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
              return Text(
                timeStr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBirthDetails(AppState app) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2D2D44)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildDropdown(
              'பிறந்த ராசி நட்சத்திரம்',
              app.birthNakshatra ?? 'புரம்',
              ['புரம்', 'பூராடம்', 'உத்திராடம்', 'திருவோணம்'],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildDropdown(
              'பிறந்த பக்ஷம்',
              'தேய்பிறை',
              ['தேய்பிறை', 'வளர்பிறை'],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildDropdown(
              'பிறந்த வகை நட்சத்திரம்',
              app.birthLagnaNakshatra ?? 'ஆயில்யம்',
              ['ஆயில்யம்', 'மகம்', 'பூரம்'],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFB0B0C3),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF2D2D44)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down,
                  color: Color(0xFF808090), size: 18),
              dropdownColor: const Color(0xFF16213E),
              style: const TextStyle(color: Colors.white, fontSize: 12),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item, style: const TextStyle(fontSize: 12)),
                );
              }).toList(),
              onChanged: (val) {},
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRulingCards(PanchapakshiState s) {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            icon: Icons.calendar_today,
            title: 'கோழி அதிகார நாள்',
            children: [
              _buildDirectionRow(true, 'வளர்பிறை', 'வெள்ளி'),
              _buildDirectionRow(false, 'தேய்பிறை', 'செவ்வாய், புதன்'),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoCard(
            icon: Icons.calendar_today,
            title: 'கோழி படிப்பசி நாள்',
            children: [
              _buildDirectionRow(true, 'வளர்பிறை', 'சனி'),
              _buildDirectionRow(false, 'தேய்பிறை', 'திங்கள்'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2D2D44)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFD4A843), size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFFD4A843),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDirectionRow(bool isUp, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isUp
                  ? Colors.green.withOpacity(0.2)
                  : Colors.red.withOpacity(0.2),
            ),
            child: Icon(
              isUp ? Icons.arrow_upward : Icons.arrow_downward,
              color: isUp ? Colors.green : Colors.red,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFB0B0C3),
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainActivityCard(PanchapakshiState s, DateFormat timeFmt) {
    return _buildActivityCard(
      birdIcon: Icons.emoji_nature,
      label: 'கோழி தற்போதைய தொழில்',
      name: s.jamamActivity.tamil,
      timeRange:
          '${timeFmt.format(s.jamamStart)} – ${timeFmt.format(s.jamamEnd)}',
      nameColor: const Color(0xFF4CAF50),
      onTap: () {},
    );
  }

  Widget _buildAntharaCards(PanchapakshiState s, DateFormat timeFmt) {
    return Row(
      children: [
        Expanded(
          child: _buildActivityCard(
            birdIcon: Icons.flutter_dash,
            label: 'தற்போதைய அந்தர பட்சி',
            name: '${s.antharamBird.tamil} – ${s.antharamActivity.tamil}',
            timeRange:
                '${timeFmt.format(s.antharamStart)} – ${timeFmt.format(s.antharamEnd)}',
            nameColor: Colors.red,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActivityCard(
            birdIcon: Icons.emoji_nature,
            label: 'அடுத்த அந்தர பட்சி',
            name: '${s.nextAntharamBird.tamil} – ${s.nextActivity.tamil}',
            timeRange: 'Starts at ${timeFmt.format(s.nextActivityStart)}',
            nameColor: const Color(0xFF4CAF50),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityCard({
    required IconData birdIcon,
    required String label,
    required String name,
    required String timeRange,
    required Color nameColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2D2D44)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFD4A843).withOpacity(0.3),
                    ),
                  ),
                  child: Center(
                    child: Icon(birdIcon, color: const Color(0xFFD4A843), size: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: Color(0xFFB0B0C3),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        name,
                        style: TextStyle(
                          color: nameColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  color: Color(0xFF808090),
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  timeRange,
                  style: const TextStyle(
                    color: Color(0xFF808090),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNakshatramCard(AppState app) {
    final moon = app.currentMoon;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2D2D44)),
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFD4A843).withOpacity(0.3),
              ),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Color(0xFFD4A843),
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'தற்போதைய நட்சத்திரம்',
                  style: TextStyle(
                    color: Color(0xFFB0B0C3),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  moon != null
                      ? '${moon.nakshatraName} – பாதம் ${moon.pada}'
                      : 'கணக்கிடுகிறது...',
                  style: const TextStyle(
                    color: Color(0xFF9C27B0),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (moon != null)
                  Text(
                    'ராசி: ${moon.rasiName}',
                    style: const TextStyle(
                      color: Color(0xFF808090),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTharaCards(AppState app) {
    return Row(
      children: [
        Expanded(
          child: _buildTharaCard(
            label: 'தாராபலன் (பிறந்த ராசி நட்சத்திரத்திற்கு)',
            thaarai: app.thaarai,
            onSetup: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BirthDetailsScreen()),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTharaCard(
            label: 'தாராபலன் (பிறந்த லக்னம் நட்சத்திரத்திற்கு)',
            thaarai: app.thaaraiLagna,
            onSetup: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BirthDetailsScreen()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTharaCard({
    required String label,
    required dynamic thaarai,
    required VoidCallback onSetup,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2D2D44)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFD4A843).withOpacity(0.4),
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.hexagon_outlined,
                    color: Color(0xFFD4A843),
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xFFB0B0C3),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (thaarai != null)
                      Text(
                        thaarai.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      )
                    else
                      TextButton(
                        onPressed: onSetup,
                        child: const Text('அமைக்க'),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimingCards(PanchapakshiState s) {
    return Row(
      children: [
        Expanded(
          child: _buildTimingCard(
            icon: Icons.face,
            label: 'தற்போதைய கொளி நல்ல நேரம்',
            name: s.gowriName,
            timeRange: '${DateFormat('hh:mm a').format(s.sunrise)} – ${DateFormat('hh:mm a').format(s.sunset)}',
            nameColor: const Color(0xFF4CAF50),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTimingCard(
            icon: Icons.nightlight_round,
            label: 'தற்போதைய கிரக ஒன்றை',
            name: s.horaiPlanet,
            timeRange: '${DateFormat('hh:mm a').format(s.sunrise)} – ${DateFormat('hh:mm a').format(s.sunset)}',
            nameColor: const Color(0xFF64B5F6),
          ),
        ),
      ],
    );
  }

  Widget _buildTimingCard({
    required IconData icon,
    required String label,
    required String name,
    required String timeRange,
    required Color nameColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2D2D44)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFD4A843).withOpacity(0.1),
                ),
                child: Center(
                  child: Icon(icon, color: const Color(0xFFD4A843), size: 24),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xFFB0B0C3),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      style: TextStyle(
                        color: nameColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.access_time,
                color: Color(0xFF808090),
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                timeRange,
                style: const TextStyle(
                  color: Color(0xFF808090),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF16213E),
        border: Border(
          top: BorderSide(color: Color(0xFF2D2D44)),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, 'டாஷ்போர்டு', true),
              _buildNavItem(Icons.calendar_today, 'நாள்காட்டி', false),
              _buildNavItem(Icons.star, 'நல்ல நேரம்', false),
              _buildNavItem(Icons.history, 'வரலாறு', false),
              _buildNavItem(Icons.settings, 'அமைப்புகள்', false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: isSelected ? const Color(0xFFD4A843) : const Color(0xFF808090),
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFFD4A843) : const Color(0xFF808090),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
