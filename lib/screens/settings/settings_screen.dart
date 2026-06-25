import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/database/database_helper.dart';
import '../../providers/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _companyName = '';
  String _currency = 'PKR';
  bool _autoBackup = true;
  bool _backingUp = false;
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadUsers();
  }

  Future<void> _loadSettings() async {
    final db = DatabaseHelper.instance;
    final name = await db.getSetting('company_name');
    final currency = await db.getSetting('currency');
    final autoBackup = await db.getSetting('auto_backup');
    if (mounted) setState(() {
      _companyName = name ?? '';
      _currency = currency ?? 'PKR';
      _autoBackup = autoBackup == 'true';
    });
  }

  Future<void> _loadUsers() async {
    final users = await DatabaseHelper.instance.getUsers();
    if (mounted) setState(() => _users = users);
  }

  Future<void> _backup() async {
    setState(() => _backingUp = true);
    try {
      final path = await DatabaseHelper.instance.backupDatabase();
      if (mounted) {
        setState(() => _backingUp = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup saved to: $path'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _backingUp = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _saveCompanyName(String name) async {
    await DatabaseHelper.instance.setSetting('company_name', name);
    setState(() => _companyName = name);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final isAdmin = auth.isAdmin;

    return Scaffold(
      backgroundColor: AppColors.bgBlack,
      appBar: AppBar(title: const Text('Settings'), backgroundColor: AppColors.bgBlack),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.primaryOrange, AppColors.orangeDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.person, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(auth.userName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                      child: Text(auth.userRole.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _SectionHeader('Company Settings'),
          _SettingsTile(
            icon: Icons.business,
            title: 'Company Name',
            subtitle: _companyName.isEmpty ? 'Set company name' : _companyName,
            onTap: () => _editCompanyName(),
          ),
          _SettingsTile(
            icon: Icons.currency_exchange,
            title: 'Currency',
            subtitle: _currency,
            onTap: () => _editCurrency(),
          ),

          const SizedBox(height: 16),
          _SectionHeader('Backup & Restore'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: _backingUp ? null : _backup,
                  icon: _backingUp
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.backup, size: 20),
                  label: Text(_backingUp ? 'Creating Backup...' : 'Create Backup'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.info,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
                const SizedBox(height: 10),
                const Text('Backup saved to: /storage/SaleismProBackup/', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                _SettingsTile(
                  icon: Icons.settings_backup_restore,
                  title: 'Auto Backup',
                  subtitle: _autoBackup ? 'Enabled' : 'Disabled',
                  trailing: Switch(
                    value: _autoBackup,
                    onChanged: (v) async {
                      await DatabaseHelper.instance.setSetting('auto_backup', v.toString());
                      setState(() => _autoBackup = v);
                    },
                    activeColor: AppColors.primaryOrange,
                  ),
                ),
              ],
            ),
          ),

          if (isAdmin) ...[
            const SizedBox(height: 16),
            _SectionHeader('User Management'),
            Container(
              decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
              child: Column(
                children: [
                  ..._users.map((user) => ListTile(
                    leading: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: AppColors.primaryOrange.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.person, color: AppColors.primaryOrange, size: 20),
                    ),
                    title: Text(user['name'] as String, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                    subtitle: Text(user['role'] as String, style: const TextStyle(color: AppColors.textSecondary)),
                    trailing: user['id'] != 1
                        ? IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.lossRed),
                            onPressed: () => _deleteUser(user['id'] as int),
                          )
                        : const Text('OWNER', style: TextStyle(color: AppColors.primaryOrange, fontSize: 11, fontWeight: FontWeight.w700)),
                  )),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: OutlinedButton.icon(
                      onPressed: _addUser,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Staff User'),
                      style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 44)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),
          _SectionHeader('App Info'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
            child: Column(
              children: [
                _InfoRow(label: 'Version', value: '1.0.0'),
                _InfoRow(label: 'App Name', value: 'SALEISM PRO'),
                _InfoRow(label: 'Build', value: 'Production'),
                _InfoRow(label: 'Database', value: 'SQLite (Local)'),
              ],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => context.read<AuthProvider>().logout(),
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error.withOpacity(0.1),
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              minimumSize: const Size(double.infinity, 52),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _editCompanyName() {
    final ctrl = TextEditingController(text: _companyName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('Company Name', style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(controller: ctrl, style: const TextStyle(color: AppColors.textPrimary), decoration: const InputDecoration(hintText: 'Enter company name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () { _saveCompanyName(ctrl.text.trim()); Navigator.pop(ctx); }, child: const Text('Save')),
        ],
      ),
    );
  }

  void _editCurrency() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('Select Currency', style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['PKR', 'USD', 'EUR', 'GBP', 'AED', 'SAR'].map((c) => ListTile(
            title: Text(c, style: const TextStyle(color: AppColors.textPrimary)),
            selected: c == _currency,
            selectedTileColor: AppColors.primaryOrange.withOpacity(0.1),
            trailing: c == _currency ? const Icon(Icons.check, color: AppColors.primaryOrange) : null,
            onTap: () async {
              await DatabaseHelper.instance.setSetting('currency', c);
              if (mounted) setState(() => _currency = c);
              Navigator.pop(ctx);
            },
          )).toList(),
        ),
      ),
    );
  }

  void _addUser() {
    final nameCtrl = TextEditingController();
    final pinCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('Add Staff User', style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, style: const TextStyle(color: AppColors.textPrimary), decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 12),
            TextField(controller: pinCtrl, style: const TextStyle(color: AppColors.textPrimary), keyboardType: TextInputType.number, maxLength: 4, decoration: const InputDecoration(labelText: '4-digit PIN')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty && pinCtrl.text.length == 4) {
                await DatabaseHelper.instance.insertUser({'name': nameCtrl.text.trim(), 'role': 'staff', 'pin': pinCtrl.text, 'fingerprint_enabled': 0});
                await _loadUsers();
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUser(int id) async {
    await DatabaseHelper.instance.deleteUser(id);
    await _loadUsers();
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title, style: const TextStyle(color: AppColors.primaryOrange, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  const _SettingsTile({required this.icon, required this.title, required this.subtitle, this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: ListTile(
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: AppColors.primaryOrange.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: AppColors.primaryOrange, size: 20),
        ),
        title: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right, color: AppColors.textMuted) : null),
        onTap: onTap,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          const Spacer(),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
