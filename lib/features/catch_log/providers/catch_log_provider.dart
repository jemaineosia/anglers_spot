import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/catch_log.dart';

final catchLogProvider = FutureProvider.autoDispose<List<CatchLog>>((
  ref,
) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;

  if (user == null) return [];

  final response = await supabase
      .from('catch_logs')
      .select()
      .eq('user_id', user.id)
      .order('created_at', ascending: false);

  return (response as List<dynamic>)
      .map((row) => CatchLog.fromJson(row as Map<String, dynamic>))
      .toList();
});

final addCatchLogProvider = FutureProvider.family.autoDispose<void, CatchLog>((
  ref,
  log,
) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;

  if (user == null) throw Exception("Not logged in");

  await supabase.from('catch_logs').insert({
    ...log.toJson(),
    'user_id': user.id,
  });
});
