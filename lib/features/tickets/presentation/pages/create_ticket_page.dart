import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
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
  String? _selectedCategory;
  XFile? _selectedImage;
  Uint8List? _imageBytes;

  final List<String> _categories = ['IT Support', 'Maintenance', 'Fasilitas', 'Lainnya'];
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Ambil dari Kamera'),
              onTap: () => _pickImage(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Pilih dari Galeri'),
              onTap: () => _pickImage(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context);
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 70, // Optimasi: Kompres gambar (Poin 4 panduan)
    );
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImage = image;
        _imageBytes = bytes;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TicketBloc, TicketState>(
      listener: (context, state) {
        if (state is TicketCreated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tiket berhasil dibuat!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        } else if (state is TicketError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Buat Tiket Baru'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Detail Kendala',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Subjek / Judul Kendala',
                    prefixIcon: Icon(Icons.title_rounded),
                  ),
                  validator: (value) => value!.isEmpty ? 'Judul tidak boleh kosong' : null,
                ),
                const SizedBox(height: 20),
                
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Kategori Layanan',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => _selectedCategory = v),
                  validator: (v) => v == null ? 'Pilih kategori' : null,
                ),
                const SizedBox(height: 20),
                
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi Masalah',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) => value!.isEmpty ? 'Deskripsi tidak boleh kosong' : null,
                ),
                const SizedBox(height: 24),
                
                const Text('Lampiran Foto (Opsional)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                
                GestureDetector(
                  onTap: _showImageSourceDialog,
                  child: Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                      image: _imageBytes != null
                        ? DecorationImage(image: MemoryImage(_imageBytes!), fit: BoxFit.cover)
                        : null,
                    ),
                    child: _selectedImage == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt_outlined, size: 40, color: Colors.grey[400]),
                            const Text('Ambil Foto atau Pilih Galeri'),
                          ],
                        )
                      : null,
                  ),
                ),
                if (_selectedImage != null)
                  TextButton.icon(
                    onPressed: () => setState(() { 
                      _selectedImage = null;
                      _imageBytes = null;
                    }),     
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: const Text('Hapus Foto', style: TextStyle(color: Colors.red)),
                  ),
                
                const SizedBox(height: 40),

                BlocBuilder<TicketBloc, TicketState>(
                  builder: (context, state) {
                    return SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: state is TicketLoading
                            ? null
                            : () {
                                if (_formKey.currentState!.validate()) {        
                                  final ticket = Ticket(
                                    id: '',
                                    title: _titleController.text,
                                    description: _descriptionController.text,   
                                    category: _selectedCategory!,
                                    status: 'Menunggu Antrean',
                                    createdAt: DateTime.now(),
                                  );
                                  context.read<TicketBloc>().add(
                                    CreateTicketEvent(
                                      ticket,
                                      imageFile: (!kIsWeb && _selectedImage != null) ? File(_selectedImage!.path) : null,
                                      imageBytes: _imageBytes,
                                      imageExt: _selectedImage?.name.split('.').last,
                                    ),
                                  );
                                }
                              },
                        child: state is TicketLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('KIRIM TIKET', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
