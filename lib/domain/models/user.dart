import 'package:app/data/repositories/user/user_model.dart';
import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String? password;
  final String? phoneNumber;
  final String? avatar;
  final List<Interest> interests;
  final List<TravelStyle> travelStyles;

  const User({
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    this.password,
    this.phoneNumber,
    this.avatar,
    this.interests = const [],
    this.travelStyles = const [],
  });

  String get initials {
    String result = "";
    if (firstName.isNotEmpty) result += firstName[0];
    if (lastName.isNotEmpty) {
      if (result.isNotEmpty && lastName[0].isNotEmpty) result += "";
      result += lastName[0];
    }
    return result.toUpperCase();
  }

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
    String? phoneNumber,
    String? avatar,
    List<Interest>? interests,
    List<TravelStyle>? travelStyles,
  }) {
    return User(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatar: avatar ?? this.avatar,
      interests: interests ?? List<Interest>.from(this.interests),
      travelStyles: travelStyles ?? List<TravelStyle>.from(this.travelStyles),
    );
  }

  @override
  String toString() {
    return 'User(firstName: $firstName, lastName: $lastName, username: $username, email: $email, phoneNumber: $phoneNumber, interests: $interests, travelStyles: $travelStyles)';
  }

  @override
  List<Object?> get props => [
    firstName,
    lastName,
    username,
    email,
    phoneNumber,
    avatar,
    interests,
    travelStyles,
  ];
}
