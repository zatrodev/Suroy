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
    try {
      return _travelPlanService.addTravelPlan(plan);
    } on Exception catch (error) {
      return Result.error(error);
    }
  }

  Future<Result<void>> updateTravelPlan(TravelPlan plan) async {
    try {
      final planToUpdate = plan.copyWith(updatedAt: DateTime.now());
      return _travelPlanService.updateTravelPlan(planToUpdate);
    } on Exception catch (error) {
      return Result.error(error);
    }
  }

  Future<Result<void>> deleteTravelPlan(String planId) async {
    try {
      return _travelPlanService.deleteTravelPlan(planId);
    } on Exception catch (error) {
      return Result.error(error);
    }
  }

  Future<Result<TravelPlan>> getTravelPlanById(String planId) async {
    final result = await _travelPlanService.getTravelPlanById(planId);
    return switch (result) {
      Ok(value: final plan) => Result.ok(plan),
      Error(error: final e) => Result.error(e),
    };
  }

  Future<Result<void>> shareTravelPlan(
    String planId,
    String userIdToShareWith,
  ) async {
    try {
      return _travelPlanService.shareTravelPlan(planId, userIdToShareWith);
    } on Exception catch (error) {
      return Result.error(error);
    }
  }

  Future<Result<void>> unshareTravelPlan(
    String planId,
    String userIdToRemove,
  ) async {
    try {
      return _travelPlanService.unshareTravelPlan(planId, userIdToRemove);
    } on Exception catch (error) {
      return Result.error(error);
    }
  }
}
