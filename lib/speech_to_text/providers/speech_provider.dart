// lib/providers/speech_provider.dart

import 'package:flutter/material.dart';
import 'dart:async'; // Future.delayedのためにインポート
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

  // ▼▼▼ ここから修正 ▼▼▼
  // ユーザーが明示的に停止したか（＝自動再開を無効にするか）を管理するフラグ
  // 初期状態は停止しているため true
  bool _stopPermanently = true;
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

  /// 音声認識を開始する
  void startListening() {
    if (!_isAvailable || _isListening) return;

    // ▼▼▼ ここから修正 ▼▼▼
    // リスニング開始時は、自動再開を有効にする
    _stopPermanently = false;
    // ▲▲▲ ここまで修正 ▲▲▲

    _speechService.startListening(
      onResult: _onSpeechResult,
      onStatus: _onStatusChanged,
    );
    _isListening = true;
    notifyListeners();
  }

  /// 音声認識を（自動再開せずに）完全に停止する
  void stopListening() {
    // ▼▼▼ ここから修正 ▼▼▼
    // 既に止まっている場合は何もしない
    if (!_isListening && _stopPermanently) return;

    // 自動再開を無効にする
    _stopPermanently = true;
    _speechService.stopListening();
    _isListening = false;
    _lastWords = '';
    notifyListeners();
    // ▲▲▲ ここまで修正 ▲▲▲
  }

  /// 認識結果が更新されたときのコールバック
  void _onSpeechResult(SpeechRecognitionResult result) {
    _lastWords = result.recognizedWords;
    notifyListeners();
  }

  /// 認識状態が変化したときのコールバック
  void _onStatusChanged(String status) {
    final isCurrentlyListening = (status == SpeechToText.listeningStatus);

    // 状態に変化がなければ何もしない
    if (_isListening == isCurrentlyListening) return;

    _isListening = isCurrentlyListening;

    // リスニングが停止した場合の処理
    if (!_isListening) {
      // 確定したテキストがあれば処理
      if (_lastWords.isNotEmpty) {
        final finalizedText = _lastWords.trim();
        _history.add(finalizedText);
        onTextFinalized?.call(finalizedText);
      }
      _lastWords = '';

      // ▼▼▼ ここから修正 ▼▼▼
      // ユーザーが意図的に停止していなければ、自動的にリスニングを再開する
      if (!_stopPermanently) {
        // 短い遅延を挟むことで、プラットフォーム側のエラーを回避する
        Future.delayed(const Duration(milliseconds: 100), () {
          // 遅延後にもう一度フラグを確認し、停止が要求されていない場合のみ再開
          if (!_stopPermanently) {
            startListening();
          }
        });
      }
      // ▲▲▲ ここまで修正 ▲▲▲
    }

    notifyListeners();
  }
}
