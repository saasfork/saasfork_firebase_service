import 'package:cloud_functions/cloud_functions.dart';

class UserFunctions {
  static Future<void> initializeUserClaims(
    String uid,
    Map<String, dynamic> claims,
  ) async {
    final callable = FirebaseFunctions.instance.httpsCallable(
      'initializeUserClaims',
    );

    await callable({'uid': uid, 'claims': claims});
  }
}
