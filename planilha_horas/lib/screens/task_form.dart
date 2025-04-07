import 'dart:convert';
import 'package:flutter/material.dart';
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
      'duracao_minutos': _duracaoController.text,
      if (forcar) 'confirmar_limite': '1',
    });

    final data = jsonDecode(response.body);

    if (data['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tarefa salva com sucesso')),
      );
      _formKey.currentState!.reset();
      setState(() {
        _categoriaSelecionada = null;
        _squadSelecionado = null;
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
              DropdownButtonFormField<String>(
                value: _categoriaSelecionada,
                items: _categorias.map<DropdownMenuItem<String>>((categoria) {
                  return DropdownMenuItem<String>(
                    value: categoria['id'].toString(),
                    child: Text(categoria['nome']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _categoriaSelecionada = value;
                  });
                },
                decoration: const InputDecoration(labelText: 'Categoria'),
                validator: (value) =>
                    value == null ? 'Selecione uma categoria' : null,
              ),
              DropdownButtonFormField<String>(
                value: _squadSelecionado,
                items: _squads.map<DropdownMenuItem<String>>((squad) {
                  return DropdownMenuItem<String>(
                    value: squad['id'].toString(),
                    child: Text(squad['nome']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _squadSelecionado = value;
                  });
                },
                decoration: const InputDecoration(labelText: 'Squad'),
                validator: (value) =>
                    value == null ? 'Selecione um time' : null,
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
