class User{
  final int id;
  final String username;
  final String password;
  final String email;
  final int color;

  User({this.id, this.username, this.password, this.email, this.color});

  //fromMap() is used to convert a Map into a User object
  User.fromMap(Map<String, dynamic> map)
      : id = map['id'],
        username = map['username'],
        password = map['password'],
        email = map['email'],
        color = map['color'];


  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'email': email,
      'color': color,
    };
  }



  @override
  String toString() {
    return 'User{id: $id, username: $username, password: $password, email: $email, color: $color}';
  }
}