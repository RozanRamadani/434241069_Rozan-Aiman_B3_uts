import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tiketdotcom/core/theme/app_theme.dart';

class AdminUserManagementPage extends StatefulWidget {
  const AdminUserManagementPage({super.key});

  @override
  State<AdminUserManagementPage> createState() => _AdminUserManagementPageState();
}

class _AdminUserManagementPageState extends State<AdminUserManagementPage> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _users = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      // we query the profiles table
      final data = await _supabase.from('profiles').select().order('full_name');
      setState(() {
        _users = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat pengguna: $e')));
      }
    }
  }

  Future<void> _toggleUserStatus(String userId, bool currentStatus) async {
    try {
      // Assuming there is an 'is_active' boolean column in 'profiles'.
      // If it doesn't exist, this will throw an error, which we catch.
      await _supabase.from('profiles').update({'is_active': !currentStatus}).eq('id', userId);
      
      setState(() {
        final index = _users.indexWhere((u) => u['id'] == userId);
        if (index != -1) {
          _users[index]['is_active'] = !currentStatus;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status pengguna berhasil diubah'), backgroundColor: AppTheme.statusResolved));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengubah status. Pastikan kolom is_active ada di tabel profiles. Error: $e'), backgroundColor: AppTheme.statusCancelled));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _users.where((u) {
      final name = (u['full_name'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Kelola Pengguna', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: AppTheme.primaryDark)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppTheme.radiusPill)),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Cari nama pengguna...',
                        hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                        border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      final bool isActive = user['is_active'] ?? true; // fallback to true if null
                      final String role = user['role'] ?? 'user';
                      final String initial = (user['full_name'] ?? 'U').toString().isNotEmpty ? (user['full_name'] ?? 'U').toString()[0].toUpperCase() : 'U';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppTheme.softShadow),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                              child: Text(initial, style: TextStyle(color: AppTheme.primaryDark, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(user['full_name'] ?? 'Unknown', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15)),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: role == 'admin' ? Colors.red[50] : (role == 'helpdesk' ? Colors.blue[50] : Colors.green[50]),
                                      borderRadius: BorderRadius.circular(4)
                                    ),
                                    child: Text(
                                      role.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10, fontWeight: FontWeight.bold,
                                        color: role == 'admin' ? Colors.red : (role == 'helpdesk' ? Colors.blue : Colors.green)
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                            Switch(
                              value: isActive,
                              activeThumbColor: AppTheme.primary,
                              onChanged: role == 'admin' ? null : (v) => _showToggleDialog(user['id'], user['full_name'], isActive),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showToggleDialog(String userId, String name, bool currentStatus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konfirmasi', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: Text('Anda yakin ingin ${currentStatus ? 'menonaktifkan' : 'mengaktifkan'} pengguna $name?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _toggleUserStatus(userId, currentStatus);
            },
            child: const Text('Ya'),
          ),
        ],
      ),
    );
  }
}
