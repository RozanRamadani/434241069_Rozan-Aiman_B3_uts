import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tiketdotcom/core/theme/app_theme.dart';

class TicketTrackingTimeline extends StatelessWidget {
  final String status;

  const TicketTrackingTimeline({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    int currentStep = 0;
    bool isCancelled = status.toLowerCase() == 'dibatalkan';

    final normalizedStatus = status.toLowerCase();
    if (normalizedStatus == 'menunggu antrean' || normalizedStatus == 'dalam antrean') {
      currentStep = 0;
    } else if (normalizedStatus == 'diproses' || normalizedStatus == 'dianalisis') {
      currentStep = 1;
    } else if (normalizedStatus == 'perbaikan') {
      currentStep = 2;
    } else if (normalizedStatus == 'selesai') {
      currentStep = 3;
    }

    final steps = ['Diterima', 'Dianalisis', 'Perbaikan', isCancelled ? 'Batal' : 'Selesai'];
    final stepIcons = [
      Icons.check_rounded,
      Icons.format_quote_rounded,
      Icons.build_rounded,
      isCancelled ? Icons.close_rounded : Icons.check_circle_outline_rounded,
    ];

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
          Row(
            children: List.generate(steps.length, (index) {
              bool isPassed = index <= currentStep || (isCancelled && index == 3);
              bool isLast = index == steps.length - 1;

              Color stepColor = isPassed
                  ? (isCancelled && index == 3 ? AppTheme.statusCancelled : AppTheme.primaryDark)
                  : Colors.white;
              Color iconColor = isPassed ? Colors.white : AppTheme.border;
              Color borderColor = isPassed ? Colors.transparent : AppTheme.border;

              return Expanded(
                child: Row(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: stepColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: borderColor, width: 2),
                          ),
                          child: Icon(stepIcons[index], size: 18, color: iconColor),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          steps[index],
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: isPassed ? AppTheme.primaryDark : AppTheme.textMuted,
                            fontWeight: isPassed ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          height: 3,
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: isPassed && index < currentStep ? AppTheme.primaryDark : AppTheme.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
