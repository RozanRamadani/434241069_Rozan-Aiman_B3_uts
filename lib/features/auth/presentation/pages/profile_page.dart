import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:image_picker/image_picker.dart';
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

  Future<void> _refresh() async {
    setState(() {});
  }

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
              title: const Text('Edit Profil'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final ImagePicker picker = ImagePicker();
                        final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                        if (image != null) {
                          setStateDialog(() {
                            selectedImage = File(image.path);
                          });
                        }
                      },
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: selectedImage != null ? FileImage(selectedImage!) : null,
                        child: selectedImage == null
                            ? const Icon(Icons.camera_alt, color: Colors.grey, size: 30)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nama Lengkap', border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;
                    
                    Navigator.pop(context); // Close dialog
                    setState(() => _isLoading = true);

                    parentContext.read<AuthBloc>().add(
                      UpdateProfileRequested(
                        fullName: nameController.text.trim(),
                        avatarPath: selectedImage?.path,
                      ),
                    );
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
        title: const Text('Ubah Password'),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Password Baru', border: OutlineInputBorder()),
        ),
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
                  (r) => ScaffoldMessenger.of(parentContext).showSnackBar(const SnackBar(content: Text('Password berhasil diubah!'))),
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
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pengaturan Notifikasi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Notifikasi Tiket Baru'),
              subtitle: const Text('Dapatkan info saat helpdesk merespon'),     
              value: true,
              onChanged: (v) {},
            ),
            SwitchListTile(
              title: const Text('Update Status'),
              subtitle: const Text('Info saat status tiket berubah'),
              value: true,
              onChanged: (v) {},
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Selesai')),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext parentContext) {
    showDialog(
      context: parentContext,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (parentContext.mounted) {
                parentContext.read<AuthBloc>().add(LogoutRequested());
                Navigator.of(parentContext).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),   
                  (route) => false,
                );
              }
            },
            child: const Text('Keluar', style: TextStyle(color: Colors.red)),   
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem(BuildContext context, {required IconData icon, required String title, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
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
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil berhasil diperbarui.'), backgroundColor: Colors.green));
        } else if (state is AuthFailure && (ModalRoute.of(context)?.isCurrent ?? false)) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Profil Saya')),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _refresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.blue,
                        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                        child: avatarUrl == null ? const Icon(Icons.person, size: 60, color: Colors.white) : null,
                      ),
                      const SizedBox(height: 16),
                      Text(fullName, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                      Text(email),
                      const SizedBox(height: 32),
                      _buildProfileItem(
                        context,
                        icon: Icons.person_outline,
                        title: 'Edit Profil',
                        onTap: () => _showEditProfileDialog(context),
                      ),
                      _buildProfileItem(
                        context,
                        icon: Icons.lock_outline,
                        title: 'Ubah Password',
                        onTap: () => _showChangePasswordDialog(context),
                      ),
                      _buildProfileItem(
                        context,
                        icon: Icons.notifications_none,
                        title: 'Pengaturan Notifikasi',
                        onTap: () => _showNotificationSettings(context),
                      ),
                      const Divider(height: 40),
                      ListTile(
                        leading: const Icon(Icons.logout, color: Colors.red),
                        title: const Text('Keluar Aplikasi', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        onTap: () => _showLogoutDialog(context),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

