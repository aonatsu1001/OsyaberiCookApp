import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../speech_to_text/providers/speech_provider.dart';

// 外部のサービスとマネージャーをインポート
import '../fusion/services/function_calling_service.dart';
import '../fusion/services/sequence_manager.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class RecipeStep {
  final String imageUrl;
  final String instruction;
  final String time;

  RecipeStep({
    required this.imageUrl,
    required this.instruction,
    required this.time,
  });
}

class VoiceInteractionPage extends StatefulWidget {
  final String recipeId;
  final String recipeName;

  const VoiceInteractionPage({
    super.key,
    required this.recipeId,
    required this.recipeName,
  });

  @override
  State<VoiceInteractionPage> createState() => _VoiceInteractionPageState();
}

class _VoiceInteractionPageState extends State<VoiceInteractionPage>
    with SingleTickerProviderStateMixin {
  late final FunctionCallingService _functionCallingService;
  late SequenceManager _sequenceManager;

  final List<ChatMessage> _conversationLog = [];
  bool _isLlmProcessing = false;
  Timer? _timer;
  int _remainingSeconds = 0;

  int _currentStep = 0;
  List<RecipeStep> _recipeSteps = [];
  bool _isLoading = true;

  late final PageController _pageController;
  late final AnimationController _animationController;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.8,
      initialPage: _currentStep,
    );

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _functionCallingService = FunctionCallingService();
    _sequenceManager = SequenceManager([]);

    // buildメソッド完了後にProviderのリスナー設定とリスニング開始を行う
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final speechProvider = context.read<SpeechProvider>();
      speechProvider.onTextFinalized = (text) {
        // ウィジェットが有効な場合のみコマンドを処理
        if (mounted && text.isNotEmpty) {
          _handleSpeechCommand(text);
        }
      };
      // ページ表示時にリスニングを開始
      speechProvider.startListening();
    });

    _fetchRecipeSteps();
  }

  Future<void> _fetchRecipeSteps() async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('recipes')
          .doc(widget.recipeId)
          .collection('content')
          .doc('steps')
          .get();

      if (docSnapshot.exists && mounted) {
        final data = docSnapshot.data();
        if (data == null) {
          if (mounted) setState(() => _isLoading = false);
          return;
        }

        final Map<String, dynamic> stepsData = data;
        final sortedKeys = stepsData.keys.toList()..sort();
        final List<RecipeStep> loadedSteps = [];

        for (final key in sortedKeys) {
          final stepData = stepsData[key] as Map<String, dynamic>;
          loadedSteps.add(
            RecipeStep(
              imageUrl: stepData['photoUrl'] ?? '',
              instruction: stepData['instruction'] ?? '手順の説明がありません',
              time: '${stepData['time'] ?? '??'}分',
            ),
          );
        }

        final instructions = loadedSteps
            .map((step) => step.instruction)
            .toList();

        setState(() {
          _recipeSteps = loadedSteps;
          _sequenceManager = SequenceManager(instructions);
          _isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          debugPrint("レシピのステップデータが見つかりませんでした。");
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("レシピの取得に失敗しました: $e");
    }
  }

  @override
  void dispose() {
    // ページを離れるときにリスニングを確実に停止する
    // Provider.ofを使用し、listen: false とすることで安全に呼び出す
    Provider.of<SpeechProvider>(context, listen: false).stopListening();
    _pageController.dispose();
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _handleSpeechCommand(String command) async {
    // 空白のみのコマンドを無視し、処理中の場合は何もしない
    if (command.trim().isEmpty || _isLlmProcessing) return;

    setState(() {
      _conversationLog.insert(0, ChatMessage(text: command, isUser: true));
      _isLlmProcessing = true;
    });

    // AI処理中は音声認識を明示的に停止
    context.read<SpeechProvider>().stopListening();

    try {
      if (_sequenceManager.items.isEmpty) {
        setState(() {
          _conversationLog.insert(
            0,
            ChatMessage(text: "レシピの手順を準備中です。少々お待ちください。", isUser: false),
          );
        });
        return;
      }

      final res = await handleUserInput(
        command,
        _sequenceManager,
        _functionCallingService,
      );

      switch (res['type']) {
        case 'sequence':
          final newIndex = res['index'];
          final item = res['item'];
          if (newIndex != -1 && item != null) {
            setState(() {
              _currentStep = newIndex;
              _conversationLog.insert(
                0,
                ChatMessage(
                  text: "手順${newIndex + 1}に移動します。\n$item",
                  isUser: false,
                ),
              );
            });
            _pageController.animateToPage(
              newIndex,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            );
          } else {
            setState(() {
              _conversationLog.insert(
                0,
                ChatMessage(text: "すみません、その手順は見つかりませんでした。", isUser: false),
              );
            });
          }
          break;

        case 'timer':
          final seconds = res['seconds'];
          _startCountdown(seconds);
          final message = res['message'] ?? "$seconds 秒のタイマーを開始します。";
          setState(() {
            _conversationLog.insert(
              0,
              ChatMessage(text: message, isUser: false),
            );
          });
          break;

        case 'message':
          final message = res['message'];
          if (message != null && message.isNotEmpty) {
            setState(() {
              _conversationLog.insert(
                0,
                ChatMessage(text: message, isUser: false),
              );
            });
          }
          break;

        case 'error':
        default:
          final message = res['message'] ?? "申し訳ありません、コマンドを理解できませんでした。";
          setState(() {
            _conversationLog.insert(
              0,
              ChatMessage(text: message, isUser: false),
            );
          });
          break;
      }
    } catch (e) {
      setState(() {
        _conversationLog.insert(
          0,
          ChatMessage(text: "エラーが発生しました: $e", isUser: false),
        );
      });
    } finally {
      // 処理が完了したら、必ず処理中フラグを下げて音声認識を再開する
      if (mounted) {
        setState(() {
          _isLlmProcessing = false;
        });
        context.read<SpeechProvider>().startListening();
      }
    }
  }

  void _startCountdown(int seconds) {
    _timer?.cancel();
    setState(() => _remainingSeconds = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() {
          _remainingSeconds = 0;
          _conversationLog.insert(
            0,
            ChatMessage(text: "タイマーが終了しました！", isUser: false),
          );
        });
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
    final speechProvider = context.watch<SpeechProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFFEF1E0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Text(
                widget.recipeName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              _buildProgressSection(),
              if (_remainingSeconds > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Text(
                    'タイマー: ${_formatTime(_remainingSeconds)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              if (_isLoading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_recipeSteps.isEmpty)
                const Expanded(child: Center(child: Text('レシピデータを取得できませんでした。')))
              else
                _buildRecipeCardSlider(),
              const SizedBox(height: 20),
              _buildConversationLog(),
              const SizedBox(height: 20),
              // ▼▼▼ 追加 ▼▼▼
              _buildRecognizingText(speechProvider),
              // ▲▲▲ 追加 ▲▲▲
              _buildBigMicIndicator(speechProvider),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ▼▼▼ 追加 ▼▼▼
  /// 認識中のテキストを表示するウィジェット
  Widget _buildRecognizingText(SpeechProvider provider) {
    // リスニング中で、かつ認識中のテキストがある場合に表示
    if (provider.isListening && provider.lastWords.isNotEmpty) {
      return Container(
        height: 44.0, // 高さを固定してレイアウトのガタつきを防ぐ
        alignment: Alignment.center,
        child: Text(
          '"${provider.lastWords}"',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey.shade700,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    } else {
      // それ以外の場合は高さを確保しつつ空のコンテナを返す
      return const SizedBox(height: 44.0);
    }
  }
  // ▲▲▲ 追加 ▲▲▲

  Widget _buildProgressSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('進行状況', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              '${_recipeSteps.isEmpty ? 0 : _currentStep + 1}/${_recipeSteps.length} 完了',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(_recipeSteps.length, (index) {
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                height: 6,
                decoration: BoxDecoration(
                  color: index <= _currentStep
                      ? Colors.black
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildRecipeCardSlider() {
    return SizedBox(
      height: 280,
      child: PageView.builder(
        controller: _pageController,
        itemCount: _recipeSteps.length,
        onPageChanged: (index) {
          setState(() {
            _currentStep = index;
          });
        },
        itemBuilder: (context, index) {
          final step = _recipeSteps[index];
          final scale = index == _currentStep ? 1.0 : 0.9;
          return TweenAnimationBuilder(
            tween: Tween(begin: scale, end: scale),
            duration: const Duration(milliseconds: 300),
            builder: (context, value, child) {
              return Transform.scale(scale: value, child: child);
            },
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Image.network(
                        step.imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                              size: 48,
                            ),
                          );
                        },
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step.instruction,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                step.time,
                                style: TextStyle(
                                  color: Colors.orange.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBigMicIndicator(SpeechProvider provider) {
    Widget child;
    Color color;
    VoidCallback? onTap;

    if (_isLlmProcessing) {
      color = Colors.orange.shade300;
      child = const CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      );
      onTap = null;
    } else if (provider.isListening) {
      color = Colors.green;
      child = const Icon(Icons.mic, color: Colors.white, size: 40);
      onTap = () => provider.stopListening();
    } else {
      color = Colors.grey.shade400;
      child = Icon(
        Icons.mic_off,
        color: Colors.white.withOpacity(0.9),
        size: 36,
      );
      onTap = () => provider.startListening();
    }

    Widget micButton = Material(
      color: color,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        splashColor: Colors.white.withOpacity(0.4),
        child: SizedBox(width: 80, height: 80, child: Center(child: child)),
      ),
    );

    if (provider.isListening && !_isLlmProcessing) {
      return ScaleTransition(scale: _animation, child: micButton);
    }

    return micButton;
  }

  Widget _buildConversationLog() {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListView.builder(
          reverse: true,
          itemCount: _conversationLog.length,
          itemBuilder: (context, index) {
            final message = _conversationLog[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: _buildChatMessage(
                isUser: message.isUser,
                text: message.text,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildChatMessage({required bool isUser, required String text}) {
    final color = isUser ? Colors.orange.shade100 : Colors.grey.shade200;
    return Row(
      mainAxisAlignment: isUser
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isUser) ...[
          const Icon(Icons.smart_toy_outlined, color: Colors.black54, size: 28),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(text),
          ),
        ),
      ],
    );
  }
}
