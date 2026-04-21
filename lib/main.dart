import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/tickets/data/datasources/ticket_remote_data_source.dart';
import 'features/tickets/data/repositories/ticket_repository_impl.dart';
import 'features/tickets/domain/repositories/ticket_repository.dart';
import 'features/tickets/presentation/bloc/ticket_bloc.dart';
import 'features/tickets/presentation/pages/dashboard_page.dart';

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
            home: Scaffold(
              backgroundColor: Colors.blue[700],
              body: const Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
          );
        }

        if (snapshot.hasError) {
          return MaterialApp(
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
              theme: ThemeData(
                useMaterial3: true,
                brightness: Brightness.light,
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light),
                textTheme: GoogleFonts.plusJakartaSansTextTheme(),
              ),
              darkTheme: ThemeData(
                useMaterial3: true,
                brightness: Brightness.dark,
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
                textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme),
              ),
              home: const SplashScreen(),
            ),
          ),
        );
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    debugPrint('>>> SplashScreen initState');
    WidgetsBinding.instance.addPostFrameCallback((_) => _startApp());
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

    await Future.delayed(const Duration(seconds: 1));
    debugPrint('>>> Splash delay done, mounted: $mounted');

    if (mounted) {
      final destination = session != null ? "Dashboard" : "Login";
      debugPrint('>>> Navigating to $destination');

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => session != null ? const DashboardPage() : const LoginPage(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[700],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.confirmation_number_rounded, size: 100, color: Colors.white),
            const SizedBox(height: 24),
            Text('E-Ticketing Helpdesk', 
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 16),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
