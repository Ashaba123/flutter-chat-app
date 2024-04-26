import 'dart:async';

import 'package:chat/src/models/receipt.dart';
import 'package:chat/src/models/user.dart';
import 'package:chat/src/utils/utils.dart';
import 'package:rethink_db_ns/rethink_db_ns.dart';

abstract class IReceiptService {
  Future<bool> send(Receipt receipt);
  Stream<Receipt> receipts(User user);
  void dispose();
}

class ReceiptService implements IReceiptService {
  final RethinkDb r;
  final Connection _connection;

  final _controller = StreamController<Receipt>.broadcast();
  StreamSubscription? _changeFeed;

  ReceiptService(this.r, this._connection);

  @override
  dispose() {
    _changeFeed?.cancel();
    _controller.close();
  }

  @override
  Stream<Receipt> receipts(User user) {
    _startReceivingReceipts(user);
    return _controller.stream;
  }

  @override
  Future<bool> send(Receipt receipt) async {
    var data = receipt.toJson();
    Map record = await r.table('receipts').insert(data).run(_connection);
    return record['inserted'] == 1;
  }

  void _startReceivingReceipts(User user) {
    _changeFeed = r
        .table('receipts')
        .filter({'recipient': user.id})
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

                final receipt = _messageFromFeed(feedData);
                _controller.sink.add(receipt);
              })
              .catchError(
                  (err) => printOnlyInDebug("Stream Receipts Error: $err"))
              .onError((error, stackTrace) => printOnlyInDebug(error));
        });
  }

  Receipt _messageFromFeed(feedData) {
    var data = feedData['new_val'];
    return Receipt.fromJson(data);
  }
}
