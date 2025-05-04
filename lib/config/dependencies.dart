import 'package:app/data/repositories/auth/auth_repository.dart';
import 'package:app/data/repositories/travel_plan/travel_plan_repository.dart';
import 'package:app/data/services/firebase/auth_service.dart';
import 'package:app/data/services/firebase/travel_plan/travel_plan_service.dart';
import 'package:app/data/services/firebase/user/user_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

List<SingleChildWidget> get providers {
  final firestoreInstance = FirebaseFirestore.instance;
  final userService = UserService(firestoreInstance: firestoreInstance);
  final authService = AuthService(userService: userService);
  final travelPlanService = TravelPlanService(
    firestoreInstance: firestoreInstance,
  );

  return [
    ChangeNotifierProvider(
      create: (context) => AuthRepository(authService: authService),
    ),
    Provider(
      create:
          (context) =>
              TravelPlanRepository(travelPlanService: travelPlanService),
    ),
  ];
}
