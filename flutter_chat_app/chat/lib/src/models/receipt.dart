enum ReceiptStatus { sent, delivered, read }

extension EnumParsing on ReceiptStatus {
  String value() {
    return toString().split('.').last;
    //ReceiptStatus.sent ==> sent
  }

  static ReceiptStatus fromString(String status) {
    return ReceiptStatus.values
        .firstWhere((element) => element.value() == status);
  }
}

class Receipt {
  final String? id;
  final String? recipient;
  final String? messageId;
  final ReceiptStatus? status;
  final DateTime? timestamp;

  Receipt(
      {required this.id,
      required this.recipient,
      required this.messageId,
      required this.status,
      required this.timestamp});

  factory Receipt.fromJson(Map<String, dynamic> json) {
    final receipt = Receipt(
        id: json["id"],
        recipient: json["recipient"],
        messageId: json["messageId"],
        timestamp: json["timestamp"],
        status: EnumParsing.fromString(json["status"]));
    return receipt;
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "recipient": recipient,
        "messageId": messageId,
        "status": status!.value(),
        "timestamp": timestamp
      };
}
