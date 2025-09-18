import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';
import '../fusion/services/sequence_manager.dart';
import 'movie_service.dart';
import 'package:video_player/video_player.dart';

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
      title: "順序操作 + タイマー + 動画統合",
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
  final TextEditingController _controller = TextEditingController(text: "千切り");

  VideoPlayerController? _videoController;
  String? _currentVideoPath;

  int _remainingSeconds = 0;
  Timer? _timer;
  String _message = "まだ入力がありません";
  int video_count = 5;

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _handleCommand() async {
    final command = _controller.text.trim();
    if (command.isEmpty) return;

    final res = await handleUserInput(command, manager, _fcService);

    if (res["type"] == "sequence") {
      setState(() {
        _message = "Index: ${res['index']}, Item: ${res['item']}";
      });
    } else if (res["type"] == "timer") {
      final seconds = res["seconds"];
      _startCountdown(seconds, "タイマー");
      setState(() {
        _message = res["message"] ?? "";
      });
    } else if (res["type"] == "video") {
      final style = res["cutting_style"];
      String path;
      switch (style) {
        case "短冊切り":
          path = "assets/videos/tanzaku.mp4";
          break;
        case "みじん切り":
          path = "assets/videos/mijin.mp4";
          break;
        case "千切り":
          path = "assets/videos/sengiri.mp4";
          break;
        default:
          path = "assets/videos/default.mp4";
      }
      await _playVideo(path);
      setState(() {
        _message = res["message"] ?? "";
      });
    } else if (res["type"] == "video_control") {
      final op = res["action"];
      video_count = res["seconds"];
      _controlVideo(op, video_count);
      setState(() {
        _message = res["message"] ?? "";
      });
    } else {
      setState(() {
        _message = res["message"] ?? "エラー";
        print(_message);
      });
    }

    _controller.clear();
  }

  // 安全な動画再生関数
  Future<void> _playVideo(String path) async {
    // 古い controller を安全に dispose
    if (_videoController != null) {
      final oldController = _videoController!;
      _videoController = null;
      await oldController.pause();
      await oldController.dispose();
    }

    // 新しい controller を作成
    final controller = VideoPlayerController.asset(path);
    _videoController = controller;

    await controller.initialize();
    setState(() {}); // UI更新
    controller.play();
    _currentVideoPath = path;
  }

  void _controlVideo(String operation, int count) {
    if (_videoController == null) return;
    final pos = _videoController!.value.position;
    final duration = _videoController!.value.duration;

    Duration newPos = pos;
    switch (operation) {
      case "play":
        _videoController!.play();
        return;
      case "pause":
        _videoController!.pause();
        return;
      case "rewind":
        newPos = pos - Duration(seconds: count);
        if (newPos < Duration.zero) newPos = Duration.zero;
        break;
      case "fast_forward":
        newPos = pos + Duration(seconds: count);
        if (newPos > duration) newPos = duration;
        break;
      default:
        return;
    }

    _videoController!.seekTo(newPos);
  }

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("順序操作 + タイマー + 動画")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_videoController != null &&
                _videoController!.value.isInitialized)
              SizedBox(height: 200, child: VideoPlayer(_videoController!))
            else
              const SizedBox(
                height: 200,
                child: Center(child: Text("動画がここに表示されます")),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "命令を入力（例: 次へ / 3分タイマー / 短冊切り / 再生）",
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
                child: Text(_message, style: const TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
