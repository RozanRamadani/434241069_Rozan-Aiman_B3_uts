import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tiketdotcom/core/theme/app_theme.dart';
import 'package:tiketdotcom/features/tickets/domain/entities/ticket.dart';
import 'package:tiketdotcom/features/tickets/presentation/bloc/ticket_bloc.dart';
import 'package:tiketdotcom/features/tickets/presentation/bloc/ticket_event.dart';
import 'package:tiketdotcom/features/tickets/presentation/bloc/ticket_state.dart';

class CreateTicketPage extends StatefulWidget {
  const CreateTicketPage({super.key});

  @override
  State<CreateTicketPage> createState() => _CreateTicketPageState();
}

class _CreateTicketPageState extends State<CreateTicketPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'Jaringan & Internet';
  String _selectedPriority = 'Sedang'; // For UI only, as model might not have priority right now.
  XFile? _selectedImage;
  Uint8List? _imageBytes;

  final List<Map<String, dynamic>> _categories = [
    {'id': 'Jaringan & Internet', 'icon': Icons.wifi_rounded},
    {'id': 'Akun & Login', 'icon': Icons.account_circle_rounded},
    {'id': 'Hardware', 'icon': Icons.computer_rounded},
    {'id': 'Lainnya', 'icon': Icons.grid_view_rounded},
  ];

  final List<String> _priorities = ['Rendah', 'Sedang', 'Tinggi'];
  final _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              ListTile(
                leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.camera_alt_rounded, color: AppTheme.primary)),
                title: const Text('Ambil dari Kamera', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () => _pickImage(ImageSource.camera),
              ),
              ListTile(
                leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFFF59E0B).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.photo_library_rounded, color: Color(0xFFF59E0B))),
                title: const Text('Pilih dari Galeri', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () => _pickImage(ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context);
    final XFile? image = await _picker.pickImage(source: source, imageQuality: 70);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() { _selectedImage = image; _imageBytes = bytes; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = Supabase.instance.client.auth.currentUser?.userMetadata?['avatar_url'];

    return BlocListener<TicketBloc, TicketState>(
      listener: (context, state) {
        if (state is TicketCreated) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tiket berhasil dikirim!'), backgroundColor: AppTheme.statusResolved));
          // Reset form since this is a tab
          _titleController.clear();
          _descriptionController.clear();
          setState(() { _selectedImage = null; _imageBytes = null; });
        } else if (state is TicketError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppTheme.statusCancelled));
        }
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false, // Hidden if in BottomNav
          title: Text('Buat Tiket Baru', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: AppTheme.primaryDark)),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null ? const Icon(Icons.person_rounded, color: AppTheme.primary, size: 20) : null,
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Header
                Center(
                  child: Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.confirmation_number_rounded, color: Colors.white, size: 32),
                  ),
                ),
                const SizedBox(height: 20),
                Center(child: Text('Ada yang bisa kami bantu?', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary))),
                const SizedBox(height: 8),
                Center(
                  child: Text('Berikan detail kendala Anda agar tim kami dapat segera memberikan solusi terbaik.',
                  textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4)),
                ),
                const SizedBox(height: 32),

                // Kategori Masalah
                Text('Kategori Masalah', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.8,
                  children: _categories.map((cat) {
                    final isSelected = _selectedCategory == cat['id'];
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat['id']),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFFFEDD5) : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: isSelected ? Colors.transparent : AppTheme.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(cat['icon'], color: isSelected ? const Color(0xFF9A3412) : AppTheme.textSecondary, size: 18),
                            const SizedBox(width: 8),
                            Text(cat['id'], style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: isSelected ? const Color(0xFF9A3412) : AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Judul
                Text('Judul Laporan', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(hintText: 'Contoh: Tidak bisa akses email @unair.ac.id'),
                  validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 24),

                // Deskripsi
                Text('Detail Kendala', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 5,
                  decoration: const InputDecoration(hintText: 'Ceritakan detail masalah yang Anda alami...'),
                  validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 24),

                // Lampiran
                Text('Lampiran Foto (Optional)', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    GestureDetector(
                      onTap: _showImageSourceDialog,
                      child: Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.border, width: 2, style: BorderStyle.none),
                        ),
                        child: CustomPaint(
                          painter: _DottedBorderPainter(color: AppTheme.border),
                          child: _imageBytes != null
                            ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.memory(_imageBytes!, fit: BoxFit.cover))
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt_rounded, color: AppTheme.textMuted, size: 24),
                                  const SizedBox(height: 4),
                                  Text('UPLOAD', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textMuted)),
                                ],
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (_imageBytes != null)
                      GestureDetector(
                        onTap: () => setState(() { _selectedImage = null; _imageBytes = null; }),
                        child: Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(color: AppTheme.inputFill, borderRadius: BorderRadius.circular(16)),
                          child: const Icon(Icons.delete_rounded, color: AppTheme.statusCancelled),
                        ),
                      )
                    else ...[
                      Container(width: 80, height: 80, decoration: BoxDecoration(color: AppTheme.inputFill, borderRadius: BorderRadius.circular(16))),
                      const SizedBox(width: 12),
                      Container(width: 80, height: 80, decoration: BoxDecoration(color: AppTheme.inputFill, borderRadius: BorderRadius.circular(16))),
                    ]
                  ],
                ),
                const SizedBox(height: 8),
                Text('Format: JPG, PNG. Maksimal 5MB per file.', style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontStyle: FontStyle.italic)),
                const SizedBox(height: 24),

                // Prioritas
                Text('Prioritas', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                const SizedBox(height: 12),
                Row(
                  children: _priorities.map((p) {
                    final isSelected = _selectedPriority == p;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedPriority = p),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFFFEDD5) : AppTheme.inputFill,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: Text(p, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: isSelected ? const Color(0xFF9A3412) : AppTheme.textPrimary)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),

                // Submit Button
                BlocBuilder<TicketBloc, TicketState>(
                  builder: (context, state) {
                    final isLoading = state is TicketLoading;
                    return SizedBox(
                      width: double.infinity, height: 56,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : () {
                          if (_formKey.currentState!.validate()) {
                            final ticket = Ticket(id: '', title: _titleController.text, description: _descriptionController.text, category: _selectedCategory, status: 'Dalam Antrean', createdAt: DateTime.now());
                            context.read<TicketBloc>().add(CreateTicketEvent(ticket,
                              imageFile: (!kIsWeb && _selectedImage != null) ? File(_selectedImage!.path) : null,
                              imageBytes: _imageBytes, imageExt: _selectedImage?.name.split('.').last));
                          }
                        },
                        child: isLoading
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                            : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.send_rounded, size: 20), SizedBox(width: 8), Text('Kirim Tiket', style: TextStyle(fontSize: 16))]),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text.rich(TextSpan(children: [
                    const TextSpan(text: 'Estimasi waktu respon: '),
                    TextSpan(text: '2 - 4 Jam Kerja', style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primaryDark)),
                  ]), style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DottedBorderPainter extends CustomPainter {
  final Color color;
  _DottedBorderPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 2..style = PaintingStyle.stroke;
    const dashWidth = 5.0;
    const dashSpace = 4.0;
    final rrect = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(16));
    final path = Path()..addRRect(rrect);
    for (PathMetric measurePath in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < measurePath.length) {
        canvas.drawPath(measurePath.extractPath(distance, distance + dashWidth), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
