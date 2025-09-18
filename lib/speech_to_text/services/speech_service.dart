// lib/services/speech_service.dart

import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

class SpeechService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isAvailable = false;

  // シングルトンインスタンス
  static final SpeechService _instance = SpeechService._internal();
  factory SpeechService() => _instance;
  SpeechService._internal();

  bool get isAvailable => _isAvailable;

  /// 音声認識の初期化
  Future<bool> initialize() async {
    _isAvailable = await _speechToText.initialize();
    return _isAvailable;
  }

  /// 音声認識を開始する
  void startListening({
    required Function(SpeechRecognitionResult) onResult,
    required Function(String) onStatus,
  }) {
    if (!_isAvailable) {
      print("音声認識が利用できません。");
      return;
    }
    _speechToText.listen(
      onResult: onResult,
      listenFor: const Duration(minutes: 5), // タイムアウト時間は長めに設定
      // ▼▼▼ 修正 ▼▼▼
      // ユーザーが少し考えても途切れないように無音時間を5秒に設定
      pauseFor: const Duration(seconds: 5),
      // ▲▲▲ ここまで修正 ▲▲▲
      localeId: 'ja_JP', // 日本語に設定
    );
    // onStatusが非推奨になったため、statusListenerを使用
    _speechToText.statusListener = onStatus;
  }

  /// 音声認識を停止する
  void stopListening() {
    _speechToText.stop();
  }
}
