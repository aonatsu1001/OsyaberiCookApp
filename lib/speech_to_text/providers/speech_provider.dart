// lib/providers/speech_provider.dart

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../services/speech_service.dart';

class SpeechProvider with ChangeNotifier {
  final SpeechService _speechService = SpeechService();

  bool _isAvailable = false;
  bool _isListening = false;
  String _lastWords = ''; // 認識中のテキスト
  final List<String> _history = []; // 確定したテキストの履歴

  // 確定したテキストを外部に渡すためのコールバック
  Function(String)? onTextFinalized;

  // ▼▼▼ 修正 ▼▼▼
  // 自動再開を制御するためのフラグ
  bool _shouldAutoRestart = false;
  // ▲▲▲ ここまで修正 ▲▲▲

  bool get isAvailable => _isAvailable;
  bool get isListening => _isListening;
  String get lastWords => _lastWords;
  List<String> get history => _history;

  SpeechProvider() {
    _initialize();
  }

  /// 初期化処理
  Future<void> _initialize() async {
    _isAvailable = await _speechService.initialize();
    notifyListeners();
  }

  // ▼▼▼ 修正 ▼▼▼
  /// 内部的にリスニングを開始する処理
  void _internalStartListening() {
    if (!_isAvailable || !_shouldAutoRestart) return;
    _speechService.startListening(
      onResult: _onSpeechResult,
      onStatus: _onStatusChanged,
    );
    if (!_isListening) {
      _isListening = true;
      notifyListeners();
    }
  }

  /// 音声認識を開始し、自動再開を有効にする
  void startListening() {
    if (_isListening) return;
    _shouldAutoRestart = true;
    _internalStartListening();
  }

  /// 音声認識を停止し、自動再開を無効にする
  void stopListening() {
    _shouldAutoRestart = false;
    _speechService.stopListening();
    // 状態の更新は _onStatusChanged に任せる
  }
  // ▲▲▲ ここまで修正 ▲▲▲

  /// 認識結果が更新されたときのコールバック
  void _onSpeechResult(SpeechRecognitionResult result) {
    _lastWords = result.recognizedWords;
    notifyListeners();
  }

  /// 認識状態が変化したときのコールバック
  void _onStatusChanged(String status) {
    // ▼▼▼ 修正 ▼▼▼
    final isCurrentlyListening = (status == SpeechToText.listeningStatus);
    if (_isListening != isCurrentlyListening) {
      _isListening = isCurrentlyListening;
      notifyListeners();
    }

    // リスニングが終了した場合
    if (status == SpeechToText.notListeningStatus ||
        status == SpeechToText.doneStatus) {
      // 確定したテキストがあれば処理
      if (_lastWords.isNotEmpty) {
        final finalizedText = _lastWords.trim();
        _history.add(finalizedText);
        // コールバックを介して確定したテキストを通知
        onTextFinalized?.call(finalizedText);
      }
      _lastWords = ''; // 認識中のテキストをクリア
      notifyListeners(); // クリアしたことをUIに反映

      // 自動再開フラグが立っていれば、再度リスニングを開始
      if (_shouldAutoRestart) {
        // 少し間を置いて再開することで、連続的なエラーを防ぐ
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_shouldAutoRestart) {
            // delayed後にもう一度チェック
            _internalStartListening();
          }
        });
      }
    }
    // ▲▲▲ ここまで修正 ▲▲▲
  }

  // Providerが破棄されるときに自動再開を確実に停止する
  @override
  void dispose() {
    _shouldAutoRestart = false;
    super.dispose();
  }
}
