import 'package:app/data/repositories/travel_plan/travel_plan_model.dart';
import 'package:app/data/repositories/travel_plan/travel_plan_repository.dart';
import 'package:app/data/repositories/user/user_repository.dart';
import 'package:app/data/services/unsplash/unsplash_service.dart';
import 'package:app/utils/command.dart';
import 'package:app/utils/result.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

class EditTravelPlanViewmodel extends ChangeNotifier {
  EditTravelPlanViewmodel({
    required TravelPlanRepository travelPlanRepository,
    required UserRepository userRepository,
  }) : _travelPlanRepository = travelPlanRepository,
       _userRepository = userRepository {
    loadTravelPlan = Command1<void, String>(_load);
    saveChanges = Command1<void, TravelPlan>(_saveChanges);
  }

  final UnsplashService _unsplashService = UnsplashService();

  final TravelPlanRepository _travelPlanRepository;
  final UserRepository _userRepository;
  final _log = Logger('EditTravelPlanViewModel');

  TravelPlan? _initialTravelPlan;
  TravelPlan? get initialTravelPlan => _initialTravelPlan;

  List<String> get friends => _userRepository.getCurrentUserFriends();

  late Command1 saveChanges;
  late Command1 loadTravelPlan;

  Future<String> _fetchLocationImage(String location) async {
    try {
      final images = await _unsplashService.fetchImagesForLocation(
        location,
        count: 1,
      );
      _log.info("in fetch: $images");
      if (images.isNotEmpty) {
        return images.first.urls.regular;
      } else {
        return "";
      }
    } catch (e) {
      _log.warning("Error in _fetchLocationImage: $e");
      return "";
    }
  }

  Future<Result<void>> _saveChanges(TravelPlan updatedTravelPlan) async {
    notifyListeners();

    if (updatedTravelPlan.location.name != _initialTravelPlan!.location.name) {
      final imageUrl = await _fetchLocationImage(
        updatedTravelPlan.location.name,
      );
      updatedTravelPlan = updatedTravelPlan.copyWith(thumbnail: imageUrl);
    }

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
