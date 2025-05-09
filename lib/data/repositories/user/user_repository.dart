import 'package:app/data/repositories/user/user_model.dart';
import 'package:app/data/services/firebase/firestore_service.dart';
import 'package:app/utils/result.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserRepository extends FirestoreService {
  UserRepository({required super.firestoreInstance})
    : super(collectionName: 'users');

  Future<Result<void>> createUser(UserModel user) async {
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
}
