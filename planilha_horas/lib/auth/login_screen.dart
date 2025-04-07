import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../screens/home_screen.dart';
import '../models/user_session.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _isLoading = false;

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final response = await http.post(
      Uri.parse('https://felpsti.com.br/backend_planilhaHoras/login.php'),
      body: {
        'email': _loginController.text.trim(), // continua como 'email' na API
        'senha': _senhaController.text,
      },
    );

    final data = json.decode(response.body);

    if (response.statusCode == 200 && data['success']) {
      UserSession.token = data['token'];
      UserSession.userId = data['user_id'];
      UserSession.email = data['email'];

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? 'Erro no login')),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: AutofillGroup(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    TextFormField(
                      controller: _loginController,
                      decoration: const InputDecoration(
                        labelText: 'E-mail ou usuário',
                      ),
                      autofillHints: const [AutofillHints.username],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Informe o e-mail ou usuário';
                        }
                        if (value.contains('@')) {
                          // parece um e-mail
                          return value.contains('.') ? null : 'E-mail inválido';
                        } else {
                          // é um username
                          return value.length >= 3 ? null : 'Usuário inválido';
                        }
                      },
                    ),
                    TextFormField(
                      controller: _senhaController,
                      decoration: const InputDecoration(labelText: 'Senha'),
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      validator: (value) =>
                          value != null && value.length >= 6 ? null : 'Senha inválida',
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isLoading ? null : login,
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Entrar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}