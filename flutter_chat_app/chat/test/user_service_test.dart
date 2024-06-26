import 'package:chat/src/models/user.dart';
import 'package:chat/src/services/user/user_service_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rethink_db_ns/rethink_db_ns.dart';

import 'helpers.dart';

void main() {
  RethinkDb r = RethinkDb();
  late Connection connection;
  late UserService sut;

  setUp(() async {
    connection = await r.connect(host: "127.0.0.1", port: 28015);
    await createDb(r, connection);
    sut = UserService(r, connection);
  });

  tearDown(() async {
    await cleanDb(r, connection);
  });

  test('creates a new user document in rethinkdb', () async {
    final user = User(
        id: "1",
        username: 'Test user',
        photourl: 'url',
        active: true,
        lastseen: DateTime.now());

    final userWithId = await sut.connect(user);
    expect(userWithId.id, isNotEmpty);
  });

  test('get users who are online', () async {
    final user = User(
        id: "2",
        username: 'Test user',
        photourl: 'url',
        active: true,
        lastseen: DateTime.now());
    //arrange
    await sut.connect(user);
    //act
    final users = await sut.online();
    //assert
    expect(users.length, 1);
  });

  test('user is offline', () async {
    final user = User(
        id: "2",
        username: 'Test user',
        photourl: 'url',
        active: true,
        lastseen: DateTime.now());
    //arrange
    await sut.connect(user);
    //act
    await sut.disconnect(user);
    final users = await sut.online();
    //assert
    expect(user.lastseen!.day, DateTime.now().day);
    expect(users.length, 0);
  });
}
