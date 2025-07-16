
// import 'package:flutter/material.dart';
// import 'package:grow_a_ting/ui/plants/find_plants.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'ui/auth/login_page.dart';
// import 'ui/auth/signup_page.dart';
// import 'ui/home/home_page.dart';
// import 'services/auth_service.dart';
// import 'package:forui/forui.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';


// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//      await dotenv.load(fileName: '.env');
//   // Initialize Supabase
//    await Supabase.initialize(
//     url: dotenv.env['SUPABASE_URL']!,
//     anonKey: dotenv.env['SUPABASE_SERVICE_ROLE_KEY']!,
//   );

//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Yaad Garden',
//       theme: ThemeData(
//         scaffoldBackgroundColor: const Color(0xFFFAFAFA),
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
//         useMaterial3: true,
//       ),
//       // Check if user is already logged in
//       home: _getInitialRoute(),
//       routes: {
//         '/login': (context) => const LoginPage(),
//         '/signup': (context) => const SignupPage(),
//         '/home': (context) => const HomePage(),
//         '/plants/find': (context) => const FindPlantsPage(),
//       },
//     );
//   }

//   Widget _getInitialRoute() {
//     final AuthService authService = AuthService();
//     return authService.isLoggedIn ? const HomePage() : const LoginPage();
//   }
// }



import 'package:flutter/material.dart';
import 'package:grow_a_ting/ui/plants/find_plants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ui/auth/login_page.dart';
import 'ui/auth/signup_page.dart';
import 'ui/home/home_page.dart';
import 'services/auth_service.dart';
import 'package:forui/forui.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  
  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_SERVICE_ROLE_KEY']!,
  );

  runApp(const MyApp());
}

// List of pages for each tab
List<Widget> _pages = [
  const HomePage(),
  const FindPlantsPage(),
  const RemindersPage(),
  const CheckUpPage(),
];

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with SingleTickerProviderStateMixin {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    
    return MaterialApp(
      title: 'Yaad Garden',
      locale: const Locale('en', 'US'),
      localizationsDelegates: FLocalizations.localizationsDelegates,
      supportedLocales: FLocalizations.supportedLocales,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFAFAFA),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFF399942)),
        useMaterial3: true,
      ),
      builder: (context, child) => FTheme(data: FThemes.zinc.light, child: child!),
      home: authService.isLoggedIn ? _buildMainApp() : const LoginPage(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/home': (context) => _buildMainApp(),
        '/plants/find': (context) => const FindPlantsPage(),
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
              FBottomNavigationBarItem(
                icon: Icon(
                  Icons.home,
                  color: index == 0 ? Colors.green : Colors.grey,
                ),
                label: Text(
                  'Home',
                  style: TextStyle(
                    color: index == 0 ? Colors.green : Colors.grey,
                    fontWeight: index == 0 ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              FBottomNavigationBarItem(
                icon: Icon(
                  Icons.search,
                  color: index == 1 ? Colors.green : Colors.grey,
                ),
                label: Text(
                  'Explore',
                  style: TextStyle(
                    color: index == 1 ? Colors.green : Colors.grey,
                    fontWeight: index == 1 ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              FBottomNavigationBarItem(
                icon: Icon(
                  Icons.notifications,
                  color: index == 2 ? Colors.green : Colors.grey,
                ),
                label: Text(
                  'Reminders',
                  style: TextStyle(
                    color: index == 2 ? Colors.green : Colors.grey,
                    fontWeight: index == 2 ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              FBottomNavigationBarItem(
                icon: Icon(
                  Icons.health_and_safety,
                  color: index == 3 ? Colors.green : Colors.grey,
                ),
                label: Text(
                  'Check Up',
                  style: TextStyle(
                    color: index == 3 ? Colors.green : Colors.grey,
                    fontWeight: index == 3 ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
          content: _pages[index],
        );
      },
    );
  }
}

// Placeholder pages
class RemindersPage extends StatelessWidget {
  const RemindersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Reminders Page'),
      ),
    );
  }
}

class CheckUpPage extends StatelessWidget {
  const CheckUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Check Up Page'),
      ),
    );
  }
}