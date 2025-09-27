import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

class CatchLogStorage {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String> uploadPhoto(File file) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("Not logged in");

    final path = "${user.id}/${DateTime.now().millisecondsSinceEpoch}.jpg";

    final response = await _supabase.storage
        .from('catch-photos')
        .upload(path, file);

    if (response.isEmpty) {
      throw Exception("Upload failed");
    }

    // Get public URL (or signed if bucket is private)
    final url = _supabase.storage.from('catch-photos').getPublicUrl(path);
    return url;
  }
}
