import 'package:app/data/repositories/notification/notification_model.dart';
import 'package:app/data/services/api/api_client.dart';
import 'package:app/data/services/firebase/firestore_service.dart';
import 'package:app/utils/result.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationRepository extends FirestoreService {
  NotificationRepository({
    required super.firestoreInstance,
    required ApiClient apiClient,
  }) : _apiClient = apiClient,
       super(collectionName: "notifications");

  final ApiClient _apiClient;

  Stream<List<Notification>> getMyNotificationsStream(String userId) {
    print("REPO: $userId");
    try {
      return collectionReference
          .where("receiverId", isEqualTo: userId)
          .orderBy("createdAt", descending: false)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs
                    .map((doc) => Notification.fromFirestore(doc))
                    .toList(),
          )
          .handleError((error) {
            print("Error in notification stream: $error");
            return <Notification>[];
          });
    } catch (e) {
      print("Exception setting up user's notification stream: $e");
      return Stream.value([]);
    }
  }

  Future<Result<void>> sendNotification(String senderId, receiverId) async {
    try {
      print("Sending notification from $senderId to $receiverId.");
      return _apiClient.pushAddFriendNotification(senderId, receiverId);
    } on Exception catch (e) {
      print("Error in sending notification: $e");
      return Result.error(e);
    }
  }

  Future<Result<void>> deleteNotification(String notificationId) async {
    try {
      print("Deleting notificaiton $notificationId");
      await collectionReference.doc(notificationId).delete();

      return Result.ok({});
    } on FirebaseException catch (e) {
      print("Error in deleting notification: ${e.message}");
      return Result.error(Exception("Firebase error: ${e.message}"));
    }
  }
}
