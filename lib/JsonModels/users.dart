// To parse this JSON data, do
//
//     final users = usersFromMap(jsonString);

class Users {
  final int? userId;
  final String usrName;
  final String usrPassword;

  Users({
    this.userId,
    required this.usrName,
    required this.usrPassword,
  });

  factory Users.fromMap(Map<String, dynamic> json) => Users(
    userId: json["userId"],
    usrName: json["usrName"],
    usrPassword: json["usrPassword"],
  );

  Map<String, dynamic> toMap() => {
    "userId": userId,
    "usrName": usrName,
    "usrPassword": usrPassword,
  };
}
