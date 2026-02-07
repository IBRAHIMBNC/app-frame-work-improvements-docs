import 'package:sc_appframework/src/models/sc_core.dart';

import 'base_response.dart';

class ListResponse<T> extends BaseResponse {
  List<T> data;

  ListResponse({
    this.data = const [],
  });

  factory ListResponse.fromJson(
      dynamic json,
      Function(Map<String, dynamic>) create,
      List<String> jsonDataLevel,
      bool isCache) {
    List<T> data = [];
    dynamic currentData = json;

    for (var level in jsonDataLevel) {
      currentData = currentData[level];
    }

    // IF IT'S A LIST OF MAP
    if (json is List<dynamic>) {
      for (var element in json) {
        T object = create(element);

        if (object is SCCore) {
          object.isCache = isCache;
        }

        data.add(object);
      }
      // A JSON STRUCTURE
    } else {
      if (jsonDataLevel.isEmpty) {
        currentData.forEach(
          (key, list) {
            for (var element in list) {
              T object = create(element);

              if (object is SCCore) {
                object.isCache = isCache;
              }

              data.add(object);
            }
          },
        );
      } else {
        currentData.forEach(
          (element) {
            T object = create(element);

            if (object is SCCore) {
              object.isCache = isCache;
            }

            data.add(object);
          },
        );
      }
    }

    return ListResponse<T>(
      data: data,
    );
  }
}
