import 'package:app/data/repositories/auth/auth_repository.dart';
import 'package:app/domain/models/user.dart';
import 'package:app/routing/routes.dart';
import 'package:app/ui/auth/login/view_models/sign_in_viewmodel.dart';
import 'package:app/routing/transitions/slide_transition_page.dart';
import 'package:app/ui/auth/login/widgets/sign_in_screen.dart';
import 'package:app/ui/home/home.dart';
import 'package:app/ui/home/home_viewmodel.dart';
import 'package:app/ui/home/plans/widgets/plans_screen.dart';
import 'package:app/ui/home/profile/edit/view_models/edit_profile_viewmodel.dart';
import 'package:app/ui/home/profile/edit/widgets/edit_profile_screen.dart';
import 'package:app/ui/home/profile/view_models/profile_viewmodel.dart';
import 'package:app/ui/home/profile/widgets/profile_screen.dart';
import 'package:app/ui/home/social/widgets/social_screen.dart';
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
        builder: (
          BuildContext context,
          GoRouterState state,
          StatefulNavigationShell navigationShell,
        ) {
          return Home(
            navigationShell: navigationShell,
            viewModel: HomeViewModel(
              authRepository: context.read(),
              userRepository: context.read(),
            ),
          );
        },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.plans,
                pageBuilder:
                    (context, state) => NoTransitionPage(
                      key: state.pageKey,
                      // For MVVM, you'd instantiate/provide PlansViewModel here
                      child: const PlansScreen(
                        /* viewModel: context.read<PlansViewModel>() */
                      ),
                    ),
                // Example of nested routes within the Plans tab:
                // routes: [
                //   GoRoute(path: 'details/:id', builder: (c,s) => PlanDetailsScreen(id: s.pathParameters['id']!)),
                // ],
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
                      child: const SocialScreen(
                        /* viewModel: context.read<SocialViewModel>() */
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
                      final userToEdit = state.extra as User?;

                      if (userToEdit == null) {
                        return MaterialPage(
                          child: Center(
                            child: Text("Error: User data missing."),
                          ),
                        );
                      }

                      return SlideTransitionPage(
                        key: state.pageKey,
                        duration: Duration(milliseconds: 500),
                        child: EditProfileScreen(
                          viewModel: EditProfileViewModel(
                            userRepository: context.read(),
                            userToEdit: userToEdit,
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
