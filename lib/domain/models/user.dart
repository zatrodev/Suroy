import 'dart:typed_data';

import 'package:app/data/repositories/user/user_model.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class User extends Equatable {
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String? password;
  final bool isDiscoverable;
  final String? phoneNumber;
  final String? avatar;
  final Uint8List? avatarBytes;
  final List<Interest> interests;
  final List<TravelStyle> travelStyles;
  final List<Friend> friends;
  final ColorScheme? colorScheme;

  const User({
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    this.password,
    this.isDiscoverable = false,
    this.phoneNumber,
    this.avatar,
    this.avatarBytes,
    this.interests = const [],
    this.travelStyles = const [],
    this.friends = const [],
    this.colorScheme,
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
      'isDiscoverable': isDiscoverable,
      'friends': friends,
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
    String? phoneNumber,
    String? avatar,
    Uint8List? avatarBytes,
    bool? isDiscoverable,
    List<Interest>? interests,
    List<TravelStyle>? travelStyles,
    List<Friend>? friends,
    ColorScheme? colorScheme,
  }) {
    return User(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatar: avatar ?? this.avatar,
      avatarBytes: avatarBytes ?? this.avatarBytes,
      isDiscoverable: isDiscoverable ?? this.isDiscoverable,
      interests: interests ?? List<Interest>.from(this.interests),
      travelStyles: travelStyles ?? List<TravelStyle>.from(this.travelStyles),
      friends: friends ?? List<Friend>.from(this.friends),
      colorScheme: colorScheme ?? this.colorScheme,
    );
  }

  @override
  String toString() {
    return 'User(firstName: $firstName, lastName: $lastName, username: $username, email: $email, phoneNumber: $phoneNumber, interests: $interests, travelStyles: $travelStyles, friends: $friends, isDiscoverable: $isDiscoverable)';
  }

  @override
  List<Object?> get props => [
    firstName,
    lastName,
    username,
    email,
    phoneNumber,
    isDiscoverable,
    avatar,
    interests,
    travelStyles,
    friends,
  ];
}
