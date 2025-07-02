
import 'package:flutter/material.dart';
import 'package:grow_a_ting/ui/plants/find_plants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ui/auth/login_page.dart';
import 'ui/auth/signup_page.dart';
import 'ui/home/home_page.dart';
import 'services/auth_service.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
   await dotenv.load(fileName: ".env"); 
  // Initialize Supabase
   await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_SERVICE_ROLE_KEY']!,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yaad Garden',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFAFAFA),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      // Check if user is already logged in
      home: _getInitialRoute(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/home': (context) => const HomePage(),
        '/plants/find': (context) => const FindPlantsPage(),
      },
    );
  }

  Widget _getInitialRoute() {
    final AuthService authService = AuthService();
    return authService.isLoggedIn ? const HomePage() : const LoginPage();
  }
}