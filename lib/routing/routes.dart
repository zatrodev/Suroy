abstract final class Routes {
  static const home = "/";
  static const signIn = "/sign-in";
  static const plans = "/plans";
  static const social = "/social";
  static const profile = "/profile";
  static const editProfileRelative = "edit";
  static const editProfile = "$profile/$editProfileRelative";
  static const travelPlanDetails = "/travel-plan/:id";
  static const notificationsRelative = "notifications";
  static const notifications = "$plans/$notificationsRelative";
  static const addPlanRelative = 'add';
  static const addPlan = '$plans/$addPlanRelative';
}
