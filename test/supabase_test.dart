import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('Supabase Query Test', () async {
    print('>>> Initializing Supabase...');
    await Supabase.initialize(
      url: 'https://kuzzjapgtcclcdfkytol.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt1enpqYXBndGNjbGNkZmt5dG9sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU4NTczMTMsImV4cCI6MjA5MTQzMzMxM30.iIRvQrzLZ-0aWCsLYWq3AQ_SyD5hymcXstlttkFM8II',
      authOptions: const FlutterAuthClientOptions(
        localStorage: const EmptyLocalStorage(),
      ),
    );

    final client = Supabase.instance.client;
    print('>>> Querying tickets...');
    try {
      final query = client.from('tickets').select('*, creator_profile:profiles!user_id(full_name), assigned_profile:profiles!assigned_to(full_name)');
      final data = await query.order('created_at', ascending: false).timeout(Duration(seconds: 10));
      print('>>> Success: $data');
    } catch (e, stack) {
      print('>>> Error querying tickets: $e');
      print('>>> Stack: $stack');
    }
  });
}
