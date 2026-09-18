import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/app_config.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/sync/sync_outbox_worker.dart';
import '../../../shared/theme/app_theme.dart';
import '../services/account_login_detector.dart';
import '../services/auth_keystore_service.dart';

/// Streamlined Authentication Screen with Email Login, Google Sign-In & Offline Student Mode
class AuthScreen extends ConsumerStatefulWidget {
  final VoidCallback onAuthenticated;

  const AuthScreen({super.key, required this.onAuthenticated});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkAndHandleAccountSwitch(String newUserId) async {
    final db = ref.read(databaseProvider);
    final lastUserId = await AuthKeystoreService.getLastUserId();
    final activeProfile = await db.getActiveProfile();

    if (lastUserId != null && lastUserId != newUserId && activeProfile != null) {
      if (!mounted) return;
      final bool startFresh = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.cardDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.sync_problem_rounded, color: AppTheme.accentAmber, size: 24),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Previous Schedule Detected',
                  style: TextStyle(color: AppTheme.textPrimaryDark, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: const Text(
            'A local schedule from another account was found on this device.\n\nWould you like to start fresh with this account\'s cloud data, or keep and adopt the local schedule?',
            style: TextStyle(color: AppTheme.textSecondaryDark, fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Keep Local Schedule', style: TextStyle(color: AppTheme.accentCyan)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentRose,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Start Fresh (Sync Cloud)'),
            ),
          ],
        ),
      ) ?? true;

      if (startFresh) {
        await db.clearAllData();
      }
    }

    await AuthKeystoreService.saveLastUserId(newUserId);
    // Immediately detect Pro status & scan cloud database for saved records
    if (mounted) {
      await AccountLoginDetector.onUserSignedIn(context, ref, userId: newUserId);
    }
  }

  Future<void> _handleEmailLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter your email and password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String? userId;
      if (!AppConfig.supabaseUrl.contains('your-project')) {
        final res = await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        if (res.user != null) {
          userId = res.user!.id;
          await AuthKeystoreService.saveJwtToken(res.session?.accessToken ?? 'token');
          await AuthKeystoreService.saveRefreshToken(res.session?.refreshToken ?? 'refresh');
        }
      }

      await AuthKeystoreService.saveUserEmail(email);

      if (userId != null) {
        await _checkAndHandleAccountSwitch(userId);
      }

      widget.onAuthenticated();
    } catch (e) {
      setState(() => _errorMessage = 'Sign in failed: ${e.toString().replaceAll('AuthException', '')}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await AuthKeystoreService.signInWithGoogle();
      if (success) {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          await _checkAndHandleAccountSwitch(user.id);
        }
        widget.onAuthenticated();
      } else {
        if (mounted) setState(() => _errorMessage = 'Google sign-in was cancelled or failed.');
      }
    } catch (e) {
      // If user is actually authenticated despite a transient event stream error, navigate seamlessly
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await _checkAndHandleAccountSwitch(user.id);
        widget.onAuthenticated();
      } else {
        if (mounted) setState(() => _errorMessage = 'Google sign-in error: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGuestBypass() async {
    setState(() => _isLoading = true);
    await AuthKeystoreService.setGuestMode(true);
    widget.onAuthenticated();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo and Title
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.4), width: 1.5),
                  ),
                  child: const Icon(Icons.school_rounded, color: AppTheme.primaryGreen, size: 36),
                ),
                const SizedBox(height: 16),
                const Text(
                  'SemBase',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryDark,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Academic Companion & Offline Tracker',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryDark),
                ),
                const SizedBox(height: 28),

                // Error Message Banner
                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.accentRose.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.accentRose.withOpacity(0.4)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppTheme.accentRose, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Email & Password Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.borderDark.withOpacity(0.35)),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: AppTheme.textPrimaryDark),
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          labelStyle: const TextStyle(color: AppTheme.textMutedDark, fontSize: 13),
                          prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.textMutedDark, size: 20),
                          filled: true,
                          fillColor: AppTheme.bgDark.withOpacity(0.6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.borderDark),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(color: AppTheme.textPrimaryDark),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: const TextStyle(color: AppTheme.textMutedDark, fontSize: 13),
                          prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.textMutedDark, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: AppTheme.textMutedDark,
                              size: 18,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          filled: true,
                          fillColor: AppTheme.bgDark.withOpacity(0.6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.borderDark),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Sign In Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                          ),
                          onPressed: _isLoading ? null : _handleEmailLogin,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text(
                                  'Sign In with Email',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Divider: OR CONTINUE WITH
                Row(
                  children: const [
                    Expanded(child: Divider(color: Color(0x20FFFFFF))),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR CONTINUE WITH',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textMutedDark,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Color(0x20FFFFFF))),
                  ],
                ),
                const SizedBox(height: 20),

                // Google Sign In Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textPrimaryDark,
                      backgroundColor: AppTheme.cardDark,
                      side: BorderSide(color: AppTheme.borderDark.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                    icon: const Icon(Icons.g_mobiledata, size: 28, color: AppTheme.accentCyan),
                    label: const Text(
                      'Continue with Google',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Offline Guest Mode Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.textSecondaryDark,
                    ),
                    onPressed: _isLoading ? null : _handleGuestBypass,
                    icon: const Icon(Icons.offline_bolt_outlined, size: 18, color: AppTheme.accentAmber),
                    label: const Text(
                      'Offline Student Mode (No Account Required)',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
