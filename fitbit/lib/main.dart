import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/home/home.dart';
import 'dashboard_screen.dart'; // <-- Your Dashboard screen
import 'screens/home/journal/journal.dart';
import 'screens/home/qna_page/qna_page.dart';
import 'screens/navbar/chatbot/chatbot.dart';
import 'screens/navbar/games/chill_farm.dart';
import 'screens/navbar/games/flower_bloom.dart';
import 'screens/navbar/games/games.dart';
import 'screens/navbar/games/snake_game.dart';
import 'screens/navbar/music/music.dart';
import 'screens/navbar/profile/profile.dart';
import 'screens/login/login.dart';
import 'screens/navbar/games/bubble_pop.dart';
import 'screens/home/analyze.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StressLens',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFFBFFFFE),
        scaffoldBackgroundColor: const Color(0xFFF3FFFF),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0B3534),
          foregroundColor: Colors.white,
        ),
      ),
      home: const AuthWrapper(), // <-- 👈 This handles login vs home screen
      routes: {
        '/home': (context) => const HomeScreen(),
        '/dashboard': (context) => DashboardScreen(), 
        '/analysis': (context) => StressAnalysisPage(),
        '/chatbot': (context) => const ChatbotScreen(),
        '/music': (context) => const MusicScreen(),
        '/games': (context) => const GamesScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/qna': (context) => DailyStressCheckScreen(),
        '/journal': (context) => JournalPage(),
        '/flower_bloom': (context) => FlowerBloomScreen(),
        '/chill_farm': (context) => ChillFarmScreen(),
        '/bubble_pop': (context) => const BubbleWrapScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          User? user = snapshot.data;
          if (user == null) {
            return const LoginScreen(); // 🔥 If not logged in
          } else {
            return const HomeScreen(); // 🔥 If already logged in
          }
        }
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
