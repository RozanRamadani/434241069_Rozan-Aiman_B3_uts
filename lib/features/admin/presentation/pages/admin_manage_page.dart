import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tiketdotcom/core/theme/app_theme.dart';
import 'package:tiketdotcom/features/admin/presentation/pages/admin_category_page.dart';
import 'package:tiketdotcom/features/auth/presentation/pages/admin_user_management_page.dart';
import 'package:tiketdotcom/features/admin/presentation/pages/admin_report_page.dart';

class AdminManagePage extends StatelessWidget {
  const AdminManagePage({super.key});

  Widget _buildMenuTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.appCardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appBorder),
        boxShadow: context.appSoftShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          title: Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: context.appTextPrimary,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: context.appTextSecondary,
              ),
            ),
          ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: context.appTextMuted,
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Kelola',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            color: context.isDark ? Colors.white : AppTheme.primaryDark,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildMenuTile(
            context,
            icon: Icons.category_rounded,
            title: 'Kategori Masalah',
            subtitle: 'Tambah, edit, hapus kategori tiket',
            color: const Color(0xFFFF6B35),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminCategoryPage()),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildMenuTile(
            context,
            icon: Icons.people_alt_rounded,
            title: 'Manajemen Pengguna',
            subtitle: 'Aktifkan / nonaktifkan akun pengguna',
            color: const Color(0xFF4A90D9),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminUserManagementPage()),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildMenuTile(
            context,
            icon: Icons.analytics_rounded,
            title: 'Laporan & Statistik',
            subtitle: 'Ringkasan performa helpdesk & laporan',
            color: const Color(0xFF50C878),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminReportPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}
