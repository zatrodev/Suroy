import 'dart:async';

import 'package:app/data/repositories/auth/auth_repository.dart';
import 'package:app/routing/routes.dart';
import 'package:app/ui/auth/login/view_models/sign_in_viewmodel.dart';
import 'package:app/routing/transitions/slide_transition_page.dart';
import 'package:app/ui/auth/login/widgets/sign_in_screen.dart';
import 'package:app/ui/home/home.dart';
import 'package:app/ui/home/plans/add/view_models/add_travel_plan_viewmodel.dart';
import 'package:app/ui/home/plans/add/widgets/add_travel_plan_screen.dart';
import 'package:app/ui/home/plans/details/view_models/travel_plan_details_viewmodel.dart';
import 'package:app/ui/home/plans/details/widgets/travel_plan_details_screen.dart';
import 'package:app/ui/home/plans/edit/view_models/edit_travel_plan_viewmodel.dart';
import 'package:app/ui/home/plans/edit/widgets/edit_travel_plan_screen.dart';
import 'package:app/ui/home/plans/view_models/plans_viewmodel.dart';
import 'package:app/ui/home/plans/widgets/plans_screen.dart';
import 'package:app/ui/home/profile/edit/view_models/edit_profile_viewmodel.dart';
import 'package:app/ui/home/profile/edit/widgets/edit_profile_screen.dart';
import 'package:app/ui/home/profile/view_models/profile_viewmodel.dart';
import 'package:app/ui/home/profile/widgets/profile_screen.dart';
import 'package:app/ui/home/social/view_models/social_viewmodel.dart';
import 'package:app/ui/home/social/widgets/social_screen.dart';
import 'package:app/ui/notifications/view_models/notification_viewmodel.dart';
import 'package:app/ui/notifications/widgets/notification_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

GoRouter router(AuthRepository authRepository) {
  final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>();

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: Routes.home,
    debugLogDiagnostics: true,
    redirect: _redirect,
    refreshListenable: authRepository,
    routes: [
      GoRoute(
        path: Routes.signIn,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          return MaterialPage(
            key: state.pageKey,
            child: SignInScreen(
              viewModel: SignInViewModel(
                userRepository: context.read(),
                signInUseCase: context.read(),
                signUpUseCase: context.read(),
              ),
            ),
          );
        },
      ),
      StatefulShellRoute.indexedStack(
        builder:
            (
              BuildContext context,
              GoRouterState state,
              StatefulNavigationShell navigationShell,
            ) => Home(navigationShell: navigationShell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.plans,
                pageBuilder:
                    (context, state) => NoTransitionPage(
                      key: state.pageKey,
                      child: PlansScreen(
                        viewModel: TravelPlanViewmodel(
                          travelPlanRepository: context.read(),
                          userRepository: context.read(),
                        ),
                      ),
                    ),
                // ],
                routes: <RouteBase>[
                  GoRoute(
                    path: Routes.notificationsRelative,
                    pageBuilder:
                        (context, state) => SlideTransitionPage(
                          key: state.pageKey,
                          slideDirection: SlideDirection.rightToLeft,
                          child: NotificationScreen(
                            viewModel: NotificationViewModel(
                              userRepository: context.read(),
                              notificationRepository: context.read(),
                            ),
                          ),
                        ),
                  ),
                  GoRoute(
                    path: Routes.addPlanRelative,
                    pageBuilder: (context, state) {
                      return SlideTransitionPage(
                        key: state.pageKey,
                        slideDirection: SlideDirection.bottomToTop,
                        child: AddTravelPlanScreen(
                          viewModel: AddTravelPlanViewmodel(
                            travelPlanRepository: context.read(),
                            userRepository: context.read(),
                          ),
                        ),
                      );
                    },
                  ),
                  GoRoute(
                    path: ":id",
                    builder: (context, state) {
                      final id = state.pathParameters["id"]!;
                      final viewModel = TravelPlanDetailsViewmodel(
                        travelPlanRepository: context.read(),
                      );

                      viewModel.loadTravelPlan.execute(id);

                      return TravelPlanDetailsScreen(viewModel: viewModel);
                    },
                    routes: <RouteBase>[
                      GoRoute(
                        path: Routes.editProfileRelative,
                        pageBuilder: (context, state) {
                          final id = state.pathParameters["id"]!;
                          final viewModel = EditTravelPlanViewmodel(
                            travelPlanRepository: context.read(),
                            userRepository: context.read(),
                          );

                          viewModel.loadTravelPlan.execute(id);

                          return SlideTransitionPage(
                            key: state.pageKey,
                            duration: Duration(milliseconds: 500),
                            child: EditTravelPlanScreen(viewModel: viewModel),
                            slideDirection: SlideDirection.bottomToTop,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          // Branch 2: Social Tab
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.social,
                pageBuilder:
                    (context, state) => NoTransitionPage(
                      key: state.pageKey,
                      child: SocialScreen(
                        viewModel: SocialViewModel(
                          userRepository: context.read(),
                          notificationRepository: context.read(),
                        ),
                      ),
                    ),
              ),
            ],
          ),

          // Branch 3: Profile Tab
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.profile,
                pageBuilder:
                    (context, state) => NoTransitionPage(
                      key: state.pageKey,
                      child: ProfileScreen(
                        viewModel: ProfileViewModel(
                          updateAvatarUseCase: context.read(),
                          authRepository: context.read(),
                          userRepository: context.read(),
                        ),
                      ),
                    ),
                routes: <RouteBase>[
                  GoRoute(
                    path: Routes.editProfileRelative,
                    pageBuilder: (context, state) {
                      return SlideTransitionPage(
                        key: state.pageKey,
                        duration: Duration(milliseconds: 500),
                        child: EditProfileScreen(
                          viewModel: EditProfileViewModel(
                            userRepository: context.read(),
                          ),
                        ),
                        slideDirection: SlideDirection.bottomToTop,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

Future<String?> _redirect(BuildContext context, GoRouterState state) async {
  final loggedIn = context.read<AuthRepository>().isAuthenticated;
  final loggingIn = state.matchedLocation == Routes.signIn;

  if (!loggedIn) {
    return Routes.signIn;
  }

  if (loggingIn) {
    return Routes.plans;
  }

  if (state.matchedLocation == Routes.home) {
    return Routes.plans;
  }

  return null;
}
