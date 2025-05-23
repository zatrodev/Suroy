import 'package:app/domain/models/user.dart';
import 'package:app/utils/convert_to_base64.dart';
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

class Friend {
  final String username;
  final bool isAccepted;

  Friend({required this.username, this.isAccepted = false});

  Map<String, dynamic> toJson() {
    return {"username": username, "isAccepted": isAccepted};
  }

  factory Friend.fromJson(Map<String, dynamic> json) {
    if (json['username'] == null) {
      throw FormatException("Missing 'username' in Friend JSON: $json");
    }
    return Friend(
      username: json['username'] as String,
      isAccepted: json['isAccepted'] as bool? ?? false,
    );
  }

  Friend copyWith({String? username, bool? isAccepted}) {
    return Friend(
      username: username ?? this.username,
      isAccepted: isAccepted ?? this.isAccepted,
    );
  }
}

class UserFirebaseModel {
  final String id;
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final List<String> fcmTokens;
  final List<Interest> interests;
  final List<TravelStyle> travelStyles;
  final bool isDiscoverable;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? phoneNumber;
  final String? avatar;
  final List<Friend> friends;

  UserFirebaseModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    this.fcmTokens = const [],
    this.phoneNumber,
    this.interests = const [],
    this.travelStyles = const [],
    this.friends = const [],
    this.avatar,
    this.isDiscoverable = false,
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
      'fcmTokens': fcmTokens,
      'email': email,
      'interests': interests.map((interest) => interest.name).toList(),
      'travelStyles': travelStyles.map((style) => style.name).toList(),
      'avatar': avatar,
      'isDiscoverable': isDiscoverable,
      'friends': friends.map(
        (friend) => {
          "username": friend.username,
          "isAccepted": friend.isAccepted,
        },
      ),
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

    print("IN FROM FIRESTORE");
    List<Interest> interestsList =
        (data['interests'] as List<dynamic>? ?? [])
            .map(
              (interestName) => Interest.values.firstWhere(
                (elem) => elem.name == interestName,
              ),
            )
            .toList();

    List<TravelStyle> travelStyleList =
        (data['travelStyles'] as List<dynamic>? ?? [])
            .map(
              (travelStyleName) => TravelStyle.values.firstWhere(
                (elem) => elem.name == travelStyleName,
              ),
            )
            .toList();

    List<Friend> friendsList =
        (data['friends'] as List<dynamic>? ?? [])
            .map((friend) => Friend.fromJson(friend))
            .toList();

    List<String> fcmTokens =
        (data['fcmTokens'] as List<dynamic>? ?? [])
            .map((token) => token.toString())
            .toList();

    return UserFirebaseModel(
      id: snapshot.id,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      username: data['username'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      email: data['email'] ?? '',
      fcmTokens: fcmTokens,
      avatar: data['avatar'],
      isDiscoverable: data['isDiscoverable'],
      interests: interestsList,
      travelStyles: travelStyleList,
      friends: friendsList,
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
    List<String>? fcmTokens,
    bool? isDiscoverable,
    List<Interest>? interests,
    List<TravelStyle>? travelStyles,
    List<Friend>? friends,
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
      fcmTokens: fcmTokens ?? this.fcmTokens,
      isDiscoverable: isDiscoverable ?? this.isDiscoverable,
      interests: interests ?? this.interests,
      travelStyles: travelStyles ?? this.travelStyles,
      friends: friends ?? this.friends,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  User toUser() {
    return User(
      firstName: firstName,
      lastName: lastName,
      username: username,
      email: email,
      isDiscoverable: isDiscoverable,
      phoneNumber: phoneNumber,
      avatar: avatar,
      avatarBytes: convertBase64ToImage(avatar),
      interests: interests,
      travelStyles: travelStyles,
      friends: friends,
    );
  }

  Friend toFriend() {
    return Friend(username: username, isAccepted: false);
  }
}
