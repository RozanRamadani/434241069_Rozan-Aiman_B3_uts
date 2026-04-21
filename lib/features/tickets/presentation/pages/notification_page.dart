import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:tiketdotcom/core/theme/app_theme.dart';
import 'ticket_detail_page.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final data = await supabase
          .from('ticket_comments')
          .select('*, tickets!inner(user_id, title, description, category, status, attachment_url)')
          .eq('tickets.user_id', userId)
          .neq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(20);

      if (mounted) setState(() { _notifications = List<Map<String, dynamic>>.from(data); _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint('Error fetch notifications: $e');
    }
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m lalu';
    if (diff.inHours < 24) return '${diff.inHours}j lalu';
    return DateFormat('dd MMM, HH:mm').format(time);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifikasi', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: () { setState(() => _isLoading = true); _fetchNotifications(); }),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.notifications_off_outlined, size: 56, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('Belum ada notifikasi.', style: TextStyle(color: AppTheme.textMuted)),
                ]))
              : RefreshIndicator(
                  onRefresh: _fetchNotifications,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    separatorBuilder: (_, i) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = _notifications[index];
                      final time = DateTime.parse(item['created_at']);
                      final ticketTitle = item['tickets']?['title'] ?? 'Tiket';

                      return Container(
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppTheme.radiusLg), boxShadow: AppTheme.softShadow),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                            onTap: () => _navigateToTicket(item),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                CircleAvatar(radius: 20, backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                                  child: Icon(Icons.message_rounded, color: AppTheme.primary, size: 18)),
                                const SizedBox(width: 14),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(children: [
                                    Expanded(child: Text(ticketTitle, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                    Text(_timeAgo(time), style: TextStyle(fontSize: 11, color: AppTheme.primaryDark, fontWeight: FontWeight.w600)),
                                  ]),
                                  const SizedBox(height: 4),
                                  Text(item['message'] ?? 'Ada balasan baru.', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                                ])),
                              ]),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Future<void> _navigateToTicket(Map<String, dynamic> item) async {
    final ticketData = item['tickets'];
    if (ticketData == null) return;
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      final ticketId = item['ticket_id'];
      final status = ticketData['status'] ?? 'Aktif';
      if (mounted) {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (_) => TicketDetailPage(
          ticketId: ticketId, title: ticketData['title'] ?? '-', description: ticketData['description'] ?? '-',
          category: ticketData['category'] ?? '-', status: status, statusColor: AppTheme.statusColor(status),
          attachmentUrl: ticketData['attachment_url'], assignedTo: ticketData['assigned_to'],
        )));
      }
    } catch (e) { if (mounted) Navigator.pop(context); }
  }
}
