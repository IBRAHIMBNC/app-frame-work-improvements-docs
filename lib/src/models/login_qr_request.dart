class LoginQrRequest {
  final String qrCodeData;
  final String pin;

  LoginQrRequest({
    required this.qrCodeData,
    required this.pin,
  });

  Map<String, dynamic> toJson() {
    return {
      'qr_code_data': qrCodeData,
      'pin': pin,
    };
  }
}
