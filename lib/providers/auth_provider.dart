import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// FirebaseAuthのインスタンスを提供するProvider
// これを介して認証操作を行う
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

// 認証状態の変化（ログイン、ログアウト）を監視し、
// Userオブジェクトを提供するProvider
final authStateChangesProvider = StreamProvider<User?>((ref) {
  // 依存するProviderを読み込む
  final auth = ref.watch(firebaseAuthProvider);
  return auth.authStateChanges();
});
