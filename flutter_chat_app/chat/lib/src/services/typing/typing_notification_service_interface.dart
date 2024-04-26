import 'dart:async';

import 'package:chat/src/models/typing_event.dart';
import 'package:chat/src/models/user.dart';
import 'package:chat/src/utils/utils.dart';
import 'package:rethink_db_ns/rethink_db_ns.dart';


abstract class ITypingNotificationService {
  Future<bool> send(TypingEvent typingEvent, User to);
  Stream<TypingEvent> subscribe(User user, List<String> userids);
  void dispose();
}

class TypingNotificationService implements ITypingNotificationService {
  final RethinkDb _r;
  final Connection _connection;

  final _controller = StreamController<TypingEvent>.broadcast();
  StreamSubscription? _changeFeed;

  TypingNotificationService(this._r, this._connection);

  @override
  Future<bool> send(TypingEvent typingEvent, User to) async {
    if (!to.active!) return false;

    Map record = await _r
        .table('typing_events')
        .insert(typingEvent.toJson(), {'conflict': 'update'}).run(_connection);
    return record['inserted'] == 1;
  }

  @override
  Stream<TypingEvent> subscribe(User user, List<String> userids) {
    _startReceivingTypingEvents(user, userids);
    return _controller.stream;
  }

  @override
  void dispose() {
    _changeFeed?.cancel();
    _controller.close();
  }

  void _startReceivingTypingEvents(User user, List<String> userids) {
    _changeFeed = _r
        .table('typing_events')
        .filter((event) {
          return event('to')
              .eq(user.id)
              .and(_r.expr(userids).contains(event('from')));
        })
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

                final typing = _eventFromFeed(feedData);
                _controller.sink.add(typing);
                _removeEvent(typing);
              })
              .catchError(
                  (err) => printOnlyInDebug("Stream Typing Events Error: $err"))
              .onError((error, stackTrace) => printOnlyInDebug(error));
        });
  }

  TypingEvent _eventFromFeed(feedData) {
    var data = feedData['new_val'];
    return TypingEvent.fromJson(data);
  }

  void _removeEvent(TypingEvent typing) {
    _r
        .table('typing_events')
        .get(typing.id)
        .delete({'return_changes': false}).run(_connection);
  }
}
