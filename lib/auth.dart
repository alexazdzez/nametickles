import 'package:firebase_auth/firebase_auth.dart';

class AuthServices {
  final FirebaseAuth auth = FirebaseAuth.instance;

  Future<User?> signinAnonymous() async {
    try {
      final result = await auth.signInAnonymously();
      return result.user;
    } catch (e) {
      return null;
    }
  }
}
