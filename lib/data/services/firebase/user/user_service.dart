import 'package:app/data/services/firebase/firestore_service.dart';
import 'package:app/data/services/firebase/user/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserService extends FirestoreService {
  UserService({required super.firestoreInstance})
    : super(collectionName: 'users');

  Future<void> createUser(UserModel user) async {
    try {
      await collectionReference.doc(user.id).set(user.toJson());
      print('User profile created in Firestore for ID: ${user.id}');
    } catch (e) {
      print('Error creating user profile in Firestore: $e');
      throw Exception('Failed to create user profile: $e');
    }
  }

  Future<String?> getEmailByUsername(String username) async {
    try {
      final querySnapshot =
          await collectionReference
              .where('username', isEqualTo: username)
              .limit(1)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userData = querySnapshot.docs.first.data();
        return userData['email'] as String?;
      }
      return null;
    } catch (e) {
      print('Error fetching email by username: $e');
      return null;
    }
  }

  Future<bool> isUsernameUnique(String username, {String? excludeUid}) async {
    try {
      Query query = collectionReference.where('username', isEqualTo: username);
      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        return true; // Username is unique
      }
      // If updating, ensure the found username doesn't belong to the current user
      if (excludeUid != null &&
          snapshot.docs.length == 1 &&
          snapshot.docs.first.id == excludeUid) {
        return true;
      }
      return false; // Username is taken
    } catch (e) {
      print('Error checking username uniqueness: $e');
      return false; // Assume not unique on error for safety
    }
  }

  Future<bool> isEmailUnique(String email, {String? excludeUid}) async {
    try {
      // Firestore queries are case-sensitive by default for 'isEqualTo'.
      // For case-insensitive email check, you might store a lowercase version of email
      // or handle this with more complex queries/backend logic.
      Query query = collectionReference.where('email', isEqualTo: email);
      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        return true;
      }
      if (excludeUid != null &&
          snapshot.docs.length == 1 &&
          snapshot.docs.first.id == excludeUid) {
        return true;
      }
      return false;
    } catch (e) {
      print('Error checking email uniqueness: $e');
      return false;
    }
  }
}
