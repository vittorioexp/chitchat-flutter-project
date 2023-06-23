import 'package:chitchat/screens/auth.dart';
import 'package:chitchat/screens/chats.dart';
import 'package:chitchat/screens/splash.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';

void main() async {
  await dotenv.load();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

// Add an artificial delay before running the app
  await Future.delayed(const Duration(seconds: 1));

  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlutterChat',
      theme: ThemeData().copyWith(
        useMaterial3: false,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2296F3),
          background: const Color(0xFFD9E2D6),
        ),
        textTheme: GoogleFonts.latoTextTheme(ThemeData().textTheme),
      ),
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }

          if (snapshot.hasData) {
            return const ChatsScreen();
          }

          if (snapshot.hasError) {}

          return const AuthScreen();
        },
      ),
    );
  }
}
