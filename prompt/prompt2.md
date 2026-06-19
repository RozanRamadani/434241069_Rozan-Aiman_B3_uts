Additional Feature: Admin Assigns Helpdesk → Helpdesk Accepts
Flow yang Diinginkan
Admin buka Detail Tiket
      ↓
Admin tap "Tugaskan Helpdesk"
      ↓
Muncul Bottom Sheet daftar Helpdesk
(nama + status availability)
      ↓
Admin pilih salah satu Helpdesk
      ↓
Notifikasi masuk ke Helpdesk
      ↓
Helpdesk buka halaman "Tiket Masuk"
      ↓
Helpdesk tap "Terima Tiket"
      ↓
Status berubah ke "Sedang Diproses"
      ↓
Helpdesk selesaikan → tap "Selesai"

Database Changes
-- Tambah kolom di tabel tickets
ALTER TABLE tickets
ADD COLUMN IF NOT EXISTS assigned_at timestamptz NULL,
ADD COLUMN IF NOT EXISTS accepted_at timestamptz NULL;

-- Tabel notifikasi untuk helpdesk
CREATE TABLE IF NOT EXISTS notifications (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid REFERENCES auth.users(id),
  ticket_id uuid REFERENCES tickets(id),
  title text NOT NULL,
  message text NOT NULL,
  is_read boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

Role-Based Actions Detail
Admin flow:

Buka TicketDetailPage
Tap tombol "Tugaskan Helpdesk"
Muncul ModalBottomSheet berisi list helpdesk dari tabel profiles where role = 'helpdesk'
Setiap item helpdesk tampilkan: nama, dan badge "Sedang Menangani X tiket" (hitung dari tickets where assigned_to = helpdesk.id AND status = 'Sedang Diproses')
Admin tap nama helpdesk → konfirmasi dialog "Tugaskan tiket ini ke [nama]?"
Confirm → update assigned_to, assigned_at, status = 'Ditugaskan'
Insert row baru ke tabel notifications untuk helpdesk yang dipilih

Helpdesk flow:

Helpdesk dapat notifikasi "Tiket baru ditugaskan kepada Anda"
Tap notifikasi → masuk ke TicketDetailPage
Muncul tombol "Terima Tiket" (hanya jika status = 'Ditugaskan' DAN assigned_to = helpdesk id)
Tap "Terima Tiket" → status = 'Sedang Diproses', accepted_at terisi
Setelah selesai tangani → tap "Selesai" → status = 'Selesai', resolved_at terisi

Files to Generate/Update
1. SQL — migration di atas
2. ticket_remote_data_source.dart — tambah/update:
// Ambil daftar helpdesk beserta jumlah tiket aktif yang ditangani
Future<List<Map<String, dynamic>>> getHelpdesks()

// Admin assign tiket ke helpdesk + insert notifikasi
Future<void> assignTicket(String ticketId, String helpdeskId, String helpdeskName)

// Helpdesk terima tiket
Future<void> acceptTicket(String ticketId)

// Helpdesk selesaikan tiket  
Future<void> resolveTicket(String ticketId)

3. ticket_event.dart — tambah:
class FetchHelpdesksEvent extends TicketEvent {}
class AssignTicketEvent extends TicketEvent {
  final String ticketId;
  final String helpdeskId;
  final String helpdeskName;
}
class AcceptTicketEvent extends TicketEvent {
  final String ticketId;
}

4. ticket_state.dart — tambah:
class HelpdesksLoaded extends TicketState {
  final List<Map<String, dynamic>> helpdesks;
}
class TicketAssigned extends TicketState {}
class TicketAccepted extends TicketState {}

5. ticket_bloc.dart — handle semua event baru
6. ticket_detail_page.dart — update UI tombol aksi:
Kondisi tombol yang tampil:

Status: Menunggu Antrean
├── Admin    → tombol "Tugaskan Helpdesk" (biru)
├── Helpdesk → tidak ada tombol
└── User     → tombol "Batalkan" (merah)

Status: Ditugaskan
├── Admin    → tombol "Ganti Helpdesk" (abu-abu)
├── Helpdesk → tombol "Terima Tiket" (hijau) — hanya jika assigned_to == currentUser.id
└── User     → info "Menunggu helpdesk menerima tiket"

Status: Sedang Diproses
├── Admin    → read only
├── Helpdesk → tombol "Selesai" (hijau) — hanya jika assigned_to == currentUser.id
└── User     → info "Tiket sedang ditangani"

Status: Selesai / Dibatalkan
└── Semua role → tidak ada tombol aksi

7. notification_page.dart — update agar baca dari tabel notifications:
// Query notifikasi milik user yang sedang login
supabase
  .from('notifications')
  .select('*, tickets(title)')
  .eq('user_id', currentUserId)
  .order('created_at', ascending: false)
  .limit(20)


  Constraints

flutter_bloc — no setState for business logic
dartz Either untuk semua repository method
Clean Architecture
Semua Supabase call pakai .timeout(const Duration(seconds: 10))
Timestamp format: 'dd MMM yyyy • HH:mm' pakai package intl
Semua teks UI dalam Bahasa Indonesia
Gunakan withValues(alpha: x) bukan withOpacity(x)
Selalu cek if (!mounted) return sebelum navigasi setelah async call
Setelah assign/accept/resolve, refresh halaman otomatis dengan fetch ulang data tiket