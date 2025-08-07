// models/tarefa_model.dart
class Tarefa {
  final int id;
  String descricao;
  String? ritm;
  String? demandante;
  DateTime data;
  String horaInicio;
  String horaFim;
  int duracaoMinutos;
  String nomeCategoria;
  String? idCategoria; // Idealmente, a API retornaria o ID
  String nomeSquad;
  String? idSquad; // Idealmente, a API retornaria o ID

  Tarefa({
    required this.id,
    required this.descricao,
    this.ritm,
    this.demandante,
    required this.data,
    required this.horaInicio,
    required this.horaFim,
    required this.duracaoMinutos,
    required this.nomeCategoria,
    this.idCategoria,
    required this.nomeSquad,
    this.idSquad,
  });

  factory Tarefa.fromJson(Map<String, dynamic> json) {
    return Tarefa(
      id: int.parse(json['id'].toString()),
      descricao: json['descricao'] ?? 'Sem descrição',
      ritm: json['ritm'],
      demandante: json['demandante'],
      data: DateTime.parse(json['data']),
      horaInicio: json['hora_inicio'],
      horaFim: json['hora_fim'],
      duracaoMinutos: int.parse(json['duracao_minutos'].toString()),
      nomeCategoria: json['categoria'] ?? 'N/A',
      nomeSquad: json['squad'] ?? 'N/A',
      // Se a API enviasse os IDs, seria assim:
      idCategoria: json['categoria_id']?.toString(), 
      idSquad: json['squad_id']?.toString(),
    );
  }
}