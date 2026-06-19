import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tiketdotcom/core/theme/app_theme.dart';
import '../../domain/repositories/ticket_repository.dart';
import '../bloc/ticket_bloc.dart';
import '../bloc/ticket_event.dart';
import '../bloc/ticket_state.dart';
import 'ticket_detail_page.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import 'notification_page.dart';

class TicketListPage extends StatefulWidget {
  const TicketListPage({super.key});

  @override
  State<TicketListPage> createState() => _TicketListPageState();
}

class _TicketListPageState extends State<TicketListPage> {
  String _searchQuery = '';
  final _searchController = TextEditingController();
  String? _selectedHelpdesk;
  List<Map<String, dynamic>> _helpdesks = [];
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkRoleAndFetchHelpdesks();
  }

  Future<void> _checkRoleAndFetchHelpdesks() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user?.userMetadata?['role'] == 'admin') {
      setState(() => _isAdmin = true);
      final repo = context.read<TicketRepository>();
      final result = await repo.getHelpdesks();
      result.fold(
        (l) => null,
        (r) => setState(() => _helpdesks = r),
      );
    }
  }

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
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          toolbarHeight: 70,
          title: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.domain_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Helpdesk UNAIR', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.primaryDark)),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.notifications_rounded, color: AppTheme.primary, size: 28),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationPage())),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            // Search & Tabs
            Container(
              color: AppTheme.background,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  // Search bar
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppTheme.radiusPill)),
                    child: Row(
                      children: [
                        Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Cari tiket bantuan...',
                              hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                              border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.only(bottom: 12), // align with icon
                            ),
                            onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          IconButton(icon: const Icon(Icons.clear_rounded, size: 18), padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); })
                      ],
                    ),
                  ),
                  if (_isAdmin && _helpdesks.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppTheme.radiusPill)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          isExpanded: true,
                          value: _selectedHelpdesk,
                          hint: Text('Semua Helpdesk', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                          icon: Icon(Icons.arrow_drop_down_rounded, color: AppTheme.textMuted),
                          items: [
                            DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Semua Helpdesk', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600)),
                            ),
                            ..._helpdesks.map((h) => DropdownMenuItem<String?>(
                              value: h['id'],
                              child: Text(h['full_name'] ?? 'Unknown', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600)),
                            )),
                          ],
                          onChanged: (val) {
                            setState(() => _selectedHelpdesk = val);
                          },
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  // Tabs
                  Container(
                    height: 44,
                    decoration: BoxDecoration(color: AppTheme.inputFill, borderRadius: BorderRadius.circular(12)),
                    child: TabBar(
                      indicator: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: AppTheme.softShadow),
                      labelColor: AppTheme.primaryDark,
                      unselectedLabelColor: AppTheme.textSecondary,
                      labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
                      unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      tabs: const [Tab(text: 'Aktif'), Tab(text: 'Selesai'), Tab(text: 'Dibatalkan')],
                    ),
                  ),
                ],
              ),
            ),
            // Tab Views
            Expanded(
              child: TabBarView(
                children: [
                  BlocProvider(create: (c) => TicketBloc(ticketRepository: c.read<TicketRepository>()), child: _TicketTab(statusFilter: 'Aktif', searchQuery: _searchQuery, helpdeskFilter: _selectedHelpdesk)),
                  BlocProvider(create: (c) => TicketBloc(ticketRepository: c.read<TicketRepository>()), child: _TicketTab(statusFilter: 'Selesai', searchQuery: _searchQuery, helpdeskFilter: _selectedHelpdesk)),
                  BlocProvider(create: (c) => TicketBloc(ticketRepository: c.read<TicketRepository>()), child: _TicketTab(statusFilter: 'Dibatalkan', searchQuery: _searchQuery, helpdeskFilter: _selectedHelpdesk)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketTab extends StatefulWidget {
  final String statusFilter;
  final String searchQuery;
  final String? helpdeskFilter;
  const _TicketTab({required this.statusFilter, required this.searchQuery, this.helpdeskFilter});

  @override
  State<_TicketTab> createState() => _TicketTabState();
}

class _TicketTabState extends State<_TicketTab> {
  @override
  void initState() {
    super.initState();
    context.read<TicketBloc>().add(FetchTickets(statusFilter: widget.statusFilter, helpdeskFilter: widget.helpdeskFilter));
  }

  @override
  void didUpdateWidget(covariant _TicketTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.helpdeskFilter != widget.helpdeskFilter) {
      context.read<TicketBloc>().add(FetchTickets(statusFilter: widget.statusFilter, helpdeskFilter: widget.helpdeskFilter));
    }
  }

  String _formatDate(DateTime time) {
    return DateFormat('dd MMM yyyy').format(time);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TicketBloc, TicketState>(
      builder: (context, state) {
        if (state is TicketLoading) {
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            itemCount: 5,
            separatorBuilder: (_, i) => const SizedBox(height: 16),
            itemBuilder: (_, i) => ShimmerLoading.rounded(height: 120),
          );
        }

        if (state is TicketsLoaded) {
          final filtered = state.tickets.where((t) => t.title.toLowerCase().contains(widget.searchQuery)).toList();

          if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.searchQuery.isEmpty ? Icons.inbox_rounded : Icons.search_off_rounded, size: 56, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text(widget.searchQuery.isEmpty ? 'Tidak ada tiket.' : 'Tiket tidak ditemukan.', style: TextStyle(color: AppTheme.textMuted)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => context.read<TicketBloc>().add(FetchTickets(statusFilter: widget.statusFilter, helpdeskFilter: widget.helpdeskFilter)),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              itemCount: filtered.length,
              separatorBuilder: (_, i) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final ticket = filtered[index];
                final statusColor = AppTheme.statusColor(ticket.status);
                final statusBg = AppTheme.statusBgColor(ticket.status);
                final shortId = '#TK-${ticket.id.length >= 5 ? ticket.id.substring(ticket.id.length - 5) : ticket.id}';
                
                String displayStatus = ticket.status.toUpperCase();
                if (ticket.status == 'Menunggu Antrean') displayStatus = 'DALAM ANTREAN';

                // Blue line effect for active tickets like reference
                final bool isActive = ticket.status != 'Selesai' && ticket.status != 'Dibatalkan';

                return Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TicketDetailPage(
                          ticket: ticket,
                        ))),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(8)),
                                  child: Text(displayStatus, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: statusColor, letterSpacing: 0.5)),
                                ),
                                const Spacer(),
                                Text(shortId, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 14),
                            // Title
                            Text(ticket.title, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 16),
                            // Footer (Category & Date)
                            Row(
                              children: [
                                Icon(Icons.category_rounded, size: 14, color: AppTheme.textSecondary),
                                const SizedBox(width: 6),
                                Text(ticket.category, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                                const SizedBox(width: 16),
                                Icon(Icons.calendar_today_rounded, size: 14, color: AppTheme.textSecondary),
                                const SizedBox(width: 6),
                                Text(_formatDate(ticket.createdAt), style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isActive)
                      Positioned(
                        left: 0, top: 24, bottom: 24,
                        child: Container(
                          width: 4,
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          );
        }
        if (state is TicketError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline_rounded, size: 56, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text(
                    state.message,
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => context.read<TicketBloc>().add(FetchTickets(statusFilter: widget.statusFilter, helpdeskFilter: widget.helpdeskFilter)),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          );
        }
        return const SizedBox();
      },
    );
  }
}
