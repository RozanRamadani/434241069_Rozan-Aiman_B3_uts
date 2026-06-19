import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tiketdotcom/core/theme/app_theme.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/ticket.dart';

class TicketTrackingTimeline extends StatelessWidget {
  final Ticket ticket;

  const TicketTrackingTimeline({super.key, required this.ticket});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PROGRESS PENANGANAN', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textSecondary, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          
          _buildStep(
            'Tiket Dibuat',
            ticket.createdAt,
            isActive: true,
            isLast: false,
          ),
          
          if (ticket.status == 'Dibatalkan' && ticket.cancelledAt != null)
             _buildStep(
               'Tiket Dibatalkan', 
               ticket.cancelledAt, 
               isActive: true, 
               isLast: true,
               isError: true,
             )
          else ...[
            _buildStep(
              ticket.assignedToName != null ? 'Ditugaskan ke: ${ticket.assignedToName}' : 'Ditugaskan',
              ticket.assignedAt,
              isActive: ticket.assignedAt != null || _isStepActive(['Ditugaskan', 'Sedang Diproses', 'Selesai']),
              isLast: false,
            ),

            _buildStep(
              'Sedang Diproses',
              ticket.acceptedAt ?? ticket.processedAt,
              isActive: ticket.acceptedAt != null || ticket.processedAt != null || _isStepActive(['Sedang Diproses', 'Selesai']),
              isLast: false,
            ),

            _buildStep(
              'Selesai',
              ticket.resolvedAt,
              isActive: ticket.resolvedAt != null || _isStepActive(['Selesai']),
              isLast: true,
            ),
          ]
        ],
      ),
    );
  }

  bool _isStepActive(List<String> statuses) {
    return statuses.contains(ticket.status);
  }

  Widget _buildStep(String title, DateTime? timestamp, {bool isActive = false, bool isLast = false, bool isError = false}) {
    final dateFormat = DateFormat('dd MMM yyyy • HH:mm');
    final Color color = isError ? AppTheme.statusCancelled : (isActive ? AppTheme.primaryDark : AppTheme.textMuted.withValues(alpha: 0.5));
    
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 16,
                height: 16,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? color : Colors.transparent,
                  border: Border.all(color: color, width: 2),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 48,
                  color: isActive ? color : AppTheme.border,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                )
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                    color: isActive ? color : AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                if (timestamp != null)
                  Row(
                    children: [
                      Icon(Icons.calendar_month_rounded, size: 14, color: AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        dateFormat.format(timestamp.toLocal()),
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                if (!isLast) const Divider(height: 24, thickness: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
