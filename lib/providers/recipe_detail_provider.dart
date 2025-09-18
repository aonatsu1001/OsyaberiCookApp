import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Firestoreのインスタンスを提供するProvider
final firestoreProvider = Provider((ref) => FirebaseFirestore.instance);

// 特定のrecipeIdに対応するドキュメントのStreamを提供するProvider
final recipeDetailStreamProvider = StreamProvider.autoDispose
    .family<DocumentSnapshot<Map<String, dynamic>>, String>((ref, recipeId) {
      final firestore = ref.watch(firestoreProvider);

      // 'recipes'コレクションの中から、渡されたrecipeIdと一致するドキュメントを監視
      return firestore.collection('recipes').doc(recipeId).snapshots();
    });
