import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'heatmap_screen.dart';
import 'report_screen.dart';
import 'safe_spots_screen.dart';
import 'portal_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? user?.email ?? 'User';
    
    // Calculate initials (e.g. Sanjana Nuwanthi -> SN)
    String initials = '';
    if (name.isNotEmpty) {
      List<String> nameParts = name.trim().split(RegExp(r'\s+'));
      initials += nameParts[0][0].toUpperCase();
      if (nameParts.length > 1) {
        initials += nameParts[1][0].toUpperCase();
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF050A0E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        elevation: 0,
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFF00FF88).withAlpha(30)),
        ),
        title: Row(children: [
          Container(width: 3, height: 18,
              decoration: BoxDecoration(
                  color: const Color(0xFF00FF88),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          const Text('SAFEROUTE LK',
              style: TextStyle(fontSize: 14, letterSpacing: 4,
                  color: Color(0xFFE2E8F0), fontWeight: FontWeight.w600)),
        ]),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.logout, color: Color(0xFFFF4444), size: 16),
            label: const Text('SIGN OUT', style: TextStyle(color: Color(0xFFFF4444), fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.bold)),
            onPressed: () => _logout(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            // Welcome section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF00FF88).withAlpha(40)),
                color: const Color(0xFF00FF88).withAlpha(5),
              ),
              child: Row(children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF00FF88), width: 1.5),
                    color: const Color(0xFF00FF88).withAlpha(15),
                  ),
                  child: Center(
                    child: Text(initials, style: const TextStyle(color: Color(0xFF00FF88), fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('WELCOME BACK', style: TextStyle(color: Color(0xFF4A5568), fontSize: 10, letterSpacing: 2)),
                    const SizedBox(height: 4),
                    Text(name, style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    const Text('Stay safe. Stay informed.', style: TextStyle(color: Color(0xFF4A5568), fontSize: 12)),
                  ],
                )),
                Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF00FF88))),
              ]),
            ),
            const SizedBox(height: 28),
            // Section title
            Row(children: [
              Container(width: 3, height: 16,
                  decoration: BoxDecoration(color: const Color(0xFF00D4FF), borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 10),
              const Text('SAFETY MODULES', style: TextStyle(color: Color(0xFF4A5568), fontSize: 11, letterSpacing: 3, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 16),
            
            // 4 Main feature buttons
            _FeatureCard(
              icon: Icons.view_in_ar_outlined,
              title: 'AR NAVIGATION',
              subtitle: 'Augmented reality safety route guidance',
              accentColor: const Color(0xFF00D4FF),
              stats: 'OBJECTIVE 1',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF0D1117),
                    content: const Row(children: [
                      Icon(Icons.info_outline, color: Color(0xFF00D4FF), size: 16),
                      SizedBox(width: 8),
                      Text('AR Navigation — Coming soon', style: TextStyle(color: Color(0xFF00D4FF))),
                    ]),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            _FeatureCard(
              icon: Icons.support_agent_outlined,
              title: 'AI CALL ASSIST',
              subtitle: 'Real-time AI-powered emergency call assistant',
              accentColor: const Color(0xFFFF8C00),
              stats: 'OBJECTIVE 2',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF0D1117),
                    content: const Row(children: [
                      Icon(Icons.info_outline, color: Color(0xFFFF8C00), size: 16),
                      SizedBox(width: 8),
                      Text('AI Call Assist — Coming soon', style: TextStyle(color: Color(0xFFFF8C00))),
                    ]),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            _FeatureCard(
              icon: Icons.bluetooth_outlined,
              title: 'BLUETOOTH BEACON',
              subtitle: 'Device theft prevention and tracking system',
              accentColor: const Color(0xFF7C3AED),
              stats: 'OBJECTIVE 3',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF0D1117),
                    content: const Row(children: [
                      Icon(Icons.info_outline, color: Color(0xFF7C3AED), size: 16),
                      SizedBox(width: 8),
                      Text('Bluetooth Beacon — Coming soon', style: TextStyle(color: Color(0xFF7C3AED))),
                    ]),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            _FeatureCard(
              icon: Icons.people_outline,
              title: 'CROWD REPORTING',
              subtitle: 'Community safety heatmap, reports & safe spots',
              accentColor: const Color(0xFF00FF88),
              stats: 'OBJECTIVE 4',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const _CrowdReportingNav()),
              ),
            ),
            const SizedBox(height: 28),
            // Sri Lanka safety stats
            Row(children: [
              Container(width: 3, height: 16,
                  decoration: BoxDecoration(color: const Color(0xFFFF4444), borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 10),
              const Text('NETWORK STATUS', style: TextStyle(color: Color(0xFF4A5568), fontSize: 11, letterSpacing: 3, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 14),
            const Row(children: [
              Expanded(child: _StatCard(value: '76', label: 'DANGER\nZONES', color: Color(0xFFFF4444))),
              SizedBox(width: 10),
              Expanded(child: _StatCard(value: '15', label: 'SAFE\nSPOTS', color: Color(0xFF00FF88))),
              SizedBox(width: 10),
              Expanded(child: _StatCard(value: '9', label: 'PROVINCES\nCOVERED', color: Color(0xFF00D4FF))),
            ]),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final String stats;
  final VoidCallback onTap;
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.stats,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accentColor.withAlpha(50)),
          color: const Color(0xFF0D1117),
        ),
        child: Row(children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withAlpha(15),
              border: Border.all(color: accentColor.withAlpha(80), width: 1.5),
            ),
            child: Icon(icon, color: accentColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: accentColor, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 2)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: Color(0xFF4A5568), fontSize: 12)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  border: Border.all(color: accentColor.withAlpha(60)),
                  borderRadius: BorderRadius.circular(4),
                  color: accentColor.withAlpha(8),
                ),
                child: Text(stats, style: TextStyle(color: accentColor, fontSize: 9, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
              ),
            ],
          )),
          Icon(Icons.chevron_right, color: accentColor.withAlpha(150), size: 20),
        ]),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatCard({required this.value, required this.label, required this.color});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(40)),
        color: color.withAlpha(5),
      ),
      child: Column(children: [
        Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF4A5568), fontSize: 9, letterSpacing: 1)),
      ]),
    );
  }
}

class _CrowdReportingNav extends StatefulWidget {
  const _CrowdReportingNav();
  @override
  State<_CrowdReportingNav> createState() => _CrowdReportingNavState();
}

class _CrowdReportingNavState extends State<_CrowdReportingNav> {
  int _currentIndex = 0;
  bool _mapPickerOpen = false;
  
  void _setMapPickerOpen(bool open) {
    setState(() => _mapPickerOpen = open);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF4A5568)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(children: [
          Container(width: 3, height: 18,
              decoration: BoxDecoration(
                  color: const Color(0xFF00FF88),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          const Text('CROWD REPORTING',
              style: TextStyle(fontSize: 14, letterSpacing: 4,
                  color: Color(0xFFE2E8F0), fontWeight: FontWeight.w600)),
        ]),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const HeatmapScreen(),
          ReportScreen(onMapPickerToggle: _setMapPickerOpen),
          const SafeSpotsScreen(),
          const PortalScreen(),
        ],
      ),
      bottomNavigationBar: _mapPickerOpen
          ? null
          : Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0D1117),
                border: Border(
                  top: BorderSide(
                    color: const Color(0xFF00FF88).withAlpha(40),
                    width: 1,
                  ),
                ),
              ),
              child: NavigationBar(
                backgroundColor: Colors.transparent,
                indicatorColor: const Color(0xFF00FF88).withAlpha(30),
                selectedIndex: _currentIndex,
                onDestinationSelected: (i) =>
                    setState(() => _currentIndex = i),
                destinations: [
                  _navItem(Icons.map_outlined, 'Heatmap', 0),
                  _navItem(Icons.warning_amber_outlined, 'Report', 1),
                  _navItem(Icons.shield_outlined, 'Safe Spots', 2),
                  _navItem(Icons.grid_view_outlined, 'Portal', 3),
                ],
              ),
            ),
    );
  }

  NavigationDestination _navItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return NavigationDestination(
      icon: Icon(icon,
          color: isSelected ? const Color(0xFF00FF88) : const Color(0xFF4A5568)),
      selectedIcon: Icon(icon, color: const Color(0xFF00FF88)),
      label: label,
    );
  }
}
