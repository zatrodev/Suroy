import 'package:app/data/repositories/notification/notification_model.dart';
import 'package:app/data/services/api/api_client.dart';
import 'package:app/data/services/firebase/firestore_service.dart';
import 'package:app/utils/result.dart';

class NotificationRepository extends FirestoreService {
  NotificationRepository({
    required super.firestoreInstance,
    required ApiClient apiClient,
  }) : _apiClient = apiClient,
       super(collectionName: "travel_plans");

  final ApiClient _apiClient;

  Stream<List<Notification>> getMyNotificationsStream(String userId) {
    try {
      return collectionReference
          .where("receiver", isEqualTo: userId)
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
}
