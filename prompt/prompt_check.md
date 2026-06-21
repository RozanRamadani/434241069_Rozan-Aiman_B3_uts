> ## Project Feature Audit: Helpdesk UNAIR (SRS v2.0.0)
>
> ### Your Role
> Kamu adalah **senior Flutter developer**. Tugasmu adalah membaca seluruh file project yang akan saya berikan, lalu mencocokkan implementasi yang ada dengan daftar fitur dari SRS v2.0.0 di bawah ini.
>
> **Jangan tulis kode dulu. Fokus pada analisa dan laporan.**
>
> ---
>
> ### Daftar Fitur Lengkap SRS v2.0.0
>
> #### Auth (FR-001 s/d FR-004)
> - [ ] Login dengan email/username dan password (semua role)
> - [ ] Logout (semua role)
> - [ ] Register akun baru (user saja)
> - [ ] Reset password via email (semua role) — sebagai **halaman terpisah**, bukan dialog
> - [ ] Session management (auto login, auto logout saat token expired)
>
> #### Fitur User (FR-005)
> - [ ] Buat tiket baru
> - [ ] Upload foto lampiran dari **kamera**
> - [ ] Upload foto lampiran dari **galeri**
> - [ ] Melihat daftar tiket milik sendiri
> - [ ] Melihat detail tiket
> - [ ] Melihat **histori perjalanan tiket** (stepping wizard dengan timestamp)
> - [ ] Mendapat **notifikasi** perubahan tiket
> - [ ] Memberikan komentar / reply di tiket
> - [ ] Melihat **statistik tiket miliknya** (total, aktif, selesai, dibatalkan)
> - [ ] Membatalkan tiket (hanya saat status "Menunggu Antrean")
>
> #### Fitur Helpdesk (FR-006)
> - [ ] Membuat tiket baru
> - [ ] Melihat **hanya** tiket yang ditugaskan kepadanya (bukan semua tiket)
> - [ ] Menangani tiket yang ditugaskan
> - [ ] Update status tiket (Terima → Sedang Diproses → Selesai)
> - [ ] Memberikan tanggapan / komentar di tiket
> - [ ] Menutup / menyelesaikan tiket
> - [ ] Melihat **statistik tiket yang ditugaskan** kepadanya
>
> #### Fitur Admin (FR-007)
> - [ ] Membuat tiket baru
> - [ ] Melihat **semua** tiket yang masuk
> - [ ] Melihat tiket **berdasarkan helpdesk** yang ditugaskan (filter per helpdesk)
> - [ ] Menugaskan helpdesk untuk mengerjakan tiket
> - [ ] Mengubah status tiket
> - [ ] Memberikan respon / komentar
> - [ ] **Mengelola daftar pengguna** (aktifkan / non-aktifkan akun)
> - [ ] **Menghapus tiket** (hard delete)
>
> #### Notifikasi (FR-008)
> - [ ] Notifikasi in-app saat status tiket berubah
> - [ ] Tap notifikasi → navigasi ke halaman tiket terkait
> - [ ] **Local notification** (muncul sebagai popup di OS)
> - [ ] **FCM Push Notification** (notifikasi saat app tertutup) ← opsional
>
> #### Dashboard (FR-009)
> - [ ] Statistik: **Total** tiket
> - [ ] Statistik: **Open** (Menunggu Antrean)
> - [ ] Statistik: **Assign** (Ditugaskan)
> - [ ] Statistik: **In Progress** (Sedang Diproses)
> - [ ] Statistik: **Closed** (Selesai)
> - [ ] Dashboard berbeda per role (User / Helpdesk / Admin)
>
> #### Riwayat & Tracking (FR-010, FR-011)
> - [ ] Riwayat semua aktivitas tiket (FR-010)
> - [ ] Tracking tiket aktif untuk **User**
> - [ ] Tracking tiket yang ditangani untuk **Helpdesk**
> - [ ] Tracking semua tiket belum closed untuk **Admin**
> - [ ] Setiap step tracking menampilkan **timestamp** (jam & tanggal)
>
> #### Business Rules
> - [ ] BR-001: Session management (auto refresh token)
> - [ ] BR-002: Upload file/image ke Supabase Storage
> - [ ] BR-002: Delete tiket
> - [ ] BR-002: Non-aktifkan pengguna
> - [ ] BR-003: Notification Service (Supabase Realtime / FCM / Local)
> - [ ] BR-004: Dashboard Service (hitung tiket per status)
> - [ ] BR-005: History Service — **simpan setiap perubahan status ke tabel terpisah**
> - [ ] BR-005: History Service — **simpan aktivitas pengguna**
>
> #### Screen (UI/UX)
> - [ ] 5.1 Splash Screen
> - [ ] 5.2 Login Screen
> - [ ] 5.3 Register Screen
> - [ ] 5.4 Forgot Password Screen (halaman terpisah, bukan dialog)
> - [ ] 5.5 Dashboard Screen
> - [ ] 5.6 List Tiket Screen
> - [ ] 5.7 Detail Tiket Screen
> - [ ] 5.8 Tracking Tiket Screen
> - [ ] 5.9 Create Tiket Screen
> - [ ] 5.10 Notification Screen
> - [ ] 5.11 Profile Screen
> - [ ] 5.12 Setting Screen
> - [ ] 5.13 Dark & Light mode
>
> #### Non-Functional
> - [ ] Lazy loading list
> - [ ] UI responsive di berbagai ukuran layar
> - [ ] Konsisten antar halaman
> - [ ] Clean Architecture
> - [ ] Role-based authorization (user/helpdesk/admin)
> - [ ] JWT Token & session management
> - [ ] Kredensial disimpan di `.env` (bukan hardcode)
>
> ---
>
> ### Yang Perlu Kamu Lakukan
>
> Setelah membaca semua file project, berikan laporan dalam format ini:
>
> #### ✅ Sudah Implementasi
> List fitur yang sudah ada dan berfungsi dengan benar.
> Format: `[Fitur] → [File] → [Catatan jika ada]`
>
> #### ❌ Belum Ada
> List fitur dari SRS yang belum ada implementasinya sama sekali.
> Format: `[FR/BR] → [Fitur] → [Complexity: Low/Medium/High]`
>
> #### ⚠️ Ada tapi Belum Selesai
> List fitur yang sudah ada tapi logic/UI-nya belum lengkap atau belum terhubung ke backend.
> Format: `[Fitur] → [File] → [Yang kurang]`
>
> #### 🐛 Bug yang Ditemukan
> List bug yang kamu temukan saat membaca kode.
> Format: `[File] → [Bug] → [Solusi]`
>
> #### 📋 Priority Fix List
> Urutkan semua temuan dari yang paling penting:
>
> | No | Fitur/Bug | Status | Complexity | Estimasi |
> |---|---|---|---|---|
>
> ---
>
> ### Instruksi
> 1. **Minta saya share file satu per satu** — jangan asumsikan isi file
> 2. Baca setiap file dengan teliti sebelum membuat kesimpulan
> 3. Cocokkan dengan checklist SRS di atas
> 4. Kalau ada yang tidak jelas, tanyakan sebelum membuat kesimpulan
> 5. **Setelah laporan disetujui**, baru kita mulai fix satu per satu
