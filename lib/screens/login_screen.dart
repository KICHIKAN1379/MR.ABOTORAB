import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final db = DatabaseHelper.instance.database;
      final users = await (await db).query(
        'users',
        where: 'username = ? AND password = ?',
        whereArgs: [_usernameController.text.trim(), _passwordController.text],
      );

      if (users.isNotEmpty) {
        await DatabaseHelper.instance.addLog(
          'ورود به سیستم',
          'کاربر ${_usernameController.text} وارد شد',
        );
        
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );        }
      } else {
        if (mounted) {
          _showError('نام کاربری یا رمز عبور اشتباه است');
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('خطا در ورود: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF1E1B4B),
              Color(0xFF0F172A),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [                    // Logo
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.groups_rounded,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Title
                    Text(
                      'MR.ABOTORAB',
                      style: GoogleFonts.vazirmatn(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        foreground: const Paint()
                          ..shader = const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                          ).createShader(const Rect.fromLTWH(0, 0, 200, 50)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'برنامه مدیریت اعضای حلقه',
                      style: GoogleFonts.vazirmatn(
                        fontSize: 16,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Username Field
                    TextFormField(
                      controller: _usernameController,
                      style: GoogleFonts.vazirmatn(color: Colors.white),                      decoration: InputDecoration(
                        labelText: 'نام کاربری',
                        labelStyle: GoogleFonts.vazirmatn(color: Colors.grey),
                        prefixIcon: const Icon(Icons.person, color: Color(0xFF6366F1)),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'لطفاً نام کاربری را وارد کنید';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: GoogleFonts.vazirmatn(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'رمز عبور',
                        labelStyle: GoogleFonts.vazirmatn(color: Colors.grey),
                        prefixIcon: const Icon(Icons.lock, color: Color(0xFF6366F1)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),                          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'لطفاً رمز عبور را وارد کنید';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          elevation: 0,
                          shadowColor: const Color(0xFF6366F1).withOpacity(0.3),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'ورود به برنامه',
                                style: GoogleFonts.vazirmatn(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),                    ),
                    const SizedBox(height: 24),

                    // Hint
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Color(0xFF6366F1)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'برای ورود از نام کاربری و رمز عبور استفاده کنید',
                              style: GoogleFonts.vazirmatn(
                                fontSize: 12,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
