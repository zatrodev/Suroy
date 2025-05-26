import 'package:app/data/repositories/travel_plan/travel_plan_model.dart';
import 'package:app/data/repositories/travel_plan/travel_plan_repository.dart';
import 'package:app/utils/command.dart';
import 'package:app/utils/result.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

class EditTravelPlanViewmodel extends ChangeNotifier {
  EditTravelPlanViewmodel({required TravelPlanRepository travelPlanRepository})
    : _travelPlanRepository = travelPlanRepository {
    loadTravelPlan = Command1<void, String>(_load);
    saveChanges = Command1<void, TravelPlan>(_saveChanges);
  }

  final TravelPlanRepository _travelPlanRepository;
  final _log = Logger('EditTravelPlanViewModel');

  TravelPlan? _initialTravelPlan;
  TravelPlan? get initialTravelPlan => _initialTravelPlan;

  late Command1 saveChanges;
  late Command1 loadTravelPlan;

  Future<Result<void>> _saveChanges(TravelPlan updatedTravelPlan) async {
    notifyListeners();

    final result = await _travelPlanRepository.updateTravelPlan(
      updatedTravelPlan,
    );
    switch (result) {
      case Ok<void>():
        return Result.ok({});
      case Error<void>():
        return Result.error(
          Exception("Failed to save changes: ${result.error}"),
        );
    }
  }

  Future<Result<void>> _load(String id) async {
    final result = await _travelPlanRepository.getTravelPlanById(id);
    switch (result) {
      case Ok<TravelPlan>():
        _log.fine("Loaded travel plan $id");
        _initialTravelPlan = result.value;
      case Error<TravelPlan>():
        _log.warning("Failed to load travel plan $id");
        throw UnimplementedError();
    }

    return result;
  }
}
