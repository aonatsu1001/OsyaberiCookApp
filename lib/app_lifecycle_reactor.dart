import 'package:flutter/material.dart';

class AppLifecycleReactor extends StatefulWidget {
  final Widget child;
  const AppLifecycleReactor({required this.child, super.key});

  @override
  State<AppLifecycleReactor> createState() => _AppLifecycleReactorState();
}

class _AppLifecycleReactorState extends State<AppLifecycleReactor>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 初回起動時のみサインアウトはmain.dartで実施するため、ここでは何もしない
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
