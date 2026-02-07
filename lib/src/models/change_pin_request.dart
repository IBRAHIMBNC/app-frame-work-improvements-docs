class ChangePinRequest {
  final String pinX;
  final String pinRepeat;

  ChangePinRequest({
    required this.pinX,
    required this.pinRepeat,
  });

  Map<String, dynamic> toJson() {
    return {
      'pin_x': pinX,
      'pin_repeat': pinRepeat,
    };
  }
}
