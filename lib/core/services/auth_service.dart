import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/app_user.dart';
import 'notification_service.dart'; // Import notification service

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService(); // Create an instance

  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Login
  Future<AppUser?> login(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;

      if (user != null) {
        DocumentSnapshot doc =
            await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final appUser = AppUser.fromMap(doc.data() as Map<String, dynamic>, user.uid);
          
          // If the user is an admin, subscribe them to the new withdrawal topic
          if (appUser.role == 'admin') {
            await _notificationService.subscribeToTopic('new_withdrawal');
          }

          return appUser;
        } else {
          // Fallback
          return AppUser(uid: user.uid, email: email, role: 'employee');
        }
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Get User Role (Helper for redirects)
  Future<String?> getUserRole(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return (doc.data() as Map<String, dynamic>)['role'];
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  // Sign out
  Future<void> signOut() async {
    // Unsubscribe from topic on sign out to prevent getting notifications when logged out
    await _notificationService.unsubscribeFromTopic('new_withdrawal');
    await _auth.signOut();
  }
}
