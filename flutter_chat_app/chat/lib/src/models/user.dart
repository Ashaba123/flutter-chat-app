class User {
  String? username;
  String? photourl;
  String? id;
  bool? active;
  DateTime? lastseen;

  User({
    required this.id,
    required this.username,
    required this.photourl,
    required this.active,
    required this.lastseen,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final user = User(
        id: json["id"] ,
        username: json["username"],
        photourl: json["photourl"],
        active: json["active"],
        lastseen: json["lastseen"]);

    return user;
  }

  toJson() => {
        "id": id,
        "username": username,
        "photourl": photourl,
        "active": active,
        "lastseen": lastseen
      };
}
