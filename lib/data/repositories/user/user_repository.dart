import 'package:app/data/repositories/user/user_model.dart';
import 'package:app/data/services/firebase/firestore_service.dart';
import 'package:app/domain/models/user.dart';
import 'package:app/utils/result.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserRepository extends FirestoreService {
  UserRepository({required super.firestoreInstance})
    : super(collectionName: 'users');

  UserFirebaseModel? _cachedUser;

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
      if (_cachedUser?.username == username) {
        return Result.ok(true);
      }

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

  Future<Result<User>> getUserById(
    String userId, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cachedUser != null && _cachedUser?.id == userId) {
      print('Serving user $userId from cache.');
      return Result.ok(_cachedUser!.toUser());
    }

    print(
      'Fetching user $userId from Firestore (forceRefresh: $forceRefresh).',
    );
    try {
      final DocumentSnapshot<Map<String, dynamic>> docSnapshot =
          await collectionReference.doc(userId).get();

      if (docSnapshot.exists) {
        final userFirebase = UserFirebaseModel.fromFirestore(docSnapshot);
        // Update cache
        _cachedUser = userFirebase;
        print('User $userId fetched and cached successfully.');
        return Result.ok(_cachedUser!.toUser());
      } else {
        print('User not found for ID: $userId');

        if (_cachedUser!.id == userId) {
          _cachedUser = null;
        }

        return Result.error(Exception("User with ID $userId not found."));
      }
    } on FirebaseException catch (e) {
      return Result.error(
        FirebaseException(
          plugin: e.plugin,
          code: e.code,
          message: 'Firebase error: ${e.message}',
        ),
      );
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<String>> updateAvatar(String userId, String avatar) async {
    try {
      await collectionReference.doc(userId).update({'avatar': avatar});

      // Cache Invalidation/Update:
      if (_cachedUser != null && _cachedUser!.id == userId) {
        _cachedUser = _cachedUser!.copyWith(
          avatar: avatar,
        ); // Assuming User has copyWith
        print('Avatar updated in cache for user ID: $userId');
      } else {
        clearCacheForUser(userId);
      }

      print('Avatar updated successfully for user ID: $userId');
      return Result.ok(avatar);
    } on FirebaseException catch (e) {
      // ... (error handling as before)
      return Result.error(
        Exception(
          'Firebase error updating avatar: ${e.message} (Code: ${e.code})',
        ),
      );
    } on Exception catch (e) {
      // ... (error handling as before)
      return Result.error(Exception('Generic error updating avatar: $e'));
    }
  }

  Future<Result<void>> updateUserProfile(User userToUpdate) async {
    try {
      if (_cachedUser == null) {
        return Result.error(Exception('No user loaded.'));
      }

      _cachedUser = _cachedUser!.copyWith(
        firstName: userToUpdate.firstName,
        lastName: userToUpdate.lastName,
        username: userToUpdate.username,
        phoneNumber: userToUpdate.phoneNumber,
        interests: userToUpdate.interests,
        travelStyles: userToUpdate.travelStyles,
        updatedAt: DateTime.now(),
      );
      final userDataMap = _cachedUser!.toJson();
      await collectionReference.doc(_cachedUser!.id).update(userDataMap);

      print('User profile updated successfully for: ${userToUpdate.username}');
      return const Result.ok(null);
    } on FirebaseException catch (e) {
      return Result.error(
        Exception('Firebase error: ${e.message} (Code: ${e.code})'),
      );
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  void clearCacheForUser(String? userIdToDelete) {
    if (userIdToDelete == null || _cachedUser!.id == userIdToDelete) {
      print(
        'Clearing cache for user: ${userIdToDelete ?? "all (single cache)"}',
      );
      _cachedUser = null;
    }
  }

  void clearAllCache() {
    clearCacheForUser(null);
  }
}
