import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/login_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
  runApp(const MediFindApp());
}

class MediFindApp extends StatelessWidget {
  const MediFindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediFind',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: const LoginScreen(),
    );
  }
}