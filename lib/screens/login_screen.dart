import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'user-not-found') {
          _error = 'No account found with this email';
        } else if (e.code == 'wrong-password') {
          _error = 'Incorrect password';
        } else if (e.code == 'invalid-credential') {
          _error = 'Invalid email or password';
        } else if (e.code == 'network-request-failed') {
          _error = 'Network error. Check your connection.';
        } else {
          _error = e.message ?? 'Login failed';
        }
      });
    } catch (e) {
      setState(() {
        _error = 'An unexpected error occurred: ${e.toString()}';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050A0E),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                // Logo
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0xFF00FF88), width: 2),
                          color: const Color(0xFF00FF88).withAlpha(20),
                        ),
                        child: const Icon(Icons.shield_outlined,
                            color: Color(0xFF00FF88), size: 40),
                      ),
                      const SizedBox(height: 16),
                      const Text('SAFEROUTE LK',
                          style: TextStyle(
                              color: Color(0xFF00FF88),
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 5)),
                      const SizedBox(height: 4),
                      const Text('COMMUNITY SAFETY NETWORK',
                          style: TextStyle(
                              color: Color(0xFF4A5568),
                              fontSize: 10,
                              letterSpacing: 3)),
                    ],
                  ),
                ),
                const SizedBox(height: 50),
                // Title
                Row(children: [
                  Container(
                      width: 3,
                      height: 18,
                      decoration: BoxDecoration(
                          color: const Color(0xFF00FF88),
                          borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 10),
                  const Text('SIGN IN',
                      style: TextStyle(
                          color: Color(0xFFE2E8F0),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4)),
                ]),
                const SizedBox(height: 28),
                // Error banner
                if (_error != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: const Color(0xFFFF4444).withAlpha(60)),
                      borderRadius: BorderRadius.circular(8),
                      color: const Color(0xFFFF4444).withAlpha(10),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline,
                          color: Color(0xFFFF4444), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(_error!,
                              style: const TextStyle(
                                  color: Color(0xFFFF4444), fontSize: 12))),
                    ]),
                  ),
                  const SizedBox(height: 16),
                ],
                // Email
                const _Label(text: 'EMAIL ADDRESS'),
                const SizedBox(height: 8),
                _FuturisticField(
                  controller: _emailController,
                  hint: 'your@email.com',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v == null || !v.contains('@')
                      ? 'Enter a valid email'
                      : null,
                ),
                const SizedBox(height: 20),
                // Password
                const _Label(text: 'PASSWORD'),
                const SizedBox(height: 8),
                _FuturisticField(
                  controller: _passwordController,
                  hint: '••••••••',
                  icon: Icons.lock_outlined,
                  obscure: _obscure,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFF4A5568),
                      size: 18,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  validator: (v) => v == null || v.length < 6
                      ? 'Password must be at least 6 characters'
                      : null,
                ),
                const SizedBox(height: 32),
                // Login button
                GestureDetector(
                  onTap: _loading ? null : _login,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF00FF88)),
                      color: const Color(0xFF00FF88).withAlpha(20),
                    ),
                    child: Center(
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Color(0xFF00FF88), strokeWidth: 2))
                          : const Text('ACCESS NETWORK',
                              style: TextStyle(
                                  color: Color(0xFF00FF88),
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 3,
                                  fontSize: 13)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Register link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? ",
                        style:
                            TextStyle(color: Color(0xFF4A5568), fontSize: 13)),
                    GestureDetector(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RegisterScreen())),
                      child: const Text('REGISTER',
                          style: TextStyle(
                              color: Color(0xFF00FF88),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label({required this.text});
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          color: Color(0xFF4A5568),
          fontSize: 11,
          letterSpacing: 3,
          fontWeight: FontWeight.bold));
}

class _FuturisticField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _FuturisticField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.suffixIcon,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF2D3748), fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF4A5568), size: 18),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFF0D1117),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF1E2A35))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF1E2A35))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF00FF88), width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFFF4444))),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFFF4444))),
        errorStyle: const TextStyle(color: Color(0xFFFF4444)),
      ),
      validator: validator,
    );
  }
}
