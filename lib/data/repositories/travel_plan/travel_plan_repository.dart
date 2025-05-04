import 'package:app/data/services/firebase/travel_plan/travel_plan_model.dart';
import 'package:app/data/services/firebase/travel_plan/travel_plan_service.dart';

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

  Future<void> addTravelPlan(TravelPlan plan) {
    // Add any repository-level logic here if needed (e.g., validation, adding timestamps)

    //final planWithTimestamps = plan.copyWith(
    //  createdAt: plan.createdAt,
    //  updatedAt: plan.updatedAt,
    //);
    return _travelPlanService.addTravelPlan(plan);
  }

  Future<void> updateTravelPlan(TravelPlan plan) {
    final planToUpdate = plan.copyWith(updatedAt: DateTime.now());
    return _travelPlanService.updateTravelPlan(planToUpdate);
  }

  Future<void> deleteTravelPlan(String planId) {
    return _travelPlanService.deleteTravelPlan(planId);
  }

  Future<TravelPlan?> getTravelPlanById(String planId) {
    return _travelPlanService.getTravelPlanById(planId);
  }

  Future<void> shareTravelPlan(String planId, String userIdToShareWith) {
    return _travelPlanService.shareTravelPlan(planId, userIdToShareWith);
  }

  Future<void> unshareTravelPlan(String planId, String userIdToRemove) {
    return _travelPlanService.unshareTravelPlan(planId, userIdToRemove);
  }
}
