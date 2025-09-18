import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../pages/login_page.dart';
// import '../screens/home_screen.dart'; // TODO: 後で作成
// import '../screens/login_screen.dart'; // TODO: 後で作成

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // authStateChangesProviderを監視
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      // データがあれば（ログイン済みなら）ホーム画面へ
      data: (user) {
        if (user != null) {
          // return const HomeScreen(); // TODO: ホーム画面に差し替える
          return const Scaffold(body: Center(child: Text("ホーム画面")));
        } else {
          // return const LoginScreen(); // TODO: ログイン画面に差し替える
          return const SignUpScreen();
        }
      },
      // 読み込み中
      loading: () => const Center(child: CircularProgressIndicator()),
      // エラー発生時
      error: (error, stack) => Center(child: Text('エラーが発生しました: $error')),
    );
  }
}
