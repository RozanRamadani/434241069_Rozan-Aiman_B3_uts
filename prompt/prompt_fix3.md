
### Prompt untuk AI Text Editor

> ## Fix Profile Page: Helpdesk UNAIR
>
> ### Issues to Fix
>
> **1. Fix Menu "Feed"**
> Arahkan ke halaman Riwayat Tiket (`HistoryPage` atau `TicketListPage`):
> ```dart
> // Ganti
> onTap: () {}
> // Jadi
> onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TicketListPage()))
> ```
>
> **2. Fix Menu "Dashboard"**
> ```dart
> // Ganti
> onTap: () => Navigator.pop(context)
> // Jadi — pop sampai ke root (dashboard)
> onTap: () => Navigator.of(context).popUntil((route) => route.isFirst)
> ```
>
> **3. Terjemahkan semua subtitle ke Bahasa Indonesia**
> ```dart
> 'Track your all ticket'          → 'Lacak semua tiket Anda'
> 'See all analytic of your Ticket'→ 'Lihat ringkasan tiket Anda'
> 'Change name and photo'          → 'Ubah nama dan foto profil'
> 'Change your password'           → 'Ganti kata sandi akun'
> 'Logout from account'            → 'Keluar dari akun'
> ```
>
> **4. Fix avatar tidak update setelah edit profil**
> Di `BlocListener`, setelah `AuthSuccess`, tambahkan refresh session:
> ```dart
> if (state is AuthSuccess) {
>   await _supabase.auth.refreshSession(); // tambahkan ini
>   setState(() => _isLoading = false);
>   ScaffoldMessenger.of(context).showSnackBar(...);
> }
> ```
>
> **5. Tambahkan Role Badge di bawah nama user**
> ```dart
> // Di bawah Text(email), tambahkan:
> const SizedBox(height: 8),
> Container(
>   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
>   decoration: BoxDecoration(
>     color: _getRoleColor(role).withValues(alpha: 0.1),
>     borderRadius: BorderRadius.circular(20),
>   ),
>   child: Text(
>     _getRoleLabel(role),
>     style: TextStyle(
>       fontSize: 12,
>       fontWeight: FontWeight.w700,
>       color: _getRoleColor(role),
>     ),
>   ),
> ),
>
> // Helper methods:
> Color _getRoleColor(String role) {
>   return switch (role) {
>     'admin'    => Colors.purple,
>     'helpdesk' => Colors.blue,
>     _          => Colors.green,
>   };
> }
>
> String _getRoleLabel(String role) {
>   return switch (role) {
>     'admin'    => '👑 Admin',
>     'helpdesk' => '🛠️ Helpdesk',
>     _          => '👤 User',
>   };
> }
> ```
>
> **6. Fix `_refresh()` agar benar-benar refresh data**
> ```dart
> Future<void> _refresh() async {
>   await _supabase.auth.refreshSession();
>   if (mounted) setState(() {});
> }
> ```
>
> **7. Sembunyikan menu "Kelola Pengguna" dengan animasi yang lebih rapi**
> Tambahkan `AnimatedSwitcher` atau `Visibility` widget agar tidak ada lompatan layout:
> ```dart
> Visibility(
>   visible: role == 'admin',
>   child: _ProfileMenuItem(
>     title: 'Kelola Pengguna',
>     subtitle: 'Aktifkan atau non-aktifkan akun pengguna',
>     onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminUserManagementPage())),
>   ),
> ),
> ```
>
> ### Constraints
> - Semua teks UI dalam **Bahasa Indonesia**
> - Gunakan `withValues(alpha: x)` bukan `withOpacity(x)`
> - Selalu `if (!mounted) return` sebelum setState setelah async
> - Jangan hapus fitur yang sudah ada
> - Jalankan `flutter analyze` setelah selesai
