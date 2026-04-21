import 'package:flutter/material.dart';

class TicketTrackingTimeline extends StatelessWidget {
  final String status;

  const TicketTrackingTimeline({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    int currentStep = 0;
    bool isCancelled = status == 'Dibatalkan';

    if (status == 'Menunggu Antrean') {
      currentStep = 0;
    } else if (status == 'Diproses') {
      currentStep = 1;
    } else if (status == 'Selesai') {
      currentStep = 2;
    }

    final steps = ['Menunggu', 'Diproses', isCancelled ? 'Dibatalkan' : 'Selesai'];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(steps.length, (index) {
          bool isPassed = index <= currentStep || (isCancelled && index == 2);
          bool isCurrent = index == currentStep || (isCancelled && index == 2);
          bool isLast = index == steps.length - 1;
          
          Color stepColor = isPassed 
              ? (isCancelled && index == 2 ? Colors.red : Colors.blue.shade600) 
              : Colors.grey.shade300;

          return Expanded(
            flex: isLast ? 1 : 2,
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: stepColor,
                        child: Icon(
                          isPassed 
                              ? (isCancelled && index == 2 ? Icons.close : Icons.check) 
                              : Icons.circle,
                          size: 14, 
                          color: Colors.white
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        steps[index], 
                        style: TextStyle(
                          fontSize: 10, 
                          color: isCurrent ? Colors.black87 : Colors.grey, 
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal
                        )
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 3,
                      color: isPassed && index < currentStep 
                          ? Colors.blue.shade600 
                          : Colors.grey.shade300,
                      margin: const EdgeInsets.only(bottom: 20), // Align with circle center
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
