import 'package:app/data/services/firebase/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserService extends FirestoreService {
  UserService({required super.firestoreInstance})
    : super(collectionName: 'users');

  Future<void> createUserProfile({
    required String userId,
    required String email,
    required String firstName,
    required String lastName,
  }) async {
    try {
      await collectionReference.doc(userId).set({
        'userId': userId,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print("User profile created for ID: $userId");
    } catch (e) {
      print("Error creating user profile: $e");

      throw Exception("Failed to create user profile: $e");
    }
  }
}
