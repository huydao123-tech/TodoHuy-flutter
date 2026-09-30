import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'user_model.dart';

const _webClientId = '154847841204-mu69pm4mjen704pekfv23f0mp90es1eb.apps.googleusercontent.com';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    FirebaseAuth.instance,
    FirebaseFirestore.instance,
    GoogleSignIn(
      clientId: kIsWeb ? _webClientId : null,
    ),
  );
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  AuthRepository(this._auth, this._firestore, this._googleSignIn);

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    return null;
  }

  Future<void> _createUserProfileIfNotExist(User user, {String? fullName}) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    final doc = await docRef.get();
    
    if (!doc.exists) {
      final newUser = UserModel(
        id: user.uid,
        email: user.email ?? '',
        fullName: fullName ?? user.displayName ?? 'Người dùng',
        role: 'USER',
        createdAt: DateTime.now(),
      );
      await docRef.set(newUser.toFirestore());
      // Seed default task groups for new users
      await _seedDefaultTaskGroups(user.uid);
    }
  }

  Future<void> _seedDefaultTaskGroups(String userId) async {
    final defaults = [
      {'name': 'Tiếng Nhật', 'color': '#16A34A', 'displayOrder': 1},
      {'name': 'Cờ vua',     'color': '#7C3AED', 'displayOrder': 2},
      {'name': 'Thể hình',   'color': '#D97706', 'displayOrder': 3},
    ];

    final batch = _firestore.batch();
    for (final g in defaults) {
      final ref = _firestore
          .collection('users')
          .doc(userId)
          .collection('task_groups')
          .doc();
      batch.set(ref, {
        'name': g['name'],
        'color': g['color'],
        'type': 'MAIN',
        'displayOrder': g['displayOrder'],
        'isArchived': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<void> signInWithEmail(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signUpWithEmail(String email, String password, String fullName) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (credential.user != null) {
      // updateDisplayName may fail silently - that's OK
      try { await credential.user!.updateDisplayName(fullName); } catch (_) {}
      // Create Firestore profile - failure here should not block auth
      try {
        await _createUserProfileIfNotExist(credential.user!, fullName: fullName);
      } catch (e) {
        // Profile creation failed (likely Firestore rules not deployed yet)
        // Auth still succeeded - user can still log in
        debugPrint('[AuthRepository] Profile creation failed: $e');
      }
    }
  }



  Future<void> signInWithGoogle() async {
    UserCredential userCredential;
    if (kIsWeb) {
      final googleProvider = GoogleAuthProvider();
      userCredential = await _auth.signInWithPopup(googleProvider);
    } else {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return; // User canceled

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      userCredential = await _auth.signInWithCredential(credential);
    }

    if (userCredential.user != null) {
      await _createUserProfileIfNotExist(userCredential.user!);
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
