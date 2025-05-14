import 'dart:io';

import 'package:app/data/repositories/user/user_model.dart';
import 'package:app/data/services/firebase/firestore_service.dart';
import 'package:app/domain/models/user.dart';
import 'package:app/utils/result.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserRepository extends FirestoreService {
  UserRepository({required super.firestoreInstance})
    : super(collectionName: 'users');

  Future<Result<void>> createUser(UserFirebaseModel user) async {
    try {
      return Result.ok(
        await collectionReference.doc(user.id).set(user.toJson()),
      );
    } on FirebaseException catch (e) {
      print(
        'Firebase error creating user profile for ID ${user.id}: ${e.message} (Code: ${e.code})',
      );
      return Result.error(
        Exception('Firebase error: ${e.message} (Code: ${e.code})'),
      );
    } on Exception catch (e) {
      print('Generic error creating user profile for ID ${user.id}: $e');
      return Result.error(e);
    }
  }

  Future<Result<String?>> getEmailByUsername(String username) async {
    try {
      final querySnapshot =
          await collectionReference
              .where('username', isEqualTo: username)
              .limit(1)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userData = querySnapshot.docs.first.data();
        final email = userData['email'];
        if (email is String || email == null) {
          return Result.ok(email as String?); // Success, email might be null
        } else {
          print(
            'Error: Email field is not a String for username: $username. Found type: ${email.runtimeType}',
          );
          return Result.error(
            FormatException(
              'Email field has an unexpected data type for username: $username',
            ),
          );
        }
      } else {
        return const Result.ok(null);
      }
    } on FirebaseException catch (error) {
      print(
        'Firebase error fetching email by username $username: ${error.message} (Code: ${error.code})',
      );
      return Result.error(
        Exception('Firebase error: ${error.message} (Code: ${error.code})'),
      );
    } on Exception catch (error) {
      print('Generic error fetching email by username $username: $error');
      return Result.error(error);
    }
  }

  Future<Result<bool>> isUsernameUnique(
    String username, {
    String? excludeUid,
  }) async {
    try {
      Query query = collectionReference.where('username', isEqualTo: username);
      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        return Result.ok(true);
      }

      if (excludeUid != null &&
          snapshot.docs.length == 1 &&
          snapshot.docs.first.id == excludeUid) {
        return Result.ok(true);
      }

      return Result.ok(false);
    } on Exception catch (error) {
      print('Error checking username uniqueness: $error');
      return Result.error(error);
    }
  }

  /// Fetches a user by their unique ID.
  ///
  /// Returns a [Result.ok] with the [UserFirebaseModel] if found.
  /// Returns a [Result.error] if the user is not found or if any other error occurs.
  Future<Result<User>> getUserById(String userId) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> docSnapshot =
          await collectionReference.doc(userId).get();

      if (docSnapshot.exists) {
        final userFirebase = UserFirebaseModel.fromFirestore(docSnapshot);
        print('User fetched successfully for ID: $userId');
        return Result.ok(userFirebase.toUser());
      } else {
        print('User not found for ID: $userId');
        return Result.error(Exception("User with ID $userId not found."));
      }
    } on FirebaseException catch (e) {
      print(
        'Firebase error fetching user by ID $userId: ${e.message} (Code: ${e.code})',
      );
      return Result.error(
        FirebaseException(
          plugin: e.plugin,
          message: 'Firebase error: ${e.message} (Code: ${e.code})',
        ),
      );
    } on Exception catch (e) {
      // This could catch errors from UserFirebaseModel.fromFirestore if it throws
      print('Generic error fetching user by ID $userId: $e');
      return Result.error(e);
    }
  }

  /// Updates the user's avatar in Firestore with a Base64 encoded image.
  ///
  /// Takes the [userId] and the [imageFile] as input.
  /// Returns a [Result.ok] with the Base64 data URL string on success.
  /// Returns a [Result.error] if any error occurs.
  Future<Result<String>> updateAvatar(String userId, String avatar) async {
    try {
      await collectionReference.doc(userId).update({
        'profilePictureUrl': avatar,
      });

      print('Avatar updated successfully for user ID: $userId');
      return Result.ok(avatar);
    } on FirebaseException catch (e) {
      print(
        'Firebase error updating avatar for user ID $userId: ${e.message} (Code: ${e.code})',
      );
      return Result.error(
        Exception(
          'Firebase error updating avatar: ${e.message} (Code: ${e.code})',
        ),
      );
    } on FileSystemException catch (e) {
      print(
        'File system error processing image for avatar update (ID $userId): $e',
      );
      return Result.error(
        FileSystemException('File system error processing image: ${e.message}'),
      );
    } on Exception catch (e) {
      print('Generic error updating avatar for user ID $userId: $e');
      return Result.error(Exception('Generic error updating avatar: $e'));
    }
  }
}
