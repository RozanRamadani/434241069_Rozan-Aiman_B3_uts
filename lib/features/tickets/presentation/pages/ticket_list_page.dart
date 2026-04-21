import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/repositories/ticket_repository.dart';
import '../bloc/ticket_bloc.dart';
import '../bloc/ticket_event.dart';
import '../bloc/ticket_state.dart';
import 'ticket_detail_page.dart';
import '../../../../core/widgets/shimmer_loading.dart';

class TicketListPage extends StatefulWidget {
  const TicketListPage({super.key});

  @override
  State<TicketListPage> createState() => _TicketListPageState();
}

class _TicketListPageState extends State<TicketListPage> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Daftar Tiket'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(110),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari judul tiket...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty 
                        ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          }) 
                        : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                  ),
                ),
                const TabBar(
                  tabs: [
                    Tab(text: 'Aktif'),
                    Tab(text: 'Selesai'),
                    Tab(text: 'Dibatalkan'),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            BlocProvider(
              create: (context) => TicketBloc(ticketRepository: context.read<TicketRepository>()),
              child: _TicketListContent(statusFilter: 'Aktif', searchQuery: _searchQuery),
            ),
            BlocProvider(
              create: (context) => TicketBloc(ticketRepository: context.read<TicketRepository>()),
              child: _TicketListContent(statusFilter: 'Selesai', searchQuery: _searchQuery),
            ),
            BlocProvider(
              create: (context) => TicketBloc(ticketRepository: context.read<TicketRepository>()),
              child: _TicketListContent(statusFilter: 'Dibatalkan', searchQuery: _searchQuery),
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketListContent extends StatefulWidget {
  final String statusFilter;
  final String searchQuery;
  const _TicketListContent({required this.statusFilter, required this.searchQuery});

  @override
  State<_TicketListContent> createState() => _TicketListContentState();
}

class _TicketListContentState extends State<_TicketListContent> {
  @override
  void initState() {
    super.initState();
    context.read<TicketBloc>().add(FetchTickets(statusFilter: widget.statusFilter));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TicketBloc, TicketState>(
      builder: (context, state) {
        if (state is TicketLoading) {
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: 5,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, _) => ShimmerLoading.rounded(height: 100),
          );
        }
        
        if (state is TicketsLoaded) {
          final filteredTickets = state.tickets.where((t) {
            return t.title.toLowerCase().contains(widget.searchQuery);
          }).toList();

          if (filteredTickets.isEmpty) {
            return Center(
              child: Text(widget.searchQuery.isEmpty ? 'Tidak ada tiket.' : 'Tiket tidak ditemukan.'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => context.read<TicketBloc>().add(FetchTickets(statusFilter: widget.statusFilter)),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filteredTickets.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final ticket = filteredTickets[index];
                final statusColor = widget.statusFilter == 'Selesai' ? Colors.green : 
                                    widget.statusFilter == 'Dibatalkan' ? Colors.red : Colors.orange;

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: statusColor.withValues(alpha: 0.1),
                      child: Icon(
                        widget.statusFilter == 'Aktif' ? Icons.pending_actions_rounded : 
                        widget.statusFilter == 'Selesai' ? Icons.check_circle_outline : 
                        Icons.cancel_outlined,
                        color: statusColor,
                      ),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Tiket #${ticket.id.substring(0, 4)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
                          ),
                        ),
                        _StatusBadge(label: ticket.status, color: statusColor),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          ticket.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                        ),
                        const SizedBox(height: 12),
                        Row(children: [
                          const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('dd MMM yyyy').format(ticket.createdAt),
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                          const SizedBox(width: 16),
                          const Icon(Icons.category_outlined, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            ticket.category,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                        ]),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => TicketDetailPage(
                        ticketId: ticket.id,
                        title: ticket.title,
                        description: ticket.description,
                        category: ticket.category,
                        status: ticket.status,
                        statusColor: statusColor,
                        attachmentUrl: ticket.attachmentUrl,
                        assignedTo: ticket.assignedTo,
                      )));
                    },
                  ),
                );
              },
            ),
          );
        }
        return const SizedBox();
      },
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
