import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dartz/dartz.dart' as dartz;

import 'package:intl/intl.dart';
import 'package:tiketdotcom/core/theme/app_theme.dart';
import '../../data/models/comment_model.dart';
import '../bloc/ticket_bloc.dart';
import '../bloc/ticket_event.dart';
import '../bloc/ticket_state.dart';
import '../../domain/entities/ticket.dart';
import '../../domain/repositories/ticket_repository.dart';
import '../widgets/ticket_tracking_timeline.dart';

class TicketDetailPage extends StatefulWidget {
  final Ticket ticket;

  const TicketDetailPage({
    super.key,
    required this.ticket,
  });

  @override
  State<TicketDetailPage> createState() => _TicketDetailPageState();
}

class _TicketDetailPageState extends State<TicketDetailPage> {
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();
  final supabase = Supabase.instance.client;
  List<Comment> _comments = [];
  bool _isLoading = true;
  late Ticket _ticket;

  @override
  void initState() {
    super.initState();
    _ticket = widget.ticket;
    Future.microtask(() => _fetchData());
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final repo = RepositoryProvider.of<TicketRepository>(context);
    final results = await Future.wait([
      repo.getComments(widget.ticket.id),
      repo.getTicketById(widget.ticket.id),
    ]);
    if (mounted) {
      setState(() {
        _isLoading = false;
        final commentResult = results[0] as dartz.Either<dynamic, List<Comment>>;
        commentResult.fold((l) {}, (r) => _comments = r);
        final ticketResult = results[1] as dartz.Either<dynamic, Ticket>;
        ticketResult.fold((l) {}, (freshTicket) => _ticket = freshTicket);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  Future<void> _sendComment() async {
    if (_commentController.text.trim().isEmpty) return;
    final message = _commentController.text.trim();
    _commentController.clear();
    final repo = RepositoryProvider.of<TicketRepository>(context);
    final result = await repo.sendComment(widget.ticket.id, message);
    if (mounted) {
      result.fold(
        (l) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.message))),
        (r) => _fetchData(),
      );
    }
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Batalkan Tiket', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: const Text('Apakah Anda yakin ingin membatalkan tiket ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Kembali')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.statusCancelled),
            onPressed: () { Navigator.pop(dialogContext); context.read<TicketBloc>().add(CancelTicketEvent(widget.ticket.id)); },
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Hapus Tiket', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: const Text('Apakah Anda yakin ingin menghapus tiket ini secara permanen?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.statusCancelled),
            onPressed: () { 
              Navigator.pop(dialogContext); 
              context.read<TicketBloc>().add(DeleteTicketEvent(widget.ticket.id)); 
            },
            child: const Text('Ya, Hapus'),
          ),
        ],
      ),
    );
  }

  void _showConfirmAssignDialog(String helpdeskId, String helpdeskName) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Konfirmasi Penugasan', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: Text('Tugaskan tiket ini ke $helpdeskName?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<TicketBloc>().add(AssignTicketEvent(ticketId: widget.ticket.id, helpdeskId: helpdeskId, helpdeskName: helpdeskName));
            },
            child: const Text('Ya, Tugaskan'),
          ),
        ],
      ),
    );
  }

  void _showAssignBottomSheet() {
    context.read<TicketBloc>().add(FetchHelpdesksEvent());
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (bottomSheetContext) {
        return BlocBuilder<TicketBloc, TicketState>(
          builder: (context, state) {
            if (state is TicketLoading) return const SizedBox(height: 250, child: Center(child: CircularProgressIndicator()));
            if (state is HelpdesksLoaded) {
              final helpdesks = state.helpdesks;
              if (helpdesks.isEmpty) return const SizedBox(height: 250, child: Center(child: Text('Tidak ada helpdesk tersedia.')));
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                  Padding(padding: const EdgeInsets.all(16), child: Text('Tugaskan Tiket ke', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 18))),
                  Expanded(
                    child: ListView.builder(
                      itemCount: helpdesks.length,
                      itemBuilder: (context, index) {
                        final hd = helpdesks[index];
                        final activeTickets = hd['active_tickets'] ?? 0;
                        final name = hd['full_name'] ?? 'Unknown';

                        return ListTile(
                          leading: CircleAvatar(backgroundColor: AppTheme.primary.withValues(alpha: 0.1), child: const Icon(Icons.person_rounded, color: AppTheme.primary)),
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('Sedang Menangani $activeTickets tiket', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                          onTap: () { 
                            Navigator.pop(bottomSheetContext); 
                            _showConfirmAssignDialog(hd['id'], name);
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            }
            if (state is TicketError) return SizedBox(height: 250, child: Center(child: Text(state.message)));
            return const SizedBox(height: 250);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = supabase.auth.currentUser;
    final role = currentUser?.userMetadata?['role'] ?? 'user';
    final avatarUrl = currentUser?.userMetadata?['avatar_url'];
    final statusColor = AppTheme.statusColor(_ticket.status);
    final statusBg = AppTheme.statusBgColor(_ticket.status);
    final shortId = '#TK-${_ticket.id.length >= 6 ? _ticket.id.substring(_ticket.id.length - 6) : _ticket.id}';
    
    String displayStatus = _ticket.status.toUpperCase();
    if (_ticket.status == 'Menunggu Antrean') displayStatus = 'DALAM ANTREAN';

    return BlocListener<TicketBloc, TicketState>(
      listener: (context, state) {
        if (state is StatusUpdated) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status berhasil diubah!'), backgroundColor: AppTheme.statusResolved));
          Navigator.pop(context, true);
        } else if (state is TicketAssigned) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tiket berhasil ditugaskan!'), backgroundColor: AppTheme.statusResolved));
          Navigator.pop(context, true);
        } else if (state is TicketAccepted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tiket mulai diproses!'), backgroundColor: AppTheme.statusResolved));
          Navigator.pop(context, true);
        } else if (state is TicketResolved) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tiket telah selesai!'), backgroundColor: AppTheme.statusResolved));
          Navigator.pop(context, true);
        } else if (state is TicketCancelled) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tiket dibatalkan!'), backgroundColor: AppTheme.statusResolved));
          Navigator.pop(context, true);
        } else if (state is TicketDeleted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tiket berhasil dihapus secara permanen!'), backgroundColor: AppTheme.statusResolved));
          Navigator.pop(context, true);
        } else if (state is TicketError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppTheme.statusCancelled));
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Helpdesk UNAIR', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: AppTheme.primaryDark)),
          centerTitle: true,
          actions: [
            if (role == 'admin')
              IconButton(icon: const Icon(Icons.delete_rounded, color: AppTheme.statusCancelled), onPressed: _showDeleteDialog),
            IconButton(icon: const Icon(Icons.notifications_rounded, color: AppTheme.primary), onPressed: () {}),
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null ? const Icon(Icons.person_rounded, color: AppTheme.primary, size: 18) : null,
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                children: [
                  // ── Ticket Header ──────────────────────────────
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(12)),
                        child: Text(displayStatus, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                      ),
                      const SizedBox(width: 8),
                      Text(shortId, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(_ticket.title, style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, height: 1.2)),
                  const SizedBox(height: 8),
                  Text('Dilaporkan pada ${DateFormat('dd MMM yyyy • HH:mm').format(_ticket.createdAt.toLocal())} WIB', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                  const SizedBox(height: 16),
                  
                  if (_ticket.status == 'Menunggu Antrean' && role == 'user')
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ActionChip(
                        backgroundColor: AppTheme.inputFill,
                        side: BorderSide.none,
                        label: Text('Batalkan Tiket', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
                        onPressed: _showCancelDialog,
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Timeline
                  TicketTrackingTimeline(ticket: _ticket),

                  // Petugas IT
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: AppTheme.cardShadow),
                    child: Column(
                      children: [
                        Text('PETUGAS IT', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textSecondary, letterSpacing: 1.5)),
                        const SizedBox(height: 16),
                        CircleAvatar(radius: 28, backgroundColor: AppTheme.primaryLight, child: const Icon(Icons.support_agent_rounded, size: 32, color: AppTheme.primary)),
                        const SizedBox(height: 12),
                        Text(_ticket.assignedToName ?? 'Belum Ditugaskan', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary)),
                        const SizedBox(height: 4),
                        Text('Infrastruktur Jaringan', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                        
                        if (_ticket.status != 'Selesai' && _ticket.status != 'Dibatalkan') ...[
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Admin Logic
                              if (role == 'admin') 
                                if (_ticket.status == 'Menunggu Antrean' || _ticket.status == 'Dalam Antrean')
                                  ElevatedButton(onPressed: _showAssignBottomSheet, child: const Text('Tugaskan Helpdesk'))
                                else if (_ticket.status == 'Ditugaskan')
                                  OutlinedButton(onPressed: _showAssignBottomSheet, child: const Text('Ganti Helpdesk')),
                              
                              // Helpdesk Logic
                              if (role == 'helpdesk' && _ticket.assignedTo == currentUser?.id) ...[
                                if (_ticket.status == 'Ditugaskan')
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                    onPressed: () => context.read<TicketBloc>().add(AcceptTicketEvent(_ticket.id)),
                                    child: const Text('Terima Tiket'),
                                  )
                                else if (_ticket.status == 'Sedang Diproses')
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                    onPressed: () => context.read<TicketBloc>().add(ResolveTicketEvent(_ticket.id)),
                                    child: const Text('Selesai'),
                                  ),
                              ],

                              // User Info
                              if (role == 'user') ...[
                                if (_ticket.status == 'Ditugaskan')
                                  Text('Menunggu helpdesk menerima tiket', style: TextStyle(color: AppTheme.textMuted, fontStyle: FontStyle.italic)),
                                if (_ticket.status == 'Sedang Diproses')
                                  Text('Tiket sedang ditangani', style: TextStyle(color: AppTheme.textMuted, fontStyle: FontStyle.italic)),
                              ],
                            ],
                          )
                        ]
                      ],
                    ),
                  ),

                  // Chat Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Diskusi & Update', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textPrimary)),
                      Text('${_comments.length} Pesan', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Description as the first message
                  _buildChatBubble(user: 'Anda', message: _ticket.description, isMe: true, time: DateFormat('HH:mm').format(_ticket.createdAt.toLocal())),
                  
                  if (_ticket.attachmentUrl != null && _ticket.attachmentUrl!.isNotEmpty)
                    _buildAttachmentBubble(isMe: true),

                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    ..._comments.map((c) => _buildChatBubble(
                      user: c.userId == currentUser?.id ? 'Anda' : (c.userName ?? 'Helpdesk'),
                      message: c.message, isMe: c.userId == currentUser?.id,
                      time: DateFormat('HH:mm').format(c.createdAt),
                    )),
                ],
              ),
            ),
            _buildChatInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))]),
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: AppTheme.inputFill, borderRadius: BorderRadius.circular(AppTheme.radiusPill)),
          child: Row(children: [
            IconButton(icon: const Icon(Icons.attach_file_rounded), color: AppTheme.textSecondary, onPressed: () {}),
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: const InputDecoration(hintText: 'Ketik pesan balasan...', border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none),
                textInputAction: TextInputAction.send, onSubmitted: (_) => _sendComment(),
              ),
            ),
            Container(
              width: 40, height: 40,
              decoration: const BoxDecoration(color: AppTheme.primaryDark, shape: BoxShape.circle),
              child: IconButton(icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18), onPressed: _sendComment),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildChatBubble({required String user, required String message, required bool isMe, required String time}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(radius: 14, backgroundColor: AppTheme.primary.withValues(alpha: 0.1), child: const Icon(Icons.support_agent_rounded, size: 16, color: AppTheme.primary)),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start, 
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 4),
                    child: Text('$user (IT)', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                  ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isMe ? AppTheme.primaryDark : Colors.white,
                    borderRadius: BorderRadius.circular(20).copyWith(
                      bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
                      bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
                    ),
                    boxShadow: isMe ? null : AppTheme.softShadow,
                  ),
                  child: Text(message, style: TextStyle(color: isMe ? Colors.white : AppTheme.textSecondary, height: 1.4, fontSize: 13)),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, right: 4, left: 4),
                  child: Text('Hari ini, $time', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAttachmentBubble({required bool isMe}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFD1FAE5), // Light green
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Color(0xFF34D399), shape: BoxShape.circle),
                  child: const Icon(Icons.image_rounded, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Screenshot_Error.png', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF065F46))),
                    const Text('2.4 MB', style: TextStyle(fontSize: 10, color: Color(0xFF065F46))),
                  ],
                ),
                const SizedBox(width: 16),
                const Icon(Icons.download_rounded, color: Color(0xFF065F46), size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
