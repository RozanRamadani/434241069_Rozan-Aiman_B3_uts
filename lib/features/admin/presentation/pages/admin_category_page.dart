import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tiketdotcom/core/theme/app_theme.dart';

class AdminCategoryPage extends StatefulWidget {
  const AdminCategoryPage({super.key});

  @override
  State<AdminCategoryPage> createState() => _AdminCategoryPageState();
}

class _AdminCategoryPageState extends State<AdminCategoryPage> {
  final SupabaseClient _client = Supabase.instance.client;
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;

  final List<Map<String, dynamic>> _presetIcons = [
    {'name': 'wifi', 'icon': Icons.wifi_rounded},
    {'name': 'person', 'icon': Icons.person_rounded},
    {'name': 'desktop', 'icon': Icons.computer_rounded},
    {'name': 'printer', 'icon': Icons.print_rounded},
    {'name': 'email', 'icon': Icons.email_rounded},
    {'name': 'phone', 'icon': Icons.phone_rounded},
    {'name': 'lock', 'icon': Icons.lock_rounded},
    {'name': 'settings', 'icon': Icons.settings_rounded},
    {'name': 'grid', 'icon': Icons.grid_view_rounded},
  ];

  final List<String> _presetColors = [
    '#FF6B35',
    '#4A90D9',
    '#7B68EE',
    '#50C878',
    '#EF4444',
    '#EC4899',
    '#F59E0B',
    '#06B6D4',
  ];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      setState(() => _isLoading = true);
      final data = await _client.from('categories').select().order('created_at', ascending: false);
      if (!mounted) return;
      setState(() {
        _categories = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('Gagal memuat kategori: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.statusCancelled : AppTheme.statusResolved,
      ),
    );
  }

  IconData _getIconData(String iconName) {
    final match = _presetIcons.firstWhere(
      (element) => element['name'] == iconName,
      orElse: () => {'icon': Icons.help_outline_rounded},
    );
    return match['icon'] as IconData;
  }

  Color _getColorFromHex(String hexColor) {
    try {
      hexColor = hexColor.replaceAll('#', '');
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor';
      }
      return Color(int.parse('0x$hexColor'));
    } catch (_) {
      return const Color(0xFFFF6B35);
    }
  }

  Future<void> _deleteCategory(Map<String, dynamic> category) async {
    final name = category['name'];
    final id = category['id'];
    try {
      // Check if tickets are using this category
      final ticketCheck = await _client
          .from('tickets')
          .select('id')
          .eq('category', name);
      
      final ticketCount = (ticketCheck as List).length;

      if (!mounted) return;

      bool confirmDelete = false;

      if (ticketCount > 0) {
        confirmDelete = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Peringatan Penghapusan'),
                content: Text(
                    'Kategori "$name" ini masih digunakan oleh $ticketCount tiket. Tetap hapus?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Batal'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: TextButton.styleFrom(foregroundColor: AppTheme.statusCancelled),
                    child: const Text('Tetap Hapus'),
                  ),
                ],
              ),
            ) ??
            false;
      } else {
        confirmDelete = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Konfirmasi Hapus'),
                content: Text('Yakin ingin menghapus kategori "$name"?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Batal'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: TextButton.styleFrom(foregroundColor: AppTheme.statusCancelled),
                    child: const Text('Hapus'),
                  ),
                ],
              ),
            ) ??
            false;
      }

      if (confirmDelete) {
        setState(() => _isLoading = true);
        await _client.from('categories').delete().eq('id', id);
        _showSnackBar('Kategori berhasil dihapus');
        _fetchCategories();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('Gagal menghapus kategori: $e', isError: true);
    }
  }

  void _showFormDialog({Map<String, dynamic>? category}) {
    final isEdit = category != null;
    final nameController = TextEditingController(text: isEdit ? category['name'] : '');
    String selectedIcon = isEdit ? category['icon'] : 'wifi';
    String selectedColor = isEdit ? category['color'] : '#FF6B35';
    bool isActive = isEdit ? category['is_active'] : true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: context.appBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusMd)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEdit ? 'Edit Kategori' : 'Tambah Kategori',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: context.appTextPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  )
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Nama Kategori',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: context.appTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  hintText: 'Masukkan nama kategori',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Pilih Icon',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: context.appTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 5,
                shrinkWrap: true,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                physics: const NeverScrollableScrollPhysics(),
                children: _presetIcons.map((item) {
                  final name = item['name'] as String;
                  final icon = item['icon'] as IconData;
                  final isSelected = selectedIcon == name;
                  return GestureDetector(
                    onTap: () => setModalState(() => selectedIcon = name),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _getColorFromHex(selectedColor).withValues(alpha: 0.2)
                            : context.appInputFill,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? _getColorFromHex(selectedColor) : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: isSelected ? _getColorFromHex(selectedColor) : context.appTextSecondary,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text(
                'Pilih Warna',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: context.appTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _presetColors.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final colorHex = _presetColors[index];
                    final color = _getColorFromHex(colorHex);
                    final isSelected = selectedColor == colorHex;
                    return GestureDetector(
                      onTap: () => setModalState(() => selectedColor = colorHex),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? context.appTextPrimary : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    );
                  },
                ),
              ),
              if (isEdit) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Status Aktif',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: context.appTextPrimary,
                      ),
                    ),
                    Switch(
                      value: isActive,
                      activeThumbColor: AppTheme.primary,
                      onChanged: (val) => setModalState(() => isActive = val),
                    )
                  ],
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      _showSnackBar('Nama kategori wajib diisi', isError: true);
                      return;
                    }
                    Navigator.pop(ctx);
                    setState(() => _isLoading = true);
                    try {
                      if (isEdit) {
                        await _client.from('categories').update({
                          'name': name,
                          'icon': selectedIcon,
                          'color': selectedColor,
                          'is_active': isActive,
                          'updated_at': DateTime.now().toIso8601String(),
                        }).eq('id', category['id']);
                        _showSnackBar('Kategori berhasil diperbarui');
                      } else {
                        await _client.from('categories').insert({
                          'name': name,
                          'icon': selectedIcon,
                          'color': selectedColor,
                          'is_active': true,
                        });
                        _showSnackBar('Kategori berhasil ditambahkan');
                      }
                      _fetchCategories();
                    } catch (e) {
                      setState(() => _isLoading = false);
                      _showSnackBar('Gagal menyimpan kategori: $e', isError: true);
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Kelola Kategori',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            color: context.isDark ? Colors.white : AppTheme.primaryDark,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton.icon(
              onPressed: () => _showFormDialog(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Tambah'),
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                foregroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
              ? Center(
                  child: Text(
                    'Belum ada kategori.',
                    style: TextStyle(color: context.appTextSecondary),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: _categories.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final name = cat['name'] as String;
                    final iconName = cat['icon'] as String;
                    final colorHex = cat['color'] as String;
                    final isActive = cat['is_active'] as bool;
                    final catColor = _getColorFromHex(colorHex);

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.appCardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: context.appBorder),
                        boxShadow: context.appSoftShadow,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getIconData(iconName),
                              color: catColor,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: context.appTextPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: isActive ? AppTheme.statusResolved : AppTheme.statusCancelled,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isActive ? 'Aktif' : 'Nonaktif',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: context.appTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: AppTheme.primary),
                            onPressed: () => _showFormDialog(category: cat),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.statusCancelled),
                            onPressed: () => _deleteCategory(cat),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
