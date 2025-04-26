import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:http/http.dart' as http;
import '../models/user_session.dart';

class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({super.key});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ritmController = TextEditingController();
  final _demandanteController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _duracaoController = TextEditingController();
  bool sucedeAlmoco = false;

  List<dynamic> _categorias = [];
  List<dynamic> _squads = [];
  String? _categoriaSelecionada;
  String? _squadSelecionado;

  @override
  void initState() {
    super.initState();
    _carregarCategoriasESquads();
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

  Future<void> _salvarTarefa({bool forcar = false}) async {
    final url = Uri.parse(
        'https://felpsti.com.br/backend_planilhaHoras/cadastrar_tarefa.php');

    final response = await http.post(url, body: {
      'user_id': UserSession.userId.toString(),
      'categoria': _categoriaSelecionada ?? '',
      'squad': _squadSelecionado ?? '',
      'ritm': _ritmController.text,
      'demandante': _demandanteController.text,
      'descricao': _descricaoController.text,
      'apos_almoco': sucedeAlmoco ? '1' : '0',
      'duracao_minutos': _duracaoController.text,
      if (forcar) 'confirmar_limite': '1',
    });
    print('Resposta da API: "${response.body}"');

    final data = jsonDecode(response.body);

    if (data['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tarefa salva com sucesso')),
      );
      // Resetar apenas os campos de texto (manualmente)
      _ritmController.clear();
      _demandanteController.clear();
      _descricaoController.clear();
      _duracaoController.clear();
      setState(() {
        sucedeAlmoco = false; // Desmarca o checkbox!
      });
    } else if (data['overflow'] == true) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Excedeu a faixa de trabalho'),
          content: Text(data['message'] ?? 'Deseja salvar mesmo assim?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmar mesmo assim'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        _salvarTarefa(forcar: true);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: ${data['message']}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova Tarefa')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
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
                            c['id'].toString() == _categoriaSelecionada)['nome']
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
                items: _squads.map((s) => '${s['id']} - ${s['nome']}').toList(),
                selectedItem: _squadSelecionado != null
                    ? (() {
                        final s = _squads
                            .firstWhere((s) => s['id'] == _squadSelecionado);
                        return '${s['id']} - ${s['nome']}';
                      })()
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
                controller: _ritmController,
                decoration: const InputDecoration(labelText: 'RITM'),
              ),
              TextFormField(
                controller: _demandanteController,
                decoration: const InputDecoration(labelText: 'Demandante'),
              ),
              TextFormField(
                controller: _descricaoController,
                decoration: const InputDecoration(labelText: 'Descrição'),
              ),
              TextFormField(
                controller: _duracaoController,
                decoration: const InputDecoration(labelText: 'Duração (min)'),
                keyboardType: TextInputType.number,
              ),
              CheckboxListTile(
                title: const Text("Sucede horário de almoço"),
                value: sucedeAlmoco,
                onChanged: (value) {
                  setState(() {
                    sucedeAlmoco = value!;
                  });
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _salvarTarefa();
                  }
                },
                child: const Text('Salvar Tarefa'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
