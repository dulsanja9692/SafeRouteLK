import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'models/incident_store.dart';
import 'screens/report_screen.dart';
import 'screens/portal_screen.dart';
import 'screens/heatmap_screen.dart';
import 'screens/safe_spots_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization note: $e');
  }
  await IncidentStore().loadFromAssets();
  IncidentStore().listenToFirestore();
  runApp(const SafeRouteLKApp());
}

class SafeRouteLKApp extends StatelessWidget {
  const SafeRouteLKApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeRouteLK',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF050A0E),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00FF88),
          secondary: Color(0xFF00D4FF),
          surface: Color(0xFF0D1117),
        ),
        useMaterial3: true,
        fontFamily: 'monospace',
      ),
      home: const SplashScreen(),
    );
  }
}

// ── Splash Screen ──
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _scaleAnim = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050A0E),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: const Color(0xFF00FF88), width: 2),
                    color: const Color(0xFF00FF88).withAlpha(20),
                  ),
                  child: const Icon(Icons.shield_outlined,
                      color: Color(0xFF00FF88), size: 50),
                ),
                const SizedBox(height: 28),

                // App name
                const Text('SAFEROUTE LK',
                    style: TextStyle(
                        color: Color(0xFF00FF88),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 6)),
                const SizedBox(height: 8),
                const Text('COMMUNITY SAFETY NETWORK',
                    style: TextStyle(
                        color: Color(0xFF4A5568),
                        fontSize: 11,
                        letterSpacing: 3)),
                const SizedBox(height: 12),

                // Sri Lanka tag
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: const Color(0xFF00FF88).withAlpha(60)),
                    borderRadius: BorderRadius.circular(4),
                    color: const Color(0xFF00FF88).withAlpha(10),
                  ),
                  child: const Text('🇱🇰  SRI LANKA',
                      style: TextStyle(
                          color: Color(0xFF00FF88),
                          fontSize: 11,
                          letterSpacing: 2)),
                ),
                const SizedBox(height: 60),

                // Loading indicator
                const SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(
                    color: Color(0xFF00FF88),
                    strokeWidth: 2,
                  ),
                ),
                const SizedBox(height: 16),
                const Text('LOADING SAFETY DATA...',
                    style: TextStyle(
                        color: Color(0xFF2D3748),
                        fontSize: 10,
                        letterSpacing: 2)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
