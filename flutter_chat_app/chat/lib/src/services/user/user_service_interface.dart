
import 'package:chat/src/models/user.dart';
import 'package:rethink_db_ns/rethink_db_ns.dart';

abstract class IUserService {
  Future<User> connect(User user);
  Future<List<User>> online();
  Future<void> disconnect(User user);
}

class UserService implements IUserService {
  final RethinkDb r;
  final Connection _connection;
  UserService(this.r, this._connection);

  @override
  Future<User> connect(User user) async {
    var data = user.toJson();
    if (user.id != null) {
      data["id"] = user.id;
    }

    final result = await r.table('users').insert(data, {
      'conflict': 'update',
      'return_changes': true,
    }).run(_connection);

    return User.fromJson(result['changes'].first['new_val']);
  }

  @override
  Future<void> disconnect(User user) async {
    await r.table('users').update({
      'id': user.id,
      'active': false,
      'lastseen': DateTime.now()
    }).run(_connection);
    // _connection.close();
  }

  @override
  Future<List<User>> online() async {
    Cursor users =
        await r.table('users').filter({'active': true}).run(_connection);
    final userList = await users.toList();
    return userList.map((item) => User.fromJson(item)).toList();
  }
}
