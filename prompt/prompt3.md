> ## Bug Fix: Assign Helpdesk Not Showing Name + "Tiket Saya" Page Empty
>
> ### Background
> Flutter E-Ticketing Helpdesk app, Clean Architecture, flutter_bloc, Supabase. App name: "Helpdesk UNAIR".
>
> ---
>
> ### Bug 1 — Assign Helpdesk Tidak Tercatat dengan Benar
>
> **Kondisi saat ini:**
> Stepping wizard di Detail Tiket sudah menunjukkan status "Ditugaskan" (dengan timestamp), TAPI section "Petugas IT" masih menampilkan **"Belum Ditugaskan"**.
>
> **Expected:**
> Setelah admin assign tiket ke helpdesk, section "Petugas IT" harus menampilkan:
> - Nama helpdesk yang ditugaskan (dari tabel `profiles.full_name`)
> - Bukan lagi "Belum Ditugaskan"
>
> **Root Cause Kemungkinan:**
> - Query `getTickets()` / `getTicketDetail()` tidak melakukan JOIN ke tabel `profiles` untuk mengambil nama dari `assigned_to`
> - Atau field `assignedToName` di entity/model ada tapi tidak di-mapping dengan benar
> - Atau UI di `TicketDetailPage` tidak membaca field tersebut, masih hardcode "Belum Ditugaskan"
>
> **Yang Perlu Diperbaiki:**
>
> 1. **`ticket_remote_data_source.dart`** — pastikan query select menyertakan join:
> ```dart
> // Saat fetch ticket detail, join ke profiles via assigned_to
> final data = await client
>     .from('tickets')
>     .select('*, assigned_profile:profiles!assigned_to(full_name)')
>     .eq('id', ticketId)
>     .single();
> ```
>
> 2. **`ticket_model.dart`** — `fromJson` harus extract nama dari hasil join:
> ```dart
> factory TicketModel.fromJson(Map<String, dynamic> json) {
>   String? assignedName;
>   if (json['assigned_profile'] != null) {
>     final profile = json['assigned_profile'];
>     assignedName = profile is Map ? profile['full_name'] : null;
>   }
>   
>   return TicketModel(
>     // ...existing fields,
>     assignedTo: json['assigned_to'],
>     assignedToName: assignedName,
>     assignedAt: json['assigned_at'] != null ? DateTime.parse(json['assigned_at']) : null,
>   );
> }
> ```
>
> 3. **`ticket.dart`** (entity) — pastikan ada field:
> ```dart
> final String? assignedTo;
> final String? assignedToName;
> final DateTime? assignedAt;
> ```
>
> 4. **`ticket_detail_page.dart`** — section "Petugas IT" harus conditional:
> ```dart
> // ❌ SEKARANG (kemungkinan hardcode)
> Text('Belum Ditugaskan')
>
> // ✅ HARUS
> Text(ticket.assignedToName ?? 'Belum Ditugaskan')
> ```
>
> 5. Setelah `AssignTicketEvent` berhasil dieksekusi (state `TicketAssigned`), **panggil ulang fetch detail tiket** agar UI langsung update dengan nama helpdesk terbaru — jangan hanya `pop()` atau diam tanpa refresh.
>
> ---
>
> ### Bug 2 — Halaman "Tiket Saya" Kosong
>
> **Kondisi saat ini:**
> Halaman "Tiket Saya" (bottom nav) menampilkan tab Aktif/Selesai/Dibatalkan, tapi **list-nya selalu kosong** — tidak ada tiket yang ditampilkan meskipun user sudah membuat tiket (terlihat dari screenshot detail tiket yang sudah ada datanya).
>
> **Expected:**
> Setiap tab harus menampilkan tiket milik user yang sedang login, sesuai status:
> - Tab **Aktif**: status `'Menunggu Antrean'`, `'Ditugaskan'`, `'Sedang Diproses'`
> - Tab **Selesai**: status `'Selesai'`
> - Tab **Dibatalkan**: status `'Dibatalkan'`
>
> **Root Cause Kemungkinan:**
> - `FetchTickets` event tidak pernah di-trigger saat halaman ini dibuka (`initState` tidak memanggil bloc)
> - Filter `eq('user_id', currentUserId)` tidak diterapkan atau salah field
> - `BlocBuilder` tidak listen ke state yang benar / state `TicketsLoaded` tidak dihandle
> - Halaman ini menggunakan widget/file yang berbeda dari `ticket_list_page.dart` yang sudah pernah dibuat sebelumnya — mungkin ada duplikasi halaman
>
> **Yang Perlu Diperiksa & Diperbaiki:**
>
> 1. Cek apakah halaman "Tiket Saya" ini adalah file `ticket_list_page.dart` yang sama, atau file baru yang terpisah. **Jika file terpisah, satukan logikanya** dengan yang sudah ada.
>
> 2. Pastikan `initState` di setiap tab content memanggil:
> ```dart
> @override
> void initState() {
>   super.initState();
>   context.read<TicketBloc>().add(FetchTickets(statusFilter: widget.statusFilter));
> }
> ```
>
> 3. Pastikan `getTickets()` di datasource benar-benar filter by `user_id`:
> ```dart
> final user = client.auth.currentUser;
> final role = user?.userMetadata?['role'] ?? 'user';
> var query = client.from('tickets').select('*, assigned_profile:profiles!assigned_to(full_name)');
>
> if (role == 'user' && user != null) {
>   query = query.eq('user_id', user.id); // pastikan ini ada
> }
> ```
>
> 4. Tambahkan **debug print sementara** untuk trace masalah:
> ```dart
> debugPrint('>>> Fetching tickets for user: ${user?.id}, role: $role, filter: $statusFilter');
> debugPrint('>>> Tickets fetched: ${data.length}');
> ```
>
> 5. Pastikan `BlocBuilder` handle semua state dengan benar — terutama state kosong vs loading vs error:
> ```dart
> if (state is TicketLoading) return ShimmerLoading...
> if (state is TicketError) return Center(child: Text(state.message)); // jangan biarkan silent fail
> if (state is TicketsLoaded) {
>   if (state.tickets.isEmpty) return Center(child: Text('Belum ada tiket.'));
>   return ListView.builder(...)
> }
> return const SizedBox(); // ini bisa jadi penyebab blank kalau state awal tidak ke-trigger
> ```
>
> ---
>
> ### Testing Checklist Setelah Fix
>
> - [ ] Admin assign tiket ke helpdesk "Budi" → Detail Tiket section "Petugas IT" langsung menampilkan "Budi", bukan "Belum Ditugaskan"
> - [ ] User buka halaman "Tiket Saya" → tab "Aktif" menampilkan tiket yang baru dibuat
> - [ ] User pindah tab "Selesai"/"Dibatalkan" → menampilkan tiket sesuai status, atau pesan "Tidak ada tiket" jika kosong
> - [ ] Pull to refresh berfungsi di semua tab
>
> ---
>
> ### Constraints
> - flutter_bloc — no setState for business logic
> - dartz Either untuk semua repository method
> - Clean Architecture
> - Semua Supabase call pakai `.timeout(const Duration(seconds: 10))`
> - Semua teks UI dalam **Bahasa Indonesia**
> - Setelah fix berhasil dan ditest, hapus semua `debugPrint` yang ditambahkan untuk debugging

---