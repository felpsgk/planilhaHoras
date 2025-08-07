import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

// Imports dos seus arquivos de modelo e serviço
import '../models/user_session.dart';
import '../models/categoria_model.dart';
import '../models/squad_model.dart';
import '../services/api_service.dart';

class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({super.key});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  // Chave do formulário
  final _formKey = GlobalKey<FormState>();

  // Serviço de API
  final ApiService _apiService = ApiService();

  // Controladores de texto
  final _ritmController = TextEditingController();
  final _demandanteController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _duracaoController = TextEditingController();
  final _dataController = TextEditingController();
  final _horaInicioController = TextEditingController();
  final _horaFimController = TextEditingController();

  // Variáveis de estado da UI
  bool _isLoadingInitialData = true;
  bool _isSaving = false;
  String? _errorMessage;

  // Variáveis de estado do formulário
  bool _usarDataHora = false;
  bool _sucedeAlmoco = false;
  
  // Variáveis para os dropdowns (usando modelos com tipagem forte)
  List<Categoria> _categorias = [];
  List<Squad> _squads = [];
  Categoria? _categoriaSelecionada;
  Squad? _squadSelecionado;

  @override
  void initState() {
    super.initState();
    _carregarDadosIniciais();
  }

  @override
  void dispose() {
    _ritmController.dispose();
    _demandanteController.dispose();
    _descricaoController.dispose();
    _duracaoController.dispose();
    _dataController.dispose();
    _horaInicioController.dispose();
    _horaFimController.dispose();
    super.dispose();
  }

  Future<void> _carregarDadosIniciais() async {
    setState(() {
      _isLoadingInitialData = true;
      _errorMessage = null;
    });

    try {
      // Executa as chamadas de rede em paralelo para mais eficiência
      final results = await Future.wait([
        _apiService.getCategorias(),
        _apiService.getSquads(),
      ]);
      
      if (!mounted) return;

      setState(() {
        _categorias = (results[0] as List).cast<Categoria>();
        _squads = (results[1] as List).cast<Squad>();
        _isLoadingInitialData = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = "Erro ao carregar dados.\nVerifique sua conexão.";
        _isLoadingInitialData = false;
      });
    }
  }

  Future<void> _salvarTarefa({bool forcar = false}) async {
    // Valida o formulário
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final url = Uri.parse('https://felpsti.com.br/backend_planilhaHoras/cadastrar_tarefa.php');

      Map<String, String> body = {
        'user_id': UserSession.userId.toString(),
        'categoria': _categoriaSelecionada?.id ?? '',
        'squad': _squadSelecionado?.id ?? '',
        'ritm': _ritmController.text,
        'demandante': _demandanteController.text,
        'descricao': _descricaoController.text,
        'apos_almoco': _sucedeAlmoco ? '1' : '0',
        if (forcar) 'confirmar_limite': '1',
      };

      if (_usarDataHora) {
        body['data'] = _dataController.text;
        body['hora_inicio'] = _horaInicioController.text;
        body['hora_fim'] = _horaFimController.text;
      } else {
        body['duracao_minutos'] = _duracaoController.text;
      }

      final response = await http.post(url, body: body);
      
      if (!mounted) return;

      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Tarefa salva com sucesso'), backgroundColor: Colors.green),
        );
        // Limpa os campos após o sucesso
        _ritmController.clear();
        _demandanteController.clear();
        _descricaoController.clear();
        _duracaoController.clear();
        _dataController.clear();
        _horaInicioController.clear();
        _horaFimController.clear();
        setState(() {
          _sucedeAlmoco = false;
          // Opcional: descomente as linhas abaixo se quiser limpar os dropdowns também
          // _categoriaSelecionada = null;
          // _squadSelecionado = null;
        });

      } else if (data['overflow'] == true) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Excedeu a faixa de trabalho'),
            content: Text(data['message'] ?? 'Deseja salvar mesmo assim?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
              ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
            ],
          ),
        );

        if (confirm == true) {
          await _salvarTarefa(forcar: true); // Re-chama a função com a flag forçar
        }

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: ${data['message'] ?? 'Erro desconhecido'}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro de conexão: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova Tarefa')),
      body: _buildBody(),
    );
  }

  // ---- MÉTODOS DE CONSTRUÇÃO DA UI ----

  Widget _buildBody() {
    if (_isLoadingInitialData) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _carregarDadosIniciais,
              child: const Text('Tentar Novamente'),
            )
          ],
        ),
      );
    }
    return _buildForm();
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildCategoriaDropdown(),
          const SizedBox(height: 16),
          _buildSquadDropdown(),
          const SizedBox(height: 16),
          TextFormField(controller: _ritmController, decoration: const InputDecoration(labelText: 'RITM', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          TextFormField(controller: _demandanteController, decoration: const InputDecoration(labelText: 'Demandante', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          TextFormField(controller: _descricaoController, decoration: const InputDecoration(labelText: 'Descrição', border: OutlineInputBorder()), maxLines: 3),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Definir por Data e Hora'),
            value: _usarDataHora,
            onChanged: (bool value) => setState(() => _usarDataHora = value),
            activeColor: Theme.of(context).colorScheme.primary,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
            child: _usarDataHora ? _buildCamposDataHora() : _buildCampoDuracao(),
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            title: const Text("Sucede horário de almoço"),
            value: _sucedeAlmoco,
            onChanged: _usarDataHora ? null : (value) => setState(() => _sucedeAlmoco = value!),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            onPressed: _isSaving ? null : _salvarTarefa,
            child: Text(_isSaving ? 'Salvando...' : 'Salvar Tarefa'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriaDropdown() {
    return DropdownSearch<Categoria>(
      items: _categorias,
      selectedItem: _categoriaSelecionada,
      onChanged: (value) => setState(() => _categoriaSelecionada = value),
      validator: (value) => value == null ? 'Selecione uma categoria' : null,
      dropdownDecoratorProps: const DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(labelText: 'Categoria', border: OutlineInputBorder()),
      ),
      popupProps: const PopupProps.menu(
        showSearchBox: true,
        searchFieldProps: TextFieldProps(decoration: InputDecoration(hintText: "Buscar...")),
        menuProps: MenuProps(shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8)))),
      ),
    );
  }

  Widget _buildSquadDropdown() {
    return DropdownSearch<Squad>(
      items: _squads,
      selectedItem: _squadSelecionado,
      onChanged: (value) => setState(() => _squadSelecionado = value),
      validator: (value) => value == null ? 'Selecione um squad' : null,
      dropdownDecoratorProps: const DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(labelText: 'Squad', border: OutlineInputBorder()),
      ),
      popupProps: const PopupProps.menu(
        showSearchBox: true,
        searchFieldProps: TextFieldProps(decoration: InputDecoration(hintText: "Buscar...")),
        menuProps: MenuProps(shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8)))),
      ),
    );
  }

  Widget _buildCampoDuracao() {
    return Column(
      key: const ValueKey('duracao'),
      children: [
        TextFormField(
          controller: _duracaoController,
          decoration: const InputDecoration(labelText: 'Duração (minutos)', border: OutlineInputBorder()),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (_usarDataHora) return null;
            if (value == null || value.isEmpty) return 'Informe a duração';
            if (int.tryParse(value) == null || int.parse(value) <= 0) return 'Duração inválida';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCamposDataHora() {
    return Column(
      key: const ValueKey('dataHora'),
      children: [
        TextFormField(
          controller: _dataController,
          decoration: const InputDecoration(labelText: 'Data da Tarefa', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)),
          readOnly: true,
          onTap: () => _selecionarData(context),
          validator: (value) => (_usarDataHora && (value == null || value.isEmpty)) ? 'Informe a data' : null,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _horaInicioController,
                decoration: const InputDecoration(labelText: 'Hora Início', border: OutlineInputBorder(), suffixIcon: Icon(Icons.access_time)),
                readOnly: true,
                onTap: () => _selecionarHora(context, _horaInicioController),
                validator: (value) => (_usarDataHora && (value == null || value.isEmpty)) ? 'Hora início' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _horaFimController,
                decoration: const InputDecoration(labelText: 'Hora Fim', border: OutlineInputBorder(), suffixIcon: Icon(Icons.access_time)),
                readOnly: true,
                onTap: () => _selecionarHora(context, _horaFimController),
                validator: (value) {
                   if (!_usarDataHora || value == null || value.isEmpty) return 'Hora fim';
                   if (_horaInicioController.text.isNotEmpty) {
                      final format = DateFormat("HH:mm");
                      if (format.parse(value).isBefore(format.parse(_horaInicioController.text))) return "Fim < Início";
                   }
                   return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---- MÉTODOS DE AÇÃO / HELPERS ----

  Future<void> _selecionarData(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      setState(() => _dataController.text = DateFormat('yyyy-MM-dd').format(pickedDate));
    }
  }

  Future<void> _selecionarHora(BuildContext context, TextEditingController controller) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (pickedTime != null) {
      setState(() => controller.text = "${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}");
    }
  }
}