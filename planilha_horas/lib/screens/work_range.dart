import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../models/user_session.dart';

class WorkRangeScreen extends StatefulWidget {
  const WorkRangeScreen({super.key});

  @override
  State<WorkRangeScreen> createState() => _WorkRangeScreenState();
}

class _WorkRangeScreenState extends State<WorkRangeScreen> {
  TimeOfDay? _horaInicio;
  TimeOfDay? _horaFim;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _carregarFaixaSalva();
  }

  Future<void> _carregarFaixaSalva() async {
    final userId = UserSession.userId;
    final url = Uri.parse(
        'https://felpsti.com.br/backend_planilhaHoras/buscar_faixa_trabalho.php?user_id=$userId');

    try {
      final res = await http.get(url);
      final data = jsonDecode(res.body);

      if (data['success']) {
        setState(() {
          _horaInicio = _stringToTime(data['hora_inicio']);
          _horaFim = _stringToTime(data['hora_fim']);
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar faixa: $e');
    }
  }

  TimeOfDay _stringToTime(String hora) {
    final parts = hora.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return '--:--';
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat.Hm().format(dt);
  }

  Future<void> _selecionarHora(bool inicio) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: inicio
          ? (_horaInicio ?? TimeOfDay.now())
          : (_horaFim ?? TimeOfDay.now()),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );

    if (selected != null) {
      setState(() {
        if (inicio) {
          _horaInicio = selected;
        } else {
          _horaFim = selected;
        }
      });
    }
  }

  Future<void> _salvarFaixa() async {
    if (_horaInicio == null || _horaFim == null) {
      _showMsg('Preencha os dois horários');
      return;
    }

    setState(() => _loading = true);

    final userId = UserSession.userId;
    final url = Uri.parse(
        'https://felpsti.com.br/backend_planilhaHoras/salvar_faixa_trabalho.php');
    final response = await http.post(url, body: {
      'user_id': '$userId',
      'hora_inicio': _formatTime(_horaInicio),
      'hora_fim': _formatTime(_horaFim),
    });

    final data = jsonDecode(response.body);
    _showMsg(data['message']);
    setState(() => _loading = false);
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Mini tutorial',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Aqui você define o intervalo em que você estará disponível para registrar suas tarefas. '
                        'Por exemplo, das 08:00 até 17:30. O sistema irá usar esses horários como base para validar e ajustar suas atividades registradas.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Text(
            'Faixa de trabalho do dia:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text('Início:', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => _selecionarHora(true),
                child: Text(_formatTime(_horaInicio)),
              ),
              const SizedBox(width: 20),
              const Text('Fim:', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => _selecionarHora(false),
                child: Text(_formatTime(_horaFim)),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Center(
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _salvarFaixa,
              icon: const Icon(Icons.save),
              label:
                  Text(_loading ? 'Salvando...' : 'Salvar faixa de trabalho'),
            ),
          ),
        ],
      ),
    );
  }
}
