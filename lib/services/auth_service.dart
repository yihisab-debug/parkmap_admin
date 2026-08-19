import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/app_user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<AppUser> signInWithGoogleAsAdmin() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Вход через Google был отменён');
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user!;
    final userDocRef = _db.collection('users').doc(user.uid);
    final snapshot = await userDocRef.get();

    if (!snapshot.exists) {
      final newUser = AppUser(
        uid: user.uid,
        name: user.displayName ?? 'Админ',
        email: user.email ?? '',
        photoUrl: user.photoURL,
        role: 'admin',
        balance: 0,
        isBanned: false,
      );
      await userDocRef.set(newUser.toMap());
      return newUser;
    }

    final appUser = AppUser.fromMap(user.uid, snapshot.data()!);
    if (appUser.role != 'admin') {
      await userDocRef.update({'role': 'admin'});
      return AppUser.fromMap(user.uid, {...snapshot.data()!, 'role': 'admin'});
    }

    return appUser;
  }

  Stream<AppUser?> watchCurrentAppUser() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);
    return _db.collection('users').doc(user.uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AppUser.fromMap(user.uid, doc.data()!);
    });
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
