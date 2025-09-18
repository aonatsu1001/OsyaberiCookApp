import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';
import 'services/sequence_manager.dart';
import 'services/function_calling_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "assets/config/.env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "順序操作 + タイマー統合アプリ",
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SequenceManager manager = SequenceManager([
    "玉ねぎを切る",
    "玉ねぎを炒める",
    "にんじんを切る",
    "にんじんを炒める",
    "盛り付ける",
    "完成を確認する",
  ]);

  final FunctionCallingService _fcService = FunctionCallingService();
  final TextEditingController _controller = TextEditingController(
    text: "2人前にして",
  );

  String _output = "";
  int _remainingSeconds = 0;
  Timer? _timer;

  /// ユーザー入力を処理
  void _handleCommand() async {
    final command = _controller.text.trim();
    if (command.isEmpty) return;

    final res = await handleUserInput(command, manager, _fcService);

    if (res["type"] == "sequence") {
      setState(() {
        _output = "Index: ${res['index']}, Item: ${res['item']}";
      });
    } else if (res["type"] == "timer") {
      final seconds = res["seconds"];
      _startCountdown(seconds, "タイマー");
      setState(() {
        _output = res["message"];
      });
    } else if (res["type"] == "message") {
      setState(() {
        _output = res["message"];
      });
    } else {
      setState(() {
        _output = res["message"] ?? "エラー";
      });
    }

    _controller.clear();
  }

  /// タイマー開始
  void _startCountdown(int seconds, String label) {
    if (_timer != null && _remainingSeconds > 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('前のタイマーはキャンセルされました')));
    }

    _timer?.cancel();
    setState(() => _remainingSeconds = seconds);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() => _remainingSeconds = 0);

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$label が終わりました！')));

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('タイマー終了'),
            content: Text('$label が終わりました！'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("順序操作 + タイマー統合アプリ")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "命令を入力（例: 次へ / 3分タイマー）",
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _handleCommand(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _handleCommand,
                  child: const Text("送信"),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_remainingSeconds > 0)
              Text(
                '残り時間: ${_formatTime(_remainingSeconds)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Text(_output, style: const TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
