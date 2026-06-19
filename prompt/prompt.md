Feature Request: Ticket Handling Flow with Stepping Wizard
Background
I have a Flutter E-Ticketing Helpdesk app with Clean Architecture, flutter_bloc, and Supabase. The app has 3 roles: User, Helpdesk, and Admin.
I want to improve the ticket handling flow with a proper stepping wizard that shows timestamps at each stage.

Desired Flow
User buat tiket
      ↓
[Step 1] Menunggu Antrean      → timestamp: created_at (sudah ada)
      ↓
Admin assign ke Helpdesk
      ↓
[Step 2] Ditugaskan            → timestamp: assigned_at (baru)
      ↓
Helpdesk terima & proses tiket
      ↓
[Step 3] Sedang Diproses       → timestamp: processed_at (baru)
      ↓
Helpdesk klik tombol Selesai
      ↓
[Step 4] Selesai               → timestamp: resolved_at (baru)

Database Changes Needed
Please provide the SQL to add these columns to the tickets table in Supabase:
-- Tambahkan kolom-kolom ini ke tabel tickets
assigned_at    timestamptz NULL
processed_at   timestamptz NULL
resolved_at    timestamptz NULL
cancelled_at   timestamptz NULL
assigned_to    uuid NULL REFERENCES auth.users(id)  -- sudah ada

Role-Based Actions
Admin:

Melihat semua tiket
Membuka bottom sheet daftar helpdesk (dari tabel profiles where role = 'helpdesk')
Memilih helpdesk → status berubah ke 'Ditugaskan' + assigned_at terisi

Helpdesk:

Menerima tiket yang di-assign kepadanya
Tombol "Terima & Proses" → status berubah ke 'Sedang Diproses' + processed_at terisi
Tombol "Selesai" → status berubah ke 'Selesai' + resolved_at terisi

User:

Tombol "Batalkan" (hanya saat status 'Menunggu Antrean') → status 'Dibatalkan' + cancelled_at terisi
Melihat stepping wizard progress tiketnya

Stepping Wizard UI
Tampilkan di TicketDetailPage sebagai timeline vertikal dengan format:

● Tiket Dibuat
  📅 19 Apr 2026 • 10:30
  ─────────────────────
● Ditugaskan ke: Budi (Helpdesk)
  📅 19 Apr 2026 • 11:00
  ─────────────────────
● Sedang Diproses
  📅 19 Apr 2026 • 11:15
  ─────────────────────
○ Selesai          ← step ini belum aktif (abu-abu)

Step yang sudah dilalui: warna biru, bold
Step yang belum dilalui: warna abu-abu
Setiap step tampilkan jam dan tanggal dari timestamp masing-masing
Jika Dibatalkan, tampilkan step khusus dengan warna merah

Files to Generate/Update

SQL migration — ALTER TABLE untuk tambah kolom baru
ticket.dart (entity) — tambah fields:
assignedTo, assignedAt, processedAt, resolvedAt, cancelledAt, assignedToName
ticket_model.dart — update fromJson dan toJson
ticket_remote_data_source.dart — update/tambah methods:

getTickets() — include join ke profiles untuk dapat assigned_to_name
assignTicket(ticketId, helpdeskId) — update assigned_to, status, assigned_at
processTicket(ticketId) — update status = 'Sedang Diproses', processed_at
resolveTicket(ticketId) — update status = 'Selesai', resolved_at
cancelTicket(ticketId) — update status = 'Dibatalkan', cancelled_at
getHelpdesks() — fetch dari profiles where role = 'helpdesk'


ticket_repository.dart + ticket_repository_impl.dart — tambah semua method baru dengan timeout 10 detik
ticket_event.dart — tambah events:

AssignTicketEvent(ticketId, helpdeskId)
ProcessTicketEvent(ticketId)
ResolveTicketEvent(ticketId)
CancelTicketEvent(ticketId)
FetchHelpdesksEvent()


ticket_state.dart — tambah states:

TicketAssigned
TicketProcessed
TicketResolved
TicketCancelled
HelpdesksLoaded(List<Map<String, dynamic>> helpdesks)


ticket_bloc.dart — handle semua event baru
ticket_detail_page.dart — update UI:

Tambahkan Stepping Wizard timeline vertikal di atas section komentar
Tombol aksi berdasarkan role dan status:

Admin: tombol "Tugaskan Helpdesk" + bottom sheet pilih helpdesk
Helpdesk: tombol "Terima & Proses" (jika status Ditugaskan) dan "Selesai" (jika Sedang Diproses)
User: tombol "Batalkan" (hanya jika status Menunggu Antrean)


Sembunyikan semua tombol aksi jika status sudah 'Selesai' atau 'Dibatalkan'

Constraints

Flutter + flutter_bloc (BlocBuilder/BlocListener) — no setState for business logic
dartz Either for all repository methods
Clean Architecture — setiap layer hanya boleh akses layer di bawahnya
All Supabase calls must have .timeout(const Duration(seconds: 10))
Timestamp format display: 'dd MMM yyyy • HH:mm' menggunakan package intl
All UI text in Bahasa Indonesia
Use withValues(alpha: x) instead of deprecated withOpacity(x)
Always check if (!mounted) return before navigation after async calls