import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'auth/login_screen.dart';
import '../models/user_session.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestor de Tarefas',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      home: UserSession.isLoggedIn ? const HomeScreen() : const LoginScreen(),
    );
  }
}
