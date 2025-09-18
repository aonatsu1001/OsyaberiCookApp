import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart';
import 'widgets/auth_gate.dart';
import 'app_lifecycle_reactor.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 毎回起動時にサインアウト
  await FirebaseAuth.instance.signOut();
  await GoogleSignIn().signOut();

  runApp(AppLifecycleReactor(child: const ProviderScope(child: MyApp())));
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
