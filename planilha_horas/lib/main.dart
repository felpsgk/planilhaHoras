import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 1. Importar o pacote

// Seus imports existentes
import 'screens/home_screen.dart';
import 'auth/login_screen.dart';
import 'models/user_session.dart';

// 2. A função main agora é assíncrona (async)
Future<void> main() async {
  // 3. Garante que o Flutter está pronto antes de carregar dados
  WidgetsFlutterBinding.ensureInitialized();

  // 4. Carrega os dados salvos do disco
  final prefs = await SharedPreferences.getInstance();
  final String? token = prefs.getString('token');
  
  // 5. Se encontrou um token, repopula a sessão do usuário
  if (token != null) {
    UserSession.token = token;
    UserSession.userId = prefs.getInt('user_id');
    UserSession.email = prefs.getString('email');
  }

  // 6. Inicia o app, informando se o usuário está ou não logado
  runApp(MyApp(isLoggedIn: token != null));
}

class MyApp extends StatelessWidget {
  // 7. Adiciona uma variável para receber o status de login
  final bool isLoggedIn;

  // 8. Atualiza o construtor para aceitar a variável
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestor de Tarefas',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      // 9. Usa a variável para decidir a tela inicial
      home: isLoggedIn ? const HomeScreen() : const LoginScreen(),
    );
  }
}