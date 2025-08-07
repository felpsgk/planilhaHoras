// services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

// Importe seus modelos de dados
import '../models/categoria_model.dart';
import '../models/squad_model.dart';
import '../models/tarefa_model.dart';

class ApiService {
  static const String _baseUrl = 'https://felpsti.com.br/backend_planilhaHoras';

  // =======================================================================
  // MÉTODOS DE LEITURA (GET)
  // =======================================================================

  /// Busca a lista de todas as categorias.
  Future<List<Categoria>> getCategorias() async {
    final response = await http.get(Uri.parse('$_baseUrl/get_categorias.php'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Categoria.fromJson(json)).toList();
    } else {
      throw Exception('Falha ao carregar categorias');
    }
  }

  /// Busca a lista de todos os squads.
  Future<List<Squad>> getSquads() async {
    final response = await http.get(Uri.parse('$_baseUrl/get_squads.php'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Squad.fromJson(json)).toList();
    } else {
      throw Exception('Falha ao carregar squads');
    }
  }

  /// Busca as tarefas de um usuário para uma data específica.
  Future<List<Tarefa>> getTarefas(String userId, DateTime data) async {
    final url = Uri.parse('$_baseUrl/listar_tarefas.php');
    final response = await http.post(url, body: {
      'user_id': userId,
      'data': DateFormat('yyyy-MM-dd').format(data),
    });

    print("--- RESPOSTA BRUTA DO SERVIDOR ---");
    print(response.body);
    print("---------------------------------");
    if (response.statusCode == 200) {
      
      final data = jsonDecode(response.body);
      if (data['tarefas'] != null && data['tarefas'] is List) {
        return (data['tarefas'] as List)
            .map((json) => Tarefa.fromJson(json))
            .toList();
      }
      return []; // Retorna lista vazia se não houver tarefas
    } else {
      throw Exception('Falha ao carregar tarefas');
    }
  }

  // =======================================================================
  // MÉTODOS DE ESCRITA (CREATE, UPDATE, DELETE) - FALTANTES
  // =======================================================================

  /// Cria uma nova tarefa.
  /// Retorna o corpo da resposta da API como um Map.
  Future<Map<String, dynamic>> createTarefa(Map<String, String> body) async {
    final url = Uri.parse('$_baseUrl/cadastrar_tarefa.php');
    final response = await http.post(url, body: body);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Falha ao criar tarefa. Status: ${response.statusCode}');
    }
  }

  /// Atualiza uma tarefa existente.
  /// Retorna o corpo da resposta da API como um Map.
  Future<Map<String, dynamic>> updateTarefa(Map<String, String?> body) async {
    final url = Uri.parse('$_baseUrl/editar_tarefa.php');
    final response = await http.post(url, body: body);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Falha ao editar tarefa. Status: ${response.statusCode}');
    }
  }

  /// Deleta uma tarefa pelo seu ID.
  /// Retorna `true` se a operação foi bem-sucedida.
  Future<bool> deleteTarefa(int tarefaId) async {
    final url = Uri.parse('$_baseUrl/deletar_tarefa.php');
    final response = await http.post(url, body: {
      'tarefa_id': tarefaId.toString(),
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['success'] == true;
    } else {
      throw Exception('Falha ao deletar tarefa. Status: ${response.statusCode}');
    }
  }
}