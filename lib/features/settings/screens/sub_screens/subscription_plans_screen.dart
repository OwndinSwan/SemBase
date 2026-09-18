import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../core/providers/subscription_provider.dart';
import '../../../../core/services/subscription_service.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/utils/app_toast.dart';
import '../../../auth/screens/auth_screen.dart';
import '../../../auth/services/auth_keystore_service.dart';

class SubscriptionPlansScreen extends ConsumerStatefulWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  ConsumerState<SubscriptionPlansScreen> createState() => _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends ConsumerState<SubscriptionPlansScreen> {
  String _effectiveAccountId = 'GUEST-ACCOUNT-LOCAL';
  bool _isGuest = true;

  @override
  void initState() {
    super.initState();
    _loadUserMeta();
  }

  Future<void> _loadUserMeta() async {
    final isGuest = await SubscriptionService.isGuest();
    final accountId = await SubscriptionService.getEffectiveAccountId();
    if (mounted) {
      setState(() {
        _isGuest = isGuest;
        _effectiveAccountId = accountId;
      });
      // Synchronize live cloud state silently in background
      ref.read(subscriptionProvider.notifier).loadSubscription(syncCloud: true);
    }
  }

  void _navigateToAuth() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AuthScreen(
          onAuthenticated: () {
            Navigator.of(context).pop();
            _loadUserMeta();
          },
        ),
      ),
    );
  }

  void _showAccountRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgDarkElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.account_circle_outlined, color: AppTheme.accentAmber, size: 24),
            SizedBox(width: 10),
            Text('Account Required', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: const Text(
          'SemBase Pro features and cloud voucher redemption require a registered student account.\n\nPlease sign in or register an account to continue.',
          style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondaryDark, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondaryDark)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _navigateToAuth();
            },
            icon: const Icon(Icons.login_rounded, size: 16),
            label: const Text('Sign In / Register', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  String get _accountId => _effectiveAccountId;

  @override
  Widget build(BuildContext context) {
    final subInfo = ref.watch(subscriptionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plans & Subscription'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            tooltip: 'Sync Cloud Subscription',
            onPressed: () async {
              AppToast.showInfo(
                context,
                'Checking Cloud subscription status...',
                icon: Icons.sync_rounded,
                duration: const Duration(seconds: 1),
              );
              await ref.read(subscriptionProvider.notifier).loadSubscription(syncCloud: true);
              if (context.mounted) {
                final updated = ref.read(subscriptionProvider);
                final text = updated.isPro
                    ? 'Synced: ${updated.planDisplayName} (${updated.expiresAt == null ? "Lifetime" : "${updated.daysRemaining} days remaining"})'
                    : 'Synced from Cloud: Free Academic';
                if (updated.isPro) {
                  AppToast.showSuccess(context, text, icon: Icons.stars_rounded);
                } else {
                  AppToast.showInfo(context, text, icon: Icons.cloud_done_outlined);
                }
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // 1. Current Status Banner
          _buildCurrentStatusCard(subInfo),
          const SizedBox(height: 20),

          // 2. Pricing Tiers
          _buildSectionHeader('SUBSCRIPTION TIERS', Icons.stars_rounded),
          const SizedBox(height: 10),
          _buildPricingCards(),
          const SizedBox(height: 20),

          // 3. Feature Breakdown Table
          _buildSectionHeader('PLAN COMPARISON', Icons.checklist_rounded),
          const SizedBox(height: 10),
          _buildComparisonCard(),
          const SizedBox(height: 20),

          // 4. Manual Payment & Admin Activation Flow
          _buildSectionHeader('HOW TO SUBSCRIBE & ACTIVATE', Icons.payment_rounded),
          const SizedBox(height: 10),
          _buildManualPaymentCard(context),
          const SizedBox(height: 20),

          // 5. Redeem Code Button & Contact Admin
          _buildRedeemAndContactSection(context, subInfo),
          const SizedBox(height: 36),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondaryDark),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondaryDark,
            letterSpacing: 0.7,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStatusCard(SubscriptionInfo sub) {
    final isPro = sub.isPro;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPro ? AppTheme.accentAmber.withOpacity(0.6) : AppTheme.primaryGreen.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isPro ? AppTheme.accentAmber.withOpacity(0.12) : AppTheme.primaryGreen.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isPro ? AppTheme.accentAmber.withOpacity(0.18) : AppTheme.primaryGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isPro ? Icons.diamond_rounded : Icons.school_rounded,
                  color: isPro ? AppTheme.accentAmber : AppTheme.primaryGreenLight,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPro ? '💎 SEMBASE PRO' : '🟢 FREE ACADEMIC PLAN',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: isPro ? AppTheme.accentAmber : AppTheme.primaryGreenLight,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isPro
                          ? (sub.expiresAt == null
                              ? 'Active • Lifetime Degree Pass'
                              : 'Active • ${sub.daysRemaining} days remaining')
                          : (_isGuest
                              ? 'Offline Student Mode • Basic Timetable'
                              : 'Active • Basic Timetable & Offline Tasks'),
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryDark),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_isGuest) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentAmber.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.accentAmber.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppTheme.accentAmber, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Offline Student Mode (Guest)',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.accentAmber),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Subscribing to Pro features requires a registered SemBase account.',
                          style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryDark),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _navigateToAuth,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentAmber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Sign In', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ] else if (sub.accountId != null && sub.accountId!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.bgDark.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderDark.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.fingerprint_rounded, size: 14, color: AppTheme.textMutedDark),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Cloud Sync ID: ${sub.accountId}',
                      style: const TextStyle(fontSize: 10.5, color: AppTheme.textSecondaryDark, fontFamily: 'monospace'),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: sub.accountId!));
                      AppToast.showSuccess(
                        context,
                        'Cloud Sync ID copied to clipboard!',
                        icon: Icons.copy_rounded,
                        duration: const Duration(seconds: 1),
                      );
                    },
                    child: const Icon(Icons.copy_rounded, size: 14, color: AppTheme.primaryGreenLight),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPricingCards() {
    final plans = [
      _PlanCardData(
        title: 'Monthly Pass',
        price: '₱49',
        period: '/ month',
        badge: 'Flexible',
        badgeColor: AppTheme.textSecondaryDark,
        description: 'Ideal for exam prep with Encrypted Cloud Vault & multi-device sync.',
      ),
      _PlanCardData(
        title: 'Semester Pass',
        price: '₱199',
        period: '/ 5 months',
        badge: 'MOST POPULAR',
        badgeColor: AppTheme.accentAmber,
        isPopular: true,
        description: 'Covers an entire term with Encrypted Cloud Vault, Auto-Sync & all Pro tools.',
      ),
      _PlanCardData(
        title: 'Lifetime Pass',
        price: '₱399',
        period: 'one-time',
        badge: 'BEST VALUE',
        badgeColor: AppTheme.primaryGreenLight,
        description: 'Full access with permanent Encrypted Cloud Vault for your entire 4-year degree.',
      ),
    ];

    return Column(
      children: plans.map((p) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: p.isPopular ? AppTheme.accentAmber.withOpacity(0.7) : AppTheme.borderDark.withOpacity(0.4),
            width: p.isPopular ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        p.title,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryDark),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: p.badgeColor.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          p.badge,
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: p.badgeColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    p.description,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryDark),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  p.price,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: p.isPopular ? AppTheme.accentAmber : AppTheme.primaryGreenLight,
                  ),
                ),
                Text(
                  p.period,
                  style: const TextStyle(fontSize: 10, color: AppTheme.textMutedDark),
                ),
              ],
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildComparisonCard() {
    final comparisons = [
      _CompareRow('Timetable Grid & Conflict Solver', '✅ Included', '✅ Included'),
      _CompareRow('Subject Hub & Task Checklists', '✅ Included', '✅ Included'),
      _CompareRow('Interactive Campus Map & Room Pins', '✅ Included', '✅ Included'),
      _CompareRow('GPS Navigation & Waypoint Route', '✅ Included', '✅ Included'),
      _CompareRow('+/- 1-Week Deadline Shifter', '✅ Included', '✅ Included'),
      _CompareRow('100% Offline SQLite Vault', '✅ Zero Data', '✅ Zero Data'),
      _CompareRow('Manual JSON Backup & Restore', '✅ Included', '✅ Included'),
      _CompareRow('Offline Map Pack Downloader', '❌ Online Only', '⚡ 100% Zero-Data'),
      _CompareRow('Campus & Room Arrival Alerts', '❌', '⚡ 50m–150m Proximity'),
      _CompareRow('Encrypted Multi-Device Cloud Vault', '❌ Device Only', '⚡ Encrypted Vault'),
      _CompareRow('Multi-Device Real-Time Cloud Sync', '❌ Manual JSON', '⚡ Real-time Auto'),
      _CompareRow('Pre-Class Notification Alert', 'Fixed (15m)', '⚡ Custom (5m-60m)'),
      _CompareRow('7:00 AM Morning Academic Briefing', '❌', '⚡ Included'),
      _CompareRow('Google & Apple Calendar Export (.ics)', '❌', '⚡ 1-Tap Live'),
      _CompareRow('Biometric App Lock (Fingerprint/Face)', '❌', '⚡ Included'),
      _CompareRow('Historical Semester Archiving', '1 Past Term', '⚡ Unlimited All Years'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark.withOpacity(0.4)),
      ),
      child: Column(
        children: List.generate(comparisons.length, (i) {
          final row = comparisons[i];
          final isLast = i == comparisons.length - 1;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Text(
                        row.feature,
                        style: const TextStyle(fontSize: 11.5, color: AppTheme.textPrimaryDark, fontWeight: FontWeight.w500),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        row.freeVal,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 10.5, color: AppTheme.textSecondaryDark),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Text(
                        row.proVal,
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTheme.accentAmber),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                const Divider(color: Color(0x10FFFFFF), height: 1),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildManualPaymentCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Manual Payment & Admin Activation Flow:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryDark),
          ),
          const SizedBox(height: 10),
          _buildStepRow('1', 'Create/Sign In to your SemBase Account.'),
          _buildStepRow('2', 'Copy your Student Account ID below.'),
          _buildStepRow('3', 'Message the Admin via Email (progamesn.site@gmail.com).'),
          _buildStepRow('4', 'Send payment via GCash or Maya.'),
          _buildStepRow('5', 'Receive your Activation Code and redeem it below.'),
          const SizedBox(height: 14),

          // Copyable Account ID Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.bgDarkElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isGuest ? AppTheme.accentAmber.withOpacity(0.4) : AppTheme.primaryGreen.withOpacity(0.3),
              ),
            ),
            child: _isGuest
                ? Row(
                    children: [
                      const Icon(Icons.lock_outline_rounded, size: 20, color: AppTheme.accentAmber),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Account Required to Subscribe',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryDark),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Sign in to link a Cloud Account ID for Pro subscriptions.',
                              style: TextStyle(fontSize: 10.5, color: AppTheme.textSecondaryDark),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _navigateToAuth,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentAmber,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Sign In', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Your SemBase Account ID:', style: TextStyle(fontSize: 10, color: AppTheme.textMutedDark)),
                            const SizedBox(height: 2),
                            SelectableText(
                              _accountId,
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.primaryGreenLight, fontFamily: 'monospace'),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _accountId));
                          AppToast.showSuccess(
                            context,
                            'Account ID copied to clipboard!',
                            icon: Icons.copy_rounded,
                            duration: const Duration(seconds: 2),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, size: 18, color: AppTheme.primaryGreenLight),
                        tooltip: 'Copy Account ID',
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepRow(String num, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.accentAmber.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: Text(
              num,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.accentAmber),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondaryDark, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRedeemAndContactSection(BuildContext context, SubscriptionInfo sub) {
    return Column(
      children: [
        // Redeem Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              if (_isGuest) {
                _showAccountRequiredDialog(context);
              } else {
                _showRedeemDialog(context);
              }
            },
            icon: Icon(_isGuest ? Icons.lock_outline_rounded : Icons.vpn_key_rounded, size: 18),
            label: Text(
              _isGuest ? 'Sign In to Redeem Code' : 'Redeem Activation Code',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isGuest ? AppTheme.cardDark : AppTheme.accentAmber,
              foregroundColor: _isGuest ? AppTheme.accentAmber : Colors.black,
              side: _isGuest ? BorderSide(color: AppTheme.accentAmber.withOpacity(0.5)) : null,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Contact Admin Actions
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(const ClipboardData(text: 'progamesn.site@gmail.com'));
                  AppToast.showInfo(
                    context,
                    'Admin Email copied: progamesn.site@gmail.com',
                    icon: Icons.email_outlined,
                  );
                },
                icon: const Icon(Icons.email_outlined, size: 16),
                label: const Text('Email Admin', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.accentCyan,
                  side: const BorderSide(color: AppTheme.accentCyan, width: 1.2),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  AppToast.showInfo(
                    context,
                    'Telegram Admin: None currently. Please contact via Email.',
                    icon: Icons.send_rounded,
                  );
                },
                icon: const Icon(Icons.send_rounded, size: 16),
                label: const Text('Telegram (None)', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textMutedDark,
                  side: BorderSide(color: AppTheme.borderDark.withOpacity(0.5), width: 1.2),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showRedeemDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.bgDarkElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.vpn_key_rounded, color: AppTheme.accentAmber, size: 22),
            SizedBox(width: 10),
            Text('Redeem Activation Code', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste the activation code provided by the admin to instantly upgrade your account to SemBase Pro.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryDark, height: 1.4),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, fontFamily: 'monospace'),
              decoration: InputDecoration(
                hintText: 'e.g. PRO-SEM-XXXX',
                filled: true,
                fillColor: AppTheme.cardDark,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.paste_rounded, size: 18),
                  onPressed: () async {
                    final data = await Clipboard.getData(Clipboard.kTextPlain);
                    if (data?.text != null) {
                      controller.text = data!.text!.trim();
                    }
                  },
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondaryDark)),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = controller.text.trim();
              if (code.isEmpty) return;

              Navigator.pop(dialogCtx);

              final result = await ref.read(subscriptionProvider.notifier).redeemCode(code, studentIdentifier: _accountId);

              if (context.mounted) {
                if (result.success) {
                  showDialog(
                    context: context,
                    builder: (sCtx) => AlertDialog(
                      backgroundColor: AppTheme.cardDark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: const Row(
                        children: [
                          Icon(Icons.stars_rounded, color: AppTheme.accentAmber, size: 26),
                          SizedBox(width: 10),
                          Text('Welcome to Pro! 🎉', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                        ],
                      ),
                      content: Text(
                        result.message.isNotEmpty
                            ? result.message
                            : 'Your SemBase Pro subscription has been activated successfully! All power-user features (Cloud Sync, Calendar Export, Morning Briefing, Biometrics, and Custom Reminders) are now unlocked.',
                        style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondaryDark, height: 1.4),
                      ),
                      actions: [
                        ElevatedButton(
                          onPressed: () => Navigator.pop(sCtx),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentAmber,
                            foregroundColor: Colors.black,
                          ),
                          child: const Text('Awesome!'),
                        ),
                      ],
                    ),
                  );
                } else {
                  AppToast.showError(
                    context,
                    result.message,
                    duration: const Duration(seconds: 4),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentAmber,
              foregroundColor: Colors.black,
            ),
            child: const Text('Activate', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _PlanCardData {
  final String title;
  final String price;
  final String period;
  final String badge;
  final Color badgeColor;
  final String description;
  final bool isPopular;

  _PlanCardData({
    required this.title,
    required this.price,
    required this.period,
    required this.badge,
    required this.badgeColor,
    required this.description,
    this.isPopular = false,
  });
}

class _CompareRow {
  final String feature;
  final String freeVal;
  final String proVal;

  _CompareRow(this.feature, this.freeVal, this.proVal);
}
