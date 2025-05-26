import 'package:app/data/repositories/travel_plan/travel_plan_model.dart';
import 'package:app/data/repositories/travel_plan/travel_plan_repository.dart';
import 'package:app/data/repositories/user/user_repository.dart';
import 'package:app/data/services/unsplash/unsplash_service.dart';
import 'package:app/utils/command.dart';
import 'package:app/utils/result.dart';
import 'package:logging/logging.dart';

class AddTravelPlanViewmodel {
  AddTravelPlanViewmodel({
    required TravelPlanRepository travelPlanRepository,
    required UserRepository userRepository,
  }) : _travelPlanRepository = travelPlanRepository,
       _userRepository = userRepository {
    addTravelPlan = Command1<void, TravelPlan>(_addTravelPlan);
  }

  final UnsplashService _unsplashService = UnsplashService();

  final TravelPlanRepository _travelPlanRepository;
  final UserRepository _userRepository;
  final _log = Logger("AddTravelPlanViewModel");

  late Command1 addTravelPlan;

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
      print("Error in _fetchLocationImage: $e");
      return "";
    }
  }

  Future<Result<void>> _addTravelPlan(TravelPlan plan) async {
    if (_userRepository.userFirebase == null) {
      _log.warning("userFirebase is null");
      return Result.error(
        Exception("User not found. Maybe you are not logged in?"),
      );
    }

    final imageUrl = await _fetchLocationImage(plan.location.name);
    _log.info("IMAGE: $imageUrl");

    final result = await _travelPlanRepository.addTravelPlan(
      plan.copyWith(
        ownerId: _userRepository.user!.username,
        thumbnail: imageUrl,
      ),
    );

    switch (result) {
      case Ok<void>():
        _log.info("Successfully created travel plan: $plan");
        return Result.ok({});
      case Error<void>():
        _log.warning("Error: ${result.error}");
        return Result.error(
          Exception("Failed to create travel plan: ${result.error}"),
        );
    }
  }
}
