import 'package:flutter_chat_app/models/local_message.dart';

class Chat {
  final String id;
  int unread = 0;
  List<LocalMessage>? messages = [];
  LocalMessage? mostRecent;

  Chat(this.id, {this.messages, this.mostRecent});

  toMap() => {"id": id};

  factory Chat.fromMap(Map<String, dynamic> json) => Chat(json['id']);
}
