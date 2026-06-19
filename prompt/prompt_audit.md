> ## Full Project Audit Request: Helpdesk UNAIR Flutter App
>
> ### Your Role
> You are a **senior Flutter developer**. I will share all my project files with you. Your job is to:
> 1. Read and understand every file I share
> 2. Cross-check with the SRS requirements below
> 3. Give me a full audit report **before writing any code**
>
> ---
>
> ### SRS v2.0.0 Requirements
>
> **3 Roles:** User, Helpdesk, Admin
>
> **FR-001 to FR-004 — Authentication**
> - Login (email + password, semua role)
> - Logout (semua role)
> - Register (user saja)
> - Reset Password (semua role)
> - Session management dengan JWT
>
> **FR-005 — User dapat:**
> 1. Membuat tiket
> 2. Upload foto (kamera / galeri)
> 3. Melihat daftar tiket miliknya
> 4. Melihat detail tiket
> 5. Melihat histori perjalanan tiket
> 6. Mendapat notifikasi perubahan tiket
> 7. Memberikan komentar / reply
> 8. Melihat statistik tiket miliknya
>
> **FR-006 — Helpdesk dapat:**
> 1. Membuat tiket
> 2. Melihat semua tiket yang ditugaskan kepadanya (bukan semua tiket)
> 3. Menangani tiket yang ditugaskan
> 4. Update status tiket yang ditugaskan
> 5. Memberikan tanggapan/komentar
> 6. Menutup/menyelesaikan tiket
> 7. Melihat statistik tiket yang ditugaskan kepadanya
>
> **FR-007 — Admin dapat:**
> 1. Membuat tiket
> 2. Melihat semua tiket yang masuk
> 3. Melihat tiket berdasarkan helpdesk yang ditugaskan
> 4. Menugaskan helpdesk untuk mengerjakan tiket
> 5. Mengubah status tiket
> 6. Memberikan respon/komentar
> 7. Mengelola daftar pengguna (aktifkan / non-aktifkan)
>
> **FR-008 — Notifikasi:**
> - Pemberitahuan perubahan status tiket
> - Tap notifikasi → navigasi ke halaman terkait
> - Menggunakan Supabase Realtime / FCM / Local Notification
>
> **FR-009 — Dashboard Statistik:**
> - Total tiket
> - Open tiket
> - Assign tiket
> - In Progress tiket
> - Closed tiket
>
> **FR-010 — Riwayat Tiket:**
> - Semua aktivitas tiket tercatat
>
> **FR-011 — Tracking Tiket:**
> - User: tracking tiket aktif miliknya
> - Helpdesk: tracking tiket yang ditangani
> - Admin: tracking semua tiket yang belum closed
>
> **Ticket Flow:**
> ```
> [Menunggu Antrean] → Admin assign → [Ditugaskan] + assigned_at
>         ↓
> Helpdesk terima → [Sedang Diproses] + accepted_at
>         ↓
> Helpdesk selesai → [Selesai] + resolved_at
>
> ATAU User batalkan → [Dibatalkan] + cancelled_at
> ```
>
> **Screens yang harus ada:**
> - Splash, Login, Register, Forgot Password
> - Dashboard, List Tiket, Detail Tiket
> - Tracking Tiket, Create Tiket
> - Notification, Profile, **Setting**
> - Dark & Light mode
>
> **Non-Functional:**
> - Lazy loading
> - Clean Architecture
> - Responsive UI
> - Role-based authorization
> - JWT Token
> - Security (RLS Supabase)
>
> ---
>
> ### Tech Stack
> - Flutter + flutter_bloc
> - Supabase (Auth + PostgreSQL + Realtime + Storage)
> - Clean Architecture (data/domain/presentation)
> - dartz (`Either<Failure, T>`)
> - Package: intl, cached_network_image, image_picker, shimmer
>
> ---
>
> ### Database Schema
> ```
> tickets:
>   id, title, description, category, status,
>   created_at, user_id, attachment_url,
>   assigned_to (uuid → auth.users),
>   assigned_at, accepted_at, resolved_at, cancelled_at
>
> ticket_comments:
>   id, ticket_id, user_id, message, created_at
>
> profiles:
>   id, full_name, role, updated_at
>
> notifications:
>   id, user_id, ticket_id, title, message, is_read, created_at
> ```
>
> ---
>
> ### Known Bugs (Already Identified)
> 1. Section "Petugas IT" di Detail Tiket menampilkan "Belum Ditugaskan" meskipun tiket sudah di-assign — nama helpdesk tidak muncul
> 2. Halaman "Tiket Saya" kosong — tiket user tidak muncul sama sekali
> 3. `RealtimeSubscribeException` muncul saat run di Flutter Web
>
> ---
>
> ### Audit Report Format
>
> Setelah membaca semua file, berikan laporan dalam format ini:
>
> #### 🔴 Critical Bugs
> > Fitur yang crash atau tidak berfungsi sama sekali
> `[File] → [Masalah] → [Solusi yang disarankan]`
>
> #### 🟡 Incomplete Features
> > Fitur yang ada UI-nya tapi logic belum selesai atau belum connect ke backend
> `[Fitur] → [Yang kurang] → [Yang perlu ditambahkan]`
>
> #### 🔵 Missing Features (Based on SRS v2.0.0)
> > Fitur yang ada di SRS tapi belum ada implementasinya sama sekali
> `[FR] → [Fitur] → [Complexity: Low/Medium/High]`
>
> #### ⚠️ Code Inefficiency
> > Kode yang jalan tapi tidak efisien
> `[File] → [Masalah] → [Rekomendasi]`
>
> #### 🔒 Security Issues
> > Potensi celah keamanan
> `[File/Layer] → [Risiko] → [Solusi]`
>
> #### 🎨 UX Problems
> > Missing loading state, empty state, error handling di UI
> `[Halaman] → [Masalah] → [Solusi]`
>
> #### ✅ Priority Fix List
> Urutkan dari prioritas tertinggi:
> | No | Issue | Category | Severity | Estimasi |
> |---|---|---|---|---|
>
> ---
>
> ### Instructions
> - **Jangan tulis kode dulu** — fokus audit dan laporan
> - Baca setiap file dengan teliti sebelum membuat kesimpulan
> - Jangan berasumsi — jika ada yang tidak jelas, tanyakan
> - Setelah laporan disetujui, kita fix satu per satu sesuai priority list
> - **Mulai dengan meminta saya share file-file project**
