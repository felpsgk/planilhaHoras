import 'package:flutter/material.dart';
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
  // ✅ Adicionado para o estado de carregamento inicial
  bool _loadingInitialData = true; 

  @override
  void initState() {
    super.initState();
    _carregarFaixaSalva();
  }

  Future<void> _carregarFaixaSalva() async {
    final userId = UserSession.userId;
    if (userId == null) {
      setState(() => _loadingInitialData = false);
      return;
    }
    final url = Uri.parse(
        'https://felpsti.com.br/backend_planilhaHoras/buscar_faixa_trabalho.php?user_id=$userId');

    try {
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (!mounted) return;

      final data = jsonDecode(res.body);

      if (data['success'] && data['hora_inicio'] != null) {
        setState(() {
          _horaInicio = _stringToTime(data['hora_inicio']);
          _horaFim = _stringToTime(data['hora_fim']);
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar faixa: $e');
      if (mounted) {
        _showMsg('Erro ao buscar dados salvos.');
      }
    } finally {
      // ✅ Garante que o estado de loading inicial seja desativado
      if (mounted) {
        setState(() => _loadingInitialData = false);
      }
    }
  }

  TimeOfDay? _stringToTime(String? hora) {
    if (hora == null || !hora.contains(':')) return null;
    final parts = hora.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  // ✅ Função de formatação simplificada
  String _formatTime(TimeOfDay? time) {
    if (time == null) return '--:--';
    final hora = time.hour.toString().padLeft(2, '0');
    final minuto = time.minute.toString().padLeft(2, '0');
    return '$hora:$minuto';
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
    
    // ✅ Validação para garantir que a hora final é maior que a inicial
    final inicioEmMinutos = _horaInicio!.hour * 60 + _horaInicio!.minute;
    final fimEmMinutos = _horaFim!.hour * 60 + _horaFim!.minute;

    if (fimEmMinutos <= inicioEmMinutos) {
      _showMsg('A hora final deve ser maior que a hora inicial.');
      return;
    }

    setState(() => _loading = true);

    // ✅ Adicionado try-catch para robustez
    try {
      final userId = UserSession.userId;
      final url = Uri.parse(
          'https://felpsti.com.br/backend_planilhaHoras/salvar_faixa_trabalho.php');
      final response = await http.post(url, body: {
        'user_id': '$userId',
        'hora_inicio': _formatTime(_horaInicio),
        'hora_fim': _formatTime(_horaFim),
      }).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      final data = jsonDecode(response.body);
      _showMsg(data['message'] ?? 'Ocorreu um erro');

    } catch (e) {
      if (!mounted) return;
      _showMsg('Erro de conexão ao salvar. Tente novamente.');
    } finally {
      // ✅ Garante que o loading sempre será desativado
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Usando o tema do app para as cores
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      // ✅ Adicionado para evitar overflow em telas pequenas
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Caixa de Tutorial
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.primaryContainer),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Defina o intervalo de horas em que você estará disponível para trabalhar hoje.',
                      style: TextStyle(fontSize: 14),
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

            // ✅ Layout dos seletores de hora melhorado
            if (_loadingInitialData)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTimePicker('Início', _horaInicio, true),
                  const Icon(Icons.arrow_forward, color: Colors.grey),
                  _buildTimePicker('Fim', _horaFim, false),
                ],
              ),

            const SizedBox(height: 40),
            Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                onPressed: _loading ? null : _salvarFaixa,
                // ✅ Feedback de loading melhorado
                icon: _loading
                    ? Container(
                        width: 20,
                        height: 20,
                        child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_alt_outlined),
                label: Text(_loading ? 'Salvando...' : 'Salvar Faixa'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Widget auxiliar para não repetir código
  Widget _buildTimePicker(String label, TimeOfDay? time, bool isInicio) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey)),
        const SizedBox(height: 8),
        TextButton(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            backgroundColor: Colors.grey.shade100,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () => _selecionarHora(isInicio),
          child: Text(
            _formatTime(time),
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
          ),
        ),
      ],
    );
  }
}