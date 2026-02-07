import 'package:share_plus/share_plus.dart';

class SCShareUtils {
  static Future<ShareResult> share(
    String text, {
    String? subject,
  }) async {
    return await Share.share(
      text,
      subject: subject,
    );
  }

  static Future<ShareResult> shareFiles(
    List<String> filePaths, {
    String? text,
    String? subject,
  }) async {
    return await Share.shareXFiles(
      filePaths.map((e) => XFile(e)).toList(),
      subject: subject,
      text: text,
    );
  }
}
