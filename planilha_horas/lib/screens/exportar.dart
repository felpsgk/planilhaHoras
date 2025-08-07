import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../models/user_session.dart';

class ExportarTarefasScreen extends StatefulWidget {
  const ExportarTarefasScreen({super.key});

  @override
  State<ExportarTarefasScreen> createState() => _ExportarTarefasScreenState();
}

class _ExportarTarefasScreenState extends State<ExportarTarefasScreen> {
  List<String> linhasFormatadas = [];
  bool carregando = false;
  bool modoPowerBI = true;

  DateTime _dataDeSelecionada = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _dataAteSelecionada = DateTime.now();

  Future<void> _carregarTarefasFormatadas() async {
    setState(() => carregando = true);

    final url = Uri.parse(
      'https://felpsti.com.br/backend_planilhaHoras/listar_tarefas_export.php',
    );

    final response = await http.post(url, body: {
      'user_id': UserSession.userId.toString(),
      'data_de': _dataDeSelecionada.toIso8601String().substring(0, 10),
      'data_ate': _dataAteSelecionada.toIso8601String().substring(0, 10),
      'modo_powerbi': modoPowerBI ? '1' : '0',
    });
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final tarefas = data['tarefas'] as List<dynamic>;

      final linhas = tarefas.asMap().entries.map((entry) {
        final i = entry.key;
        final tarefa = entry.value;

        final linhaExcel = i + 5;

        final inicio = tarefa['hora_inicio'] ?? '';
        final fim = tarefa['hora_fim'] ?? '';
        final categoria = tarefa['categoria_nome'] ?? '';
        final squad =
            modoPowerBI ? tarefa['squad_id'] ?? '' : tarefa['squad_nome'] ?? '';
        final ritm = tarefa['ritm'] ?? '';
        final demandante = tarefa['demandante'] ?? '';
        final descricao = tarefa['descricao'] ?? '';
        final data = tarefa['data'] ?? '';

        final dataHoraInicio = '$data ${inicio.toString().substring(0, 5)}';
        final dataHoraFim = '$data ${fim.toString().substring(0, 5)}';

          
        if (modoPowerBI) {
          final formulaDuracao =
              '=IF(C$linhaExcel="";"";D$linhaExcel-C$linhaExcel)';
          return '$squad\t$dataHoraInicio\t$dataHoraFim\t$formulaDuracao\t$categoria\t$ritm\t$demandante\t$descricao';
        } else {
          final formulaDuracao =
              '=IF(E$linhaExcel="";"";F$linhaExcel-E$linhaExcel)';
          final formula1 =
              '=IFERROR(IF(B$linhaExcel="<SELECIONAR>";"";VLOOKUP(B$linhaExcel;Listas!B2:D61;2;FALSE));"")';
          final formula2 =
              '=IFERROR(IF(B$linhaExcel="<SELECIONAR>";"";VLOOKUP(C$linhaExcel;Listas!F2:G17;2;FALSE));"")';
          return '$squad\t$formula1\t$formula2\t$dataHoraInicio\t$dataHoraFim\t$formulaDuracao\t$categoria\t$ritm\t$demandante\t$descricao';
        }
      }).toList();

      setState(() {
        linhasFormatadas = linhas;
        carregando = false;
      });
    } else {
      setState(() => carregando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao carregar tarefas')),
      );
    }
  }

  Future<void> _selecionarData({required bool isDataDe}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isDataDe ? _dataDeSelecionada : _dataAteSelecionada,
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isDataDe) {
          _dataDeSelecionada = picked;
        } else {
          _dataAteSelecionada = picked;
        }
      });
    }
  }

  void _copiarParaClipboard() {
    final textoFinal = linhasFormatadas.join('\n');
    Clipboard.setData(ClipboardData(text: textoFinal));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copiado para a área de transferência!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exportar Tarefas')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selecionarData(isDataDe: true),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Data de',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        DateFormat('dd/MM/yyyy').format(_dataDeSelecionada),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => _selecionarData(isDataDe: false),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Data até',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        DateFormat('dd/MM/yyyy').format(_dataAteSelecionada),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _carregarTarefasFormatadas,
                  child: const Text('Buscar Tarefas'),
                ),
              ],
            ),
            Row(
              children: [
                const Text('Modo Power BI'),
                Switch(
                  value: modoPowerBI,
                  onChanged: (value) {
                    setState(() => modoPowerBI = value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            carregando
                ? const CircularProgressIndicator()
                : linhasFormatadas.isEmpty
                    ? const Text(
                        'Nenhuma tarefa encontrada no intervalo informado.')
                    : Expanded(
                        child: Column(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                child: SelectableText(
                                  linhasFormatadas.join('\n'),
                                  style:
                                      const TextStyle(fontFamily: 'monospace'),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _copiarParaClipboard,
                              icon: const Icon(Icons.copy),
                              label: const Text('Copiar Tudo'),
                            ),
                          ],
                        ),
                      ),
          ],
        ),
      ),
    );
  }
}
