import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String> uploadPostImage(File file) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("Not logged in");

    final path = "${user.id}/${DateTime.now().millisecondsSinceEpoch}.jpg";

    final response = await _supabase.storage
        .from('community-media')
        .upload(path, file);

    if (response.isEmpty) {
      throw Exception("Upload failed");
    }

    final url = _supabase.storage.from('community-media').getPublicUrl(path);
    return url;
  }

  Future<String> uploadAvatar(File file) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("Not logged in");

    final path =
        "${user.id}/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg";

    final response = await _supabase.storage.from('avatars').upload(path, file);

    if (response.isEmpty) {
      throw Exception("Upload failed");
    }

    final url = _supabase.storage.from('avatars').getPublicUrl(path);
    return url;
  }

  Future<String> uploadMarketplaceImage(File file) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("Not logged in");

    final path = "${user.id}/${DateTime.now().millisecondsSinceEpoch}.jpg";

    final response = await _supabase.storage
        .from('community-media')
        .upload(path, file);

    if (response.isEmpty) {
      throw Exception("Upload failed");
    }

    final url = _supabase.storage.from('community-media').getPublicUrl(path);
    return url;
  }
}
