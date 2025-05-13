import 'package:app/data/repositories/user/user_model.dart';

class User {
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String password;
  final List<Interest> interests;
  final List<TravelStyle> travelStyles;

  User({
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    required this.password,
    required this.interests,
    required this.travelStyles,
  });

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'username': username,
      'email': email,
      'password': password,
      'interests': interests.map((interest) => interest.name).toList(),
      'travelStyles': travelStyles.map((style) => style.name).toList(),
    };
  }

  User copyWith({
    String? firstName,
    String? lastName,
    String? username,
    String? email,
    String? password,
    List<Interest>? interests,
    List<TravelStyle>? travelStyles,
  }) {
    return User(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      interests: interests ?? this.interests,
      travelStyles: travelStyles ?? this.travelStyles,
    );
  }

  @override
  String toString() {
    return 'UserSignUpRequest(firstName: $firstName, lastName: $lastName, username: $username, email: $email, interests: $interests, travelStyles: $travelStyles)';
  }
}
