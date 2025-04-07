import 'package:flutter/material.dart';
import 'work_range.dart';
import 'task_form.dart';
import 'task_list.dart';
import 'exportar.dart';
import '../auth/login_screen.dart';
import '../models/user_session.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const WorkRangeScreen(),
    const TaskFormScreen(),
    const TaskListScreen(),
    const ExportarTarefasScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestor de Tarefas'), actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Sair',
          onPressed: () {
            UserSession.clear();
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          },
        )
      ]),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // ← ESSA LINHA AQUI
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time),
            label: 'Faixa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_task),
            label: 'Nova',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Tarefas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.download),
            label: 'Exportar',
          ),
        ],
      ),
    );
  }
}
