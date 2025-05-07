import 'package:app/data/repositories/auth/auth_repository.dart';
import 'package:app/routing/routes.dart';
import 'package:app/ui/auth/login/view_models/login_viewmodel.dart';
import 'package:app/ui/auth/login/widgets/login_screen.dart';
import 'package:app/ui/screens/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

GoRouter router(AuthRepository authRepository) => GoRouter(
  initialLocation: Routes.home,
  debugLogDiagnostics: true,
  redirect: _redirect,
  refreshListenable: authRepository,
  routes: [
    GoRoute(
      path: Routes.home,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: Routes.login,
      builder: (context, state) {
        return LoginScreen(
          viewModel: LoginViewModel(authRepository: context.read()),
        );
      },
    ),
    GoRoute(
      path: Routes.travelPlanDetails,
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        // TODO: Implement travel plan details screen
        return Scaffold(
          appBar: AppBar(title: Text('Travel Plan $id')),
          body: const Center(child: Text('Travel Plan Details')),
        );
      },
    ),
  ],
);

Future<String?> _redirect(BuildContext context, GoRouterState state) async {
  final loggedIn = context.read<AuthRepository>().isAuthenticated;
  final loggingIn = state.matchedLocation == Routes.login;

  if (!loggedIn) {
    return Routes.login;
  }

  if (loggingIn) {
    return Routes.home;
  }

  return null;
}
