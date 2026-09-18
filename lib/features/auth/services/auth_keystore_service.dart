import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/config/app_config.dart';
import '../../../core/logging/app_log_service.dart';

/// Authentication state model
class AuthStateModel {
  final bool isAuthenticated;
  final bool isBiometricEnabled;
  final String? userEmail;
  final String? studentNo;

  const AuthStateModel({
    this.isAuthenticated = false,
    this.isBiometricEnabled = false,
    this.userEmail,
    this.studentNo,
  });
}

/// Service managing hardware-backed Android Keystore tokens, Google Sign-in, and Biometric unlock
class AuthKeystoreService {
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
  );

  static final LocalAuthentication _localAuth = LocalAuthentication();
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: AppConfig.googleAndroidClientId,
    serverClientId: AppConfig.googleWebClientId,
    scopes: ['email', 'profile'],
  );

  static const _kBiometricEnabledKey = 'sembase_biometric_enabled';
  static const _kJwtTokenKey = 'sembase_jwt_token';

  /// Authenticates using device biometrics (Fingerprint / PIN)
  static Future<bool> authenticateWithBiometrics() async {
    try {
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();

      if (!canCheckBiometrics && !isDeviceSupported) {
        return false;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Scan fingerprint or enter device PIN to unlock SemBase Vault',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: true,
        ),
      );

      if (authenticated) {
        AppLogService.success(AppLogService.catAuth, 'Biometric authentication succeeded');
      } else {
        AppLogService.warning(AppLogService.catAuth, 'Biometric authentication canceled or failed');
      }

      return authenticated;
    } catch (e) {
      AppLogService.error(AppLogService.catAuth, 'Biometric authentication exception', details: '$e');
      return false;
    }
  }

  static Future<bool> isBiometricHardwareAvailable() async {
    try {
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheckBiometrics || isDeviceSupported;
    } catch (e) {
      return false;
    }
  }

  /// Sets biometric toggle status
  static Future<void> setBiometricEnabled(bool enabled) async {
    await _secureStorage.write(
      key: _kBiometricEnabledKey,
      value: enabled ? 'true' : 'false',
    );
  }

  /// Checks if biometric lock is active
  static Future<bool> isBiometricEnabled() async {
    final value = await _secureStorage.read(key: _kBiometricEnabledKey);
    return value == 'true';
  }

  /// Performs Google Sign-In and Supabase token exchange
  static Future<bool> signInWithGoogle() async {
    try {
      // 1. Cleanly disconnect previous sessions to avoid account-switching collision
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
      try {
        if (!AppConfig.supabaseUrl.contains('your-project')) {
          await Supabase.instance.client.auth.signOut(scope: SignOutScope.local);
        }
      } catch (_) {}

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User closed or dismissed the Google account selector
        AppLogService.info(AppLogService.catAuth, 'Google Sign-In canceled/dismissed by user');
        return false;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null || idToken.isEmpty) {
        AppLogService.error(AppLogService.catAuth, 'Google Sign-In returned null or empty idToken');
        return false;
      }

      if (!AppConfig.supabaseUrl.contains('your-project')) {
        final response = await Supabase.instance.client.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
          accessToken: accessToken,
        );

        final session = response.session ?? Supabase.instance.client.auth.currentSession;
        final user = response.user ?? Supabase.instance.client.auth.currentUser ?? session?.user;

        if (session != null) {
          await _secureStorage.write(
            key: _kJwtTokenKey,
            value: session.accessToken,
          );
        }

        final email = user?.email ?? googleUser.email;
        if (email.isNotEmpty) {
          await saveUserEmail(email);
        }
        await setGuestMode(false);
        AppLogService.success(
          AppLogService.catAuth,
          'Signed in via Google ($email)',
          details: 'User ID: ${user?.id}',
        );
        return true;
      } else {
        // Offline / placeholder Supabase config mode
        await saveUserEmail(googleUser.email);
        await setGuestMode(false);
        AppLogService.success(
          AppLogService.catAuth,
          'Signed in via Google in offline mode (${googleUser.email})',
        );
        return true;
      }
    } catch (e) {
      AppLogService.error(AppLogService.catAuth, 'Google Sign-In error', details: '$e');
      // If Supabase already recognized the user despite a transient event exception, treat as success
      try {
        final currentUser = Supabase.instance.client.auth.currentUser;
        if (currentUser != null && currentUser.email != null) {
          await saveUserEmail(currentUser.email!);
          await setGuestMode(false);
          AppLogService.success(
            AppLogService.catAuth,
            'Recovered active session after Google Sign-In (${currentUser.email})',
          );
          return true;
        }
      } catch (_) {}
      return false;
    }
  }

  static const _kUserEmailKey = 'sembase_user_email';
  static const _kRefreshTokenKey = 'sembase_refresh_token';
  static const _kIsGuestKey = 'sembase_is_guest_mode';
  static const _kLastUserIdKey = 'sembase_last_user_id';

  static String? _cachedEmail;
  static bool? _cachedIsGuest;

  static String? get cachedEmail {
    if (_cachedIsGuest == true) return null;
    if (_cachedEmail != null && _cachedEmail!.isNotEmpty) return _cachedEmail;
    try {
      final supabaseEmail = Supabase.instance.client.auth.currentUser?.email;
      if (supabaseEmail != null && supabaseEmail.isNotEmpty) {
        _cachedEmail = supabaseEmail;
        return supabaseEmail;
      }
    } catch (_) {}
    return _cachedEmail;
  }

  static bool get cachedIsGuest {
    if (_cachedIsGuest != null) return _cachedIsGuest!;
    try {
      if (Supabase.instance.client.auth.currentUser != null) {
        _cachedIsGuest = false;
        return false;
      }
    } catch (_) {}
    return _cachedIsGuest ?? false;
  }

  static Future<void> setGuestMode(bool isGuest) async {
    _cachedIsGuest = isGuest;
    if (isGuest) {
      _cachedEmail = null;
      AppLogService.info(AppLogService.catAuth, 'Entered Guest Offline Mode');
    }
    await _secureStorage.write(key: _kIsGuestKey, value: isGuest ? 'true' : 'false');
  }

  static Future<bool> isGuestMode() async {
    if (_cachedIsGuest != null) return _cachedIsGuest!;
    final val = await _secureStorage.read(key: _kIsGuestKey);
    _cachedIsGuest = val == 'true';
    return _cachedIsGuest!;
  }

  static Future<void> saveUserEmail(String email) async {
    _cachedEmail = email;
    _cachedIsGuest = false;
    await _secureStorage.write(key: _kUserEmailKey, value: email);
    if (email.isNotEmpty) {
      await setGuestMode(false);
    }
  }

  static Future<String?> getUserEmail() async {
    final isGuest = await isGuestMode();
    if (isGuest) return null; // Guest accounts have no email
    if (_cachedEmail != null && _cachedEmail!.isNotEmpty) return _cachedEmail;
    final email = await _secureStorage.read(key: _kUserEmailKey);
    _cachedEmail = (email != null && email.isNotEmpty) ? email : null;
    return _cachedEmail;
  }

  static Future<void> saveLastUserId(String userId) async {
    await _secureStorage.write(key: _kLastUserIdKey, value: userId);
  }

  static Future<String?> getLastUserId() async {
    return await _secureStorage.read(key: _kLastUserIdKey);
  }

  static Future<void> saveJwtToken(String token) async {
    await _secureStorage.write(key: _kJwtTokenKey, value: token);
  }

  static Future<void> saveRefreshToken(String token) async {
    await _secureStorage.write(key: _kRefreshTokenKey, value: token);
  }

  static Future<bool> isSessionActive() async {
    final isGuest = await isGuestMode();
    if (isGuest) return true;
    final email = await getUserEmail();
    return email != null && email.isNotEmpty;
  }

  /// Signs out from Supabase & Google and clears local session
  static Future<void> signOut() async {
    try {
      final previousEmail = _cachedEmail;
      _cachedEmail = null;
      _cachedIsGuest = null;
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
      if (!AppConfig.supabaseUrl.contains('your-project')) {
        await Supabase.instance.client.auth.signOut();
      }
      await _secureStorage.delete(key: _kJwtTokenKey);
      await _secureStorage.delete(key: _kRefreshTokenKey);
      await _secureStorage.delete(key: _kUserEmailKey);
      await _secureStorage.delete(key: _kIsGuestKey);

      AppLogService.info(
        AppLogService.catAuth,
        'User signed out successfully',
        details: 'Previous account: ${previousEmail ?? "Guest"}',
      );
    } catch (e) {
      AppLogService.error(AppLogService.catAuth, 'Sign out exception', details: '$e');
    }
  }

  /// Wipes all encrypted hardware keystore keys
  static Future<void> clearAll() async {
    try {
      _cachedEmail = null;
      _cachedIsGuest = null;
      await _secureStorage.deleteAll();
    } catch (e) {
      debugPrint('Error clearing secure storage: $e');
    }
  }
}
