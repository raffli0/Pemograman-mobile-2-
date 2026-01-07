import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Register new user with role
  Future<UserModel?> register({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    try {
      // Create user in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) return null;

      // Create user profile in Firestore
      final userModel = UserModel(
        uid: user.uid,
        email: email,
        name: name,
        role: role,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(user.uid).set(userModel.toMap());

      return userModel;
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with email and password
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) return null;

      return await getUserProfile(user.uid);
    } catch (e) {
      rethrow;
    }
  }

  // Sign in anonymously (Guest)
  Future<UserModel?> signInAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously();
      final user = userCredential.user;

      if (user == null) return null;

      // Return a temporary user model for guests
      // We don't save guest users to Firestore to avoid clutter,
      // or we could save them with a 'guest' role if needed.
      // For now, returning a local UserModel.
      return UserModel(
        uid: user.uid,
        email: '',
        name: 'Guest',
        role: UserRole.customer,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      rethrow;
    }
  }

  // Get user profile from Firestore
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return null;

      return UserModel.fromMap(doc.data()!);
    } catch (e) {
      rethrow;
    }
  }

  // Get user role
  Future<UserRole?> getUserRole(String uid) async {
    try {
      final userModel = await getUserProfile(uid);
      return userModel?.role;
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Check if user is signed in
  bool isSignedIn() {
    return _auth.currentUser != null;
  }
}
