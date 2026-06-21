> ## Fix & Feature Completion: Helpdesk UNAIR (Final Sprint)
>
> ### Context
> Flutter E-Ticketing Helpdesk app dengan stack:
> - Flutter + flutter_bloc + Clean Architecture
> - Supabase (Auth + PostgreSQL + Realtime + Storage)
> - dartz (`Either<Failure, T>`)
> - Package: intl, cached_network_image, image_picker, shimmer, flutter_dotenv, flutter_local_notifications, shared_preferences
>
> ### Database Info
> ```
> tickets:
>   id, title, description, category, status,
>   created_at, user_id, attachment_url,
>   assigned_to, assigned_at, accepted_at,
>   resolved_at, cancelled_at
>
> ticket_history:
>   id, ticket_id, user_id, old_status,
>   new_status, changed_at
>   ← Sudah ada Postgres Trigger otomatis insert saat status berubah
>
> profiles:
>   id, full_name, role, updated_at, is_active
>
> notifications:
>   id, user_id, ticket_id, title, message,
>   is_read, created_at
> ```
>
> ---
>
> ## Tasks
>
> ### Task 1 — Optimasi Stream Dashboard (30 menit)
> **File:** `dashboard_page.dart`
>
> **Masalah:** Stream mengambil semua record tiket tanpa limit, memberatkan bandwidth dan memori saat data banyak.
>
> **Yang perlu dilakukan:**
> - Batasi stream hanya mengambil **50 record terbaru**
> - Untuk statistik (count), gunakan query terpisah yang hanya ambil kolom `status` saja (bukan semua kolom)
> - Pisahkan query statistik dan query list tiket terbaru:
> ```dart
> // Query statistik — ambil kolom status saja
> final stats = await supabase
>   .from('tickets')
>   .select('status')
>   .eq('user_id', userId); // filter sesuai role
>
> // Query list terbaru — limit 10 untuk preview dashboard
> final recent = await supabase
>   .from('tickets')
>   .select()
>   .order('created_at', ascending: false)
>   .limit(10);
> ```
> - Tampilkan shimmer loading selama query berjalan
>
> ---
>
> ### Task 2 — Force Change Status oleh Admin (1 jam)
> **File:** `ticket_detail_page.dart`
>
> **Masalah:** Admin hanya bisa assign helpdesk, tapi tidak bisa force-change status tiket secara manual.
>
> **Yang perlu dilakukan:**
> - Tambahkan tombol **"Ubah Status"** di AppBar atau bottom section — hanya untuk role `admin`
> - Tombol ini membuka `ModalBottomSheet` berisi pilihan status:
> ```
> ○ Menunggu Antrean
> ○ Ditugaskan
> ○ Sedang Diproses
> ○ Selesai
> ○ Dibatalkan
> ```
> - Status yang sedang aktif diberi tanda centang ✓
> - Setelah dipilih → konfirmasi dialog → update status via `UpdateStatusEvent`
> - Sembunyikan tombol ini jika status sudah `'Selesai'` atau `'Dibatalkan'`
> - Teks UI dalam Bahasa Indonesia
>
> ---
>
> ### Task 3 — Lazy Loading / Pagination (2 jam)
> **File:** `ticket_list_page.dart`, `ticket_remote_data_source.dart`, `ticket_repository.dart`, `ticket_repository_impl.dart`
>
> **Masalah:** Semua tiket diambil sekaligus tanpa pagination.
>
> **Yang perlu dilakukan:**
> - Implementasi **cursor-based pagination** menggunakan `created_at` sebagai cursor
> - Load **20 tiket per halaman**
> - Di `ticket_list_page.dart`:
>   - Gunakan `ScrollController` untuk deteksi scroll mendekati bawah
>   - Saat scroll ke bawah → trigger load more
>   - Tampilkan `CircularProgressIndicator` kecil di bawah list saat loading more
>   - Tampilkan pesan "Semua tiket sudah dimuat" saat tidak ada data lagi
> - Update method `getTickets()` di datasource:
> ```dart
> Future<List<TicketModel>> getTickets({
>   String? statusFilter,
>   DateTime? cursor,      // untuk pagination
>   int limit = 20,
> })
> ```
> - Update `FetchTickets` event:
> ```dart
> class FetchTickets extends TicketEvent {
>   final String? statusFilter;
>   final DateTime? cursor;
>   final bool isLoadMore;  // true = load halaman berikutnya
> }
> ```
> - Update `TicketsLoaded` state:
> ```dart
> class TicketsLoaded extends TicketState {
>   final List<Ticket> tickets;
>   final bool hasMore;  // masih ada data berikutnya?
> }
> ```
>
> ---
>
> ### Task 4 — Notification Service (3 jam)
> **File:** `notification_service.dart`, `main.dart`, `main_nav_page.dart`
>
> **Masalah:** `notification_service.dart` sudah ada tapi method-nya masih kosong/stub.
>
> **Yang perlu dilakukan:**
>
> **4a. Implementasi `notification_service.dart`:**
> ```dart
> class NotificationService {
>   // 1. Init flutter_local_notifications
>   Future<void> init() async {
>     // Setup Android notification channel
>     // Setup iOS permissions
>   }
>
>   // 2. Tampilkan local notification
>   Future<void> showNotification({
>     required String title,
>     required String body,
>     String? payload, // ticket_id untuk navigasi
>   }) async {}
>
>   // 3. Listen ke tabel notifications via Supabase Realtime
>   void listenToNotifications(String userId) {
>     supabase
>       .from('notifications')
>       .stream(primaryKey: ['id'])
>       .eq('user_id', userId)
>       .listen((data) {
>         // Filter hanya yang is_read = false dan baru
>         // Panggil showNotification()
>       });
>   }
>
>   // 4. Mark as read
>   Future<void> markAsRead(String notificationId) async {}
>
>   // 5. Dispose / cancel subscription
>   void dispose() {}
> }
> ```
>
> **4b. Pastikan `NotificationService` diinisialisasi di `main.dart`:**
> ```dart
> void main() async {
>   WidgetsFlutterBinding.ensureInitialized();
>   await NotificationService().init(); // tambahkan ini
>   // ... rest of main
> }
> ```
>
> **4c. Start listening setelah user login di `main_nav_page.dart`:**
> ```dart
> @override
> void initState() {
>   super.initState();
>   final userId = Supabase.instance.client.auth.currentUser?.id;
>   if (userId != null) {
>     NotificationService().listenToNotifications(userId);
>   }
> }
> ```
>
> **4d. Update `notification_page.dart`:**
> - Saat notifikasi dibuka → panggil `markAsRead()` untuk semua notifikasi yang ditampilkan
> - Tampilkan badge indicator (titik biru) untuk notifikasi yang belum dibaca (`is_read = false`)
> - Bedakan visual antara notifikasi **belum dibaca** (background lebih terang) dan **sudah dibaca**
>
> ---
>
> ### Task 5 — Log Aktivitas Pengguna (1 jam)
> **File:** `ticket_remote_data_source.dart`
>
> **Masalah:** Belum ada log aktivitas pengguna selain perubahan status (yang sudah dihandle trigger).
>
> **Yang perlu dilakukan:**
> - Buat tabel baru di Supabase (berikan SQL-nya):
> ```sql
> CREATE TABLE IF NOT EXISTS activity_logs (
>   id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
>   user_id uuid REFERENCES auth.users(id),
>   ticket_id uuid REFERENCES tickets(id) NULL,
>   action text NOT NULL,
>   description text,
>   created_at timestamptz DEFAULT now()
> );
> ```
> - Tambahkan method `logActivity()` di datasource:
> ```dart
> Future<void> logActivity({
>   required String action,
>   String? ticketId,
>   String? description,
> }) async {
>   await client.from('activity_logs').insert({
>     'user_id': client.auth.currentUser?.id,
>     'ticket_id': ticketId,
>     'action': action,
>     'description': description,
>   });
> }
> ```
> - Panggil `logActivity()` setelah aksi-aksi penting:
>   - User buat tiket → `action: 'CREATE_TICKET'`
>   - User batalkan tiket → `action: 'CANCEL_TICKET'`
>   - Helpdesk terima tiket → `action: 'ACCEPT_TICKET'`
>   - Helpdesk selesaikan tiket → `action: 'RESOLVE_TICKET'`
>   - Admin assign tiket → `action: 'ASSIGN_TICKET'`
>   - Admin hapus tiket → `action: 'DELETE_TICKET'`
>   - Admin nonaktifkan user → `action: 'DEACTIVATE_USER'`
>
> ---
>
> ### Task 6 — Dark & Light Mode (1 jam)
> **File:** `main.dart`, `setting_page.dart`, `app_theme.dart`
>
> **Masalah:** Dark & Light mode belum diimplementasi — app hanya punya satu tema.
>
> **Yang perlu dilakukan:**
>
> **6a. Buat `ThemeNotifier` di `main.dart`:**
> ```dart
> final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);
>
> void main() async {
>   // Load saved theme dari SharedPreferences
>   final prefs = await SharedPreferences.getInstance();
>   final savedTheme = prefs.getString('theme_mode') ?? 'system';
>   themeNotifier.value = switch(savedTheme) {
>     'light' => ThemeMode.light,
>     'dark'  => ThemeMode.dark,
>     _       => ThemeMode.system,
>   };
>   runApp(const TicketingApp());
> }
> ```
>
> **6b. Update `MaterialApp` di `main.dart`:**
> ```dart
> return ValueListenableBuilder<ThemeMode>(
>   valueListenable: themeNotifier,
>   builder: (context, themeMode, _) {
>     return MaterialApp(
>       themeMode: themeMode,
>       theme: AppTheme.lightTheme,     // definisikan di app_theme.dart
>       darkTheme: AppTheme.darkTheme,  // definisikan di app_theme.dart
>       ...
>     );
>   },
> );
> ```
>
> **6c. Update `app_theme.dart` — definisikan light & dark theme:**
> ```dart
> class AppTheme {
>   // Light Theme
>   static ThemeData get lightTheme => ThemeData(
>     useMaterial3: true,
>     brightness: Brightness.light,
>     colorScheme: ColorScheme.fromSeed(
>       seedColor: primary,
>       brightness: Brightness.light,
>     ),
>     // ... warna & styling
>   );
>
>   // Dark Theme
>   static ThemeData get darkTheme => ThemeData(
>     useMaterial3: true,
>     brightness: Brightness.dark,
>     colorScheme: ColorScheme.fromSeed(
>       seedColor: primary,
>       brightness: Brightness.dark,
>     ),
>     // ... warna & styling yang sesuai dark mode
>   );
> }
> ```
>
> **6d. Update `setting_page.dart` — toggle dark mode:**
> ```dart
> // Toggle theme
> void _changeTheme(ThemeMode mode) async {
>   themeNotifier.value = mode;
>   final prefs = await SharedPreferences.getInstance();
>   await prefs.setString('theme_mode', switch(mode) {
>     ThemeMode.light  => 'light',
>     ThemeMode.dark   => 'dark',
>     ThemeMode.system => 'system',
>   });
> }
>
> // UI — 3 pilihan tema
> ListTile(
>   title: const Text('Tema Aplikasi'),
>   subtitle: Text(currentTheme),
>   trailing: SegmentedButton<ThemeMode>(
>     segments: const [
>       ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode)),
>       ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.smartphone)),
>       ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode)),
>     ],
>     selected: {themeNotifier.value},
>     onSelectionChanged: (val) => _changeTheme(val.first),
>   ),
> ),
> ```
>
> **6e. Pastikan semua widget menggunakan warna dari `Theme.of(context)` bukan hardcode:**
> ```dart
> // ❌ Hindari
> color: Colors.white
> color: Colors.black
> backgroundColor: Color(0xFF...)
>
> // ✅ Gunakan
> color: Theme.of(context).colorScheme.surface
> color: Theme.of(context).colorScheme.onSurface
> color: Theme.of(context).colorScheme.primary
> ```
>
> ---
>
> ## Constraints
> - flutter_bloc — no setState for business logic
> - dartz Either untuk semua repository method
> - Clean Architecture
> - Semua Supabase call pakai `.timeout(const Duration(seconds: 10))`
> - Semua teks UI dalam **Bahasa Indonesia**
> - Gunakan `withValues(alpha: x)` bukan `withOpacity(x)`
> - Selalu `if (!mounted) return` sebelum navigasi setelah async
> - Jalankan `flutter analyze` setelah setiap task selesai
> - Jangan hapus fitur yang sudah ada
>
> ## Instruksi
> 1. Kerjakan **satu task per satu** secara berurutan (Task 1 → 2 → 3 → 4 → 5 → 6)
> 2. Jalankan `flutter analyze` setelah setiap task
> 3. Setelah semua selesai, buat **summary** file apa saja yang diubah
> 4. Untuk Task 5, berikan SQL yang perlu dijalankan di Supabase sebelum mulai coding
