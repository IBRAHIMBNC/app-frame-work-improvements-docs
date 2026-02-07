class Failure {
  int? statusCode;
  int? internalStatusCode;
  String? errorMessage;

  @override
  bool operator ==(Object other) =>
      other is Failure &&
      other.statusCode == statusCode &&
      other.internalStatusCode == internalStatusCode;

  @override
  int get hashCode =>
      statusCode.hashCode + internalStatusCode.hashCode + errorMessage.hashCode;

  Failure(
    this.statusCode,
    this.internalStatusCode,
    this.errorMessage,
  );
}
