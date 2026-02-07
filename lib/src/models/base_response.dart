class BaseResponse {
  int? status;
  

  BaseResponse({this.status});

  factory BaseResponse.fromJson(Map<String, dynamic> json) {
    return BaseResponse(
      status: json["status"],
    );
  }
}
