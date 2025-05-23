import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class Notification {
  final String id;
  final String title;
  final String body;
  final String senderId;
  final String receiverId;
  final DateTime createdAt;
  Uint8List? senderAvatarBytes;

  Notification({
    required this.id,
    required this.title,
    required this.body,
    required this.senderId,
    required this.receiverId,
    required this.createdAt,
    this.senderAvatarBytes,
  });

  factory Notification.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Missing data for Notificaiton ID: ${snapshot.id}');
    }

    return Notification(
      id: snapshot.id,
      title: data["title"] ?? "",
      body: data["body"] ?? "",
      senderId: data["senderId"] ?? "",
      receiverId: data["receiverId"] ?? "",
      createdAt: data["createdAt"] ?? "",
    );
  }
}
