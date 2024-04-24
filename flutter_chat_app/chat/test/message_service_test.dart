import 'package:chat/src/models/message.dart';
import 'package:chat/src/models/user.dart';
import 'package:chat/src/services/encryption/encryption_interface.dart';
import 'package:chat/src/services/message/message_service_interface.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rethink_db_ns/rethink_db_ns.dart';

import 'helpers.dart';

void main() {
  RethinkDb r = RethinkDb();
  late Connection connection;
  late MessageService sut; // sut is system under test.
  setUp(() async {
    connection = await r.connect(host: 'localhost', port: 28015);
    final encryption = EncryptionService(Encrypter(AES(Key.fromLength(32))));
    await createDb(r, connection);
    sut = MessageService(r, connection, encryption);
  });
  tearDown(() async {
    sut.dispose();
    await cleanDb(r, connection);
  });

  final user1 =
      User.fromJson({"id": "1", "active": true, "lastseen": DateTime.now()});
  final user2 =
      User.fromJson({"id": "2", "active": true, "lastseen": DateTime.now()});

  test('Messages are sent successfully', () async {
    Message message = Message(
        id: "1",
        from: user1.id,
        to: "2",
        timestamp: DateTime.now(),
        content: "Hello User 2");

    final result = await sut.send(message);
    expect(result, true);
  });

  test('successfully subscribe and receive mesages', () async {
    const content = "This is a message";
    sut.messages(activeUser: user2).listen(expectAsync1((message) {
          expect(message.to, user2.id);
          expect(message.id, isNotEmpty);
          expect(message.content, content);
        }, count: 2));

    Message message = Message(
        id: "1",
        from: user1.id,
        to: user2.id,
        timestamp: DateTime.now(),
        content: content);

    Message secondmessage = Message(
        id: "2",
        from: user1.id,
        to: user2.id,
        timestamp: DateTime.now(),
        content: content);

    await sut.send(message);
    await sut.send(secondmessage);
  });

  test('successfully subscribe and receive  new mesages in queue', () async {
    Message message = Message(
        id: "1",
        from: user1.id,
        to: user2.id,
        timestamp: DateTime.now(),
        content: "Hello User 2");

    Message secondmessage = Message(
        id: "2",
        from: user1.id,
        to: user2.id,
        timestamp: DateTime.now(),
        content: "How are you User 2");

    await sut.send(message);
    await sut
        .send(secondmessage)
        .whenComplete(() => sut.messages(activeUser: user2).listen(
              expectAsync1((message) {
                expect(message.to, user2.id);
              }, count: 2),
            ));
  });
}
