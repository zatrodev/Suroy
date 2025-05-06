import 'package:app/data/services/firebase/travel_plan/travel_plan_model.dart';
import 'package:app/data/services/firebase/travel_plan/travel_plan_service.dart';
import 'package:app/utils/result.dart'; // Import your Result class

class TravelPlanRepository {
  final TravelPlanService _travelPlanService;

  TravelPlanRepository({required TravelPlanService travelPlanService})
      : _travelPlanService = travelPlanService;

  Stream<List<TravelPlan>> getMyTravelPlansStream(String userId) {
    return _travelPlanService.getMyTravelPlansStream(userId);
  }

  Stream<List<TravelPlan>> getSharedTravelPlansStream(String userId) {
    return _travelPlanService.getSharedTravelPlansStream(userId);
  }

  Future<Result<void>> addTravelPlan(TravelPlan plan) async {
    final result = await _travelPlanService.addTravelPlan(plan);
    return switch (result) {
      Ok() => const Result.ok(()),
      Error(error: final e) => Result.error(e),
    };
  }

  Future<Result<void>> updateTravelPlan(TravelPlan plan) async {
    final planToUpdate = plan.copyWith(updatedAt: DateTime.now());
    final result = await _travelPlanService.updateTravelPlan(planToUpdate);

    return switch (result) {
      Ok() => const Result.ok(()),
      Error(error: final e) => Result.error(e),
    };
  }

  Future<Result<void>> deleteTravelPlan(String planId) async {
    final result = await _travelPlanService.deleteTravelPlan(planId);

    return switch (result) {
      Ok() => const Result.ok(()),
      Error(error: final e) => Result.error(e),
    };
  }

  Future<Result<TravelPlan>> getTravelPlanById(String planId) async {
    final result = await _travelPlanService.getTravelPlanById(planId);
    return switch (result) {
      Ok(value: final plan) => Result.ok(plan),
      Error(error: final e) => Result.error(e),
    };
  }

  Future<Result<void>> shareTravelPlan(String planId, String userIdToShareWith) async {
    final result = await _travelPlanService.shareTravelPlan(planId, userIdToShareWith);

    return switch (result) {
      Ok() => const Result.ok(()),
      Error(error: final e) => Result.error(e),
    };
  }

  Future<Result<void>> unshareTravelPlan(String planId, String userIdToRemove) async {
    final result = await _travelPlanService.unshareTravelPlan(planId, userIdToRemove);

    return switch (result) {
      Ok() => const Result.ok(()),
      Error(error: final e) => Result.error(e),
    };
  }
}
