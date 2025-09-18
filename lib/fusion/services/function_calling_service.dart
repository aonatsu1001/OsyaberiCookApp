import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'sequence_manager.dart';

/// Azure FunctionCalling サービス
class FunctionCallingService {
  final String endpoint = dotenv.env["AZURE_ENDPOINT"]!;
  final String deployment = dotenv.env["AZURE_DEPLOYMENT"]!;
  final String apiKey = dotenv.env["AZURE_API_KEY"]!;
  final String apiVersion = dotenv.env["AZURE_API_VERSION"]!;

  /// 定義する関数群（順序操作 + タイマー）
  final List<Map<String, dynamic>> functions = [
    {
      "name": "get_sequence_item",
      "description": "順序付きデータの特定アイテムを返す",
      "parameters": {
        "type": "object",
        "properties": {
          "direction": {
            "type": "string",
            "enum": ["next", "previous", "jump"],
            "description": "次/前/ジャンプの操作",
          },
          "jump_index": {
            "type": "integer",
            "description": "ジャンプ先インデックス。direction が 'jump' の場合に必須",
          },
          "items": {
            "type": "array",
            "items": {"type": "string"},
            "description": "順序付きデータリスト",
          },
        },
        "required": ["direction", "items"],
      },
    },
    {
      "name": "start_timer",
      "description": "タイマーをセットして開始する。例: 3分セットして, 10秒タイマー, 5分後に通知など",
      "parameters": {
        "type": "object",
        "properties": {
          "seconds": {"type": "integer", "description": "タイマーの秒数（例: 180 = 3分）"},
        },
        "required": ["seconds"],
      },
    },
  ];

  /// メッセージ送信
  Future<Map<String, dynamic>> sendMessageWithFunctions(
    String userMessage,
    List<String> items,
    int currentIndex,
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
あなたは料理の順序付きデータとタイマー操作のアシスタント兼料理研究家です。
現在の材料は玉ねぎ一つ人参一つカレールー1箱で1人前です。また、一度聞かれたこと等を聞かれたときは「またかい」のように
人間っぽいリアクションをしていくようにユーザが料理を進めていくと楽しくなるような返答をしてください。
また、順序を提供するとともに今何をしているか把握してください。
- ユーザーが「次へ」「前に戻って」の場合は next/previous を返してください。
- 「〇番に進んで」「〇〇を〇〇するに進んで」などステップ名で指示された場合は jump と jump_index を返してください。
- ユーザーが「◯分タイマー」「◯秒セット」などと言った場合は start_timer 関数を必ず呼び出してください。
- 上記に当てはまらない場合は function_call をせず、通常の文章で回答してください。

現在のステップ一覧:
${items.asMap().entries.map((e) => "${e.key}: ${e.value}").join('\n')}
""",
        },
        {"role": "user", "content": userMessage},
      ],
      "functions": functions,
      "function_call": "auto",
    });

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
          "message": choice["message"]["content"] ?? "",
        };
      } else {
        return {"type": "message", "message": choice["message"]["content"]};
      }
    } else {
      return {
        "type": "error",
        "message":
            "エラー: ${response.statusCode}\n${utf8.decode(response.bodyBytes)}",
      };
    }
  }
}

/// ユーザー入力処理
Future<Map<String, dynamic>> handleUserInput(
  String userMessage,
  SequenceManager manager,
  FunctionCallingService functionService,
) async {
  final res = await functionService.sendMessageWithFunctions(
    userMessage,
    manager.items,
    manager.currentIndex,
  );

  if (res["type"] == "function_call") {
    final functionName = res["function_name"];
    final args = res["arguments"];

    switch (functionName) {
      case "get_sequence_item":
        final direction = args["direction"];
        final jumpIndex = args["jump_index"];
        switch (direction) {
          case "next":
            return {"type": "sequence", ...manager.next()};
          case "previous":
            return {"type": "sequence", ...manager.previous()};
          case "jump":
            return {"type": "sequence", ...manager.jump(jumpIndex)};
        }
        break;

      case "start_timer":
        final seconds = args["seconds"];
        // 実際にはアプリ側でタイマー処理を開始する
        return {
          "type": "timer",
          "seconds": seconds,
          "message": "$seconds 秒のタイマーを開始します。",
        };
    }
  }

  return {"type": "message", "message": res["message"] ?? ""};
}
