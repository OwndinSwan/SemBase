import 'dart:async';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/services/auth_keystore_service.dart';
import '../config/app_config.dart';
import '../logging/app_log_service.dart';

enum SubscriptionTier {
  free,
  pro,
}

enum SubscriptionPlan {
  free,
  monthly,
  semester,
  lifetime,
}

class SubscriptionInfo {
  final SubscriptionTier tier;
  final SubscriptionPlan plan;
  final DateTime? expiresAt;
  final DateTime? activatedAt;
  final String? activationCode;
  final String? accountId;

  const SubscriptionInfo({
    required this.tier,
    required this.plan,
    this.expiresAt,
    this.activatedAt,
    this.activationCode,
    this.accountId,
  });

  bool get isPro {
    if (tier != SubscriptionTier.pro) return false;
    if (expiresAt == null) return true; // Lifetime
    return expiresAt!.isAfter(DateTime.now());
  }

  int get daysRemaining {
    if (!isPro) return 0;
    if (expiresAt == null) return 9999;
    return expiresAt!.difference(DateTime.now()).inDays.clamp(0, 9999);
  }

  String get planDisplayName {
    if (!isPro) return 'Free Academic';
    switch (plan) {
      case SubscriptionPlan.monthly:
        return 'SemBase Pro (Monthly)';
      case SubscriptionPlan.semester:
        return 'SemBase Pro (Semester Pass)';
      case SubscriptionPlan.lifetime:
        return 'SemBase Pro (Lifetime Degree)';
      case SubscriptionPlan.free:
        return 'Free Academic';
    }
  }
}

class SubscriptionRedemptionResult {
  final bool success;
  final String message;
  final SubscriptionPlan? plan;

  const SubscriptionRedemptionResult({
    required this.success,
    required this.message,
    this.plan,
  });
}

class SubscriptionService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
  );

  static const _kTierKey = 'sembase_sub_tier';
  static const _kPlanKey = 'sembase_sub_plan';
  static const _kExpiryKey = 'sembase_sub_expiry';
  static const _kCodeKey = 'sembase_sub_code';
  static const _kActivatedKey = 'sembase_sub_activated_at';
  static const _kDeviceIdKey = 'sembase_device_install_id';

  static SubscriptionInfo? _cachedInfo;

  /// Returns true if the user is currently running in Guest / Offline Student Mode without an account
  static Future<bool> isGuest() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null && user.id.isNotEmpty) return false;
    } catch (_) {}
    try {
      final email = await AuthKeystoreService.getUserEmail();
      if (email != null && email.isNotEmpty) return false;
      final isGuest = await AuthKeystoreService.isGuestMode();
      return isGuest || email == null || email.isEmpty;
    } catch (_) {
      return true;
    }
  }

  /// Returns the current active account ID (Email, Auth UID, or Device Account ID)
  static Future<String> getEffectiveAccountId() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user?.email != null && user!.email!.isNotEmpty) {
        return user.email!.trim().toLowerCase();
      }
      if (user?.id != null && user!.id.isNotEmpty) {
        return user.id;
      }
    } catch (_) {}

    // Fallback to permanent Device Install ID
    var deviceId = await _storage.read(key: _kDeviceIdKey);
    if (deviceId == null || deviceId.isEmpty) {
      final randomHex = DateTime.now().millisecondsSinceEpoch.toRadixString(16).toUpperCase();
      deviceId = 'DEVICE-$randomHex';
      await _storage.write(key: _kDeviceIdKey, value: deviceId);
    }
    return deviceId;
  }

  /// Synchronizes subscription state directly from the Cloud database (`user_subscriptions`)
  /// If the admin deletes the row, edits days, plan, or tier in the Cloud Dashboard, this reflects it instantly!
  /// Missing subscription rows automatically put the user account into the Free plan.
  static Future<SubscriptionInfo> syncCloudSubscription({String? accountId}) async {
    final isGuestAccount = await isGuest();
    if (isGuestAccount) {
      // Guest accounts are strictly Free Academic tier
      await resetToFree(notifyCloud: false);
      return const SubscriptionInfo(tier: SubscriptionTier.free, plan: SubscriptionPlan.free);
    }

    final savedCode = await _storage.read(key: _kCodeKey);
    final effectiveAccount = accountId ?? await getEffectiveAccountId();

    final candidateIds = <String>{};
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user?.email != null && user!.email!.isNotEmpty) {
        candidateIds.add(user.email!.trim().toLowerCase());
        candidateIds.add(user.email!.trim());
      }
      if (user?.id != null && user!.id.isNotEmpty) {
        candidateIds.add(user.id);
      }
    } catch (_) {}

    final savedEmail = await AuthKeystoreService.getUserEmail();
    if (savedEmail != null && savedEmail.isNotEmpty) {
      candidateIds.add(savedEmail.trim().toLowerCase());
      candidateIds.add(savedEmail.trim());
    }

    final deviceId = await _storage.read(key: _kDeviceIdKey);
    if (deviceId != null && deviceId.isNotEmpty) {
      candidateIds.add(deviceId);
    }
    if (accountId != null && accountId.isNotEmpty) {
      candidateIds.add(accountId.trim().toLowerCase());
      candidateIds.add(accountId.trim());
    }
    if (effectiveAccount.isNotEmpty) {
      candidateIds.add(effectiveAccount.trim().toLowerCase());
      candidateIds.add(effectiveAccount.trim());
    }

    try {
      if (!AppConfig.supabaseUrl.contains('your-project')) {
        final client = Supabase.instance.client;

        // 1. Query user_subscriptions for this account across all candidate IDs
        Map<String, dynamic>? response;
        for (final cand in candidateIds) {
          final res = await client
              .from('user_subscriptions')
              .select()
              .eq('account_id', cand)
              .maybeSingle()
              .timeout(const Duration(seconds: 4));
          if (res != null) {
            response = res;
            break;
          }
        }

        // 2. If not found by candidate IDs, check by activation code if one was saved
        if (response == null && savedCode != null && savedCode.isNotEmpty) {
          final res = await client
              .from('user_subscriptions')
              .select()
              .eq('activation_code', savedCode)
              .maybeSingle()
              .timeout(const Duration(seconds: 4));
          if (res != null) {
            response = res;
          }
        }

        if (response != null) {
          final tierStr = response['tier'] as String? ?? 'free';
          final planStr = response['plan_type'] as String? ?? 'free';
          final expiresAtStr = response['expires_at'] as String?;
          final activatedAtStr = response['activated_at'] as String?;
          final codeStr = response['activation_code'] as String? ?? savedCode;
          final durationDaysVal = response['duration_days'] as int?;
          final isActive = (response['is_active'] as bool?) ?? true;

          DateTime? activated;
          if (activatedAtStr != null && activatedAtStr.isNotEmpty) {
            activated = DateTime.tryParse(activatedAtStr);
          }
          activated ??= DateTime.now();

          DateTime? expiry;
          if (durationDaysVal != null && durationDaysVal > 0) {
            // Admin explicitly modified duration_days (e.g. 150 -> 31)
            expiry = activated.add(Duration(days: durationDaysVal));
          } else if (expiresAtStr != null && expiresAtStr.isNotEmpty) {
            expiry = DateTime.tryParse(expiresAtStr);
          }

          // Check if admin revoked, set to free, or expired
          if (!isActive || tierStr != 'pro' || (expiry != null && DateTime.now().isAfter(expiry))) {
            await resetToFree(notifyCloud: false);
            return SubscriptionInfo(tier: SubscriptionTier.free, plan: SubscriptionPlan.free, accountId: effectiveAccount);
          }

          final plan = SubscriptionPlan.values.firstWhere(
            (p) => p.name == planStr,
            orElse: () => SubscriptionPlan.semester,
          );

          // Update local encrypted storage to match cloud
          await _saveLocalSubscriptionState(
            code: codeStr ?? '',
            plan: plan,
            expiryDate: expiry,
            now: activated,
            accountId: effectiveAccount,
          );

          AppLogService.info(
            AppLogService.catAction,
            'Cloud subscription state synchronized for $effectiveAccount ($plan, Pro: true, Expiry: $expiry)',
          );

          return _cachedInfo!;
        }

        // 3. If no user_subscriptions row, check if an active voucher key exists in subscription_keys
        Map<String, dynamic>? keyResponse;
        for (final cand in candidateIds) {
          try {
            final res = await client
                .from('subscription_keys')
                .select()
                .or('redeemed_by.eq.$cand,assigned_account_id.eq.$cand,assigned_student_id.eq.$cand')
                .eq('is_active', true)
                .order('created_at', ascending: false)
                .limit(1)
                .maybeSingle()
                .timeout(const Duration(seconds: 4));
            if (res != null) {
              keyResponse = res;
              break;
            }
          } catch (_) {}
        }

        if (keyResponse == null && savedCode != null && savedCode.isNotEmpty) {
          try {
            keyResponse = await client
                .from('subscription_keys')
                .select()
                .eq('activation_code', savedCode)
                .eq('is_active', true)
                .maybeSingle()
                .timeout(const Duration(seconds: 4));
          } catch (_) {}
        }

        if (keyResponse != null) {
          final isKeyActive = (keyResponse['is_active'] as bool?) ?? true;
          final planStr = keyResponse['plan_type'] as String? ?? 'semester';
          final durationDays = keyResponse['duration_days'] as int?;
          final keyCode = keyResponse['activation_code'] as String? ?? savedCode ?? '';
          final redeemedAtStr = keyResponse['redeemed_at'] as String?;

          final activated = redeemedAtStr != null ? DateTime.tryParse(redeemedAtStr) ?? DateTime.now() : DateTime.now();
          final expiry = durationDays != null ? activated.add(Duration(days: durationDays)) : null;

          if (!isKeyActive || (expiry != null && DateTime.now().isAfter(expiry))) {
            await resetToFree(notifyCloud: false);
            return SubscriptionInfo(tier: SubscriptionTier.free, plan: SubscriptionPlan.free, accountId: effectiveAccount);
          }

          final plan = SubscriptionPlan.values.firstWhere(
            (p) => p.name == planStr,
            orElse: () => SubscriptionPlan.semester,
          );

          await _saveLocalSubscriptionState(
            code: keyCode,
            plan: plan,
            expiryDate: expiry,
            now: activated,
            accountId: effectiveAccount,
          );

          // Self-heal into user_subscriptions on Cloud
          try {
            await client.from('user_subscriptions').upsert({
              'account_id': effectiveAccount,
              'tier': 'pro',
              'plan_type': plan.name,
              'duration_days': durationDays,
              'expires_at': expiry?.toIso8601String(),
              'activated_at': activated.toIso8601String(),
              'activation_code': keyCode,
              'is_active': true,
              'updated_at': DateTime.now().toIso8601String(),
              'notes': 'Self-healed from subscription_keys ($keyCode)',
            }, onConflict: 'account_id');
          } catch (_) {}

          AppLogService.info(
            AppLogService.catAction,
            'Cloud key state synchronized for $effectiveAccount ($plan, Days: $durationDays, Code: $keyCode)',
          );

          return _cachedInfo!;
        }

        // Table row is missing across all candidate IDs in user_subscriptions & subscription_keys -> revert to Free tier!
        AppLogService.info(
          AppLogService.catAction,
          'No active subscription found in Cloud database for candidates $candidateIds. Reverting account to Free tier.',
        );
        await resetToFree(notifyCloud: false);
        return SubscriptionInfo(tier: SubscriptionTier.free, plan: SubscriptionPlan.free, accountId: effectiveAccount);
      }
    } catch (e) {
      AppLogService.warning(AppLogService.catAction, 'Notice syncing cloud subscription: $e');
    }

    return await getSubscriptionInfo();
  }

  /// Loads current subscription info from secure hardware storage
  static Future<SubscriptionInfo> getSubscriptionInfo() async {
    try {
      final tierStr = await _storage.read(key: _kTierKey);
      final planStr = await _storage.read(key: _kPlanKey);
      final expiryStr = await _storage.read(key: _kExpiryKey);
      final codeStr = await _storage.read(key: _kCodeKey);
      final activatedStr = await _storage.read(key: _kActivatedKey);
      final accountId = await getEffectiveAccountId();

      if (tierStr == 'pro') {
        final plan = SubscriptionPlan.values.firstWhere(
          (p) => p.name == planStr,
          orElse: () => SubscriptionPlan.monthly,
        );

        DateTime? expiry;
        if (expiryStr != null && expiryStr.isNotEmpty) {
          expiry = DateTime.tryParse(expiryStr);
        }

        DateTime? activated;
        if (activatedStr != null && activatedStr.isNotEmpty) {
          activated = DateTime.tryParse(activatedStr);
        }

        // Check if expired
        if (expiry != null && DateTime.now().isAfter(expiry)) {
          AppLogService.info(
            AppLogService.catAction,
            'Subscription expired on $expiryStr, reverting to free tier',
          );
          _cachedInfo = SubscriptionInfo(
            tier: SubscriptionTier.free,
            plan: SubscriptionPlan.free,
            accountId: accountId,
          );
          return _cachedInfo!;
        }

        _cachedInfo = SubscriptionInfo(
          tier: SubscriptionTier.pro,
          plan: plan,
          expiresAt: expiry,
          activatedAt: activated,
          activationCode: codeStr,
          accountId: accountId,
        );
        return _cachedInfo!;
      }
    } catch (e) {
      AppLogService.warning(
        AppLogService.catAction,
        'Failed reading subscription info: $e',
      );
    }

    final accountId = await getEffectiveAccountId();
    _cachedInfo = SubscriptionInfo(
      tier: SubscriptionTier.free,
      plan: SubscriptionPlan.free,
      accountId: accountId,
    );
    return _cachedInfo!;
  }

  /// Fast cached Pro check
  static Future<bool> isPro() async {
    final info = await getSubscriptionInfo();
    return info.isPro;
  }

  /// 100% STRICT ONLINE CLOUD REDEMPTION
  /// Redeems an activation key and registers the subscription under the student's Account ID.
  /// Requires a registered SemBase account (disabled for guest accounts).
  static Future<SubscriptionRedemptionResult> redeemActivationCode(
    String rawCode, {
    String? studentIdentifier,
    SupabaseClient? customClient,
  }) async {
    final isGuestAccount = await isGuest();
    if (isGuestAccount && (studentIdentifier == null || studentIdentifier.startsWith('DEVICE-') || studentIdentifier.contains('GUEST'))) {
      return const SubscriptionRedemptionResult(
        success: false,
        message: 'A registered SemBase account is required to subscribe or activate Pro features. Please sign in or register first.',
      );
    }

    final code = rawCode.trim().toUpperCase();
    if (code.isEmpty) {
      return const SubscriptionRedemptionResult(
        success: false,
        message: 'Please enter an activation code.',
      );
    }

    final effectiveAccount = studentIdentifier ?? await getEffectiveAccountId();
    final now = DateTime.now();

    try {
      final client = customClient ?? Supabase.instance.client;

      // 1. Query the Cloud Database for the activation code
      final response = await client
          .from('subscription_keys')
          .select()
          .eq('activation_code', code)
          .eq('is_active', true)
          .maybeSingle()
          .timeout(const Duration(seconds: 10));

      if (response == null) {
        AppLogService.warning(AppLogService.catAction, 'Cloud key redemption failed: Key not found or inactive ($code)');
        return const SubscriptionRedemptionResult(
          success: false,
          message: 'Invalid activation code. Please check your key or contact the admin.',
        );
      }

      final maxRedemptions = (response['max_redemptions'] as int?) ?? 1;
      final timesRedeemed = (response['times_redeemed'] as int?) ?? 0;
      final assignedId = (response['assigned_account_id'] ?? response['assigned_student_id']) as String?;
      final planTypeStr = response['plan_type'] as String? ?? 'semester';
      final durationDays = response['duration_days'] as int?;

      // Check if key is locked to a specific account
      if (assignedId != null && assignedId.trim().isNotEmpty) {
        if (assignedId.trim().toLowerCase() != effectiveAccount.trim().toLowerCase()) {
          return const SubscriptionRedemptionResult(
            success: false,
            message: 'This activation code is assigned to a different account.',
          );
        }
      }

      // Check redemption usage limit (Single-use enforcement)
      if (timesRedeemed >= maxRedemptions) {
        return const SubscriptionRedemptionResult(
          success: false,
          message: 'This activation code has already been redeemed.',
        );
      }

      // Determine plan duration
      SubscriptionPlan plan = SubscriptionPlan.semester;
      if (planTypeStr == 'lifetime' || durationDays == null) {
        plan = SubscriptionPlan.lifetime;
      } else if (planTypeStr == 'monthly') {
        plan = SubscriptionPlan.monthly;
      }

      DateTime? expiryDate;
      if (plan != SubscriptionPlan.lifetime) {
        final days = durationDays ?? (plan == SubscriptionPlan.monthly ? 31 : 150);
        expiryDate = now.add(Duration(days: days));
      }

      // 2. Consume the key on the Cloud server
      await client.from('subscription_keys').update({
        'times_redeemed': timesRedeemed + 1,
        'redeemed_by': effectiveAccount,
        'redeemed_at': now.toIso8601String(),
      }).eq('id', response['id']);

      // 3. Upsert into live `user_subscriptions` table for live account synchronization
      try {
        await client.from('user_subscriptions').upsert({
          'account_id': effectiveAccount,
          'tier': 'pro',
          'plan_type': plan.name,
          'expires_at': expiryDate?.toIso8601String(),
          'activated_at': now.toIso8601String(),
          'activation_code': code,
          'is_active': true,
          'updated_at': now.toIso8601String(),
          'notes': 'Activated via voucher key $code',
        }, onConflict: 'account_id');
      } catch (e) {
        AppLogService.warning(AppLogService.catAction, 'Notice upserting user_subscriptions row: $e');
      }

      // 4. Save to hardware encrypted storage
      await _saveLocalSubscriptionState(
        code: code,
        plan: plan,
        expiryDate: expiryDate,
        now: now,
        accountId: effectiveAccount,
      );

      AppLogService.success(AppLogService.catAction, 'Successfully redeemed Pro key via Cloud: $code ($plan) for $effectiveAccount');

      return SubscriptionRedemptionResult(
        success: true,
        message: 'SemBase Pro activated successfully! Your account subscription is synced with the Cloud.',
        plan: plan,
      );
    } on TimeoutException {
      return const SubscriptionRedemptionResult(
        success: false,
        message: 'Cloud verification timed out. Please check your internet connection and try again.',
      );
    } on SocketException {
      return const SubscriptionRedemptionResult(
        success: false,
        message: 'Internet connection required. Please connect to Wi-Fi or mobile data to verify your code with the Cloud server.',
      );
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('socket') || errStr.contains('network') || errStr.contains('offline') || errStr.contains('failed host lookup')) {
        return const SubscriptionRedemptionResult(
          success: false,
          message: 'Internet connection required. Please connect to Wi-Fi or mobile data to verify your code with the Cloud server.',
        );
      }

      AppLogService.warning(AppLogService.catAction, 'Cloud verification exception: $e');
      return const SubscriptionRedemptionResult(
        success: false,
        message: 'Invalid activation code. Please check your key or contact the admin.',
      );
    }
  }

  static Future<void> _saveLocalSubscriptionState({
    required String code,
    required SubscriptionPlan plan,
    required DateTime? expiryDate,
    required DateTime now,
    required String accountId,
  }) async {
    await _storage.write(key: _kTierKey, value: 'pro');
    await _storage.write(key: _kPlanKey, value: plan.name);
    await _storage.write(key: _kExpiryKey, value: expiryDate?.toIso8601String() ?? '');
    await _storage.write(key: _kCodeKey, value: code);
    await _storage.write(key: _kActivatedKey, value: now.toIso8601String());

    _cachedInfo = SubscriptionInfo(
      tier: SubscriptionTier.pro,
      plan: plan,
      expiresAt: expiryDate,
      activatedAt: now,
      activationCode: code,
      accountId: accountId,
    );
  }

  /// Reverts subscription to Free tier
  static Future<void> resetToFree({bool notifyCloud = true}) async {
    final accountId = await getEffectiveAccountId();

    await _storage.delete(key: _kTierKey);
    await _storage.delete(key: _kPlanKey);
    await _storage.delete(key: _kExpiryKey);
    await _storage.delete(key: _kCodeKey);
    await _storage.delete(key: _kActivatedKey);

    _cachedInfo = SubscriptionInfo(
      tier: SubscriptionTier.free,
      plan: SubscriptionPlan.free,
      accountId: accountId,
    );

    if (notifyCloud) {
      try {
        if (!AppConfig.supabaseUrl.contains('your-project')) {
          await Supabase.instance.client
              .from('user_subscriptions')
              .update({'tier': 'free', 'is_active': false, 'updated_at': DateTime.now().toIso8601String()})
              .eq('account_id', accountId);
        }
      } catch (_) {}
    }

    AppLogService.info(
      AppLogService.catAction,
      'Subscription reset to free tier for $accountId',
    );
  }
}
