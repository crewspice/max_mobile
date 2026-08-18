class ChatMessage {
  final int id;
  final String senderUserId;
  final String senderName;
  final String body;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.senderUserId,
    required this.senderName,
    required this.body,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      senderUserId: json['senderUserId'] ?? '',
      senderName: json['senderName'] ?? '',
      body: json['body'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
