import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerWidget {
  // ConsumerWidgetを継承
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('ログイン')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'メールアドレス'),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'パスワード'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                try {
                  // Provider経由でFirebaseAuthのインスタンスを取得
                  final auth = ref.read(firebaseAuthProvider);

                  // ログイン処理を呼び出し
                  await auth.signInWithEmailAndPassword(
                    email: emailController.text,
                    password: passwordController.text,
                  );

                  // 成功時の処理はAuthGateが自動で行うので、ここでは不要
                } on FirebaseAuthException catch (e) {
                  // エラーメッセージをスナックバーで表示
                  final snackBar = SnackBar(
                    content: Text('ログインに失敗しました: ${e.message}'),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                }
              },
              child: const Text('ログイン'),
            ),
          ],
        ),
      ),
    );
  }
}
