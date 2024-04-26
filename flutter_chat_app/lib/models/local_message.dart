import 'package:chat/chat.dart';

class LocalMessage {
  String? chatId;
  String? id;
  Message? message;
  ReceiptStatus? receiptStatus;

  LocalMessage({this.id, this.chatId, this.message, this.receiptStatus});

  Map<String, dynamic> toMap() => {
        "id": message!.id,
        ...message!.toJson(),
        "chat_id": chatId,
        "receipt_status": receiptStatus!.value()
      };

  factory LocalMessage.fromMap(Map<String, dynamic> json) {
    final message = Message(
        id: json['id'],
        from: json['from'],
        to: json['to'],
        content: json['content'],
        timestamp: json['timestamp']);

    final localMessage = LocalMessage(
        id: json['id'],
        chatId: json['chat_id'],
        message: message,
        receiptStatus: EnumParsing.fromString(json['receipt_status']));
    return localMessage;
  }
}
