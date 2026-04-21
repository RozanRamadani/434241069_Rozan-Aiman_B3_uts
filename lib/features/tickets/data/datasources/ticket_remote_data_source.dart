import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ticket_model.dart';
import '../models/comment_model.dart';
import '../models/ticket_history_model.dart';

abstract class TicketRemoteDataSource {
  Future<List<TicketModel>> getTickets({String? statusFilter});
  Future<TicketModel> createTicket(TicketModel ticket, {File? imageFile, dynamic imageBytes, String? imageExt});      
  Future<List<Comment>> getComments(String ticketId);
  Future<void> sendComment(String ticketId, String message);
  Future<void> updateStatus(String ticketId, String status);
  Future<void> assignTicket(String ticketId, String helpdeskId);
  Future<List<Map<String, dynamic>>> getHelpdesks();
  Future<List<TicketHistoryModel>> getTicketHistory(String ticketId);
}

class SupabaseTicketRemoteDataSourceImpl implements TicketRemoteDataSource {    
  final SupabaseClient client;
  SupabaseTicketRemoteDataSourceImpl(this.client);

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
  Future<List<TicketModel>> getTickets({String? statusFilter}) async {
    final user = client.auth.currentUser;
    final role = user?.userMetadata?['role'] ?? 'user';
    var query = client.from('tickets').select();
    
    if (role == 'user' && user != null) {
      query = query.eq('user_id', user.id);
    }

    if (statusFilter != null) {
      if (statusFilter == 'Aktif') {
        // Aktif = Bukan Selesai dan Bukan Dibatalkan (FR-011)
        query = query.neq('status', 'Selesai').neq('status', 'Dibatalkan');
      } else {
        query = query.eq('status', statusFilter);
      }
    }

    final data = await query.order('created_at', ascending: false);
    return (data as List).map((e) => TicketModel.fromJson(e)).toList();
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
  }

  @override
  Future<void> updateStatus(String ticketId, String status) async {
    final List data = await client.from('tickets').update({'status': status}).eq('id', ticketId).select(); 
    if (data.isEmpty) {
      throw 'Akses Ditolak: RLS Policy Supabase tidak mengizinkan Anda meng-update tiket ini.';
    }
  }

  @override
  Future<void> assignTicket(String ticketId, String helpdeskId) async {
    final List data = await client.from('tickets').update({'assigned_to': helpdeskId}).eq('id', ticketId).select();
    if (data.isEmpty) {
      throw 'Akses Ditolak: Tidak dapat menugaskan tiket ini.';
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getHelpdesks() async {
    final data = await client.from('profiles').select('id, full_name').eq('role', 'helpdesk');
    return List<Map<String, dynamic>>.from(data);
  }
}

