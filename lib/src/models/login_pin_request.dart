class LoginPinRequest {
  final String username;
  final String pin;

  LoginPinRequest({
    required this.username,
    required this.pin,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'pin_x': pin,
    };
  }
}
