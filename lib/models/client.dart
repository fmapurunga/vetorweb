class Client {
  final String id;
  final String nome;
  final String foto;
  final String ultimaMensagem;
  final DateTime ultimaMensagemData;

  Client({
    required this.id,
    required this.nome,
    required this.foto,
    required this.ultimaMensagem,
    required this.ultimaMensagemData,
  });

  /// 🔹 Construtor para criar um `Cliente` a partir do Firestore
  factory Client.fromFirestore(String id, Map<String, dynamic> data) {
    return Client(
      id: id,
      nome: data['nome'] ?? 'Desconhecido',
      foto: data['foto'] ?? '',
      ultimaMensagem: data['lastMessage'] ?? '',
      ultimaMensagemData: (data['lastMessageTime'])?.toDate() ?? DateTime(2000, 1, 1),
    );
  }

  /// 🔹 Converter `Cliente` para um Map (para salvar no Firestore)
  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'foto': foto,
      'lastMessage': ultimaMensagem,
      'lastMessageTime': ultimaMensagemData,
    };
  }
}