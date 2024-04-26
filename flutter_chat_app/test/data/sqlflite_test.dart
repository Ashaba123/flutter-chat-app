import 'package:chat/chat.dart';
import 'package:flutter_chat_app/data/data_source/data_source_interface.dart';
import 'package:flutter_chat_app/models/chat.dart';
import 'package:flutter_chat_app/models/local_message.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite/sqflite.dart';
import 'sqlflite_test.mocks.dart';

@GenerateMocks([sqflite.Database])
@GenerateMocks([sqflite.Batch])
void main() {
  late SqfliteDataSource sut;
  late MockDatabase database;
  late MockBatch batch;

  setUp(() {
    database = MockDatabase();
    batch = MockBatch();
    sut = SqfliteDataSource(database);
  });

  final message = Message.fromJson({
    'id': "4444",
    'from': '111',
    'to': '222',
    'content': 'hey',
    'timestamp': DateTime.parse('2024-04-25'),
  });

  test('should perform insert of chat to the database', () async {
    //arrange
    final chat = Chat('1234');
    when(database.insert('chats', chat.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace))
        .thenAnswer((_) async => 1);
    //act
    await sut.addChat(chat);

    //assert
    verify(database.insert('chats', chat.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace))
        .called(1);
  });

  test('should perform insert of message to the database', () async {
    //arrange
    final localMessage = LocalMessage(
        id: '1234', message: message, receiptStatus: ReceiptStatus.sent);

    when(database.insert('messages', localMessage.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace))
        .thenAnswer((_) async => 1);
    //act
    await sut.addMessage(localMessage);

    //assert
    verify(database.insert('messages', localMessage.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace))
        .called(1);
  });

  test('should perform a database query and return message', () async {
    //arrange
    final messagesMap = [
      {
        'chat_id': '111',
        'id': '4444',
        'from': '111',
        'to': '222',
        'content': 'hey',
        'receipt_status': 'sent',
        'timestamp': DateTime.parse("2021-04-01"),
      }
    ];
    when(database.query(
      'messages',
      where: anyNamed('where'),
      whereArgs: anyNamed('whereArgs'),
    )).thenAnswer((_) async => messagesMap);

    //act
    var messages = await sut.findMessages('111');

    //assert
    expect(messages.length, 1);
    expect(messages.first.chatId, '111');
    verify(database.query(
      'messages',
      where: anyNamed('where'),
      whereArgs: anyNamed('whereArgs'),
    )).called(1);
  });

  test('should perform database update on messages', () async {
    //arrange
    when(database.update(any, any))
        .thenAnswer((_) async => Future<int>.value(0));
        
    final localMessage = LocalMessage(
        id: '1234', message: message, receiptStatus: ReceiptStatus.sent);

    when(database.update('messages', localMessage.toMap(),
            where: anyNamed('where'), whereArgs: anyNamed('whereArgs'),conflictAlgorithm: ConflictAlgorithm.replace))
        .thenAnswer((_) async => 1);

    //act
    await sut.updateMessage(localMessage);

    //assert
    verify(database.update('messages', localMessage.toMap(),
            where: anyNamed('where'),
            whereArgs: anyNamed('whereArgs'),
            conflictAlgorithm: ConflictAlgorithm.replace))
        .called(1);
  });

  test('should perform database batch delete of chat', () async {
    //arrange
    when(batch.commit(noResult: true)).thenAnswer((_) async => <Object?>[]);
    const chatId = '111';
    when(database.batch()).thenReturn(batch);

    //act
    await sut.deleteChat(chatId);

    //assert
    verifyInOrder([
      database.batch(),
      batch.delete('messages', where: anyNamed('where'), whereArgs: [chatId]),
      batch.delete('chats', where: anyNamed('where'), whereArgs: [chatId]),
      batch.commit(noResult: true)
    ]);
  });
}
