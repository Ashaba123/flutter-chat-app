enum Typing { start, stop }

extension EnumParsingTypingEvent on Typing {
  String value() {
    return toString().split('.').last;
  }

  static Typing fromString(String status) {
    return Typing.values.firstWhere((element) => element.value() == status);
  }
}

class TypingEvent {
  final String id;
  final String from;
  final String to;
  final Typing event;

  TypingEvent(
      {required this.id,
      required this.from,
      required this.to,
      required this.event});

  factory TypingEvent.fromJson(Map<String, dynamic> json) {
    final typingEvent = TypingEvent(
        id: json["id"],
        from: json["from"],
        to: json["to"],
        event: EnumParsingTypingEvent.fromString(json["event"]));
    return typingEvent;
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "from": from,
        "to": to,
        "event": event.value(),
      };
}
