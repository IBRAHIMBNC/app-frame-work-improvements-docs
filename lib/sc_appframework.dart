library scappframework;

import 'package:flutter/services.dart';
export 'package:sc_appframework/src/storage/sc_internal_storage.dart';
export 'package:sc_appframework/src/storage/sc_shared_prefs_storage.dart';
export 'package:sc_appframework/src/network/sc_network_api.dart';
export 'package:sc_appframework/src/network/sc_update.dart';
export 'package:sc_appframework/src/services/sc_auth_service.dart';

export 'package:sc_appframework/src/logger/sc_logger.dart';
export 'package:sc_appframework/src/broadcast/sc_broadcast.dart';
export 'package:sc_appframework/src/utils/sc_base64_utils.dart';
export 'package:sc_appframework/src/utils/sc_color_utils.dart';
export 'package:sc_appframework/src/utils/sc_date_utils.dart';
export 'package:sc_appframework/src/utils/sc_file_utils.dart';
export 'package:sc_appframework/src/utils/sc_location_utils.dart';
export 'package:sc_appframework/src/utils/sc_share_utils.dart';
export 'package:sc_appframework/src/utils/sc_app_config_interface.dart';

export 'package:sc_appframework/src/models/failure.dart';
export 'package:sc_appframework/src/models/file_payload.dart';
export 'package:sc_appframework/src/models/sc_cached_request.dart';
export 'package:sc_appframework/src/models/sc_core.dart';
export 'package:sc_appframework/src/models/auth_account.dart';
export 'package:sc_appframework/src/models/auth_api_device_log.dart';
export 'package:sc_appframework/src/models/login_pin_request.dart';
export 'package:sc_appframework/src/models/login_qr_request.dart';
export 'package:sc_appframework/src/models/login_result.dart';
export 'package:sc_appframework/src/models/login_status_codes.dart';
export 'package:sc_appframework/src/models/change_password_request.dart';
export 'package:sc_appframework/src/models/change_pin_request.dart';

export 'package:sc_appframework/src/extension/sc_context_extension.dart';

export 'package:dartz/dartz.dart' show Either, Left, Right;

export 'package:sc_appframework/src/utils/sc_constants.dart';

class ScAppframework {
  static const MethodChannel _channel =
      MethodChannel('de.symblcrowd.sc_appframework');

  static invokePlatformMethod(String method, dynamic args) {
    _channel.invokeMethod(method, args);
  }
}
