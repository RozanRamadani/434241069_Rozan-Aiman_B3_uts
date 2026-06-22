import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:tiketdotcom/core/theme/app_theme.dart';
import '../../domain/repositories/ticket_repository.dart';
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
          .from('notifications')
          .select('*, tickets(title, description, category, status, attachment_url, assigned_to)')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(20);

      if (mounted) setState(() { _notifications = List<Map<String, dynamic>>.from(data); _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint('Error fetch notifications: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    
    try {
      await supabase.from('notifications').update({'is_read': true}).eq('user_id', userId).eq('is_read', false);
      _fetchNotifications();
    } catch (e) {
      debugPrint('Error mark all as read: $e');
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
          IconButton(icon: const Icon(Icons.done_all_rounded), tooltip: 'Tandai semua dibaca', onPressed: _markAllAsRead),
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: () { setState(() => _isLoading = true); _fetchNotifications(); }),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.notifications_off_outlined, size: 56, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('Belum ada notifikasi.', style: TextStyle(color: context.appTextMuted)),
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
                      final title = item['title'] ?? 'Notifikasi Baru';
                      final message = item['message'] ?? '';

                      return Container(
                        decoration: BoxDecoration(
                          color: item['is_read'] == true ? Colors.white : AppTheme.primary.withValues(alpha: 0.05), 
                          borderRadius: BorderRadius.circular(AppTheme.radiusLg), 
                          boxShadow: context.appSoftShadow
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                            onTap: () async {
                              // mark as read
                              if (item['is_read'] != true) {
                                await supabase.from('notifications').update({'is_read': true}).eq('id', item['id']);
                              }
                              _navigateToTicket(item);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                CircleAvatar(radius: 20, backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                                  child: Icon(Icons.notifications_active_rounded, color: AppTheme.primary, size: 18)),
                                const SizedBox(width: 14),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(children: [
                                    if (item['is_read'] != true) ...[
                                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle)),
                                      const SizedBox(width: 6),
                                    ],
                                    Expanded(child: Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14, color: item['is_read'] == true ? context.appTextSecondary : context.appTextPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                    Text(_timeAgo(time), style: TextStyle(fontSize: 11, color: item['is_read'] == true ? context.appTextMuted : AppTheme.primaryDark, fontWeight: FontWeight.w600)),
                                  ]),
                                  const SizedBox(height: 4),
                                  Text(message, style: TextStyle(fontSize: 13, color: context.appTextSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Text('Tiket: $ticketTitle', style: TextStyle(fontSize: 11, color: AppTheme.primaryDark, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
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
    final ticketId = item['ticket_id'];
    if (ticketId == null) return;
    
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      final eitherResult = await context.read<TicketRepository>().getTicketById(ticketId);
      if (mounted) {
        Navigator.pop(context); // Dismiss loading
        eitherResult.fold(
          (failure) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat tiket: ${failure.message}'))),
          (ticket) => Navigator.push(context, MaterialPageRoute(builder: (_) => TicketDetailPage(ticket: ticket))),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat tiket: $e')));
      }
    }
  }
}

