import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'widgets/auth_gate.dart';

void main() async {
  // main関数で非同期処理を呼び出すためのお約束
  WidgetsFlutterBinding.ensureInitialized();
  // Firebaseの初期化
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    // Riverpodをアプリ全体で使えるようにする
    const ProviderScope(child: MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Osyaberi Cook',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AuthGate(), // 最初の画面をAuthGateにする
    );
  }
}
