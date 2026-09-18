import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/subscription_service.dart';

class SubscriptionNotifier extends StateNotifier<SubscriptionInfo> {
  SubscriptionNotifier()
      : super(const SubscriptionInfo(
          tier: SubscriptionTier.free,
          plan: SubscriptionPlan.free,
        )) {
    loadSubscription();
  }

  Future<void> loadSubscription({bool syncCloud = true}) async {
    // 1. Instant local read for snappy UI
    final localInfo = await SubscriptionService.getSubscriptionInfo();
    state = localInfo;

    // 2. Synchronize with Cloud in background to reflect manual admin dashboard edits
    if (syncCloud) {
      final cloudInfo = await SubscriptionService.syncCloudSubscription();
      state = cloudInfo;
    }
  }

  Future<SubscriptionRedemptionResult> redeemCode(String code, {String? studentIdentifier}) async {
    final result = await SubscriptionService.redeemActivationCode(code, studentIdentifier: studentIdentifier);
    if (result.success) {
      await loadSubscription(syncCloud: false);
    }
    return result;
  }

  Future<void> resetToFree() async {
    await SubscriptionService.resetToFree();
    await loadSubscription(syncCloud: false);
  }
}

final subscriptionProvider = StateNotifierProvider<SubscriptionNotifier, SubscriptionInfo>((ref) {
  return SubscriptionNotifier();
});

final isProProvider = Provider<bool>((ref) {
  final sub = ref.watch(subscriptionProvider);
  return sub.isPro;
});
