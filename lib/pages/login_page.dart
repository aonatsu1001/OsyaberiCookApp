import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

final isLoadingProvider = StateProvider<bool>((ref) => false);
final errorMessageProvider = StateProvider<String?>((ref) => null);

class SignUpScreen extends ConsumerWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final isLoading = ref.watch(isLoadingProvider);
    final errorMessage = ref.watch(errorMessageProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFDF2E9), // 背景色を画像に寄せる
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  // アプリ名
                  const Text(
                    "おしゃべりクック",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    height: 4,
                    width: 140,
                    color: Colors.orangeAccent,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "アカウントの作成\nこのアプリに登録するには\nメールアドレスを入力してください",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  // メールアドレス
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      hintText: "email@domain.com",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // パスワード入力
                  TextField(
                    controller: passwordController,
                    decoration: const InputDecoration(
                      labelText: "パスワード",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 20),
                  // 続行ボタン
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: isLoading
                          ? null
                          : () async {
                              ref.read(isLoadingProvider.notifier).state = true;
                              ref.read(errorMessageProvider.notifier).state =
                                  null;
                              try {
                                await signUp(
                                  emailController.text,
                                  passwordController.text,
                                );
                              } catch (e) {
                                ref.read(errorMessageProvider.notifier).state =
                                    "登録に失敗しました: $e";
                              } finally {
                                ref.read(isLoadingProvider.notifier).state =
                                    false;
                              }
                            },
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("続行"),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  // Googleログインボタン
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: Image.network(
                        "https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg",
                        height: 24,
                      ),
                      label: const Text("Googleで続行"),
                      onPressed: isLoading
                          ? null
                          : () async {
                              ref.read(isLoadingProvider.notifier).state = true;
                              try {
                                await login();
                              } catch (e) {
                                ref.read(errorMessageProvider.notifier).state =
                                    "Googleログインに失敗しました: $e";
                              } finally {
                                ref.read(isLoadingProvider.notifier).state =
                                    false;
                              }
                            },
                    ),
                  ),
                  const SizedBox(height: 16),
                  // エラーメッセージ表示
                  if (errorMessage != null)
                    Text(
                      errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  const SizedBox(height: 16),
                  const Text(
                    "「続行」をクリックすることで、利用規約とプライバシーポリシーに同意したことになります。",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 仮の処理
  Future<void> login() async {
    await Future.delayed(const Duration(seconds: 2));
    // Googleログイン処理をここに実装
  }

  Future<void> signUp(String email, String password) async {
    final auth = FirebaseAuth.instance; // (実際にはProvider経由で取得)
    await auth.createUserWithEmailAndPassword(email: email, password: password);
  }
}
