import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:http/http.dart' as http;
import '../models/user_session.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<dynamic> tarefas = [];
  DateTime _dataSelecionada = DateTime.now();

  List<dynamic> _categorias = [];
  List<dynamic> _squads = [];
  String? _categoriaSelecionada;
  String? _squadSelecionado;

  String _formatarHora(String hora) {
    try {
      final dateTime = DateFormat("HH:mm:ss").parse(hora);
      return DateFormat("HH:mm").format(dateTime);
    } catch (e) {
      return hora; // já está formatado ou inválido, retorna como veio
    }
  }

  Future<void> _carregarTarefas() async {
    final url = Uri.parse(
        'https://felpsti.com.br/backend_planilhaHoras/listar_tarefas.php');
    final response = await http.post(url, body: {
      'user_id': UserSession.userId.toString(),
      'data': _dataSelecionada.toIso8601String().substring(0, 10),
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        tarefas = data['tarefas'];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao carregar tarefas')),
      );
    }
  }

  Future<void> _carregarCategoriasESquads() async {
    final categoriasUrl = Uri.parse(
        'https://felpsti.com.br/backend_planilhaHoras/get_categorias.php');
    final squadsUrl = Uri.parse(
        'https://felpsti.com.br/backend_planilhaHoras/get_squads.php');

    final categoriasResp = await http.get(categoriasUrl);
    final squadsResp = await http.get(squadsUrl);

    if (categoriasResp.statusCode == 200 && squadsResp.statusCode == 200) {
      setState(() {
        _categorias = jsonDecode(categoriasResp.body);
        _squads = jsonDecode(squadsResp.body);
      });
    } else {
      // erro
      print('Erro ao buscar dados');
    }
  }

  Future<void> _selecionarData() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _dataSelecionada) {
      setState(() {
        _dataSelecionada = picked;
      });
    }
  }

  void _editarTarefa(Map tarefa) async {
    await _carregarCategoriasESquads();

    final formKey = GlobalKey<FormState>();

    String? squadSelecionado = tarefa['squad'];
    String? categoriaSelecionada = tarefa['categoria'];
    final ritm = TextEditingController(text: tarefa['ritm'] ?? '');
    final demandante = TextEditingController(text: tarefa['demandante'] ?? '');
    final descricao = TextEditingController(text: tarefa['descricao'] ?? '');
    final duracao = TextEditingController(
      text: tarefa['duracao_minutos']?.toString() ?? '',
    );
    DateTime dataSelecionada =
        DateTime.tryParse(tarefa['data'] ?? '') ?? DateTime.now();

    final dataController = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(dataSelecionada),
    );

    Future<void> selecionarDataTarefa() async {
      final picked = await showDatePicker(
        context: context,
        initialDate: dataSelecionada,
        firstDate: DateTime(2023),
        lastDate: DateTime(2100),
      );
      if (picked != null) {
        dataSelecionada = picked;
        dataController.text = DateFormat('dd/MM/yyyy').format(dataSelecionada);
      }
    }

    bool ajustarFuturas = false;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Tarefa'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: dataController,
                  readOnly: true,
                  onTap: selecionarDataTarefa,
                  decoration: const InputDecoration(labelText: 'Data'),
                ),
                DropdownSearch<String>(
                  items: _categorias
                      .map((c) => '${c['id']} - ${c['nome']}')
                      .toList(),
                  selectedItem: _categoriaSelecionada != null
                      ? _categorias
                              .firstWhere((c) =>
                                  c['id'].toString() ==
                                  _categoriaSelecionada)['id']
                              .toString() +
                          ' - ' +
                          _categorias.firstWhere((c) =>
                              c['id'].toString() ==
                              _categoriaSelecionada)['nome']
                      : null,
                  dropdownDecoratorProps: const DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      labelText: 'Categoria',
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _categoriaSelecionada = value?.split(' - ').first;
                    });
                  },
                  validator: (value) => value == null || value.isEmpty
                      ? 'Selecione uma categoria'
                      : null,
                  popupProps: const PopupProps.menu(
                    showSearchBox: true,
                  ),
                ),
                DropdownSearch<String>(
                  items:
                      _squads.map((s) => '${s['id']} - ${s['nome']}').toList(),
                  selectedItem: _squadSelecionado != null
                      ? _squads
                              .firstWhere((s) =>
                                  s['id'].toString() == _squadSelecionado)['id']
                              .toString() +
                          ' - ' +
                          _squads.firstWhere((s) =>
                              s['id'].toString() == _squadSelecionado)['nome']
                      : null,
                  dropdownDecoratorProps: const DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      labelText: 'Squad',
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _squadSelecionado = value?.split(' - ').first;
                    });
                  },
                  validator: (value) => value == null || value.isEmpty
                      ? 'Selecione um squad'
                      : null,
                  popupProps: const PopupProps.menu(
                    showSearchBox: true,
                  ),
                ),
                TextFormField(
                  controller: ritm,
                  decoration: const InputDecoration(labelText: 'RITM'),
                ),
                TextFormField(
                  controller: demandante,
                  decoration: const InputDecoration(labelText: 'Demandante'),
                ),
                TextFormField(
                  controller: descricao,
                  decoration: const InputDecoration(labelText: 'Descrição'),
                ),
                TextFormField(
                  controller: duracao,
                  decoration: const InputDecoration(labelText: 'Duração (min)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                StatefulBuilder(
                  builder: (context, setState) {
                    return CheckboxListTile(
                      title: const Text('Ajustar tarefas posteriores'),
                      value: ajustarFuturas,
                      onChanged: (value) {
                        setState(() {
                          ajustarFuturas = value!;
                        });
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final updateUrl = Uri.parse(
                  'https://felpsti.com.br/backend_planilhaHoras/editar_tarefa.php',
                );

                final response = await http.post(updateUrl, body: {
                  'tarefa_id': tarefa['id'].toString(),
                  'data': dataSelecionada.toIso8601String().substring(0, 10),
                  'squad': squadSelecionado ?? '',
                  'categoria': categoriaSelecionada ?? '',
                  'ritm': ritm.text,
                  'demandante': demandante.text,
                  'descricao': descricao.text,
                  'duracao_minutos': duracao.text,
                  'ajustar_futuras': ajustarFuturas ? '1' : '0',
                });

                final data = jsonDecode(response.body);

                if (data['success']) {
                  Navigator.pop(context);
                  _carregarTarefas();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tarefa atualizada com sucesso'),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro: ${data['message']}')),
                  );
                }
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tarefas do Dia')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selecionarData,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Data',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        DateFormat('dd/MM/yyyy').format(_dataSelecionada),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _carregarTarefas,
                  child: const Text('Buscar Tarefas'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            tarefas.isEmpty
                ? const Center(child: Text('Nenhuma tarefa para essa data'))
                : Expanded(
                    child: ListView.builder(
                      itemCount: tarefas.length,
                      itemBuilder: (context, index) {
                        final tarefa = tarefas[index];
                        return Card(
                          child: ListTile(
                            title: Text(
                              '${_formatarHora(tarefa['hora_inicio'])} - ${_formatarHora(tarefa['hora_fim'])}',
                            ),
                            subtitle: Text(tarefa['descricao'] ?? ''),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _editarTarefa(tarefa),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
