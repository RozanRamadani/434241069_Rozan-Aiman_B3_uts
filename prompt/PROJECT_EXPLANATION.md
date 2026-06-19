# Penjelasan Proyek "tiketdotcom" (E-Ticketing Helpdesk Mobile Application)

Berikut adalah penjelasan komprehensif mengenai proyek **"tiketdotcom"** yang dibagi menjadi dua bagian utama: **Alur Aplikasi (Flow)** dan **Struktur Kode (Architecture)**.

---

### 1. Pendahuluan Proyek
Aplikasi ini dikembangkan menggunakan **Flutter** dan bertujuan untuk menjadi aplikasi *Helpdesk e-Ticketing*. Proyek ini mengadopsi pilar-pilar pengembangan aplikasi modern, di antaranya:
- **Backend as a Service (BaaS):** Menggunakan **Supabase** untuk Autentikasi dan Database.
- **State Management:** Menggunakan **BLoC (Business Logic Component)** untuk memisahkan urusan UI dengan logika bisnis.
- **Arsitektur:** Mengadopsi prinsip **Clean Architecture (Feature-Driven)** guna menjaga kode tetap rapi, dapat diskalakan (*scalable*), dan mudah dipelihara (*maintainable*).

---

### 2. Alur Aplikasi (App Flow)
Alur aplikasi ini berjalan mulai dari pengguna membuka aplikasi hingga masuk ke halaman utama:

1. **Inisialisasi (`main.dart`)**
   - Fungsi `main()` dijalankan. Hal pertama yang dilakukan adalah menginisialisasi perutean platform dan membungkus error (*error handling*) dari UI thread maupun Background thread agar aplikasi tidak langsung terhenti jika terkena *crash*.
   - **Inisialisasi Supabase:** Aplikasi melakukan koneksi ke server Supabase (melalui URL dan anon key) secara *asynchronous*.
   - Aplikasi merender `TicketingApp`.
2. **Provider & Dependency Injection (DI)**
   - Saat dirender, aplikasi mendaftarkan *Repository* (`AuthRepository`, `TicketRepository`) menggunakan `MultiRepositoryProvider`.
   - Repositori yang sudah dibuat kemudian disuntikkan (*injected*) ke dalam BLoC (`AuthBloc`, `TicketBloc`) melalui `MultiBlocProvider`. Hal ini memastikan bahwa manajemen *state* sudah memiliki akses penuh ke fungsi-data.
3. **Splash Screen & Pemeriksaan Sesi**
   - Aplikasi awalnya mengarahkan user ke `SplashScreen` sembari melakukan animasi masuk (*fade & scale*).
   - Di *background*, aplikasi memanggil konfigurasi autentikasi aktif dari Supabase (`client.auth.currentSession`).
   - Aplikasi juga me-*listen* perubahan status autentikasi. Jika *user* log out, aplikasi akan ter-trigger otomatis memaksa navigasi kembali ke halaman Login.
4. **Navigasi Cerdas (Routing)**
   - Jika sistem mendeteksi **sesi aktif (user sudah login)**, aplikasi secara otomatis menavigasikan *user* ke **`MainNavPage`** (Halaman Utama).
   - Jika **tidak ada sesi (user baru / belum login)**, navigasi akan dialihkan ke **`LoginPage`**.

---

### 3. Struktur Kode (Code Structure / Clean Architecture)
Proyek ini mengadopsi struktur folder berbasis **fitur** (*Feature-First*) dengan memadukan konsep **Clean Architecture**. Jika kita membedah *root* direktori `lib/`, berikut adalah anatominya:

```text
lib/
 ├── main.dart             # Entry point utama aplikasi dan set up providers.
 ├── core/                 # Komponen umum yang dipakai lintas fitur.
 │    ├── error/           # Penanganan fail/error global.
 │    ├── theme/           # Konfigurasi UI (Warna, Tipografi, AppTheme ringan/gelap).
 │    └── widgets/         # Reusable widgets (tombol, input yang biasa digunakan).
 └── features/             # Modul-modul utama aplikasi.
      ├── auth/            # Fitur Login, Register, Manajemen Sesi.
      └── tickets/         # Fitur utama membuat, merespons, & melihat tiket helpdesk.
```

Pada setiap fitur di dalam folder `features/` (seperti `auth` dan `tickets`), strukturnya dipecah menjadi **3 lapisan utama (Layers)** untuk memisahkan tanggung jawab (*Separation of Concerns*):

1. **Layer Data (`data/`)**
   - **Tugas:** Berinteraksi langsung dengan dunia luar, seperti API atau set data lokal.
   - **Isi:** 
     - *Data Sources:* Kumpulan fungsi untuk menembak API (dalam kasus ini: Supabase). Contohnya `ticket_remote_data_source.dart`.
     - *Models:* Model serialisasi JSON (DTO).
     - *Repositories Impl:* Implementasi riil dari antarmuka (*interface*) domain.

2. **Layer Domain (`domain/`)**
   - **Tugas:** Menjadi otak aplikasi, tempat aturan bisnis utama berada. Layer ini tidak terikat dengan teknologi luar (Supabase/Flutter UI).
   - **Isi:**
     - *Entities:* Objek data riil yang digunakan oleh frontend (bentuk murni dari Model).
     - *Repositories (Interface):* Kontrak (*abstract class*) tentang fungsi apa saja yang harus tersedia (contoh: `AuthRepository`).

3. **Layer Presentation (`presentation/`)**
   - **Tugas:** Menampilkan UI dan menangani respon interaksi dari *user*.
   - **Isi:**
     - *Pages/Screens:* Tampilan halaman (seperti `LoginPage`, `MainNavPage`).
     - *BLoC (Business Logic Component):* Penghubung antara layer UI dan layer Domain/Data (*State Management*). BLoC akan meneruskan bertugas menangkap event (seperti tombol ditekan), memberitahu repository untuk memproses data, lalu memancarkan (*emit*) status (*state*) seperti "Loading", "Success", atau "Error" kembali ke UI.

---

### 4. Logika Kode (Code Logic) & Preview Code
Untuk memberikan gambaran yang lebih teknis tentang bagaimana data mengalir di dalam aplikasi, kita bisa melihat contoh pada fitur **Manajemen Tiket (`TicketBloc`)**:

**Pola Komunikasi (User Action -> State):**

1. **Event Triggered (UI memicu aksi):** 
   Ketika *user* (misal Helpdesk) menekan tombol "Ambil Tiket" pada layar, UI (Presentation Layer) akan memicu *event* ke BLoC.
   ```dart
   // Contoh tombol ditekan di UI
   ElevatedButton(
     onPressed: () {
       context.read<TicketBloc>().add(AcceptTicketEvent(ticketId: ticket.id));
     },
     child: Text('Ambil Tiket'),
   )
   ```

2. **BLoC Merespons & Memanggil Repository (Presentation & Domain Logic):**
   Di dalam `TicketBloc`, event akan ditangkap. BLoC akan mengubah *state* menjadi `TicketLoading()`, lalu meminta *Repository* menyelesaikan tugas, dan meng-handle hasilnya (menggunakan *pattern Either* dari *Dartz*):
   ```dart
   // Di dalam ticket_bloc.dart
   on<AcceptTicketEvent>((event, emit) async {
     // a. Tampilkan animasi loading ke UI
     emit(TicketLoading());
     
     // b. Memanggil Repository untuk memproses data (menyimpan ke Supabase)
     final result = await ticketRepository.acceptTicket(event.ticketId);
     
     // c. Response handling: membedakan ketika gagal atau sukses
     result.fold(
       (failure) => emit(TicketError(failure.message)), // Emit error jika gagal
       (_) => emit(TicketAccepted()),                   // Emit sukses jika berhasil
     );
   });
   ```

3. **Eksekusi Update Data ke Supabase (Data Layer):**
   Di lapisan data (`TicketRemoteDataSource`), kode akan langsung menembak API Supabase menggunakan id tiket yang dilempar dari BLoC.
   ```dart
   // Cuplikan bayangan untuk Data Layer (Supabase)
   await supabaseClient
       .from('tickets')
       .update({'status': 'In Progress'})
       .eq('id', ticketId);
   ```

4. **State Diperbarui & UI Berubah (Reaktivitas UI):**
   Tampilan UI selalu merespons *State* BLoC. UI menggunakan widget `BlocConsumer` atau `BlocListener` untuk merespons hasil akhirnya.
   ```dart
   // Di Layar UI / Page
   BlocListener<TicketBloc, TicketState>(
     listener: (context, state) {
       if (state is TicketError) {
         // Memunculkan pesan error / Snackbar merah
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
       } else if (state is TicketAccepted) {
         // Jika berhasil, re-fetch kumpulan tiket / perbarui layar
         context.read<TicketBloc>().add(FetchTickets(statusFilter: currentStatus));
       }
     },
     child: Container(...), // UI utama rendering list tiket dsb
   )
   ```

Pola aliran statis (Satu Arah / Unidirectional Data Flow) ini digunakan *konsisten* pada setiap fitur (seperti Fetch Tickets, Create Ticket, Assign, dll), membuat performa lebih stabil dan *bugs* lebih mudah ditelusuri.

---

### 5. Poin-poin Penilaian Ekstra (Nilai Tambah untuk Dosen)
Jika ditanya terkait kelebihan desain arsitektur yang Anda pakai, Anda bisa menyampaikan poin-poin ini:
* **Tingkat Kemudahan Maintain (Maintainable):** Karena mengusung *Clean Architecture*, saat nanti *backend* berubah (misal dari Supabase ke Firebase atau REST API kustom), Anda hanya perlu mengganti kode di **Data layer** tanpa menyentuh *UI* ataupun *Domain layer* sama sekali.
* **Solid Reactivity:** Menggunakan *pattern* `BlocProvider` dan integrasi *Stream listener* (*auth listener*) membuat aplikasi responsif. User yang sudah tidak memiliki akses bisa otomatis tertendang ke halaman login tanpa perlu me-*refresh* aplikasi manual.
