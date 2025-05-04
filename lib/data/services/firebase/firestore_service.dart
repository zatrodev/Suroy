import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';

abstract class FirestoreService {
  @protected
  late CollectionReference<Map<String, dynamic>> collectionReference;

  FirestoreService({
    required String collectionName,
    required FirebaseFirestore firestoreInstance,
  }) : collectionReference = firestoreInstance.collection(collectionName);
}
