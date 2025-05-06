import 'package:app/data/services/firebase/firestore_service.dart';
import 'package:app/data/services/firebase/travel_plan/travel_plan_model.dart'; // Assuming model is here
import 'package:app/utils/result.dart'; // Import your Result class
import 'package:cloud_firestore/cloud_firestore.dart';

class TravelPlanService extends FirestoreService {
  TravelPlanService({required super.firestoreInstance})
    : super(collectionName: "travel_plans");

  Stream<List<TravelPlan>> getMyTravelPlansStream(String userId) {
    try {
      return collectionReference
          .where('ownerId', isEqualTo: userId)
          .orderBy('startDate', descending: false)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs
                    .map((doc) => TravelPlan.fromFirestore(doc))
                    .toList(),
          )
          .handleError((error) {
            print("Error in user's travel plans stream: $error");
            return <TravelPlan>[];
          });
    } catch (e) {
      print("Exception setting up user's travel plans stream: $e");
      return Stream.value([]);
    }
  }

  Stream<List<TravelPlan>> getSharedTravelPlansStream(String userId) {
    try {
      return collectionReference
          .where('sharedWith', arrayContains: userId)
          .orderBy('startDate', descending: false)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs
                    .map((doc) => TravelPlan.fromFirestore(doc))
                    .toList(),
          )
          .handleError((error) {
            print("Error in shared travel plans stream: $error");
            return <TravelPlan>[];
          });
    } catch (e) {
      print("Exception setting up shared travel plans stream: $e");
      return Stream.value([]);
    }
  }

  Future<Result<void>> addTravelPlan(TravelPlan plan) async {
    try {
      return Result.ok(
        await collectionReference.doc(plan.id).set(plan.toJson()),
      );
    } on FirebaseException catch (e) {
      print(
        'Error adding travel plan (FirebaseException): ${e.code} - ${e.message}',
      );
      return Result.error(e);
    } on Exception catch (e) {
      print('Error adding travel plan (General Exception): $e');
      return Result.error(e);
    }
  }

  Future<Result<void>> updateTravelPlan(TravelPlan plan) async {
    try {
      return Result.ok(
        await collectionReference.doc(plan.id).update(plan.toJson()),
      );
    } on FirebaseException catch (e) {
      print(
        'Error updating travel plan (FirebaseException): ${e.code} - ${e.message}',
      );
      return Result.error(e);
    } on Exception catch (e) {
      print('Error updating travel plan (General Exception): $e');
      return Result.error(e);
    }
  }

  Future<Result<void>> deleteTravelPlan(String planId) async {
    try {
      return Result.ok(await collectionReference.doc(planId).delete());
    } on FirebaseException catch (e) {
      print(
        'Error deleting travel plan (FirebaseException): ${e.code} - ${e.message}',
      );
      return Result.error(e);
    } on Exception catch (e) {
      print('Error deleting travel plan (General Exception): $e');
      return Result.error(e);
    }
  }

  Future<Result<TravelPlan>> getTravelPlanById(String planId) async {
    try {
      final docSnapshot = await collectionReference.doc(planId).get();
      if (docSnapshot.exists) {
        final plan = TravelPlan.fromFirestore(docSnapshot);
        print('TravelPlan fetched successfully for ID: $planId');
        return Result.ok(plan);
      } else {
        print('TravelPlan not found for ID: $planId');
        return Result.error(
          Exception("Travel plan with ID $planId not found."),
        );
      }
    } on FirebaseException catch (e) {
      print(
        'Error fetching travel plan by ID (FirebaseException): ${e.code} - ${e.message}',
      );
      return Result.error(e);
    } on Exception catch (e) {
      print('Error fetching travel plan by ID (General Exception): $e');
      return Result.error(e);
    }
  }

  Future<Result<void>> shareTravelPlan(
    String planId,
    String userIdToShareWith,
  ) async {
    try {
      print('TravelPlan $planId shared successfully with $userIdToShareWith');
      return Result.ok(
        await collectionReference.doc(planId).update({
          'sharedWith': FieldValue.arrayUnion([userIdToShareWith]),
        }),
      );
    } on FirebaseException catch (e) {
      print(
        'Error sharing travel plan (FirebaseException): ${e.code} - ${e.message}',
      );
      return Result.error(e);
    } on Exception catch (e) {
      print('Error sharing travel plan (General Exception): $e');
      return Result.error(e);
    }
  }

  Future<Result<void>> unshareTravelPlan(
    String planId,
    String userIdToRemove,
  ) async {
    try {
      print('TravelPlan $planId unshared successfully from $userIdToRemove');
      return Result.ok(
        await collectionReference.doc(planId).update({
          'sharedWith': FieldValue.arrayRemove([userIdToRemove]),
        }),
      ); // Return Ok on success
    } on FirebaseException catch (e) {
      print(
        'Error un-sharing travel plan (FirebaseException): ${e.code} - ${e.message}',
      );
      return Result.error(e);
    } on Exception catch (e) {
      print('Error un-sharing travel plan (General Exception): $e');
      return Result.error(e);
    }
  }
}
