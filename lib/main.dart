import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/tickets/data/datasources/ticket_remote_data_source.dart';
import 'features/tickets/data/repositories/ticket_repository_impl.dart';
import 'features/tickets/domain/repositories/ticket_repository.dart';
import 'features/tickets/presentation/bloc/ticket_bloc.dart';
import 'features/tickets/presentation/pages/main_nav_page.dart';

late Future<void> supabaseInitializer;

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Tangkap error UI thread
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('>>> FlutterError: ${details.exceptionAsString()}');
  };

  // Tangkap error asinkron (Background thread)
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('>>> PlatformError: $error');
    debugPrint('>>> Stack: $stack');
    return true;
  };

  debugPrint('>>> Initializing Supabase...');
  supabaseInitializer = Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL',
        defaultValue: 'https://kuzzjapgtcclcdfkytol.supabase.co'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY',
        defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt1enpqYXBndGNjbGNkZmt5dG9sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU4NTczMTMsImV4cCI6MjA5MTQzMzMxM30.iIRvQrzLZ-0aWCsLYWq3AQ_SyD5hymcXstlttkFM8II'),
  );

  runApp(const TicketingApp());
}

class TicketingApp extends StatelessWidget {
  const TicketingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: supabaseInitializer,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: const _InitLoadingScreen(),
          );
        }

        if (snapshot.hasError) {
          return MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: Scaffold(
              body: Center(child: Text('Gagal Inisialisasi: ${snapshot.error}')),
            ),
          );
        }

        final client = Supabase.instance.client;

        return MultiRepositoryProvider(
          providers: [
            RepositoryProvider<AuthRepository>(
              create: (_) => AuthRepositoryImpl(supabaseClient: client),
            ),
            RepositoryProvider<TicketRepository>(
              create: (_) => TicketRepositoryImpl(
                SupabaseTicketRemoteDataSourceImpl(client),
              ),
            ),
          ],
          child: MultiBlocProvider(
            providers: [
              BlocProvider(create: (ctx) => AuthBloc(authRepository: ctx.read<AuthRepository>())),
              BlocProvider(create: (ctx) => TicketBloc(ticketRepository: ctx.read<TicketRepository>())),
            ],
            child: MaterialApp(
              title: 'E-Ticketing Helpdesk',
              debugShowCheckedModeBanner: false,
              themeMode: ThemeMode.system,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              home: const SplashScreen(),
            ),
          ),
        );
      },
    );
  }
}

class _InitLoadingScreen extends StatelessWidget {
  const _InitLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      ),
    );
  }
}

// ─── Splash Screen ──────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _scaleAnim = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();

    debugPrint('>>> SplashScreen initState');
    WidgetsBinding.instance.addPostFrameCallback((_) => _startApp());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startApp() async {
    debugPrint('>>> _startApp() called');
    if (!mounted) return;

    // Session Listener Reaktif
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      debugPrint('>>> Auth event: ${data.event}');
      if (data.event == AuthChangeEvent.signedOut && mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()), (route) => false);
      }
    });

    final session = Supabase.instance.client.auth.currentSession;
    debugPrint('>>> Current Session: ${session != null ? "Active" : "None"}');

    await Future.delayed(const Duration(seconds: 2));
    debugPrint('>>> Splash delay done, mounted: $mounted');

    if (mounted) {
      final destination = session != null ? "MainNavPage" : "Login";
      debugPrint('>>> Navigating to $destination');

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (context, animation, secondaryAnimation) =>
              session != null ? const MainNavPage() : const LoginPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ScaleTransition(
          scale: _scaleAnim,
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo icon
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.confirmation_number_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                // Brand name
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Helpdesk',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryDark,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Desk',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppTheme.primary.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
