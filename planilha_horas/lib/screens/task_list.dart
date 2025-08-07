import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart';

// Imports dos seus arquivos de modelo e serviço
import '../models/user_session.dart';
import '../models/tarefa_model.dart';
import '../models/categoria_model.dart';
import '../models/squad_model.dart';
import '../services/api_service.dart';

// Enum para gerenciar os estados da tela de forma clara
enum ScreenState { loading, success, error }

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final ApiService _apiService = ApiService();

  // Variáveis de estado da UI
  ScreenState _state = ScreenState.loading;
  String _errorMessage = '';
  DateTime _dataSelecionada = DateTime.now();

  // Listas de dados com tipagem forte
  List<Tarefa> _tarefas = [];
  List<Categoria> _categorias = [];
  List<Squad> _squads = [];

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados({bool showLoadingIndicator = true}) async {
    if (!mounted) return;
    if (showLoadingIndicator) {
      setState(() => _state = ScreenState.loading);
    }

    try {
      // Carrega tudo que a tela precisa em paralelo
      final results = await Future.wait([
        _apiService.getTarefas(UserSession.userId.toString(), _dataSelecionada),
        if (_categorias.isEmpty) _apiService.getCategorias(),
        if (_squads.isEmpty) _apiService.getSquads(),
      ]);

      if (!mounted) return;

      setState(() {
        _tarefas = results[0] as List<Tarefa>;
        if (results.length > 1) _categorias = results[1] as List<Categoria>;
        if (results.length > 2) _squads = results[2] as List<Squad>;
        _state = ScreenState.success;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Erro ao carregar dados: $e';
        _state = ScreenState.error;
      });
    }
  }

  Future<void> _selecionarDataFiltro() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _dataSelecionada) {
      setState(() {
        _dataSelecionada = picked;
      });
      _carregarDados();
    }
  }

  void _abrirDialogoEdicao(Tarefa tarefa) async {
    if (_categorias.isEmpty || _squads.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Dados de categoria/squad não carregados.')));
      return;
    }

    final foiSalvo = await showDialog<bool>(
      context: context,
      builder: (context) => EditTaskDialog(
        tarefa: tarefa,
        categorias: _categorias,
        squads: _squads,
      ),
    );

    if (foiSalvo == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Tarefa atualizada com sucesso!'),
            backgroundColor: Colors.green),
      );
      _carregarDados(showLoadingIndicator: false);
    }
  }

  Future<void> _deletarTarefa(int tarefaId) async {
    try {
      //  final bool sucesso = await _apiService.deletarTarefa(tarefaId);
      //  if (sucesso) {
      //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tarefa deletada!')));
      //     setState(() {
      //        _tarefas.removeWhere((t) => t.id == tarefaId);
      //     });
      //  }
      //  Apenas para demonstração:
      setState(() {
        _tarefas.removeWhere((t) => t.id == tarefaId);
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Tarefa ID: $tarefaId removida da lista.'),
          backgroundColor: Colors.orange));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro ao deletar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Tarefas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _carregarDados(),
            tooltip: 'Recarregar',
          )
        ],
      ),
      body: Column(
        children: [
          _buildFiltroData(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildFiltroData() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: InkWell(
        onTap: _selecionarDataFiltro,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Data Selecionada',
            border: const OutlineInputBorder(),
            suffixIcon: Icon(Icons.calendar_month,
                color: Theme.of(context).primaryColor),
          ),
          child: Text(
            DateFormat('dd/MM/yyyy').format(_dataSelecionada),
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case ScreenState.loading:
        return const Center(child: CircularProgressIndicator());
      case ScreenState.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, size: 60, color: Colors.grey),
              const SizedBox(height: 16),
              Text('Não foi possível carregar as tarefas.\n$_errorMessage',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 10),
              ElevatedButton(
                  onPressed: _carregarDados,
                  child: const Text('Tentar Novamente')),
            ],
          ),
        );
      case ScreenState.success:
        if (_tarefas.isEmpty) {
          return const Center(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_outlined, size: 60, color: Colors.grey),
              SizedBox(height: 16),
              Text('Nenhuma tarefa para esta data.',
                  style: TextStyle(fontSize: 16)),
            ],
          ));
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _tarefas.length,
          itemBuilder: (context, index) {
            final tarefa = _tarefas[index];
            return Dismissible(
              key: ValueKey(tarefa.id),
              direction: DismissDirection.endToStart,
              onDismissed: (_) => _deletarTarefa(tarefa.id),
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20.0),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: const Icon(Icons.delete_forever, color: Colors.white),
              ),
              child: _TaskCard(
                tarefa: tarefa,
                onEdit: () => _abrirDialogoEdicao(tarefa),
              ),
            );
          },
        );
    }
  }
}

// =========================================================================
// WIDGET DO CARD DA TAREFA (para organizar o layout da lista)
// =========================================================================
class _TaskCard extends StatelessWidget {
  final Tarefa tarefa;
  final VoidCallback onEdit;

  const _TaskCard({required this.tarefa, required this.onEdit});

  String _formatarHora(String hora) {
    try {
      return DateFormat("HH:mm").format(DateFormat("HH:mm:ss").parse(hora));
    } catch (e) {
      return hora; // Retorna a string original se houver erro de formato
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Text(
                    '${_formatarHora(tarefa.horaInicio)} - ${_formatarHora(tarefa.horaFim)}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: theme.primaryColorDark),
                  ),
                ),
                Text(
                  '${tarefa.duracaoMinutos} min',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: theme.colorScheme.secondary),
                ),
              ],
            ),
            const Divider(height: 20),
            Text(tarefa.descricao, style: const TextStyle(fontSize: 15)),
            if (tarefa.ritm != null && tarefa.ritm!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('RITM: ${tarefa.ritm}',
                  style: const TextStyle(fontSize: 13, color: Colors.black54)),
            ],
            if (tarefa.demandante != null && tarefa.demandante!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Demandante: ${tarefa.demandante}',
                  style: const TextStyle(fontSize: 13, color: Colors.black54)),
            ],
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Usamos Expanded para garantir que os chips usem o espaço disponível
                // e o IconButton fique no final.
                Expanded(
                  child: Wrap(
                    spacing: 8.0, // Espaço horizontal entre os chips
                    runSpacing: 4.0, // Espaço vertical entre as linhas
                    children: [
                      Chip(
                        label: Text(tarefa.nomeCategoria),
                        backgroundColor: Colors.blue.shade50,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      Chip(
                        label: Text(tarefa.nomeSquad),
                        backgroundColor: Colors.green.shade50,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                ),
                // O IconButton fica fora do Wrap para se manter sempre à direita
                IconButton(
                  icon:
                      Icon(Icons.edit_note, color: theme.colorScheme.secondary),
                  onPressed: onEdit,
                  tooltip: 'Editar Tarefa',
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// WIDGET DO DIÁLOGO DE EDIÇÃO (encapsula toda a lógica de edição)
// =========================================================================
class EditTaskDialog extends StatefulWidget {
  final Tarefa tarefa;
  final List<Categoria> categorias;
  final List<Squad> squads;

  const EditTaskDialog({
    super.key,
    required this.tarefa,
    required this.categorias,
    required this.squads,
  });

  @override
  State<EditTaskDialog> createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends State<EditTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  // Controllers do formulário do diálogo
  late final TextEditingController _ritmController;
  late final TextEditingController _demandanteController;
  late final TextEditingController _descricaoController;
  late final TextEditingController _duracaoController;
  late final TextEditingController _dataExibicaoController;

  // Estado interno do diálogo
  late DateTime _dataTarefaEdit;
  Categoria? _tempCategoria;
  Squad? _tempSquad;
  bool _tempAjustarFuturas = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Inicializa os controllers com os dados da tarefa original
    _ritmController = TextEditingController(text: widget.tarefa.ritm);
    _demandanteController =
        TextEditingController(text: widget.tarefa.demandante);
    _descricaoController = TextEditingController(text: widget.tarefa.descricao);
    _duracaoController =
        TextEditingController(text: widget.tarefa.duracaoMinutos.toString());

    _dataTarefaEdit = widget.tarefa.data;
    _dataExibicaoController = TextEditingController(
        text: DateFormat('dd/MM/yyyy').format(_dataTarefaEdit));

    // Lógica para encontrar o item inicial dos dropdowns
    // Idealmente, a API retornaria os IDs na lista de tarefas.
    // Este código busca pelo nome como fallback.
    try {
      _tempCategoria = widget.categorias.firstWhere(
          (c) => c.nome == widget.tarefa.nomeCategoria,
          orElse: null);
    } catch (e) {
      _tempCategoria = null;
    }

    try {
      _tempSquad = widget.squads
          .firstWhere((s) => s.nome == widget.tarefa.nomeSquad, orElse: null);
    } catch (e) {
      _tempSquad = null;
    }
  }

  @override
  void dispose() {
    _ritmController.dispose();
    _demandanteController.dispose();
    _descricaoController.dispose();
    _duracaoController.dispose();
    _dataExibicaoController.dispose();
    super.dispose();
  }

  Future<void> _selecionarDataDialogo() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataTarefaEdit,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _dataTarefaEdit = picked;
        _dataExibicaoController.text =
            DateFormat('dd/MM/yyyy').format(_dataTarefaEdit);
      });
    }
  }

  Future<void> _salvarAlteracoes() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // ✅ ANTES (Incorreto, pois mistura UI com lógica de rede):
      // final updateUrl = Uri.parse('...');
      // final response = await http.post(updateUrl, body: {...});

      // ✅ AGORA (Correto, usando o serviço centralizado):
      final body = {
        'tarefa_id': widget.tarefa.id.toString(),
        'data': DateFormat('yyyy-MM-dd').format(_dataTarefaEdit),
        'squad': _tempSquad?.id,
        'categoria': _tempCategoria?.id,
        'ritm': _ritmController.text,
        'demandante': _demandanteController.text,
        'descricao': _descricaoController.text,
        'duracao_minutos': _duracaoController.text,
        'ajustar_futuras': _tempAjustarFuturas ? '1' : '0',
      };

      // Chama o método do serviço, que lida com toda a complexidade da rede
      final data = await _apiService.updateTarefa(body);

      if (!mounted) return;

      if (data['success'] == true) {
        Navigator.pop(context, true); // Retorna 'true' para indicar sucesso
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erro: ${data['message'] ?? 'Erro desconhecido'}'),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Exceção ao atualizar tarefa: $e'),
            backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar Tarefa'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _dataExibicaoController,
                readOnly: true,
                onTap: _selecionarDataDialogo,
                decoration: const InputDecoration(
                    labelText: 'Data',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today)),
              ),
              const SizedBox(height: 16),
              DropdownSearch<Categoria>(
                items: widget.categorias,
                selectedItem: _tempCategoria,
                onChanged: (value) => setState(() => _tempCategoria = value),
                dropdownDecoratorProps: const DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                        labelText: 'Categoria', border: OutlineInputBorder())),
                popupProps: const PopupProps.menu(
                    showSearchBox: true,
                    searchFieldProps: TextFieldProps(
                        decoration: InputDecoration(hintText: "Buscar..."))),
                validator: (v) => v == null ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              DropdownSearch<Squad>(
                items: widget.squads,
                selectedItem: _tempSquad,
                onChanged: (value) => setState(() => _tempSquad = value),
                dropdownDecoratorProps: const DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                        labelText: 'Squad', border: OutlineInputBorder())),
                popupProps: const PopupProps.menu(
                    showSearchBox: true,
                    searchFieldProps: TextFieldProps(
                        decoration: InputDecoration(hintText: "Buscar..."))),
                validator: (v) => v == null ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                  controller: _ritmController,
                  decoration: const InputDecoration(
                      labelText: 'RITM', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextFormField(
                  controller: _demandanteController,
                  decoration: const InputDecoration(
                      labelText: 'Demandante', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextFormField(
                  controller: _descricaoController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                      labelText: 'Descrição', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextFormField(
                controller: _duracaoController,
                decoration: const InputDecoration(
                    labelText: 'Duração (min)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Informe a duração';
                  if (int.tryParse(value) == null || int.parse(value) <= 0)
                    return 'Duração inválida';
                  return null;
                },
              ),
              CheckboxListTile(
                title: const Text('Ajustar tarefas posteriores'),
                value: _tempAjustarFuturas,
                onChanged: (value) =>
                    setState(() => _tempAjustarFuturas = value!),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: _isSaving ? null : _salvarAlteracoes,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Salvar'),
        ),
      ],
    );
  }
}
