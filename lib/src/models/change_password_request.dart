class ChangePasswordRequest {
  final String passwordX;
  final String passwordRepeat;

  ChangePasswordRequest({
    required this.passwordX,
    required this.passwordRepeat,
  });

  Map<String, dynamic> toJson() {
    return {
      'password_x': passwordX,
      'password_repeat': passwordRepeat,
    };
  }
}
