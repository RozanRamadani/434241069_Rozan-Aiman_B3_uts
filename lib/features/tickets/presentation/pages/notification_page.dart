import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
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

  // ✅ Perbaikan 1: Filter notifikasi khusus untuk tiket milik user ini (FR-007)
  Future<void> _fetchNotifications() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final data = await supabase
          .from('ticket_comments')
          .select('*, tickets!inner(user_id, title, description, category, status, attachment_url)')
          .eq('tickets.user_id', userId)
          .neq('user_id', userId) // Kecualikan komentar dari diri sendiri
          .order('created_at', ascending: false)
          .limit(20);

      if (mounted) {
        setState(() {
          _notifications = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint('Error fetch notifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchNotifications,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(child: Text('Belum ada notifikasi baru.'))
              : RefreshIndicator(
                  onRefresh: _fetchNotifications,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final item = _notifications[index];
                      final time = DateTime.parse(item['created_at']);
                      final ticketTitle = item['tickets']?['title'] ?? 'Tiket';
                      
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.withValues(alpha: 0.1),
                          child: const Icon(Icons.message_outlined, color: Colors.blue),
                        ),
                        // ✅ Perbaikan 3: Judul notifikasi dinamis berdasarkan judul tiket
                        title: Text(
                          'Komentar di: $ticketTitle',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis, // ✅ Perbaikan Typo
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(item['message'] ?? 'Ada balasan baru.'),
                            const SizedBox(height: 8),
                            Text(
                              DateFormat('HH:mm • dd MMM').format(time),
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                        onTap: () => _navigateToTicket(item),
                      );
                    },
                  ),
                ),
    );
  }

  // ✅ Perbaikan 2: Navigasi dengan loading indicator (Feedback UX)
  Future<void> _navigateToTicket(Map<String, dynamic> item) async {
    final ticketData = item['tickets'];
    if (ticketData == null) return;

    // Tampilkan loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Pastikan data tiket terbaru diambil (atau gunakan data dari join)
      final String ticketId = item['ticket_id'];
      final status = ticketData['status'] ?? 'Aktif';
      
      if (mounted) {
        Navigator.pop(context); // Tutup loading
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TicketDetailPage(
              ticketId: ticketId,
              title: ticketData['title'] ?? '-',
              description: ticketData['description'] ?? '-',
              category: ticketData['category'] ?? '-',
              status: status,
              statusColor: status == 'Selesai' 
                  ? Colors.green 
                  : (status == 'Dibatalkan' ? Colors.red : Colors.orange),
              attachmentUrl: ticketData['attachment_url'],
              assignedTo: ticketData['assigned_to'],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint('Error navigasi: $e');
    }
  }
}
