import 'dart:async';

import 'package:chat/src/models/message.dart';
import 'package:chat/src/models/user.dart';
import 'package:chat/src/services/encryption/encryption_interface.dart';
import 'package:chat/src/utils/utils.dart';
import 'package:rethink_db_ns/rethink_db_ns.dart';

abstract class IMessageService {
  Future<bool> send(Message message);
  Stream<Message> messages({required User activeUser});
  dispose();
}

class MessageService implements IMessageService {
  final RethinkDb r;
  final Connection _connection;
  final IEncryption _encryption;

  final _controller = StreamController<Message>.broadcast();
  StreamSubscription? _changeFeed;

  MessageService(this.r, this._connection, this._encryption);

  @override
  dispose() {
    _changeFeed?.cancel();
    _controller.close();
  }

  @override
  Stream<Message> messages({required User activeUser}) {
    _startReceivingMessages(activeUser);
    return _controller.stream;
  }

  @override
  Future<bool> send(Message message) async {
    var data = message.toJson();
    data['content'] = _encryption.encrypt(message.content!);
    Map record = await r.table('messages').insert(data).run(_connection);
    return record['inserted'] == 1;
  }

  void _startReceivingMessages(User activeUser) {
    _changeFeed = r
        .table('messages')
        .filter({'to': activeUser.id})
        .changes({'include_initial': true})
        .run(_connection)
        .asStream()
        .cast<Feed>()
        .listen((event) {
          event
              .forEach((feedData) {
                if (feedData['new_val'] == null) {
                  return;
                }

                final message = _messageFromFeed(feedData);
                _controller.sink.add(message);
                _removeDeliveredMessage(message);
              })
              .catchError((err) => printOnlyInDebug("Stream Error: $err"))
              .onError((error, stackTrace) => printOnlyInDebug(error));
        });
  }

  Message _messageFromFeed(feedData) {
    var data = feedData['new_val'];
    data['content'] = _encryption.decrypt(data['content']);
    return Message.fromJson(data);
  }

  void _removeDeliveredMessage(Message message) {
    r
        .table('messages')
        .get(message.id)
        .delete({'return_changes': false}).run(_connection);
  }
}
