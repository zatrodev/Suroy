import 'package:cloud_firestore/cloud_firestore.dart';

enum Interest {
  hiking,
  technology,
  cooking,
  arts,
  sports,
  music,
  reading,
  photography;

  String get displayName {
    switch (this) {
      case Interest.hiking:
        return 'Hiking';
      case Interest.technology:
        return 'Technology';
      case Interest.cooking:
        return 'Cooking';
      case Interest.arts:
        return 'Arts & Crafts';
      case Interest.sports:
        return 'Sports';
      case Interest.music:
        return 'Music';
      case Interest.reading:
        return 'Reading';
      case Interest.photography:
        return 'Photography';
    }
  }

  String get emoji {
    switch (this) {
      case Interest.hiking:
        return '⛰️';
      case Interest.technology:
        return '💻';
      case Interest.cooking:
        return '🍳';
      case Interest.arts:
        return '🎨';
      case Interest.sports:
        return '⚽';
      case Interest.music:
        return '🎵';
      case Interest.reading:
        return '📚';
      case Interest.photography:
        return '📸';
    }
  }
}

enum TravelStyle {
  luxury,
  budget,
  adventure,
  relaxation,
  cultural,
  solo,
  group,
  family;

  String get displayName {
    switch (this) {
      case TravelStyle.luxury:
        return 'Luxury';
      case TravelStyle.budget:
        return 'Budget-Friendly';
      case TravelStyle.adventure:
        return 'Adventure';
      case TravelStyle.relaxation:
        return 'Relaxation';
      case TravelStyle.cultural:
        return 'Cultural Immersion';
      case TravelStyle.solo:
        return 'Solo Travel';
      case TravelStyle.group:
        return 'Group Travel';
      case TravelStyle.family:
        return 'Family Travel';
    }
  }

  String get emoji {
    switch (this) {
      case TravelStyle.luxury:
        return '💎';
      case TravelStyle.budget:
        return '💰';
      case TravelStyle.adventure:
        return '🧗';
      case TravelStyle.relaxation:
        return '🧘';
      case TravelStyle.cultural:
        return '🏛️';
      case TravelStyle.solo:
        return '🚶';
      case TravelStyle.group:
        return '👥';
      case TravelStyle.family:
        return '👨‍👩‍👧‍👦';
    }
  }
}

class UserFirebaseModel {
  final String id;
  String firstName;
  String lastName;
  String username;
  String email;
  List<Interest> interests;
  List<TravelStyle> travelStyles;
  DateTime createdAt;
  DateTime updatedAt;
  String? phoneNumber;
  String? avatar;

  UserFirebaseModel({
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

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'username': username,
      'phoneNumber': phoneNumber,
      'email': email,
      'interests': interests.map((interest) => interest.name).toList(),
      'travelStyles': travelStyles.map((style) => style.name).toList(),
      'avatar': avatar,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory UserFirebaseModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Missing data for User ID: ${snapshot.id}');
    }

    return UserFirebaseModel(
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

  UserFirebaseModel copyWith({
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
    return UserFirebaseModel(
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
