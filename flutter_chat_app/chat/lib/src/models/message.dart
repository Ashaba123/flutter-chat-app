class Message {
  final String? id;
  final String? from;
  final String? to;
  final DateTime? timestamp;
  final String? content;

  Message(
      {required this.id,
      required this.from,
      required this.to,
      required this.timestamp,
      required this.content});

  factory Message.fromJson(Map<String, dynamic> json) {
    final msg = Message(
        id: json["id"],
        from: json["from"],
        to: json["to"],
        timestamp: json["timestamp"],
        content: json["content"]);

    return msg;
  }

  toJson() => {
        "id": id,
        "from": from,
        "to": to,
        "timestamp": timestamp,
        "content": content
      };
}
