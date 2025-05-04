import 'package:app/data/services/firebase/firestore_service.dart';
import 'package:app/data/services/firebase/travel_plan/travel_plan_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TravelPlanService extends FirestoreService {
  TravelPlanService({required super.firestoreInstance})
    : super(collectionName: "travel_plans");

  Stream<List<TravelPlan>> getMyTravelPlansStream(String userId) {
    try {
      return collectionReference
          .where('ownerId', isEqualTo: userId)
          .orderBy('startDate', descending: false) // Example sorting
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs
                    .map((doc) => TravelPlan.fromFirestore(doc))
                    .toList(),
          )
          .handleError((error) {
            print("Error fetching user's travel plans: $error");
            // Depending on stream error handling strategy, might return empty list or let error propagate
            return <TravelPlan>[];
          });
    } catch (e) {
      print("Exception setting up user's travel plans stream: $e");
      return Stream.value([]); // Return empty stream on initial setup error
    }
  }

  /// Gets a stream of travel plans shared with the user.
  Stream<List<TravelPlan>> getSharedTravelPlansStream(String userId) {
    try {
      return collectionReference
          .where(
            'sharedWith',
            arrayContains: userId,
          ) // Query based on the array field
          .orderBy('startDate', descending: false) // Example sorting
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs
                    .map((doc) => TravelPlan.fromFirestore(doc))
                    .toList(),
          )
          .handleError((error) {
            print("Error fetching shared travel plans: $error");
            return <TravelPlan>[];
          });
    } catch (e) {
      print("Exception setting up shared travel plans stream: $e");
      return Stream.value([]);
    }
  }

  // --- CRUD Methods ---

  Future<void> addTravelPlan(TravelPlan plan) async {
    try {
      // The plan.id should be pre-generated (e.g., using Uuid) before calling this
      await collectionReference.doc(plan.id).set(plan.toJson());
      print('TravelPlan added with ID: ${plan.id}');
    } catch (e) {
      print('Error adding travel plan: $e');
      // Re-throw a more specific exception or handle as needed
      throw Exception('Failed to add travel plan.');
    }
  }

  Future<void> updateTravelPlan(TravelPlan plan) async {
    try {
      // Ensure the 'updatedAt' field is current (optional, could be handled in model/repo)
      // final dataToUpdate = plan.copyWith(updatedAt: DateTime.now()).toJson();
      await collectionReference.doc(plan.id).update(plan.toJson());
      print('TravelPlan updated with ID: ${plan.id}');
    } catch (e) {
      print('Error updating travel plan: $e');
      throw Exception('Failed to update travel plan.');
    }
  }

  Future<void> deleteTravelPlan(String planId) async {
    try {
      await collectionReference.doc(planId).delete();
      print('TravelPlan deleted with ID: $planId');
    } catch (e) {
      print('Error deleting travel plan: $e');
      throw Exception('Failed to delete travel plan.');
    }
  }

  Future<TravelPlan?> getTravelPlanById(String planId) async {
    try {
      final docSnapshot = await collectionReference.doc(planId).get();
      if (docSnapshot.exists) {
        return TravelPlan.fromFirestore(docSnapshot);
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching travel plan by ID: $e');
      // Depending on requirements, return null or throw
      return null;
    }
  }

  // --- Sharing Methods ---

  Future<void> shareTravelPlan(String planId, String userIdToShareWith) async {
    try {
      await collectionReference.doc(planId).update({
        'sharedWith': FieldValue.arrayUnion([userIdToShareWith]),
      });
      print('TravelPlan $planId shared with $userIdToShareWith');
    } catch (e) {
      print('Error sharing travel plan: $e');
      throw Exception('Failed to share travel plan.');
    }
  }

  Future<void> unshareTravelPlan(String planId, String userIdToRemove) async {
    try {
      await collectionReference.doc(planId).update({
        'sharedWith': FieldValue.arrayRemove([userIdToRemove]),
      });
      print('TravelPlan $planId unshared from $userIdToRemove');
    } catch (e) {
      print('Error un-sharing travel plan: $e');
      throw Exception('Failed to unshare travel plan.');
    }
  }
}
