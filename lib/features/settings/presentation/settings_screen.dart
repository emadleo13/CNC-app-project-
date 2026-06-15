import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:country_flags/country_flags.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../data/settings_repository.dart';
import '../data/account_repository.dart';
import '../../subscription/data/subscription_repository.dart';

final _settingsRepoProvider = Provider((_) => SettingsRepository());

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: ref.read(userNameProvider));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _setName(String name) {
    ref.read(userNameProvider.notifier).state = name;
    ref.read(_settingsRepoProvider).saveName(name);
  }

  Future<void> _setLocale(String locale) async {
    ref.read(localeProvider.notifier).state = locale;
    await ref.read(_settingsRepoProvider).saveLocale(locale);
  }

  Future<void> _setUnits(String units) async {
    ref.read(defaultUnitsProvider.notifier).state = units;
    await ref.read(_settingsRepoProvider).saveUnits(units);
  }

  Future<void> _setDialect(String dialect) async {
    ref.read(defaultDialectProvider.notifier).state = dialect;
    await ref.read(_settingsRepoProvider).saveDialect(dialect);
  }

  Future<void> _confirmDeleteAccount(AppStrings s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title:   Text(s.deleteAccountConfirmTitle),
        content: Text(s.deleteAccountConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:     Text(s.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:     TextButton.styleFrom(foregroundColor: AppColors.errorRed),
            child:     Text(s.deleteAccountConfirmBtn),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    // Blocking progress indicator while the server processes deletion.
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await ref.read(accountRepoProvider).deleteAccount();
      if (!mounted) return;
      Navigator.pop(context); // dismiss progress
      // Reset in-memory state tied to the deleted account.
      ref.read(userNameProvider.notifier).state = '';
      _nameCtrl.text = '';
      ref.invalidate(currentTierProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.deleteAccountDone)),
      );
    } catch (_) {
      if (!mounted) return;
      Navigator.pop(context); // dismiss progress
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.deleteAccountError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s       = ref.watch(appStringsProvider);
    final locale  = ref.watch(localeProvider);
    final units   = ref.watch(defaultUnitsProvider);
    final dialect = ref.watch(defaultDialectProvider);
    final tier    = ref.watch(currentTierProvider);

    return Scaffold(
      appBar: AppBar(title: Text(s.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Display name ──────────────────────────────────────────────────
          _SectionHeader(s.settingsName),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: TextField(
                controller: _nameCtrl,
                textInputAction: TextInputAction.done,
                onChanged: _setName,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person_outline, color: AppColors.primary),
                  hintText: s.settingsNameHint,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Subscription ─────────────────────────────────────────────────
          _SectionHeader(s.settingsSubscription),
          Card(
            child: tier.when(
              loading: () => const ListTile(
                leading: Icon(Icons.workspace_premium, color: AppColors.primary),
                title:   Text('...'),
              ),
              error: (e, st) => _buildFreeTile(s, context),
              data:  (t) => (t == 'pro' || t == 'team')
                  ? _buildProTile(s)
                  : _buildFreeTile(s, context),
            ),
          ),
          const SizedBox(height: 20),

          // ── Language ─────────────────────────────────────────────────────
          _SectionHeader(s.settingsLanguage),
          Card(
            child: Column(children: [
              _RadioTile<String>(
                leading: const _Flag('GB'),
                title: s.settingsLanguageEn, subtitle: 'English',
                value: 'en', groupValue: locale, onChanged: _setLocale,
              ),
              const Divider(height: 1, color: AppColors.border),
              _RadioTile<String>(
                leading: const _Flag('RO'),
                title: s.settingsLanguageRo, subtitle: 'Română',
                value: 'ro', groupValue: locale, onChanged: _setLocale,
              ),
              const Divider(height: 1, color: AppColors.border),
              _RadioTile<String>(
                leading: const _Flag('IR'),
                title: s.settingsLanguageFa, subtitle: 'Persian · فارسی',
                value: 'fa', groupValue: locale, onChanged: _setLocale,
              ),
              const Divider(height: 1, color: AppColors.border),
              _RadioTile<String>(
                leading: const _Flag('SA'),
                title: s.settingsLanguageAr, subtitle: 'Arabic · العربية',
                value: 'ar', groupValue: locale, onChanged: _setLocale,
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // ── Default Units ─────────────────────────────────────────────────
          _SectionHeader(s.settingsUnits),
          Card(
            child: Column(children: [
              _RadioTile<String>(
                title: s.settingsUnitsMetric,   subtitle: 'mm, m/min',
                value: 'metric',   groupValue: units, onChanged: _setUnits,
              ),
              const Divider(height: 1, color: AppColors.border),
              _RadioTile<String>(
                title: s.settingsUnitsImperial, subtitle: 'inch, SFM',
                value: 'imperial', groupValue: units, onChanged: _setUnits,
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // ── Default CNC Dialect ───────────────────────────────────────────
          _SectionHeader(s.settingsDialect),
          Card(
            child: Column(children: [
              _RadioTile<String>(
                title: 'Haas', subtitle: 'Haas CNC',
                value: 'haas', groupValue: dialect, onChanged: _setDialect,
              ),
              const Divider(height: 1, color: AppColors.border),
              _RadioTile<String>(
                title: 'Siemens Sinumerik', subtitle: 'Sinumerik 840D / 828D',
                value: 'sinumerik', groupValue: dialect, onChanged: _setDialect,
              ),
              const Divider(height: 1, color: AppColors.border),
              _RadioTile<String>(
                title: 'Generic ISO', subtitle: 'ISO 6983',
                value: 'generic', groupValue: dialect, onChanged: _setDialect,
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // ── Theme ─────────────────────────────────────────────────────────
          _SectionHeader(s.settingsTheme),
          Card(
            child: ListTile(
              leading: const Icon(Icons.dark_mode, color: AppColors.primary),
              title:   Text(s.settingsThemeDark),
              trailing: const Icon(Icons.check, color: AppColors.primary, size: 18),
            ),
          ),
          const SizedBox(height: 20),

          // ── Support & Contact ──────────────────────────────────────────────
          _SectionHeader(s.supportTitle),
          Card(
            child: Column(children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12), topRight: Radius.circular(12),
                  ),
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.successGreen.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.verified_user, color: AppColors.successGreen, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.support247,
                        style: const TextStyle(color: AppColors.successGreen, fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(s.supportSubtitle,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  )),
                ]),
              ),
              const Divider(height: 1, color: AppColors.border),
              ListTile(
                leading: const Icon(Icons.person_outline, color: AppColors.primary),
                title:   Text(s.supportDeveloper),
                subtitle: const Text('Emad Leo', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ),
              const Divider(height: 1, color: AppColors.border),
              ListTile(
                leading: const Icon(Icons.email_outlined, color: AppColors.primary),
                title:   Text(s.supportEmail),
                subtitle: const Text('hamidleo1984@gmail.com', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                trailing: const Icon(Icons.open_in_new, size: 16, color: AppColors.textMuted),
                onTap: () => launchUrl(Uri.parse('mailto:hamidleo1984@gmail.com')),
              ),
              const Divider(height: 1, color: AppColors.border),
              ListTile(
                leading: const Icon(Icons.send_outlined, color: AppColors.primary),
                title:   Text(s.supportTelegram),
                subtitle: const Text('@EMADLEO1984', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                trailing: const Icon(Icons.open_in_new, size: 16, color: AppColors.textMuted),
                onTap: () => launchUrl(Uri.parse('https://t.me/EMADLEO1984'), mode: LaunchMode.externalApplication),
              ),
              const Divider(height: 1, color: AppColors.border),
              ListTile(
                leading: const Icon(Icons.work_outline, color: AppColors.primary),
                title:   Text(s.supportLinkedIn),
                subtitle: const Text('Emad Leo', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                trailing: const Icon(Icons.open_in_new, size: 16, color: AppColors.textMuted),
                onTap: () => launchUrl(Uri.parse('https://www.linkedin.com/in/emadleo13-b42882236'), mode: LaunchMode.externalApplication),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // ── About ─────────────────────────────────────────────────────────
          _SectionHeader(s.settingsAbout),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline, color: AppColors.textSecondary),
              title:   const Text('CNC Assist'),
              subtitle: Text(s.settingsVersion),
            ),
          ),
          const SizedBox(height: 20),

          // ── Account (data deletion) ───────────────────────────────────────
          _SectionHeader(s.settingsAccount),
          Card(
            child: ListTile(
              leading:  const Icon(Icons.delete_forever_outlined, color: AppColors.errorRed),
              title:    Text(s.settingsDeleteAccount,
                  style: const TextStyle(color: AppColors.errorRed)),
              subtitle: Text(s.settingsDeleteAccountDesc,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              onTap:    () => _confirmDeleteAccount(s),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildFreeTile(AppStrings s, BuildContext context) {
    return Column(children: [
      ListTile(
        leading: const Icon(Icons.workspace_premium_outlined, color: AppColors.textSecondary),
        title:   Text(s.settingsFreePlan),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
        onTap:   () => context.push(RouteNames.subscription),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => context.push(RouteNames.subscription),
            icon:  const Icon(Icons.workspace_premium, size: 16),
            label: Text(s.settingsUpgradePro),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding:         const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _buildProTile(AppStrings s) {
    return ListTile(
      leading: const Icon(Icons.workspace_premium, color: AppColors.primary),
      title:   Text(s.settingsProPlan),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color:        AppColors.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border:       Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
        ),
        child: const Text('PRO',
          style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _Flag extends StatelessWidget {
  final String countryCode;
  const _Flag(this.countryCode);

  @override
  Widget build(BuildContext context) {
    return CountryFlag.fromCountryCode(
      countryCode,
      theme: const ImageTheme(width: 34, height: 24, shape: RoundedRectangle(4)),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11, letterSpacing: 1.2, color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _RadioTile<T> extends StatelessWidget {
  final String         title;
  final String         subtitle;
  final T              value;
  final T              groupValue;
  final ValueChanged<T> onChanged;
  final Widget?        leading;
  const _RadioTile({
    required this.title, required this.subtitle,
    required this.value, required this.groupValue, required this.onChanged,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return ListTile(
      leading:  leading,
      title:    Text(title),
      subtitle: Text(subtitle,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      trailing: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: selected ? AppColors.primary : AppColors.textSecondary,
        size:  20,
      ),
      onTap:      () => onChanged(value),
      tileColor:  selected ? AppColors.primaryDim.withValues(alpha: 0.15) : null,
    );
  }
}
