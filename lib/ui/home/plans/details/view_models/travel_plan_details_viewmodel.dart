import 'package:app/data/repositories/travel_plan/travel_plan_model.dart';
import 'package:app/data/repositories/travel_plan/travel_plan_repository.dart';
import 'package:app/utils/command.dart';
import 'package:app/utils/result.dart';
import 'package:logging/logging.dart';

class TravelPlanDetailsViewmodel {
  TravelPlanDetailsViewmodel({
    required TravelPlanRepository travelPlanRepository,
  }) : _travelPlanRepository = travelPlanRepository {
    loadTravelPlan = Command1<void, String>(_load);
    deleteTravelPlan = Command0(_deleteTravelPlan);
  }

  final TravelPlanRepository _travelPlanRepository;
  final _log = Logger('TravelPlanDetailsViewmodel');

  TravelPlan? _travelPlan;
  TravelPlan? get travelPlan => _travelPlan;

  late Command1 loadTravelPlan;
  late Command0 deleteTravelPlan;

  Future<Result<void>> _load(String id) async {
    final result = await _travelPlanRepository.getTravelPlanById(id);
    switch (result) {
      case Ok<TravelPlan>():
        _log.fine("Loaded travel plan $id");
        _travelPlan = result.value;
      case Error<TravelPlan>():
        _log.warning("Failed to load travel plan $id");
        throw UnimplementedError();
    }

    return result;
  }

  Future<Result<void>> _deleteTravelPlan() async {
    final result = await _travelPlanRepository.deleteTravelPlan(
      _travelPlan!.id!,
    );

    switch (result) {
      case Ok<void>():
        return Result.ok({});
      case Error<void>():
        return Result.error(result.error);
    }
  }
}
