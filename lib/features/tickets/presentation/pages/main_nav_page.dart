import 'package:flutter/material.dart';

import 'package:tiketdotcom/features/auth/presentation/pages/profile_page.dart';
import 'package:tiketdotcom/features/tickets/presentation/pages/create_ticket_page.dart';
import 'package:tiketdotcom/features/tickets/presentation/pages/dashboard_page.dart';
import 'package:tiketdotcom/features/tickets/presentation/pages/ticket_list_page.dart';
import 'package:tiketdotcom/core/services/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MainNavPage extends StatefulWidget {
  final int initialIndex;
  const MainNavPage({super.key, this.initialIndex = 0});

  @override
  State<MainNavPage> createState() => _MainNavPageState();
}

class _MainNavPageState extends State<MainNavPage> {
  late int _currentIndex;

  final List<Widget> _pages = [
    const DashboardPage(),
    const TicketListPage(),
    const CreateTicketPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    
    // Start listening to notifications
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      NotificationService().listenToSupabaseRealtime(user.id);
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  void dispose() {
    NotificationService().stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: 'Beranda',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_rounded),
                label: 'Tiket Saya',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.add_circle_rounded),
                label: 'Lapor',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
