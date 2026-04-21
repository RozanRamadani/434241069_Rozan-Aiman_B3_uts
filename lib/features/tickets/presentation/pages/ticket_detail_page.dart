import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dartz/dartz.dart' as dartz;
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/comment_model.dart';
import '../../domain/entities/ticket_history.dart';
import '../bloc/ticket_bloc.dart';
import '../bloc/ticket_event.dart';
import '../bloc/ticket_state.dart';
import '../../domain/repositories/ticket_repository.dart';
import '../widgets/ticket_tracking_timeline.dart';

class TicketDetailPage extends StatefulWidget {
  final String ticketId;
  final String title;
  final String description;
  final String category;
  final String status;
  final Color statusColor;
  final String? attachmentUrl;
  final String? assignedTo;

  const TicketDetailPage({
    super.key,
    required this.ticketId,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.statusColor,
    this.attachmentUrl,
    this.assignedTo,
  });

  @override
  State<TicketDetailPage> createState() => _TicketDetailPageState();
}

class _TicketDetailPageState extends State<TicketDetailPage> {
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();
  final supabase = Supabase.instance.client;
  List<Comment> _comments = [];
  List<TicketHistory> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
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
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final repo = RepositoryProvider.of<TicketRepository>(context);
    
    // Fetch comments and history concurrently
    final results = await Future.wait([
      repo.getComments(widget.ticketId),
      repo.getTicketHistory(widget.ticketId),
    ]);

    if (mounted) {
      setState(() {
        _isLoading = false;
        
        final commentResult = results[0] as dartz.Either<dynamic, List<Comment>>;
        commentResult.fold((l) {}, (r) => _comments = r);

        final historyResult = results[1] as dartz.Either<dynamic, List<TicketHistory>>;
        historyResult.fold((l) {}, (r) => _history = r);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  Future<void> _sendComment() async {
    if (_commentController.text.trim().isEmpty) return;
    final message = _commentController.text.trim();
    _commentController.clear();

    final repo = RepositoryProvider.of<TicketRepository>(context);
    final result = await repo.sendComment(widget.ticketId, message);

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
        title: const Text('Batalkan Tiket'),
        content: const Text('Apakah Anda yakin ingin membatalkan tiket ini?'),  
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Kembali')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(dialogContext); // Tutup dialog
              context.read<TicketBloc>().add(UpdateStatusEvent(ticketId: widget.ticketId, status: 'Dibatalkan'));
            },
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );
  }

  void _showAssignBottomSheet() {
    context.read<TicketBloc>().add(FetchHelpdesksEvent());

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (bottomSheetContext) {
        return BlocBuilder<TicketBloc, TicketState>(
          builder: (context, state) {
            if (state is TicketLoading) {
              return const SizedBox(height: 250, child: Center(child: CircularProgressIndicator()));
            } else if (state is HelpdesksLoaded) {
              final helpdesks = state.helpdesks;
              if (helpdesks.isEmpty) {
                return const SizedBox(height: 250, child: Center(child: Text('Tidak ada helpdesk tersedia.')));
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Tugaskan Tiket ke', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: helpdesks.length,
                      itemBuilder: (context, index) {
                        final hd = helpdesks[index];
                        return ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.person)),
                          title: Text(hd['full_name'] ?? 'Unknown'),
                          onTap: () {
                            Navigator.pop(bottomSheetContext);
                            context.read<TicketBloc>().add(AssignTicketEvent(ticketId: widget.ticketId, helpdeskId: hd['id']));
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            } else if (state is TicketError) {
              return SizedBox(height: 250, child: Center(child: Text(state.message)));
            }
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

    return BlocListener<TicketBloc, TicketState>(
      listener: (context, state) {
        if (state is StatusUpdated) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status berhasil diubah!'), backgroundColor: Colors.green));
          Navigator.pop(context); // Kembali ke list
        } else if (state is TicketAssigned) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tiket berhasil ditugaskan!'), backgroundColor: Colors.green));
          Navigator.pop(context); // Kembali agar data direfresh
        } else if (state is TicketError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Detail #${widget.ticketId.substring(0, 4)}'),
          actions: [
            // Hak Akses Role
            if (widget.status == 'Menunggu Antrean' && role == 'user')
              IconButton(
                icon: const Icon(Icons.cancel_outlined, color: Colors.red),     
                onPressed: _showCancelDialog,
                tooltip: 'Batalkan Tiket',
              ),
            
            // Hak Akses Admin / Helpdesk: Proses Tiket
            if (widget.status == 'Menunggu Antrean' && (role == 'helpdesk' || role == 'admin'))
              TextButton.icon(
                onPressed: () => context.read<TicketBloc>().add(UpdateStatusEvent(ticketId: widget.ticketId, status: 'Diproses')),
                icon: const Icon(Icons.play_circle_outline, color: Colors.orange),
                label: const Text('Proses Tiket', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
              ),

            // Hak Akses Admin / Helpdesk: Selesaikan Tiket
            if (widget.status == 'Diproses' && (role == 'helpdesk' || role == 'admin'))
              TextButton.icon(
                onPressed: () => context.read<TicketBloc>().add(UpdateStatusEvent(ticketId: widget.ticketId, status: 'Selesai')),
                icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                label: const Text('Selesai', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16.0),
                children: [
                  _StatusBadge(label: widget.status, color: widget.statusColor),
                  const SizedBox(height: 16),
                  Text(widget.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(widget.category, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 16),

                  // Tracking Widget
                  TicketTrackingTimeline(status: widget.status),
                  _buildHistoryList(),

                  // Info Ditugaskan & Tombol Tugaskan
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.support_agent, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Ditugaskan ke:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              Text(widget.assignedTo ?? 'Belum ditugaskan', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        if (widget.status != 'Selesai' && widget.status != 'Dibatalkan' && (role == 'admin' || role == 'helpdesk'))
                          OutlinedButton(
                            onPressed: _showAssignBottomSheet,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              minimumSize: Size.zero,
                            ),
                            child: const Text('Tugaskan'),
                          ),
                      ],
                    ),
                  ),

                  const Divider(height: 32),
                  const Text('Deskripsi', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(widget.description, style: const TextStyle(height: 1.5)),

                  if (widget.attachmentUrl != null && widget.attachmentUrl!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text('Lampiran', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => Dialog(
                            backgroundColor: Colors.transparent,
                            insetPadding: const EdgeInsets.all(8),
                            child: Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                InteractiveViewer(
                                  maxScale: 5.0,
                                  child: CachedNetworkImage(
                                    imageUrl: widget.attachmentUrl!,
                                    fit: BoxFit.contain,
                                    placeholder: (context, url) => const CircularProgressIndicator(color: Colors.white),
                                    errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white),
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: IconButton(
                                    icon: const Icon(Icons.close, color: Colors.white, size: 32),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: widget.attachmentUrl!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: Colors.grey.shade200, child: const Center(child: CircularProgressIndicator())),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                        ),
                      ),
                    ),
                  ],

                  const Divider(height: 48),
                  const Text('Aktivitas & Komentar', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  if (_isLoading) 
                    const Center(child: CircularProgressIndicator())
                  else if (_comments.isEmpty)
                    const Center(child: Text('Belum ada komentar.'))
                  else
                    ..._comments.map((c) => _buildTimelineItem(
                      user: c.userId == currentUser?.id ? 'Anda' : (c.userName ?? 'Helpdesk'),
                      message: c.message,
                      isMe: c.userId == currentUser?.id,
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

  Widget _buildHistoryList() {
    if (_history.isEmpty) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.history, size: 16, color: Colors.blue),
              SizedBox(width: 8),
              Text('Riwayat Perubahan Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue)),
            ],
          ),
          const SizedBox(height: 8),
          ..._history.map((h) {
            final oldS = h.oldStatus ?? '-';
            final newS = h.newStatus ?? '-';
            final time = "\${h.changedAt.day}/\${h.changedAt.month} \${h.changedAt.hour.toString().padLeft(2, '0')}:\${h.changedAt.minute.toString().padLeft(2, '0')}";
            final userUpdate = h.userName ?? 'Sistem';

            return Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: '$oldS ', style: const TextStyle(color: Colors.grey, decoration: TextDecoration.lineThrough)),
                          const TextSpan(text: '→ ', style: TextStyle(color: Colors.grey)),
                          TextSpan(text: '$newS ', style: const TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: 'oleh $userUpdate pada $time', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
      child: SafeArea(
        child: Row(children: [
          Expanded(child: TextField(controller: _commentController, decoration: const InputDecoration(hintText: 'Balas...', border: InputBorder.none))),
          IconButton(icon: const Icon(Icons.send, color: Colors.blue), onPressed: _sendComment),
        ]),
      ),
    );
  }

  Widget _buildTimelineItem({required String user, required String message, required bool isMe}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(user, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isMe ? Colors.blue : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(message, style: TextStyle(color: isMe ? Colors.white : Colors.black87)),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)), child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)));
  }
}

