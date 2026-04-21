import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:image_picker/image_picker.dart';
import 'package:tiketdotcom/core/theme/app_theme.dart';
import 'package:tiketdotcom/features/auth/domain/repositories/auth_repository.dart';
import 'package:tiketdotcom/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:tiketdotcom/features/auth/presentation/bloc/auth_event.dart';
import 'package:tiketdotcom/features/auth/presentation/bloc/auth_state.dart';
import 'package:tiketdotcom/features/auth/presentation/pages/login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;

  Future<void> _refresh() async => setState(() {});

  void _showEditProfileDialog(BuildContext parentContext) {
    final user = _supabase.auth.currentUser;
    final nameController = TextEditingController(text: user?.userMetadata?['full_name']);
    File? selectedImage;

    showDialog(
      context: parentContext,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Edit Profil', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final image = await picker.pickImage(source: ImageSource.gallery);
                        if (image != null) setStateDialog(() => selectedImage = File(image.path));
                      },
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                        backgroundImage: selectedImage != null ? FileImage(selectedImage!) : null,
                        child: selectedImage == null ? Icon(Icons.camera_alt_rounded, color: AppTheme.primary, size: 28) : null,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nama Lengkap', prefixIcon: Icon(Icons.person_outline))),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;
                    Navigator.pop(context);
                    setState(() => _isLoading = true);
                    parentContext.read<AuthBloc>().add(UpdateProfileRequested(fullName: nameController.text.trim(), avatarPath: selectedImage?.path));
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showChangePasswordDialog(BuildContext parentContext) {
    final passwordController = TextEditingController();
    showDialog(
      context: parentContext,
      builder: (context) => AlertDialog(
        title: Text('Ubah Password', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: TextField(controller: passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password Baru', prefixIcon: Icon(Icons.lock_outline))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (passwordController.text.length < 6) {
                ScaffoldMessenger.of(parentContext).showSnackBar(const SnackBar(content: Text('Password minimal 6 karakter')));
                return;
              }
              final authRepo = RepositoryProvider.of<AuthRepository>(parentContext);
              final result = await authRepo.updatePassword(passwordController.text);
              if (parentContext.mounted) {
                result.fold(
                  (l) => ScaffoldMessenger.of(parentContext).showSnackBar(SnackBar(content: Text(l.message))),
                  (r) => ScaffoldMessenger.of(parentContext).showSnackBar(const SnackBar(content: Text('Password berhasil diubah!'), backgroundColor: AppTheme.statusResolved)),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
              Text('Pengaturan Notifikasi', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              SwitchListTile(title: const Text('Notifikasi Tiket Baru'), subtitle: const Text('Dapatkan info saat helpdesk merespon'), value: true, onChanged: (v) {}),
              SwitchListTile(title: const Text('Update Status'), subtitle: const Text('Info saat status tiket berubah'), value: true, onChanged: (v) {}),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, height: 48, child: ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Selesai'))),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext parentContext) {
    showDialog(
      context: parentContext,
      builder: (context) => AlertDialog(
        title: Text('Konfirmasi', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.statusCancelled),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (parentContext.mounted) {
                parentContext.read<AuthBloc>().add(LogoutRequested());
                Navigator.of(parentContext).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginPage()), (route) => false);
              }
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _supabase.auth.currentUser;
    final fullName = user?.userMetadata?['full_name'] ?? 'User';
    final email = user?.email ?? '-';
    final avatarUrl = user?.userMetadata?['avatar_url'];

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess && (ModalRoute.of(context)?.isCurrent ?? false)) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil berhasil diperbarui.'), backgroundColor: AppTheme.statusResolved));
        } else if (state is AuthFailure && (ModalRoute.of(context)?.isCurrent ?? false)) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppTheme.statusCancelled));
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: AppTheme.background,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    const SizedBox(height: 8),
                    // Avatar + info
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 44,
                            backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                            child: avatarUrl == null
                                ? Text(fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U',
                                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppTheme.primary))
                                : null,
                          ),
                          const SizedBox(height: 16),
                          Text(fullName, style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                          const SizedBox(height: 4),
                          Text(email, style: TextStyle(color: AppTheme.primaryDark, fontSize: 14)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Menu items (matching reference)
                    _ProfileMenuItem(
                      title: 'Feed',
                      subtitle: 'Track your all ticket',
                      onTap: () {},
                    ),
                    _ProfileMenuItem(
                      title: 'Dashboard',
                      subtitle: 'See all analytic of your Ticket',
                      onTap: () => Navigator.pop(context),
                    ),
                    _ProfileMenuItem(
                      title: 'Edit Profil',
                      subtitle: 'Change name and photo',
                      onTap: () => _showEditProfileDialog(context),
                    ),
                    _ProfileMenuItem(
                      title: 'Ubah Password',
                      subtitle: 'Change your password',
                      onTap: () => _showChangePasswordDialog(context),
                    ),
                    _ProfileMenuItem(
                      title: 'Notifications Settings',
                      subtitle: 'Setting your notification',
                      onTap: () => _showNotificationSettings(context),
                    ),

                    const SizedBox(height: 16),
                    // Logout
                    _ProfileMenuItem(
                      title: 'Keluar Aplikasi',
                      subtitle: 'Logout from account',
                      isDestructive: true,
                      onTap: () => _showLogoutDialog(context),
                    ),

                    const SizedBox(height: 40),
                    // Version
                    Center(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Helpdesk', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.primary)),
                              const SizedBox(width: 3),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(color: AppTheme.primaryDark, borderRadius: BorderRadius.circular(4)),
                                child: Text('Desk', style: GoogleFonts.plusJakartaSans(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Version 1.0.0', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool isDestructive;

  const _ProfileMenuItem({required this.title, required this.subtitle, this.onTap, this.isDestructive = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: GoogleFonts.plusJakartaSans(
                        fontSize: 15, fontWeight: FontWeight.w700,
                        color: isDestructive ? AppTheme.statusCancelled : AppTheme.textPrimary,
                      )),
                      const SizedBox(height: 2),
                      Text(subtitle, style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                    ],
                  ),
                ),
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: isDestructive ? AppTheme.statusCancelledBg : AppTheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: isDestructive ? AppTheme.statusCancelled : AppTheme.primary,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
