import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:forui/forui.dart';

// Screens
import 'ui/auth/login_page.dart';
import 'ui/auth/signup_page.dart';
import 'ui/home/home_page.dart';
import 'ui/plants/find_plants.dart';
import 'ui/plant_diary/plant_diary.dart';
import 'ui/diagnosis/leaf_diagnosis.dart';
import 'services/auth_service.dart';
import 'ui/reminders/reminders.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_SERVICE_ROLE_KEY']!,
  );

  runApp(const MyApp());
}

List<Widget> _pages = [
  const HomePage(),
  const FindPlantsPage(),
  const RemindersPage(),
  const LeafDiagnosisPage(),
];

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return MaterialApp(
      title: 'Yaad Garden',
      locale: const Locale('en', 'US'),
      localizationsDelegates: FLocalizations.localizationsDelegates,
      supportedLocales: FLocalizations.supportedLocales,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFAFAFA),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF399942)),
        useMaterial3: true,
      ),
      builder: (context, child) =>
          FTheme(data: FThemes.zinc.light, child: child!),
      home: authService.isLoggedIn ? _buildMainApp() : const LoginPage(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/home': (context) => _buildMainApp(),
        '/plants/find': (context) => const FindPlantsPage(),
        '/plant_diary': (context) => const PlantDiaryPage(),
        '/leaf_diagnosis': (context) => const LeafDiagnosisPage(),
        '/reminders': (context) => const RemindersPage(),
        '/logout': (context) {
          authService.logout();
          return const LoginPage();
        },
      },
    );
  }

  Widget _buildMainApp() {
    return Builder(
      builder: (context) {
        return FScaffold(
          footer: FBottomNavigationBar(
            index: index,
            onChange: (newIndex) => setState(() => index = newIndex),
            children: [
              _navItem(Icons.home, 'Home', 0),
              _navItem(Icons.search, 'Explore', 1),
              _navItem(Icons.notifications, 'Reminders', 2),
              _navItem(Icons.health_and_safety, 'Diagnose Plant', 3),
            ],
          ),
          content: _pages[index],
        );
      },
    );
  }

  FBottomNavigationBarItem _navItem(IconData icon, String label, int tabIndex) {
    return FBottomNavigationBarItem(
      icon: Icon(
        icon,
        color: index == tabIndex ? Colors.green : Colors.grey,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: index == tabIndex ? Colors.green : Colors.grey,
          fontWeight: index == tabIndex ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}
