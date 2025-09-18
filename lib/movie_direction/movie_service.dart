// lib/fusion/services/movie_service.dart

import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../fusion/services/sequence_manager.dart';

/// Azure FunctionCalling サービス (レシピアシスタント用)
class FunctionCallingService {
  final String endpoint = dotenv.env["AZURE_ENDPOINT"]!;
  final String deployment = dotenv.env["AZURE_DEPLOYMENT"]!;
  final String apiKey = dotenv.env["AZURE_API_KEY"]!;
  final String apiVersion = dotenv.env["AZURE_API_VERSION"]!;

  /// 定義する関数群（順序操作 + タイマー）
  final List<Map<String, dynamic>> functions = [
    {
      "name": "get_sequence_item",
      "description": "レシピの手順を次に進める、前に戻る、または指定の番号にジャンプする",
      "parameters": {
        "type": "object",
        "properties": {
          "direction": {
            "type": "string",
            "enum": ["next", "previous", "jump"],
            "description":
                "次へ進む場合は'next', 前に戻る場合は'previous', 特定の番号に飛ぶ場合は'jump'を指定する",
          },
          "jump_index": {
            "type": "integer",
            "description":
                "ジャンプ先のステップ番号。directionが'jump'の場合に必須。ユーザーが「3番目」と言ったら2を指定する（0始まりのため）",
          },
        },
        "required": ["direction"],
      },
    },
    {
      "name": "start_timer",
      "description": "指定された時間でタイマーを開始する",
      "parameters": {
        "type": "object",
        "properties": {
          "seconds": {
            "type": "integer",
            "description": "タイマーの秒数。ユーザーが「3分」と言ったら180を指定する",
          },
        },
        "required": ["seconds"],
      },
    },
  ];

  /// メッセージを送信し、Function Callingまたはテキスト応答を取得
  Future<Map<String, dynamic>> sendMessageWithFunctions(
    String userMessage,
    List<String> items,
  ) async {
    final url = Uri.parse(
      "$endpoint/openai/deployments/$deployment/chat/completions?api-version=$apiVersion",
    );

    final headers = {"Content-Type": "application/json", "api-key": apiKey};

    final body = jsonEncode({
      "messages": [
        {
          "role": "system",
          "content":
              """
あなたは親切な料理アシスタントです。レシピの手順案内とタイマー設定ができます。

- 「次へ」「次に進んで」などの指示には `get_sequence_item` の `next` を使ってください。
- 「前に戻って」「前の手順」などの指示には `get_sequence_item` の `previous` を使ってください。
- 「〇番の手順」「〇番目に進んで」などの指示には `get_sequence_item` の `jump` と `jump_index` を使ってください。インデックスは0から始まることに注意してください。
- 「〇分タイマー」「〇秒セットして」などの時間に関する指示には `start_timer` を使ってください。
- 上記の機能に該当しない、ユーザーからの一般的な質問や会話には、通常のテキストで応答してください。

現在のレシピ手順一覧:
${items.asMap().entries.map((e) => "${e.key}: ${e.value}").join('\n')}
""",
        },
        {"role": "user", "content": userMessage},
      ],
      "functions": functions,
      "function_call": "auto",
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final choice = data["choices"][0];

        if (choice["message"]["function_call"] != null) {
          final functionCall = choice["message"]["function_call"];
          final functionName = functionCall["name"];
          final arguments = jsonDecode(functionCall["arguments"]);

          return {
            "type": "function_call",
            "function_name": functionName,
            "arguments": arguments,
          };
        } else {
          return {"type": "message", "message": choice["message"]["content"]};
        }
      } else {
        return {
          "type": "error",
          "message":
              "APIエラー: ${response.statusCode}\n${utf8.decode(response.bodyBytes)}",
        };
      }
    } catch (e) {
      return {"type": "error", "message": "通信エラー: $e"};
    }
  }
}

/// ユーザーの音声入力を解釈し、対応するアクションを実行
Future<Map<String, dynamic>> handleUserInput(
  String userMessage,
  SequenceManager manager,
  FunctionCallingService functionService,
) async {
  final res = await functionService.sendMessageWithFunctions(
    userMessage,
    manager.items,
  );

  if (res["type"] == "function_call") {
    final functionName = res["function_name"];
    final args = res["arguments"];

    switch (functionName) {
      case "get_sequence_item":
        final direction = args["direction"];
        // jump_index が null の場合を考慮
        final jumpIndex = args["jump_index"];
        switch (direction) {
          case "next":
            return {"type": "sequence", ...manager.next()};
          case "previous":
            return {"type": "sequence", ...manager.previous()};
          case "jump":
            if (jumpIndex != null) {
              return {"type": "sequence", ...manager.jump(jumpIndex)};
            }
            return {"type": "message", "message": "何番目に進みますか？"};
        }
        break;

      case "start_timer":
        final seconds = args["seconds"];
        return {
          "type": "timer",
          "seconds": seconds,
          "message": "$seconds 秒のタイマーを開始します。",
        };
    }
  }

  // function_call以外 (message or error)
  return res;
}
