import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/chat_provider.dart';
import 'screens/chat_screen.dart';
import 'services/supabase_eval_service.dart';
import 'services/device_id_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseEvalService.initialize(
    supabaseUrl: const String.fromEnvironment('SUPABASE_URL'),
    supabaseAnonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  final prefs = await SharedPreferences.getInstance();
  bool onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

  // ← add this fallback block
  if (!onboardingComplete) {
    final deviceId = await DeviceIdService.getDeviceId();
    final hasResponses = await SupabaseEvalService.hasExistingResponses(
      deviceId,
    );
    if (hasResponses) {
      await prefs.setBool('onboarding_complete', true);
      onboardingComplete = true;
    }
  }

  runApp(MyApp(onboardingComplete: onboardingComplete));
}

class MyApp extends StatelessWidget {
  final bool onboardingComplete;

  const MyApp({super.key, required this.onboardingComplete});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => ChatProvider())],
      child: MaterialApp(
        title: 'Agri-Pinoy Bot',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
        home: ChatScreen(onboardingComplete: onboardingComplete),
      ),
    );
  }
}
