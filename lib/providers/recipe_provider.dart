import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Firestoreのインスタンスを提供するProvider
final firestoreProvider = Provider((ref) => FirebaseFirestore.instance);

// 'recipes'コレクションのStreamを提供するProvider
final recipesStreamProvider = StreamProvider.autoDispose((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore.collection('recipes').snapshots();
});