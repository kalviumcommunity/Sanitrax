import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_application_1/models/user_model.dart';
import 'package:flutter_application_1/services/firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  late final GoogleSignIn _googleSignIn = _createGoogleSignIn();

  GoogleSignIn _createGoogleSignIn() {
    if (!kIsWeb) {
      return GoogleSignIn();
    }

    final webClientId = const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
    if (webClientId.isNotEmpty) {
      return GoogleSignIn(clientId: webClientId);
    }

    return GoogleSignIn();
  }

  /// Determines user role based on email domain
  /// driver@driver.company.com or driver*@company.com -> Driver
  /// * @company.com -> Admin
  /// all others -> Resident
  String roleFromEmail(String email) {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) {
      return 'Resident';
    }

    if (normalized.endsWith('@driver.company.com') ||
        (normalized.endsWith('@company.com') &&
            normalized.split('@').first.startsWith('driver'))) {
      return 'Driver';
    }

    if (normalized.endsWith('@company.com')) {
      return 'Admin';
    }

    return 'Resident';
  }

  // Email Sign Up
  Future<User?> signUp(
    String email,
    String password, {
    required String name,
    required String role,
  }) async {
    try {
      final resolvedRole = email.trim().isEmpty ? role : roleFromEmail(email);
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
      if (user != null) {
        await user.updateDisplayName(name);
        await _firestoreService.addUser(
          UserModel(
            uid: user.uid,
            email: user.email ?? email,
            name: name,
            role: resolvedRole,
          ),
        );
      }
      print('SignUp successful: ${userCredential.user?.email}');
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print('SignUp FirebaseAuthException: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('SignUp Error: $e');
      rethrow;
    }
  }

  // Email Login
  Future<User?> signIn(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('SignIn successful: ${userCredential.user?.email}');
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print('SignIn FirebaseAuthException: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('SignIn Error: $e');
      rethrow;
    }
  }

  Future<void> ensureUserProfile(
    User user, {
    String defaultRole = 'Resident',
  }) async {
    final existing = await _firestoreService.getUser(user.uid);

    final email = user.email ?? '';
    final resolvedRole = email.isNotEmpty ? roleFromEmail(email) : defaultRole;

    // If profile exists, keep admin-assigned role to avoid overriding manual roles.
    if (existing != null) {
      return;
    }

    // Create new profile
    final safeName = (user.displayName?.trim().isNotEmpty ?? false)
        ? user.displayName!.trim()
        : user.email?.split('@').first ?? 'User';

    await _firestoreService.addUser(
      UserModel(
        uid: user.uid,
        email: email,
        name: safeName,
        role: resolvedRole,
      ),
    );
  }

  Future<String> getUserRole(String uid) async {
    final user = await _firestoreService.getUser(uid);
    return user?.role ?? 'Resident';
  }

  // Google Sign In
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled login
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      print('idToken: ${googleAuth.idToken}');
      print('accessToken: ${googleAuth.accessToken}');
      print('serverAuthCode: ${googleAuth.serverAuthCode}');

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user != null) {
        await ensureUserProfile(user);
      }

      return user;
    } on AssertionError catch (_) {
      throw StateError(
        'Google Sign-In web Client ID is missing. Set <meta name="google-signin-client_id" content="CLIENT_ID.apps.googleusercontent.com"> in web/index.html '
        'or run with --dart-define=GOOGLE_WEB_CLIENT_ID=CLIENT_ID.apps.googleusercontent.com',
      );
    } catch (e) {
      print('Google SignIn Error: $e');
      rethrow;
    }
  }

  // Phone Login
  Future<void> verifyPhone(
    String phoneNumber,
    Function(String verificationId) codeSent,
  ) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        print(e.message);
      },
      codeSent: (String verificationId, int? resendToken) {
        codeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  Future<User?> verifyOTP(String verificationId, String smsCode) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );

    final userCredential = await _auth.signInWithCredential(credential);

    return userCredential.user;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
