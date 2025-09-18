import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 階層が一つ上(../)のprovidersフォルダにあるファイルを指定
import '../providers/auth_provider.dart'; 
// 階層が一つ上(../)のpagesフォルダにあるファイルを指定
import '../pages/login_page.dart'; 
import '../pages/top_page.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          return const TopPage();
        } else {
          // login_page.dart をインポートしたことで、この行が正しく機能します
          return const SignUpScreen(); 
        }
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Text('エラーが発生しました: $error'),
        ),
      ),
    );
  }
}