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

    // ▼▼▼ 変更点 ▼▼▼
    // タイムアウト時間を設定し、無音での停止時間を最大まで延長
    const listenDuration = Duration(minutes: 5);
    // ▲▲▲ ここまで ▲▲▲

    _speechToText.listen(
      onResult: onResult,
      // ▼▼▼ 変更点 ▼▼▼
      listenFor: listenDuration,
      pauseFor: listenDuration, // 無音で停止するまでの時間を最大に設定
      // ▲▲▲ ここまで ▲▲▲
      localeId: 'ja_JP',
    );
    _speechToText.statusListener = onStatus;
  }

  /// 音声認識を停止する
  void stopListening() {
    _speechToText.stop();
  }
}
