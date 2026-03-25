import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseEvalService {
  static const String _table = 'eval_responses';

  static SupabaseClient get _client => Supabase.instance.client;

  static Future<void> initialize({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) async {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }

  static Future<void> saveEvalResponse({
    required String deviceId,
    required String question,
    required String answer,
    required int rating,
    required int questionIndex,
  }) async {
    try {
      await _client.from(_table).insert({
        'device_id': deviceId,
        'question': question,
        'answer': answer,
        'rating': rating,
        'question_index': questionIndex,
        'created_at': DateTime.now().toIso8601String(),
      });
      print(
        'SupabaseEvalService: Saved response $questionIndex/10 for $deviceId',
      );
    } catch (e) {
      print('SupabaseEvalService: Failed to save response — $e');
    }
  }
}
