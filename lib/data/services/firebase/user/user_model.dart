import 'package:cloud_firestore/cloud_firestore.dart';

enum Interest {
  hiking,
  technology,
  cooking,
  arts,
  sports,
  music,
  reading,
  photography,
}

enum TravelStyle {
  luxury,
  budget,
  adventure,
  relaxation,
  cultural,
  solo,
  group,
  family,
}

class UserModel {
  final String id;
  String firstName;
  String lastName;
  String username;
  String email;
  List<Interest> interests; // Could be List<Interest> if using enums
  List<TravelStyle> travelStyles; // Could be List<TravelStyle> if using enums
  DateTime createdAt;
  DateTime updatedAt;
  String? phoneNumber;
  String? avatar;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    this.phoneNumber,
    this.interests = const [],
    this.travelStyles = const [],
    this.avatar,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName => '$firstName $lastName';

  // --- Firestore Serialization ---

  Map<String, dynamic> toJson() {
    return {
      // 'id' is typically not stored in the document data itself, but is the document's ID.
      'firstName': firstName,
      'lastName': lastName,
      'username': username,
      'phoneNumber': phoneNumber,
      'email': email,
      'interests': interests, // Firestore handles List<Interest> directly
      'travelStyles': travelStyles,
      'avatar': avatar,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory UserModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Missing data for User ID: ${snapshot.id}');
    }

    return UserModel(
      id: snapshot.id,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      username: data['username'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      email: data['email'] ?? '',
      interests: List<Interest>.from(data['interests'] ?? []),
      travelStyles: List<TravelStyle>.from(data['travelStyles'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  UserModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? username,
    String? phoneNumber,
    String? avatar,
    String? email,
    List<Interest>? interests,
    List<TravelStyle>? travelStyles,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatar: avatar ?? this.avatar,
      email: email ?? this.email,
      interests: interests ?? this.interests,
      travelStyles: travelStyles ?? this.travelStyles,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
