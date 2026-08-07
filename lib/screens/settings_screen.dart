import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/constants.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/webview_provider.dart';
import '../utils/helpers.dart';

/// Native settings screen for legal links, cache, logout, and app info.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _versionLabel = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        _versionLabel = '${info.version} (${info.buildNumber})';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _versionLabel = '1.0.0');
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Log out'),
        content: const Text(
          'This clears your secure session cookies and returns you to the login page.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final auth = context.read<AuthProvider>();
    final webView = context.read<WebViewProvider>();
    await auth.logout();
    await webView.clearCache();
    await webView.loadUrl(AppConstants.baseUrl);
    if (mounted) context.go('/');
  }

  Future<void> _clearCache() async {
    final webView = context.read<WebViewProvider>();
    final auth = context.read<AuthProvider>();
    await webView.clearCache();
    await auth.cookieService.clearCookies();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cache and cookies cleared')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        children: [
          _sectionHeader('Legal & compliance'),
          _tile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () => _openUrl(AppConstants.privacyPolicyUrl),
          ),
          _tile(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            onTap: () => _openUrl(AppConstants.termsOfServiceUrl),
          ),
          _tile(
            icon: Icons.warning_amber_outlined,
            title: 'Risk Disclosure',
            onTap: () => _openUrl(AppConstants.riskDisclosureUrl),
          ),
          const Divider(height: 32),
          _sectionHeader('Support'),
          _tile(
            icon: Icons.support_agent_outlined,
            title: 'Contact Support',
            subtitle: AppConstants.supportEmail,
            onTap: () => Helpers.openMailto(
              AppConstants.supportEmail,
              subject: 'Bitzlatoview Mobile Support',
            ),
          ),
          _tile(
            icon: Icons.help_outline,
            title: 'Help Center',
            onTap: () => _openUrl(AppConstants.supportUrl),
          ),
          const Divider(height: 32),
          _sectionHeader('App'),
          _tile(
            icon: Icons.cleaning_services_outlined,
            title: 'Clear Cache',
            subtitle: 'Removes WebView cache and session cookies',
            onTap: _clearCache,
          ),
          _tile(
            icon: Icons.logout,
            title: 'Log out',
            onTap: _logout,
          ),
          ListTile(
            leading: const Icon(Icons.info_outline, color: AppTheme.gold),
            title: const Text('App Version'),
            subtitle: Text(
              _versionLabel.isEmpty ? '…' : _versionLabel,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Bitzlatoview does not store sensitive financial data on this device. '
              'All transactions are processed securely on the server. '
              'Trading involves risk — past performance is not indicative of future results.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textMuted,
                    height: 1.4,
                  ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppTheme.goldMuted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.gold),
      title: Text(title),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(color: AppTheme.textSecondary),
            )
          : null,
      trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
      onTap: onTap,
    );
  }
}
