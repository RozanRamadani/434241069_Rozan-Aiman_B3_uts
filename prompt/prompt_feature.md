> ## Feature Completion Request: Helpdesk UNAIR Flutter App (SRS v2.0.0)
>
> ### Context
> Saya memiliki Flutter E-Ticketing Helpdesk app yang sudah berjalan dengan stack:
> - Flutter + flutter_bloc + Clean Architecture
> - Supabase (Auth + PostgreSQL + Realtime + Storage)
> - dartz (`Either<Failure, T>`)
> - Package: intl, cached_network_image, image_picker, shimmer, flutter_dotenv, flutter_local_notifications
>
> ### Database Schema Saat Ini
> ```
> tickets:
>   id, title, description, category, status,
>   created_at, user_id, attachment_url,
>   assigned_to (uuid), assigned_at,
>   accepted_at, resolved_at, cancelled_at
>
> ticket_comments:
>   id, ticket_id, user_id, message, created_at
>
> profiles:
>   id, full_name, role (default: 'user'), updated_at, is_active (boolean, default: true)
>
> notifications:
>   id, user_id, ticket_id, title, message, is_read, created_at
> ```
>
> ### Ticket Status Values
> ```
> 'Menunggu Antrean' → 'Ditugaskan' → 'Sedang Diproses' → 'Selesai'
> ATAU → 'Dibatalkan'
> ```
>
> ### Role-Based Access
> ```
> User     → buat tiket, lihat tiket milik sendiri, komentar, batalkan
> Helpdesk → buat tiket, lihat & tangani tiket yang ditugaskan kepadanya saja
> Admin    → buat tiket, lihat semua tiket, assign helpdesk, kelola pengguna
> ```
>
> ---
>
> ## Features to Implement
>
> ### 1. Helpdesk & Admin Bisa Buat Tiket (FR-006, FR-007)
> **Yang perlu dilakukan:**
> - Tampilkan tombol/FAB "Buat Tiket" untuk role `helpdesk` dan `admin` (saat ini hanya `user`)
> - Saat helpdesk/admin buat tiket, `user_id` tetap diisi dengan id mereka sendiri
> - Di `dashboard_page.dart`, update kondisi FAB:
> ```dart
> // Sekarang
> floatingActionButton: role == 'user' ? FAB : null
>
> // Harusnya
> floatingActionButton: FAB // semua role bisa buat tiket
> ```
>
> ### 2. Helpdesk Hanya Lihat Tiket yang Ditugaskan Kepadanya (FR-006)
> **Yang perlu dilakukan:**
> - Di `ticket_remote_data_source.dart`, update query `getTickets()`:
> ```dart
> // Sekarang
> if (role == 'user') query = query.eq('user_id', user.id);
> // role lain lihat semua tiket
>
> // Harusnya
> if (role == 'user') {
>   query = query.eq('user_id', user.id);
> } else if (role == 'helpdesk') {
>   query = query.eq('assigned_to', user.id); // hanya tiket yang di-assign ke dia
> }
> // admin tetap lihat semua
> ```
> - Update juga query di `dashboard_page.dart` stream untuk helpdesk
>
> ### 3. Setting Screen (SRS 5.12)
> **Buat file baru:** `lib/features/settings/presentation/pages/setting_page.dart`
>
> **Konten Setting Screen:**
> ```
> ⚙️ Pengaturan
>
> 🎨 Tampilan
>   - Dark Mode toggle (simpan ke SharedPreferences)
>   - Ukuran font (Normal / Besar)
>
> 🔔 Notifikasi
>   - Aktifkan notifikasi (toggle)
>   - Notifikasi perubahan status (toggle)
>   - Notifikasi komentar baru (toggle)
>
> ℹ️ Tentang Aplikasi
>   - Versi aplikasi
>   - Nama developer
>   - Universitas: Universitas Airlangga
> ```
> - Tambahkan package `shared_preferences` untuk simpan preferensi
> - Hubungkan dark mode toggle ke `ThemeMode` di `main.dart`
> - Tambahkan navigasi ke Setting dari `profile_page.dart`
>
> ### 4. Filter Tiket Per Helpdesk (Admin) (FR-007 point 3)
> **Di `ticket_list_page.dart` atau halaman khusus admin:**
> - Tambahkan dropdown filter "Lihat berdasarkan Helpdesk"
> - Dropdown berisi daftar helpdesk dari `profiles` where `role = 'helpdesk'`
> - Saat dipilih → filter tiket berdasarkan `assigned_to = helpdesk.id`
> - Ada opsi "Semua Helpdesk" untuk reset filter
>
> ### 5. Dashboard Statistik Lengkap (FR-009)
> **Update `dashboard_page.dart`** — stat cards harus mencakup:
> ```dart
> // Status yang perlu dihitung
> final openCount      = tickets.where((t) => t['status'] == 'Menunggu Antrean').length;
> final assignedCount  = tickets.where((t) => t['status'] == 'Ditugaskan').length;
> final progressCount  = tickets.where((t) => t['status'] == 'Sedang Diproses').length;
> final closedCount    = tickets.where((t) => t['status'] == 'Selesai').length;
> final cancelledCount = tickets.where((t) => t['status'] == 'Dibatalkan').length;
> final totalCount     = tickets.length;
> ```
> **Layout stat cards:**
> ```
> [Total]        [Open]
> [Ditugaskan]   [Sedang Diproses]
> [Selesai]      [Dibatalkan]
> ```
>
> ### 6. Delete Tiket (BR-002)
> **Yang perlu dilakukan:**
> - Tambahkan method `deleteTicket(String ticketId)` di datasource & repository
> - Tambahkan `DeleteTicketEvent` di `ticket_event.dart`
> - Tambahkan `TicketDeleted` state di `ticket_state.dart`
> - Handle di `ticket_bloc.dart`
> - Di `ticket_detail_page.dart`:
>   - Tampilkan tombol delete **hanya untuk Admin**
>   - Tampilkan confirmation dialog sebelum delete
>   - Setelah delete berhasil → `Navigator.pop()` kembali ke list
>
> ### 7. Forgot Password Jadi Halaman Terpisah (SRS 5.4)
> **Saat ini:** Reset password hanya berupa dialog popup di LoginPage
> **Yang diinginkan:** Halaman terpisah `forgot_password_page.dart`
>
> **Konten halaman:**
> ```
> ← Kembali
>
> 🔑 Lupa Password
> "Masukkan email Anda dan kami akan mengirimkan link untuk reset password"
>
> [Email TextField]
>
> [Tombol "Kirim Link Reset"]
>
> Loading state saat proses kirim
> Success state: "Email berhasil dikirim! Cek inbox Anda."
> Error state: tampilkan pesan error
> ```
> - Update `login_page.dart`: ganti `_showResetPasswordDialog()` dengan navigasi ke `ForgotPasswordPage`
> - Gunakan `AuthBloc` yang sudah ada dengan event `ResetPasswordSubmitted`
>
> ### 8. Statistik Khusus Helpdesk (FR-006 point 7)
> **Di dashboard helpdesk**, tampilkan statistik hanya untuk tiket yang ditugaskan kepadanya:
> ```
> [Total Ditugaskan]   [Sedang Diproses]
> [Selesai]            [Menunggu Diterima]
> ```
> Dashboard harus menampilkan data berbeda berdasarkan role — gunakan kondisi:
> ```dart
> if (role == 'helpdesk') {
>   // filter stream by assigned_to == currentUser.id
> } else if (role == 'admin') {
>   // tampilkan semua tiket
> } else {
>   // filter by user_id == currentUser.id
> }
> ```
>
> ---
>
> ## Constraints
> - **flutter_bloc** — no setState for business logic
> - **dartz** Either untuk semua repository method
> - **Clean Architecture** — setiap layer hanya akses layer di bawahnya
> - Semua Supabase call pakai `.timeout(const Duration(seconds: 10))`
> - Semua teks UI dalam **Bahasa Indonesia**
> - Gunakan `withValues(alpha: x)` bukan deprecated `withOpacity(x)`
> - Selalu `if (!mounted) return` sebelum navigasi setelah async
> - Tambahkan `shared_preferences` ke `pubspec.yaml` jika belum ada
> - Ikuti naming convention yang sudah ada di project
>
> ---
>
> ## Instructions
> 1. **Baca semua file yang relevan dulu** sebelum mulai edit
> 2. Kerjakan **satu fitur per satu** secara berurutan sesuai urutan di atas
> 3. Setelah setiap fitur selesai, **jalankan `flutter analyze`** untuk cek error
> 4. Jika ada breaking change di file lain, update juga
> 5. Setelah semua selesai, buat **summary** apa saja yang sudah dikerjakan dan file apa saja yang diubah
> 6. **Jangan hapus fitur yang sudah ada** — hanya tambah dan perbaiki

---