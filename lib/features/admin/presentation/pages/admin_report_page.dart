import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tiketdotcom/core/theme/app_theme.dart';

class AdminReportPage extends StatefulWidget {
  const AdminReportPage({super.key});

  @override
  State<AdminReportPage> createState() => _AdminReportPageState();
}

class _AdminReportPageState extends State<AdminReportPage> {
  final SupabaseClient _client = Supabase.instance.client;
  String _selectedPeriod = 'Semua'; // 'Minggu Ini', 'Bulan Ini', 'Semua'
  bool _isLoading = true;

  int _totalTickets = 0;
  int _resolvedTickets = 0;
  int _pendingTickets = 0;
  int _cancelledTickets = 0;

  List<Map<String, dynamic>> _helpdeskPerformance = [];
  List<Map<String, dynamic>> _categoryCounts = [];

  @override
  void initState() {
    super.initState();
    _fetchReportData();
  }

  Future<void> _fetchReportData() async {
    try {
      setState(() => _isLoading = true);

      // Define date filter
      DateTime? startDate;
      if (_selectedPeriod == 'Minggu Ini') {
        startDate = DateTime.now().subtract(const Duration(days: 7));
      } else if (_selectedPeriod == 'Bulan Ini') {
        startDate = DateTime.now().subtract(const Duration(days: 30));
      }

      // Fetch all tickets for status counts
      var query = _client.from('tickets').select('status, category, assigned_to');
      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }
      final ticketsData = await query;
      final tickets = List<Map<String, dynamic>>.from(ticketsData);

      // 1. Calculate status counts
      _totalTickets = tickets.length;
      _resolvedTickets = 0;
      _pendingTickets = 0;
      _cancelledTickets = 0;

      final Map<String, int> categoriesMap = {};

      for (var t in tickets) {
        final status = (t['status'] ?? '').toString().toLowerCase();
        if (status == 'selesai') {
          _resolvedTickets++;
        } else if (status == 'dibatalkan') {
          _cancelledTickets++;
        } else {
          _pendingTickets++;
        }

        final category = (t['category'] ?? 'Lainnya').toString();
        categoriesMap[category] = (categoriesMap[category] ?? 0) + 1;
      }

      // 2. Format Category Counts
      final List<Map<String, dynamic>> catList = [];
      categoriesMap.forEach((key, value) {
        catList.add({'category': key, 'count': value});
      });
      catList.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
      _categoryCounts = catList;

      // 3. Helpdesk Performance
      // Fetch resolved tickets grouped by assigned_to
      var helpdeskQuery = _client
          .from('tickets')
          .select('assigned_to, profiles(full_name)')
          .eq('status', 'Selesai');
      
      if (startDate != null) {
        helpdeskQuery = helpdeskQuery.gte('created_at', startDate.toIso8601String());
      }
      final performanceData = await helpdeskQuery;
      final performanceList = List<Map<String, dynamic>>.from(performanceData);

      final Map<String, Map<String, dynamic>> helpdeskMap = {};
      for (var p in performanceList) {
        final assignedTo = p['assigned_to'] as String?;
        if (assignedTo == null) continue;
        final profiles = p['profiles'] as Map<String, dynamic>?;
        final fullName = profiles != null ? (profiles['full_name'] ?? 'Helpdesk') as String : 'Helpdesk';

        if (!helpdeskMap.containsKey(assignedTo)) {
          helpdeskMap[assignedTo] = {'name': fullName, 'count': 0};
        }
        helpdeskMap[assignedTo]!['count'] = (helpdeskMap[assignedTo]!['count'] as int) + 1;
      }

      final List<Map<String, dynamic>> resolvedHelpdesks = helpdeskMap.values.toList();
      resolvedHelpdesks.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

      if (!mounted) return;

      setState(() {
        _helpdeskPerformance = resolvedHelpdesks;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat laporan: $e'),
          backgroundColor: AppTheme.statusCancelled,
        ),
      );
    }
  }

  Widget _buildStatCard(String title, String count, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: context.appSoftShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            count,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Laporan Sistem',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            color: context.isDark ? Colors.white : AppTheme.primaryDark,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchReportData,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // Period selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Periode Laporan',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: context.appTextPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: context.appInputFill,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedPeriod,
                          underline: const SizedBox(),
                          icon: const Icon(Icons.arrow_drop_down_rounded),
                          dropdownColor: context.appCardColor,
                          style: TextStyle(
                            color: context.appTextPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Minggu Ini', child: Text('Minggu Ini')),
                            DropdownMenuItem(value: 'Bulan Ini', child: Text('Bulan Ini')),
                            DropdownMenuItem(value: 'Semua', child: Text('Semua Waktu')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedPeriod = val;
                              });
                              _fetchReportData();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Stats Grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.6,
                    children: [
                      _buildStatCard(
                        'Total Tiket',
                        '$_totalTickets Tiket',
                        AppTheme.primary,
                        AppTheme.primary.withValues(alpha: 0.1),
                      ),
                      _buildStatCard(
                        'Selesai',
                        '$_resolvedTickets Tiket',
                        AppTheme.statusResolved,
                        AppTheme.statusResolved.withValues(alpha: 0.1),
                      ),
                      _buildStatCard(
                        'Pending',
                        '$_pendingTickets Tiket',
                        AppTheme.statusInProgress,
                        AppTheme.statusInProgress.withValues(alpha: 0.1),
                      ),
                      _buildStatCard(
                        'Dibatalkan',
                        '$_cancelledTickets Tiket',
                        AppTheme.statusCancelled,
                        AppTheme.statusCancelled.withValues(alpha: 0.1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Helpdesk Performance
                  Text(
                    '🏆 Performa Helpdesk',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: context.appTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_helpdeskPerformance.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.appCardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: context.appBorder),
                      ),
                      child: Center(
                        child: Text(
                          'Belum ada data performa.',
                          style: TextStyle(color: context.appTextSecondary),
                        ),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: context.appCardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: context.appBorder),
                        boxShadow: context.appSoftShadow,
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _helpdeskPerformance.length,
                        separatorBuilder: (context, index) => Divider(color: context.appBorder, height: 1),
                        itemBuilder: (context, index) {
                          final hp = _helpdeskPerformance[index];
                          final name = hp['name'] as String;
                          final count = hp['count'] as int;

                          // Dynamic rating stars based on resolved count (max 5)
                          int stars = 3;
                          if (count >= 8) {
                            stars = 5;
                          } else if (count >= 5) {
                            stars = 4;
                          } else if (count < 2) {
                            stars = 2;
                          }

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                              child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                            ),
                            title: Text(
                              name,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                                color: context.appTextPrimary,
                              ),
                            ),
                            subtitle: Text('$count selesai', style: TextStyle(color: context.appTextSecondary, fontSize: 13)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(
                                5,
                                (i) => Icon(
                                  Icons.star_rounded,
                                  color: i < stars ? const Color(0xFFF59E0B) : context.appTextMuted,
                                  size: 18,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 32),

                  // Category Breakdown
                  Text(
                    '📋 Kategori Terbanyak',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: context.appTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_categoryCounts.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.appCardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: context.appBorder),
                      ),
                      child: Center(
                        child: Text(
                          'Belum ada data kategori.',
                          style: TextStyle(color: context.appTextSecondary),
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: context.appCardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: context.appBorder),
                        boxShadow: context.appSoftShadow,
                      ),
                      child: Column(
                        children: _categoryCounts.map((cc) {
                          final category = cc['category'] as String;
                          final count = cc['count'] as int;
                          final percentage = _totalTickets > 0 ? (count / _totalTickets) : 0.0;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      category,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: context.appTextPrimary,
                                      ),
                                    ),
                                    Text(
                                      '${(percentage * 100).toStringAsFixed(0)}% ($count)',
                                      style: TextStyle(
                                        color: context.appTextSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: percentage,
                                    minHeight: 8,
                                    backgroundColor: context.appInputFill,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
