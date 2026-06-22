import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ticket_model.dart';
import '../models/comment_model.dart';
import '../models/ticket_history_model.dart';

abstract class TicketRemoteDataSource {
  Future<List<TicketModel>> getTickets({String? statusFilter, String? helpdeskFilter, DateTime? cursor, int limit = 20});
  Future<TicketModel> getTicketById(String ticketId);
  Future<TicketModel> createTicket(TicketModel ticket, {File? imageFile, dynamic imageBytes, String? imageExt});      
  Future<List<Comment>> getComments(String ticketId);
  Future<void> sendComment(String ticketId, String message);
  Future<void> updateStatus(String ticketId, String status);
  Future<void> assignTicket(String ticketId, String helpdeskId, String helpdeskName);
  Future<void> acceptTicket(String ticketId);
  Future<void> resolveTicket(String ticketId);
  Future<void> cancelTicket(String ticketId);
  Future<void> deleteTicket(String ticketId);
  Future<List<Map<String, dynamic>>> getHelpdesks();
  Future<List<TicketHistoryModel>> getTicketHistory(String ticketId);
}

class SupabaseTicketRemoteDataSourceImpl implements TicketRemoteDataSource {    
  final SupabaseClient client;
  SupabaseTicketRemoteDataSourceImpl(this.client);

  Future<void> _insertNotification({
    required String userId,
    required String ticketId,
    required String title,
    required String message,
  }) async {
    final currentUser = client.auth.currentUser;
    if (currentUser != null && userId == currentUser.id) return;

    await client.from('notifications').insert({
      'user_id': userId,
      'ticket_id': ticketId,
      'title': title,
      'message': message,
      'is_read': false,
    });
  }

  @override
  Future<List<TicketHistoryModel>> getTicketHistory(String ticketId) async {
    // We don't join auth because it's tricky with RLS on 'auth.users' from public, 
    // simply just fetching history records
    final response = await client
        .from('ticket_history')
        .select()
        .eq('ticket_id', ticketId)
        .order('changed_at', ascending: true);

    return (response as List).map((json) {
       return TicketHistoryModel(
         id: json['id'],
         ticketId: json['ticket_id'],
         oldStatus: json['old_status'],
         newStatus: json['new_status'],
         userId: json['user_id'],
         userName: 'Sistem/Operator', 
         changedAt: DateTime.parse(json['changed_at']).toLocal(),
       );
    }).toList();
  }

  @override
  Future<List<TicketModel>> getTickets({String? statusFilter, String? helpdeskFilter, DateTime? cursor, int limit = 20}) async {
    try {
      final user = client.auth.currentUser;
      final role = user?.userMetadata?['role'] ?? 'user';
      var query = client.from('tickets').select();
      
      if (role == 'user' && user != null) {
        query = query.eq('user_id', user.id);
      } else if (role == 'helpdesk' && user != null) {
        query = query.eq('assigned_to', user.id);
      }

      if (statusFilter != null) {
        if (statusFilter == 'Aktif') {
          // Aktif = Bukan Selesai dan Bukan Dibatalkan (FR-011)
          query = query.neq('status', 'Selesai').neq('status', 'Dibatalkan');
        } else {
          query = query.eq('status', statusFilter);
        }
      }

      if (helpdeskFilter != null && helpdeskFilter.isNotEmpty) {
        query = query.eq('assigned_to', helpdeskFilter);
      }

      if (cursor != null) {
        query = query.lt('created_at', cursor.toUtc().toIso8601String());
      }

      final data = await query.order('created_at', ascending: false).limit(limit);
      final ticketsList = data as List<dynamic>;
      
      // Collect unique profile IDs
      final profileIds = <String>{};
      for (var t in ticketsList) {
        if (t['user_id'] != null) profileIds.add(t['user_id']);
        if (t['assigned_to'] != null) profileIds.add(t['assigned_to']);
      }

      // Fetch profiles
      Map<String, String> profileNames = {};
      if (profileIds.isNotEmpty) {
        final profiles = await client.from('profiles').select('id, full_name').inFilter('id', profileIds.toList());
        for (var p in profiles) {
          profileNames[p['id']] = p['full_name'];
        }
      }

      return ticketsList.map((e) {
        final map = Map<String, dynamic>.from(e as Map);
        if (map['user_id'] != null) map['creator_profile'] = {'full_name': profileNames[map['user_id']]};
        if (map['assigned_to'] != null) map['assigned_profile'] = {'full_name': profileNames[map['assigned_to']]};
        return TicketModel.fromJson(map);
      }).toList();
    } catch (e) {
      throw 'Gagal memuat tiket: $e';
    }
  }

  @override
  Future<TicketModel> getTicketById(String ticketId) async {
    try {
      final data = await client
          .from('tickets')
          .select()
          .eq('id', ticketId)
          .single();
          
      final profileIds = <String>{};
      if (data['user_id'] != null) profileIds.add(data['user_id']);
      if (data['assigned_to'] != null) profileIds.add(data['assigned_to']);

      Map<String, String> profileNames = {};
      if (profileIds.isNotEmpty) {
        final profiles = await client.from('profiles').select('id, full_name').inFilter('id', profileIds.toList());
        for (var p in profiles) {
          profileNames[p['id']] = p['full_name'];
        }
      }

      final map = Map<String, dynamic>.from(data);
      if (map['user_id'] != null) map['creator_profile'] = {'full_name': profileNames[map['user_id']]};
      if (map['assigned_to'] != null) map['assigned_profile'] = {'full_name': profileNames[map['assigned_to']]};

      return TicketModel.fromJson(map);
    } catch (e) {
      throw 'Gagal memuat detail tiket: $e';
    }
  }

  @override
  Future<TicketModel> createTicket(TicketModel ticket, {File? imageFile, dynamic imageBytes, String? imageExt}) async {
    String? url;
    
    if (imageBytes != null && imageExt != null) {
      final path = 'attachments/${DateTime.now().millisecondsSinceEpoch}.$imageExt';  
      await client.storage.from('tickets').uploadBinary(path, imageBytes);
      url = client.storage.from('tickets').getPublicUrl(path);
    } else if (imageFile != null) {
      final path = 'attachments/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await client.storage.from('tickets').upload(path, imageFile);
      url = client.storage.from('tickets').getPublicUrl(path);
    }

    final data = await client.from('tickets').insert({
      'title': ticket.title,
      'description': ticket.description,
      'category': ticket.category,
      'status': 'Menunggu Antrean',
      'user_id': client.auth.currentUser?.id,
      'attachment_url': url,
    }).select().single();
    
    final admins = await client.from('profiles').select('id').eq('role', 'admin');
    final currentUserFullName = client.auth.currentUser?.userMetadata?['full_name'] ?? 'Seseorang';
    
    for (var admin in admins) {
      await _insertNotification(
        userId: admin['id'],
        ticketId: data['id'],
        title: 'Tiket Baru Masuk',
        message: '$currentUserFullName membuat tiket baru: \'${ticket.title}\'',
      );
    }
    
    return TicketModel.fromJson(data);
  }

  @override
  Future<List<Comment>> getComments(String ticketId) async {
    final data = await client
        .from('ticket_comments')
        .select('*, profiles(full_name)')
        .eq('ticket_id', ticketId)
        .order('created_at', ascending: true);
    
    return (data as List).map((e) => Comment.fromJson(e)).toList();
  }

  @override
  Future<void> sendComment(String ticketId, String message) async {
    final user = client.auth.currentUser;
    if (user == null) throw 'Sesi berakhir, silakan login ulang.';

    await client.from('ticket_comments').insert({
      'ticket_id': ticketId,
      'user_id': user.id,
      'message': message,
    });

    final ticketData = await client.from('tickets').select('user_id, assigned_to, title').eq('id', ticketId).single();
    final role = user.userMetadata?['role'] ?? 'user';
    final senderName = user.userMetadata?['full_name'] ?? 'Seseorang';

    if (role == 'helpdesk' || role == 'admin') {
      if (ticketData['user_id'] != null) {
        await _insertNotification(
          userId: ticketData['user_id'],
          ticketId: ticketId,
          title: 'Balasan Baru',
          message: '$senderName membalas tiket \'${ticketData['title']}\'',
        );
      }
    } else {
      if (ticketData['assigned_to'] != null) {
        await _insertNotification(
          userId: ticketData['assigned_to'],
          ticketId: ticketId,
          title: 'Pesan Baru dari User',
          message: '$senderName membalas di tiket \'${ticketData['title']}\'',
        );
      }
    }
  }

  @override
  Future<void> updateStatus(String ticketId, String status) async {
    final List data = await client.from('tickets').update({'status': status}).eq('id', ticketId).select(); 
    if (data.isEmpty) {
      throw 'Akses Ditolak: RLS Policy Supabase tidak mengizinkan Anda meng-update tiket ini.';
    }
  }

  @override
  Future<void> assignTicket(String ticketId, String helpdeskId, String helpdeskName) async {
    final List data = await client.from('tickets').update({
      'assigned_to': helpdeskId,
      'status': 'Ditugaskan',
      'assigned_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', ticketId).select();
    if (data.isEmpty) {
      throw 'Akses Ditolak: Tidak dapat menugaskan tiket ini.';
    }

    final ticketData = data.first;

    await _insertNotification(
      userId: helpdeskId,
      ticketId: ticketId,
      title: 'Tiket Baru Ditugaskan',
      message: 'Anda mendapat tiket baru: \'${ticketData['title']}\'',
    );
    
    if (ticketData['user_id'] != null) {
      await _insertNotification(
        userId: ticketData['user_id'],
        ticketId: ticketId,
        title: 'Tiket Sedang Ditangani',
        message: 'Tiket \'${ticketData['title']}\' telah ditugaskan kepada $helpdeskName',
      );
    }
  }

  @override
  Future<void> acceptTicket(String ticketId) async {
    final List data = await client.from('tickets').update({
      'status': 'Sedang Diproses',
      'accepted_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', ticketId).select();
    if (data.isEmpty) {
      throw 'Akses Ditolak: Tidak dapat menerima tiket ini.';
    }

    final ticketData = data.first;
    final helpdeskName = client.auth.currentUser?.userMetadata?['full_name'] ?? 'Helpdesk';
    
    if (ticketData['user_id'] != null) {
      await _insertNotification(
        userId: ticketData['user_id'],
        ticketId: ticketId,
        title: 'Tiket Sedang Diproses',
        message: 'Tiket \'${ticketData['title']}\' sedang diproses oleh $helpdeskName',
      );
    }
  }

  @override
  Future<void> resolveTicket(String ticketId) async {
    final List data = await client.from('tickets').update({
      'status': 'Selesai',
      'resolved_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', ticketId).select();
    if (data.isEmpty) {
      throw 'Akses Ditolak: Tidak dapat menyelesaikan tiket ini.';
    }

    final ticketData = data.first;
    final helpdeskName = client.auth.currentUser?.userMetadata?['full_name'] ?? 'Helpdesk';

    if (ticketData['user_id'] != null) {
      await _insertNotification(
        userId: ticketData['user_id'],
        ticketId: ticketId,
        title: 'Tiket Selesai ✓',
        message: 'Tiket \'${ticketData['title']}\' telah berhasil diselesaikan',
      );
    }
    
    final admins = await client.from('profiles').select('id').eq('role', 'admin');
    for (var admin in admins) {
      await _insertNotification(
        userId: admin['id'],
        ticketId: ticketId,
        title: 'Tiket Diselesaikan',
        message: '$helpdeskName telah menyelesaikan tiket \'${ticketData['title']}\'',
      );
    }
  }

  @override
  Future<void> cancelTicket(String ticketId) async {
    final List data = await client.from('tickets').update({
      'status': 'Dibatalkan',
    }).eq('id', ticketId).select();
    
    if (data.isEmpty) {
      throw 'Akses Ditolak: Tidak dapat membatalkan tiket ini.';
    }

    final ticketData = data.first;
    if (ticketData['user_id'] != null) {
      await _insertNotification(
        userId: ticketData['user_id'],
        ticketId: ticketId,
        title: 'Tiket Dibatalkan',
        message: 'Tiket \'${ticketData['title']}\' telah dibatalkan',
      );
    }
  }

  @override
  Future<void> deleteTicket(String ticketId) async {
    final List data = await client.from('tickets').delete().eq('id', ticketId).select();
    if (data.isEmpty) {
      throw 'Akses Ditolak: Tidak dapat menghapus tiket ini.';
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getHelpdesks() async {
    final List profiles = await client.from('profiles').select('id, full_name').eq('role', 'helpdesk');
    final activeTickets = await client.from('tickets').select('assigned_to').eq('status', 'Sedang Diproses');
    
    final Map<String, int> counts = {};
    for (var t in activeTickets) {
      final hd = t['assigned_to'];
      if (hd != null) {
        counts[hd] = (counts[hd] ?? 0) + 1;
      }
    }

    return profiles.map((p) {
      return {
        'id': p['id'],
        'full_name': p['full_name'],
        'active_tickets': counts[p['id']] ?? 0,
      };
    }).toList();
  }
}


