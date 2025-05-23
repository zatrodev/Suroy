import 'package:app/data/repositories/auth/auth_repository.dart';
import 'package:app/data/repositories/notification/notification_model.dart';
import 'package:app/data/repositories/notification/notification_repostiory.dart';
import 'package:app/data/repositories/travel_plan/travel_plan_repository.dart';
import 'package:app/data/repositories/user/user_repository.dart';
import 'package:app/data/services/api/api_client.dart';
import 'package:app/data/services/internal/image/image_picker_service.dart';
import 'package:app/domain/use-cases/auth/auth_sign_in_use_case.dart';
import 'package:app/domain/use-cases/auth/auth_sign_up_use_case.dart';
import 'package:app/domain/use-cases/user/update_avatar_use_case.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

List<SingleChildWidget> get providers {
  final firestoreInstance = FirebaseFirestore.instance;
  final imagePickerInstance = ImagePickerService.instance;

  return [
    Provider(create: (context) => ApiClient()),
    ChangeNotifierProvider(create: (context) => AuthRepository()),
    Provider(
      create:
          (context) =>
              TravelPlanRepository(firestoreInstance: firestoreInstance),
    ),
    Provider(
      create: (context) => UserRepository(firestoreInstance: firestoreInstance),
    ),
    Provider(
      create:
          (context) => NotificationRepository(
            apiClient: context.read(),
            firestoreInstance: firestoreInstance,
          ),
    ),
    Provider(
      create:
          (context) => AuthSignInUseCase(
            userRepository: context.read(),
            authRepository: context.read(),
          ),
    ),
    Provider(
      create:
          (context) => AuthSignInUseCase(
            userRepository: context.read(),
            authRepository: context.read(),
          ),
    ),
    Provider(
      create:
          (context) => AuthSignUpUseCase(
            userRepository: context.read(),
            authRepository: context.read(),
          ),
    ),
    Provider(
      create:
          (context) => UpdateAvatarUseCase(
            imagePickerService: imagePickerInstance,
            userRepository: context.read(),
          ),
    ),
  ];
}
