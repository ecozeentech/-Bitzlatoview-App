import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/constants.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';

/// Native settings screen - required both functionally (logout, cache
/// management, biometric lock) and for App Store Guideline 4.2 compliance,
/// since it demonstrates native chrome beyond the WebView itself.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  PackageInfo? _packageInfo;
  bool _biometricAvailable = false;
  bool _isClearing = false;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
    _checkBiometrics();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _packageInfo = info);
  }

  Future<void> _checkBiometrics() async {
    final available = await context.read<AuthProvider>().canUseBiometrics();
    if (mounted) setState(() => _biometricAvailable = available);
  }

  Future<void> _openExternal(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $url')),
        );
      }
    }
  }

  Future<void> _contactSupport() async {
    final Uri uri = Uri(
      scheme: 'mailto',
      path: AppConstants.supportEmail,
      query: 'subject=${Uri.encodeComponent("Support request - ${AppConstants.appName} app")}',
    );
    if (!await launchUrl(uri)) {
      await _openExternal(AppConstants.supportUrl);
    }
  }

  Future<void> _confirmAndRun({
    required String title,
    required String message,
    required Future<void> Function() action,
  }) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceVariant,
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed == true) await action();
  }

  Future<void> _logout() async {
    await _confirmAndRun(
      title: 'Log out',
      message: 'You will be signed out of ${AppConstants.appName} on this device.',
      action: () async {
        await context.read<AuthProvider>().logout();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Logged out')),
          );
        }
      },
    );
  }

  Future<void> _clearCache() async {
    await _confirmAndRun(
      title: 'Clear cache',
      message: 'This clears cached pages, cookies and local app data. '
          'You will need to log in again.',
      action: () async {
        setState(() => _isClearing = true);
        try {
          await InAppWebViewController.clearAllCache();
          if (!mounted) return;
          await context.read<AuthProvider>().clearAllLocalData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cache cleared')),
            );
          }
        } finally {
          if (mounted) setState(() => _isClearing = false);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final notificationProvider = context.watch<NotificationProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionHeader('Security'),
          SwitchListTile(
            secondary: const Icon(Icons.fingerprint_rounded),
            title: const Text('Biometric app lock'),
            subtitle: Text(
              _biometricAvailable
                  ? 'Require Face ID / fingerprint to open the app'
                  : 'Not available on this device',
            ),
            value: authProvider.biometricLockEnabled,
            onChanged: _biometricAvailable
                ? (value) => authProvider.setBiometricLockEnabled(value)
                : null,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_active_rounded),
            title: const Text('Push notifications'),
            subtitle: const Text('Trade updates and P2P order alerts'),
            value: notificationProvider.permissionGranted,
            onChanged: (_) => notificationProvider.requestPermission(),
          ),
          const Divider(),
          const _SectionHeader('Legal'),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.open_in_new_rounded, size: 18),
            onTap: () => _openExternal(AppConstants.privacyPolicyUrl),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.open_in_new_rounded, size: 18),
            onTap: () => _openExternal(AppConstants.termsOfServiceUrl),
          ),
          ListTile(
            leading: const Icon(Icons.warning_amber_rounded),
            title: const Text('Risk Disclosure'),
            trailing: const Icon(Icons.open_in_new_rounded, size: 18),
            onTap: () => _openExternal(AppConstants.riskDisclosureUrl),
          ),
          const Divider(),
          const _SectionHeader('Data & Support'),
          ListTile(
            leading: const Icon(Icons.cleaning_services_outlined),
            title: const Text('Clear cache'),
            subtitle: const Text('Removes cookies, session and cached pages'),
            trailing: _isClearing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            onTap: _isClearing ? null : _clearCache,
          ),
          ListTile(
            leading: const Icon(Icons.support_agent_rounded),
            title: const Text('Contact Support'),
            onTap: _contactSupport,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppTheme.error),
            title: const Text('Log out', style: TextStyle(color: AppTheme.error)),
            onTap: _logout,
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              _packageInfo == null
                  ? ' '
                  : '${AppConstants.appName} v${_packageInfo!.version} (${_packageInfo!.buildNumber})',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AppTheme.gold,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
