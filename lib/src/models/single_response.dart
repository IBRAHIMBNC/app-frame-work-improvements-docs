import 'package:sc_appframework/src/models/sc_core.dart';

import 'base_response.dart';

class SingleResponse<T> extends BaseResponse {
  late T data;

  SingleResponse({
    required this.data,
  });

  factory SingleResponse.fromJson(
      Map<String, dynamic> json,
      Function(Map<String, dynamic>) create,
      List<String> jsonDataLevel,
      bool isCache) {
    for (var level in jsonDataLevel) {
      json = json[level];
    }

    T object = create(
      json,
    );

    if (object is SCCore) {
      object.isCache = isCache;
    }

    return SingleResponse<T>(
      data: object,
    );
  }
}
