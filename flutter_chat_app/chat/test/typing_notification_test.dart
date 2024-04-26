import 'package:chat/src/models/typing_event.dart';
import 'package:chat/src/models/user.dart';
import 'package:chat/src/services/typing/typing_notification_service_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rethink_db_ns/rethink_db_ns.dart';

import 'helpers.dart';

void main() {
  RethinkDb r = RethinkDb();
  late Connection connection;
  late TypingNotificationService sut;

  setUp(() async {
    connection = await r.connect();
    await createDb(r, connection);
    sut = TypingNotificationService(r, connection);
  });
  tearDown(() async {
    sut.dispose();
    await cleanDb(r, connection);
  });

  final user =
      User.fromJson({"id": "1", "active": true, "lastseen": DateTime.now()});
  final user2 =
      User.fromJson({"id": "2", "active": true, "lastseen": DateTime.now()});

  test('sent typing notification successfully', () async {
    TypingEvent typingEvent = TypingEvent(
        id: "1", from: user2.id!, to: user.id!, event: Typing.start);

    final res = await sut.send(typingEvent, user);
    expect(res, true);
  });

  
    test('successfully subscribe and receive events', () async {
    sut.subscribe(user2, [user.id!]).listen(expectAsync1((event) {
          expect(event.from, user.id);
         
        }, count: 2));

    TypingEvent typingEvent = TypingEvent(
        id: "1", from: user.id!, to: user2.id!, event: Typing.start);

       TypingEvent stoptypingEvent = TypingEvent(
        id: "1", from: user.id!, to: user2.id!, event: Typing.stop);

    await sut.send(typingEvent,user2);
    await sut.send(stoptypingEvent,user2);
  });
}
