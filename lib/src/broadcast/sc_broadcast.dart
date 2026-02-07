import 'dart:convert';

import 'package:sc_appframework/sc_appframework.dart';

class SCBroadcast {
  static sendBroadcast(String action, Map<String, dynamic> extra) {
    Map<String, dynamic> json = {
      'action': action,
      'extra': extra,
    };

    ScAppframework.invokePlatformMethod('sendBroadcast', jsonEncode(json));
  }

  static disableSCLauncherRestart(String packageName) {
    sendBroadcast('de.symblcrowd.sc_launcher.broadcast.ABORT',
        {'package_name': packageName});
  }
}
