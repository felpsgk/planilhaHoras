// Faça o mesmo para Squad em outro arquivo
// models/squad_model.dart
class Squad {
  final String id;
  final String nome;

  Squad({required this.id, required this.nome});

  factory Squad.fromJson(Map<String, dynamic> json) {
    return Squad(
      id: json['id'].toString(),
      nome: json['nome'],
    );
  }

  @override
  String toString() => '$id - $nome';
}