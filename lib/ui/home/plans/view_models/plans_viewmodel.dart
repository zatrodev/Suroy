import 'dart:async';
import 'dart:typed_data';

import 'package:app/data/repositories/travel_plan/travel_plan_model.dart';
import 'package:app/data/repositories/travel_plan/travel_plan_repository.dart';
import 'package:app/data/repositories/user/user_repository.dart';
import 'package:app/utils/result.dart';
import 'package:logging/logging.dart';

class TravelPlanViewmodel {
  TravelPlanViewmodel({
    required TravelPlanRepository travelPlanRepository,
    required UserRepository userRepository,
  }) : _travelPlanRepository = travelPlanRepository,
       _userRepository = userRepository;

  final TravelPlanRepository _travelPlanRepository;
  final UserRepository _userRepository;
  final _log = Logger("PlansViewModel");

  String searchText = "";
  Stream<List<TravelPlan>>? _myTravelPlansStreamCache;
  Stream<List<TravelPlan>>? _sharedTravelPlansStreamCache;

  void updateSearchText(String searchText) {
    this.searchText = searchText;
  }

  void handleFilterTravelPlan(
    List<TravelPlan> incomingTravelPlans,
    EventSink<List<TravelPlan>> sink,
  ) async {
    if (searchText.isEmpty) {
      sink.add(incomingTravelPlans);
      return;
    }

    final filteredTravelPlans = <TravelPlan>[];

    for (final travelPlan in incomingTravelPlans) {
      if (travelPlan.name.toLowerCase().contains(searchText) ||
          (travelPlan.name.toLowerCase().contains(searchText))) {
        filteredTravelPlans.add(travelPlan);
      }
    }

    sink.add(filteredTravelPlans);
  }

  void handleSharedTravelPlanAvatar(
    List<TravelPlan> incomingTravelPlans,
    EventSink<List<TravelPlan>> sink,
  ) async {
    final List<Future<TravelPlan>> processedTravelPlanFutures = [];

    for (final travelPlan in incomingTravelPlans) {
      final futureTravelPlan = Future(() async {
        final result = await _userRepository.getAvatarBytesOByUsername(
          travelPlan.ownerId,
        );

        switch (result) {
          case Ok<Uint8List?>():
            return travelPlan.copyWith(ownerAvatar: result.value);
          case Error<Uint8List?>():
            return travelPlan;
        }
      });
      processedTravelPlanFutures.add(futureTravelPlan);
    }

    try {
      final List<TravelPlan> processedTravelPlans = await Future.wait(
        processedTravelPlanFutures,
      );
      sink.add(processedTravelPlans);
    } catch (e) {
      sink.add(incomingTravelPlans);
    }
  }

  Stream<List<TravelPlan>> watchMyTravelPlans() {
    final username = _userRepository.user?.username;
    if (username == null) return Stream.empty();

    _myTravelPlansStreamCache ??= _travelPlanRepository
        .getMyTravelPlansStream(_userRepository.user!.username)
        .transform(
          StreamTransformer.fromHandlers(handleData: handleFilterTravelPlan),
        )
        .handleError((error, stackTrace) {
          _log.severe(
            "Failed to listen to notification stream (or error in transform). Error: $error",
            error,
            stackTrace,
          );
          return <TravelPlan>[];
        });

    return _myTravelPlansStreamCache!;
  }

  Stream<List<TravelPlan>> watchSharedTravelPlans() {
    final username = _userRepository.user?.username;
    if (username == null) return Stream.empty();

    _sharedTravelPlansStreamCache ??= _travelPlanRepository
        .getSharedTravelPlansStream(
          _userRepository.user!.friends
              .map((friend) => friend.username)
              .toList(),
        )
        .transform(
          StreamTransformer.fromHandlers(
            handleData: handleSharedTravelPlanAvatar,
          ),
        )
        .handleError((error, stackTrace) {
          _log.severe(
            "Failed to listen to notification stream (or error in transform). Error: $error",
            error,
            stackTrace,
          );
          return <TravelPlan>[];
        });

    return _sharedTravelPlansStreamCache!;
  }
}
