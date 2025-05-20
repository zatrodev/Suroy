import 'dart:async';

import 'package:app/data/repositories/user/user_model.dart';
import 'package:app/data/services/firebase/firestore_service.dart';
import 'package:app/domain/models/user.dart';
import 'package:app/utils/result.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:rxdart/rxdart.dart';

class UserRepository extends FirestoreService {
  final fb_auth.FirebaseAuth _firebaseAuth;

  final BehaviorSubject<UserFirebaseModel?> _currentUserModelController =
      BehaviorSubject<UserFirebaseModel?>.seeded(null);

  Stream<User?> get currentUser =>
      _currentUserModelController.stream.map((model) => model?.toUser());

  User? get user => _currentUserModelController.value?.toUser();

  StreamSubscription? _authSubscription;
  StreamSubscription? _userDocumentSubscription;

  UserRepository({
    required super.firestoreInstance,
    fb_auth.FirebaseAuth? firebaseAuthInstance,
  }) : _firebaseAuth = firebaseAuthInstance ?? fb_auth.FirebaseAuth.instance,
       super(collectionName: 'users') {
    _initAuthListener();
  }

  void _initAuthListener() {
    _authSubscription?.cancel();
    _authSubscription = _firebaseAuth.authStateChanges().listen(
      _onAuthStateChanged,
    );
  }

  Future<void> _onAuthStateChanged(fb_auth.User? firebaseUser) async {
    await _userDocumentSubscription?.cancel();
    _userDocumentSubscription = null;

    if (firebaseUser == null) {
      print("UserRepository: User signed out. Clearing user data.");
      _currentUserModelController.add(null);
    } else {
      print(
        "UserRepository: User signed in/changed: ${firebaseUser.uid}. Setting up user document listener.",
      );
      _userDocumentSubscription = collectionReference
          .doc(firebaseUser.uid)
          .snapshots()
          .listen(
            (snapshot) {
              if (snapshot.exists) {
                print(
                  "UserRepository: Current user document updated: ${firebaseUser.uid}",
                );
                final userModel = UserFirebaseModel.fromFirestore(snapshot);
                _currentUserModelController.add(userModel);
              } else {
                print(
                  "UserRepository: Current user document does not exist: ${firebaseUser.uid}",
                );
                // This case might mean the Firestore profile hasn't been created yet
                // or was deleted.
                _currentUserModelController.add(null);
              }
            },
            onError: (error) {
              print(
                "UserRepository: Error listening to user document ${firebaseUser.uid}: $error",
              );
              _currentUserModelController.addError(error); // Propagate error
              _currentUserModelController.add(null); // Or revert to null state
            },
          );
    }
  }

  Future<Result<void>> createUser(UserFirebaseModel user) async {
    try {
      await collectionReference.doc(user.id).set(user.toJson());
      // No need to update, for _onAuthStateChanged will pick it up
      return Result.ok(null);
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

  Future<Result<User>> getUserById(
    String userId, {
    bool forceRefresh = false,
  }) async {
    final currentCachedModel = _currentUserModelController.value;
    if (!forceRefresh &&
        currentCachedModel != null &&
        currentCachedModel.id == userId) {
      print('UserRepository: Serving user $userId from reactive cache.');
      return Result.ok(currentCachedModel.toUser());
    }

    print(
      'UserRepository: Fetching user $userId from Firestore (forceRefresh: $forceRefresh).',
    );
    try {
      final DocumentSnapshot<Map<String, dynamic>> docSnapshot =
          await collectionReference.doc(userId).get();

      if (docSnapshot.exists) {
        final userFirebase = UserFirebaseModel.fromFirestore(docSnapshot);
        return Result.ok(userFirebase.toUser());
      } else {
        print('UserRepository: User not found for ID: $userId');
        return Result.error(Exception("User with ID $userId not found."));
      }
    } on FirebaseException catch (e) {
      return Result.error(Exception(e.message));
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<bool>> isUsernameUnique(
    String username, {
    String? excludeUid,
  }) async {
    try {
      if (_currentUserModelController.value?.username == username &&
          _currentUserModelController.value?.id == excludeUid) {
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
      print('UserRepository: Error checking username uniqueness: $error');
      return Result.error(error);
    }
  }

  Stream<List<User>> getSimilarPeopleStream() {
    return _currentUserModelController.stream.switchMap((currentUserModel) {
      if (currentUserModel == null) {
        print(
          "UserRepository (getSimilarPeopleStream): No current user, returning empty stream.",
        );
        return Stream.value(<User>[]); // No user, so no similar people
      }

      print(
        "UserRepository (getSimilarPeopleStream): Current user changed/updated (${currentUserModel.username}). Rebuilding similar people query.",
      );

      var query = collectionReference
          .where(FieldPath.documentId, isNotEqualTo: currentUserModel.id)
          .where("isDiscoverable", isEqualTo: true);

      final friendUsernames =
          currentUserModel.friends.map((friend) => friend.username).toList();

      final interestNames =
          currentUserModel.interests.map((interest) => interest.name).toList();
      final travelStyleNames =
          currentUserModel.travelStyles
              .map((travelStyle) => travelStyle.name)
              .toList();

      bool hasInterests = interestNames.isNotEmpty;
      bool hasTravelStyles = travelStyleNames.isNotEmpty;

      if (hasInterests && hasTravelStyles) {
        query = query.where(
          Filter.or(
            Filter("interests", arrayContainsAny: interestNames),
            Filter("travelStyles", arrayContainsAny: travelStyleNames),
          ),
        );
      } else if (hasInterests) {
        query = query.where("interests", arrayContainsAny: interestNames);
      } else if (hasTravelStyles) {
        query = query.where("travelStyles", arrayContainsAny: travelStyleNames);
      } else {
        print(
          "UserRepository (getSimilarPeopleStream): User has no interests or travel styles. Fetching all discoverable (non-friend) users.",
        );
      }

      return query
          .snapshots()
          .map((snapshot) {
            print(
              "UserRepository (getSimilarPeopleStream): Firestore snapshot received. Docs: ${snapshot.docs.length} for user ${currentUserModel.username}",
            );
            if (snapshot.docs.isEmpty) {
              return <User>[];
            }
            return snapshot.docs
                .map((doc) => UserFirebaseModel.fromFirestore(doc).toUser())
                // Used client-side filtering for the user's that are already the current user's friend
                .where(
                  (potentialMatch) =>
                      !friendUsernames.contains(potentialMatch.username),
                )
                .toList();
          })
          .handleError((error) {
            print(
              "UserRepository (getSimilarPeopleStream): Error in Firestore stream: $error",
            );
            return <User>[];
          });
    });
  }

  Future<Result<String>> updateAvatar(String userId, String avatar) async {
    // This method now implicitly benefits from the reactive cache.
    // If userId is the current user, updating Firestore will trigger the
    // _userDocumentSubscription, which updates _currentUserModelController.
    try {
      // Ensure we're only allowing the logged-in user to update their own avatar
      if (_currentUserModelController.value?.id != userId) {
        return Result.error(
          Exception("Cannot update avatar for another user."),
        );
      }
      await collectionReference.doc(userId).update({'avatar': avatar});
      print(
        'UserRepository: Avatar updated successfully in Firestore for user ID: $userId',
      );
      // No need to manually update _currentUserModelController, stream will handle it.
      return Result.ok(avatar);
    } on FirebaseException catch (e) {
      return Result.error(
        Exception(
          'Firebase error updating avatar: ${e.message} (Code: ${e.code})',
        ),
      );
    } on Exception catch (e) {
      return Result.error(Exception('Generic error updating avatar: $e'));
    }
  }

  Future<Result<void>> updateUserProfile(User userToUpdate) async {
    final currentModel = _currentUserModelController.value;
    if (currentModel == null ||
        currentModel.username != userToUpdate.username) {
      return Result.error(Exception('No user loaded.'));
    }

    try {
      final updatedModel = currentModel.copyWith(
        firstName: userToUpdate.firstName,
        lastName: userToUpdate.lastName,
        username: userToUpdate.username,
        phoneNumber: userToUpdate.phoneNumber,
        isDiscoverable: userToUpdate.isDiscoverable,
        interests: userToUpdate.interests,
        friends: userToUpdate.friends,
        travelStyles: userToUpdate.travelStyles,
        updatedAt: DateTime.now(),
      );

      final userDataMap = updatedModel.toJson();
      await collectionReference.doc(updatedModel.id).update(userDataMap);

      print(
        'UserRepository: User profile updated successfully in Firestore for: ${userToUpdate.username}',
      );
      return const Result.ok(null);
    } on FirebaseException catch (e) {
      return Result.error(
        Exception('Firebase error: ${e.message} (Code: ${e.code})'),
      );
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<void>> addFriend(Friend userToBefriend) async {
    final currentModel = _currentUserModelController.value;
    if (currentModel == null) {
      return Result.error(Exception('No user loaded to add a friend to.'));
    }

    print(
      "UserRepository: Attempting to add friend: ${userToBefriend.username} for user ${currentModel.username}",
    );

    try {
      await collectionReference.doc(currentModel.id).update({
        "friends": FieldValue.arrayUnion([userToBefriend.toJson()]),
      });
      print(
        "UserRepository: Added ${userToBefriend.username} to ${currentModel.username}'s friends list in Firestore.",
      );

      // Update the other user's document
      final querySnapshot =
          await collectionReference
              .where('username', isEqualTo: userToBefriend.username)
              .limit(1)
              .get();

      if (querySnapshot.docs.isEmpty) {
        // Rollback or handle: friend to add doesn't exist
        // For simplicity, we'll just error out here.
        // In a real app, you might remove `userToBefriend` from current user's list.
        print(
          "UserRepository: User to befriend (${userToBefriend.username}) not found.",
        );
        return Result.error(Exception("User to befriend not found."));
      }

      final friendDocId = querySnapshot.docs.first.id;
      final myFriendEntry = currentModel.toFriend().copyWith(
        isAccepted: false,
      ); // I sent the request, they haven't accepted

      await collectionReference.doc(friendDocId).update({
        "friends": FieldValue.arrayUnion([myFriendEntry.toJson()]),
      });
      print(
        "UserRepository: Added ${currentModel.username} to ${userToBefriend.username}'s friends list in Firestore.",
      );

      return Result.ok(
        "Friend request to ${userToBefriend.username} sent successfully.",
      );
    } on FirebaseException catch (e) {
      print("UserRepository: Firebase error adding friend: ${e.message}");
      return Result.error(Exception(e.message));
    } on Exception catch (e) {
      print("UserRepository: Generic error adding friend: $e");
      return Result.error(e);
    }
  }

  // ... (acceptFriendRequest needs similar reactive adjustment if it modifies current user)
  Future<Result<void>> acceptFriendRequest(Friend acceptedFriendRequest) async {
    final currentModel = _currentUserModelController.value;
    if (currentModel == null) {
      return Result.error(
        Exception('No user loaded to accept a friend request for.'),
      );
    }

    print(
      "UserRepository: User ${currentModel.username} attempting to accept friend request from ${acceptedFriendRequest.username}",
    );

    try {
      // 1. Update current user's friend entry to isAccepted: true
      final List<Map<String, dynamic>> updatedMyFriends =
          currentModel.friends.map((f) {
            if (f.username == acceptedFriendRequest.username) {
              return f.copyWith(isAccepted: true).toJson();
            }
            return f.toJson();
          }).toList();

      await collectionReference.doc(currentModel.id).update({
        "friends": updatedMyFriends,
      });
      print(
        "UserRepository: Updated ${acceptedFriendRequest.username} to accepted in ${currentModel.username}'s friend list.",
      );

      // 2. Update the other user's friend entry (for me) to isAccepted: true
      final friendUserDoc =
          await collectionReference
              .where("username", isEqualTo: acceptedFriendRequest.username)
              .limit(1)
              .get();

      if (friendUserDoc.docs.isEmpty) {
        print(
          "UserRepository: Error accepting friend request - friend ${acceptedFriendRequest.username} not found.",
        );
        // Potentially rollback previous update or handle error
        return Result.error(
          Exception("Friend ${acceptedFriendRequest.username} not found."),
        );
      }
      final friendUserId = friendUserDoc.docs.first.id;
      final friendUserData = UserFirebaseModel.fromFirestore(
        friendUserDoc.docs.first,
      );

      final List<Map<String, dynamic>> updatedTheirFriends =
          friendUserData.friends.map((f) {
            if (f.username == currentModel.username) {
              // I am the friend in their list
              return f.copyWith(isAccepted: true).toJson();
            }
            return f.toJson();
          }).toList();

      await collectionReference.doc(friendUserId).update({
        "friends": updatedTheirFriends,
      });
      print(
        "UserRepository: Updated ${currentModel.username} to accepted in ${acceptedFriendRequest.username}'s friend list.",
      );

      // Firestore listeners will update the respective UserFirebaseModels if they are being listened to.
      return Result.ok(
        "Friend request from ${acceptedFriendRequest.username} accepted.",
      );
    } on FirebaseException catch (e) {
      print(
        "UserRepository: Firebase error accepting friend request: ${e.message}",
      );
      return Result.error(Exception("Firebase error: ${e.message}"));
    } on Exception catch (e) {
      print("UserRepository: Generic error accepting friend request: $e");
      return Result.error(e);
    }
  }

  // --- Cache Clearing ---
  // `clearCacheForUser` and `clearAllCache` become less critical as direct methods
  // because the cache is now primarily driven by auth state.
  // Logging out will clear the cache.
  // If you need to force a refresh of the current user:
  Future<void> forceRefreshCurrentUser() async {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid != null) {
      // Re-trigger the fetch logic or simply rely on a new snapshot if data changes.
      // For an explicit refresh, you could re-fetch and push to controller,
      // but typically Firestore's own listeners are enough if data changes server-side.
      // If it's about re-evaluating _onAuthStateChanged logic:
      await _onAuthStateChanged(_firebaseAuth.currentUser);
    }
  }

  void dispose() {
    print("UserRepository: Disposing...");
    _authSubscription?.cancel();
    _userDocumentSubscription?.cancel();
    _currentUserModelController.close();
    // _similarPeopleStream is managed by switchMap, will clean up itself.
  }

  // getEmailByUsername seems independent of cached user, so it can remain as is.
  // Keep it if it's used.
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
          return Result.ok(email as String?);
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
}
