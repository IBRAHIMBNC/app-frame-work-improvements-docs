import 'package:sc_appframework/src/models/failure.dart';

class SCConstants {
  static const TIMEOUT_EXCEPTION_MESSAGE =
      'The connection has timed out, please try again!';
  static const STORAGE_REQUEST_ID_KEY = "STORAGE_REQUEST_ID_KEY";
  static const STORAGE_CACHE_KEY = "STORAGE_CACHE_KEY";

  static const HIVE_BOX_GET_CACHE = "HIVE_GET_CACHE_KEY";

  static Failure NetworkFailure = Failure(-1, -1, "Network failure");
  static Failure CacheFailure = Failure(-2, -2, "Cache failure");
  static Failure JsonFailure = Failure(-3, -3, "JSON parse failure");
}
