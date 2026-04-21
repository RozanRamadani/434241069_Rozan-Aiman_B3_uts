import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tiketdotcom/features/auth/presentation/pages/profile_page.dart';
import 'package:tiketdotcom/features/tickets/presentation/pages/create_ticket_page.dart';
import 'package:tiketdotcom/features/tickets/presentation/pages/notification_page.dart';
import 'package:tiketdotcom/features/tickets/presentation/pages/ticket_list_page.dart';
import 'package:tiketdotcom/features/tickets/presentation/pages/ticket_detail_page.dart';

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
    final fullName = user?.userMetadata?['full_name'] ?? 'User';
    final role = user?.userMetadata?['role'] ?? 'user';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationPage())),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage())),
          ),
        ],
      ),
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
          return _buildBodyContent(context, fullName, role, tickets);
        },
      ),
      floatingActionButton: role == 'user'
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateTicketPage()));
              },
              label: const Text('Buat Tiket'),
              icon: const Icon(Icons.add),
            )
          : null,
    );
  }

  Stream<List<Map<String, dynamic>>> _getTicketsStream(String? userId, String role) {
    if (userId == null) return const Stream.empty();

    if (role == 'user') {
      return supabase
          .from('tickets')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(20);
    } else {
      return supabase
          .from('tickets')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .limit(20);
    }
  }

  Widget _buildErrorState(String errorMessage) {
    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text('Terjadi kesalahan koneksi', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey[700])),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBodyContent(BuildContext context, String fullName, String role, List<Map<String, dynamic>> tickets) {
    final totalCount = tickets.length;
    final activeCount = tickets.where((t) => t['status'] != 'Selesai' && t['status'] != 'Dibatalkan').length;
    final completedCount = tickets.where((t) => t['status'] == 'Selesai').length;
    final cancelledCount = tickets.where((t) => t['status'] == 'Dibatalkan').length;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(), // To enable pull-to-refresh even if content doesn't overflow
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Text('Halo, $fullName!', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              _buildRoleBadge(role),
              const SizedBox(height: 32),
              const Text('Ringkasan Tiket', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              _buildStatGrid(totalCount, activeCount, completedCount, cancelledCount),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Laporan Terbaru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const TicketListPage()));
                    },
                    child: const Text('Lihat Semua'),
                  ),
                ],
              ),
            ]),
          ),
        ),
        if (tickets.isEmpty)
          const SliverToBoxAdapter(
            child: Center(child: Padding(padding: EdgeInsets.only(top: 40), child: Text('Belum ada tiket.'))),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildTicketCard(context, tickets[index]),
                childCount: tickets.length > 5 ? 5 : tickets.length,
              ),            ),
          ),
      ],
    );
  }
  Widget _buildRoleBadge(String role) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: role == 'user' ? Colors.blue[50] : Colors.purple[50], borderRadius: BorderRadius.circular(20)),
        child: Text(role.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: role == 'user' ? Colors.blue : Colors.purple)),        
      ),
    );
  }

  Widget _buildStatGrid(int total, int active, int completed, int cancelled) {  
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _StatCard(title: 'Total Tiket', count: total.toString(), color: Colors.blue, icon: Icons.confirmation_number_outlined)),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(title: 'Status Aktif', count: active.toString(), color: Colors.orange, icon: Icons.pending_actions_rounded)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _StatCard(title: 'Selesai', count: completed.toString(), color: Colors.green, icon: Icons.check_circle_outline_rounded)),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(title: 'Dibatalkan', count: cancelled.toString(), color: Colors.red, icon: Icons.cancel_outlined)),
          ],
        ),
      ],
    );
  }

  Widget _buildTicketCard(BuildContext context, Map<String, dynamic> t) {
    final status = t['status'] ?? 'Menunggu Antrean';
    final statusColor = status == 'Selesai' ? Colors.green : (status == 'Dibatalkan' ? Colors.red : Colors.orange);
    final category = t['category'] ?? '-';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        title: Text(t['title'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$category • $status'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => TicketDetailPage(
            ticketId: t['id'],
            title: t['title'] ?? '-',
            description: t['description'] ?? '-',
            category: category,
            status: status,
            statusColor: statusColor,
            attachmentUrl: t['attachment_url'],
            assignedTo: t['assigned_to'],
          )));
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String count;
  final Color color;
  final IconData icon;
  const _StatCard({required this.title, required this.count, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: 0.1))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(count, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
