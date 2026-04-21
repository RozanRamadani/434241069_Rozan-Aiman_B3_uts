import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tiketdotcom/core/theme/app_theme.dart';
import 'package:tiketdotcom/features/tickets/presentation/pages/notification_page.dart';
import 'package:tiketdotcom/features/tickets/presentation/pages/ticket_detail_page.dart';
import 'package:tiketdotcom/features/tickets/presentation/pages/main_nav_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final role = user?.userMetadata?['role'] ?? 'user';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _getTicketsStream(user?.id, role),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }
          final tickets = snapshot.data ?? [];
          return _buildBody(context, tickets, role);
        },
      ),
    );
  }

  Stream<List<Map<String, dynamic>>> _getTicketsStream(String? userId, String role) {
    if (userId == null) return const Stream.empty();
    if (role == 'user') {
      return supabase.from('tickets').stream(primaryKey: ['id']).eq('user_id', userId).order('created_at', ascending: false);
    } else {
      return supabase.from('tickets').stream(primaryKey: ['id']).order('created_at', ascending: false);
    }
  }

  Widget _buildErrorState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('Terjadi kesalahan', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 4),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 40), child: Text(msg, textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textMuted, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, List<Map<String, dynamic>> tickets, String role) {
    int total = tickets.length;
    int active = tickets.where((t) => t['status'] != 'Selesai' && t['status'] != 'Dibatalkan').length;
    int resolved = tickets.where((t) => t['status'] == 'Selesai').length;
    int cancelled = tickets.where((t) => t['status'] == 'Dibatalkan').length;

    // Show up to 5 recent tickets on the dashboard
    final recentTickets = tickets.take(5).toList();

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // ── Header ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Row(
                children: [
                  // Logo
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.domain_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AIRLANGGA NEXUS', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textSecondary, letterSpacing: 0.5)),
                      Text('Helpdesk UNAIR', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.primaryDark)),
                    ],
                  ),
                  const Spacer(),
                  // Notification
                  IconButton(
                    icon: Icon(Icons.notifications_rounded, color: AppTheme.primary, size: 28),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationPage())),
                  ),
                ],
              ),
            ),
          ),

          // ── Welcome Banner ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF60A5FA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Halo, Rek! 👋', style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(height: 12),
                    Text(
                      'Ada kendala dengan layanan kampus hari ini? Tim kami siap membantu.',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14, height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    if (role == 'user')
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.primaryDark,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusPill)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        onPressed: () {
                          // Navigate to Lapor tab (index 2)
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNavPage(initialIndex: 2)));
                        },
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                        label: const Text('Buat Tiket Baru'),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // ── Stats Grid ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.25,
                children: [
                  _StatCard(title: 'TOTAL TIKET', count: total.toString().padLeft(2, '0'), icon: Icons.receipt_long_rounded, iconColor: AppTheme.primary, iconBg: AppTheme.primaryLight),
                  _StatCard(title: 'AKTIF', count: active.toString().padLeft(2, '0'), icon: Icons.assignment_rounded, iconColor: const Color(0xFFB45309), iconBg: const Color(0xFFFEF3C7)),
                  _StatCard(title: 'SELESAI', count: resolved.toString().padLeft(2, '0'), icon: Icons.check_circle_rounded, iconColor: AppTheme.statusResolved, iconBg: AppTheme.statusResolvedBg),
                  _StatCard(title: 'DIBATALKAN', count: cancelled.toString().padLeft(2, '0'), icon: Icons.cancel_rounded, iconColor: AppTheme.statusCancelled, iconBg: AppTheme.statusCancelledBg),
                ],
              ),
            ),
          ),

          // ── Recent Tickets Title ─────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tiket Terbaru', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                  const SizedBox(height: 12),
                  // Search bar
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(color: AppTheme.inputFill, borderRadius: BorderRadius.circular(AppTheme.radiusPill)),
                    child: Row(
                      children: [
                        Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 20),
                        const SizedBox(width: 10),
                        Text('Cari nomor tiket atau keluhan...', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Ticket list ────────────────────────────────────────
          if (recentTickets.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 40, bottom: 60),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.inbox_rounded, size: 56, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text('Belum ada tiket.', style: TextStyle(color: AppTheme.textMuted)),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _TicketCard(ticket: recentTickets[index]),
                  childCount: recentTickets.length,
                ),
              ),
            ),
            
          // Bottom spacer
          if (recentTickets.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 40),
                child: Column(
                  children: [
                    Icon(Icons.inbox_rounded, color: Colors.grey[400], size: 24),
                    const SizedBox(height: 8),
                    Text('Semua tiket terbaru sudah ditampilkan', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                  ],
                ),
              ),
            )
        ],
      ),
    );
  }
}

// ─── Stat Card ──────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String title;
  final String count;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  const _StatCard({required this.title, required this.count, required this.icon, required this.iconColor, required this.iconBg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const Spacer(),
          Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textSecondary, letterSpacing: 0.5)),
          const SizedBox(height: 2),
          Text(count, style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }
}


// ─── Ticket Card ─────────────────────────────────────────────
class _TicketCard extends StatelessWidget {
  final Map<String, dynamic> ticket;
  const _TicketCard({required this.ticket});

  String _timeAgo(String? createdAt) {
    if (createdAt == null) return '';
    final time = DateTime.tryParse(createdAt);
    if (time == null) return '';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit yang lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam yang lalu';
    if (diff.inDays == 1) return 'Kemarin';
    return '${diff.inDays} hari yang lalu';
  }

  IconData _getCategoryIcon(String category) {
    if (category.toLowerCase().contains('wifi') || category.toLowerCase().contains('jaringan')) return Icons.wifi_off_rounded;
    if (category.toLowerCase().contains('printer') || category.toLowerCase().contains('hardware')) return Icons.print_rounded;
    if (category.toLowerCase().contains('login') || category.toLowerCase().contains('akun')) return Icons.school_rounded; // Assuming CyberCampus AULA
    return Icons.support_agent_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final status = ticket['status'] ?? 'Dalam Antrean';
    final statusColor = AppTheme.statusColor(status);
    final statusBg = AppTheme.statusBgColor(status);
    final category = ticket['category'] ?? '-';
    final title = ticket['title'] ?? '-';
    final description = ticket['description'] ?? '';
    final ticketId = ticket['id'] ?? '';
    final shortId = '#TK-${ticketId.length >= 5 ? ticketId.substring(ticketId.length - 5) : ticketId}';
    final timeAgo = _timeAgo(ticket['created_at']);
    
    // Status label map (menunggu antrean -> dalam antrean, etc)
    String displayStatus = status.toUpperCase();
    if (status == 'Menunggu Antrean') displayStatus = 'DALAM ANTREAN';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.cardShadow,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => TicketDetailPage(
            ticketId: ticketId,
            title: title,
            description: description,
            category: category,
            status: status,
            statusColor: statusColor,
            attachmentUrl: ticket['attachment_url'],
            assignedTo: ticket['assigned_to'],
          )));
        },
        child: Row(
          children: [
            // Icon
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(_getCategoryIcon(category), color: AppTheme.primaryDark),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(shortId, style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(8)),
                        child: Text(displayStatus, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: statusColor, letterSpacing: 0.5)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('Terakhir diperbarui: $timeAgo', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }
}
