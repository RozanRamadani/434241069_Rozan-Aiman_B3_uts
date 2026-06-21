import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiketdotcom/core/theme/app_theme.dart';
import 'package:tiketdotcom/main.dart'; // To access themeNotifier

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  bool _isDarkMode = false;
  bool _notifEnabled = true;
  bool _notifStatus = true;
  bool _notifComment = true;
  String _fontSize = 'Normal';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
      _notifEnabled = prefs.getBool('notifEnabled') ?? true;
      _notifStatus = prefs.getBool('notifStatus') ?? true;
      _notifComment = prefs.getBool('notifComment') ?? true;
      _fontSize = prefs.getString('fontSize') ?? 'Normal';
    });
  }

  Future<void> _saveBoolPref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _saveStringPref(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  void _toggleDarkMode(bool value) {
    setState(() {
      _isDarkMode = value;
    });
    _saveBoolPref('isDarkMode', value);
    themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        title: Text('Pengaturan', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: context.appTextPrimary)),
        iconTheme: IconThemeData(color: context.appTextPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          _buildSectionHeader('🎨 Tampilan'),
          _buildSwitchTile(
            title: 'Dark Mode',
            value: _isDarkMode,
            onChanged: _toggleDarkMode,
          ),
          ListTile(
            title: Text('Ukuran Font', style: TextStyle(color: context.appTextPrimary)),
            trailing: DropdownButton<String>(
              value: _fontSize,
              dropdownColor: context.appBackground,
              style: TextStyle(color: context.appTextPrimary),
              underline: const SizedBox(),
              items: ['Normal', 'Besar'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _fontSize = val);
                  _saveStringPref('fontSize', val);
                }
              },
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('🔔 Notifikasi'),
          _buildSwitchTile(
            title: 'Aktifkan Notifikasi',
            value: _notifEnabled,
            onChanged: (val) {
              setState(() => _notifEnabled = val);
              _saveBoolPref('notifEnabled', val);
            },
          ),
          _buildSwitchTile(
            title: 'Perubahan Status',
            value: _notifStatus,
            enabled: _notifEnabled,
            onChanged: (val) {
              setState(() => _notifStatus = val);
              _saveBoolPref('notifStatus', val);
            },
          ),
          _buildSwitchTile(
            title: 'Komentar Baru',
            value: _notifComment,
            enabled: _notifEnabled,
            onChanged: (val) {
              setState(() => _notifComment = val);
              _saveBoolPref('notifComment', val);
            },
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('ℹ️ Tentang Aplikasi'),
          ListTile(
            title: Text('Versi Aplikasi', style: TextStyle(color: context.appTextPrimary)),
            trailing: Text('2.0.0', style: TextStyle(color: context.appTextSecondary, fontWeight: FontWeight.w600)),
          ),
          ListTile(
            title: Text('Nama Developer', style: TextStyle(color: context.appTextPrimary)),
            trailing: Text('Helpdesk Team', style: TextStyle(color: context.appTextSecondary, fontWeight: FontWeight.w600)),
          ),
          ListTile(
            title: Text('Universitas', style: TextStyle(color: context.appTextPrimary)),
            trailing: Text('Universitas Airlangga', style: TextStyle(color: context.appTextSecondary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 16.0),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: AppTheme.primary,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({required String title, required bool value, required ValueChanged<bool> onChanged, bool enabled = true}) {
    return SwitchListTile(
      title: Text(title, style: TextStyle(color: enabled ? context.appTextPrimary : context.appTextMuted)),
      value: value,
      onChanged: enabled ? onChanged : null,
      activeThumbColor: AppTheme.primary,
    );
  }
}

