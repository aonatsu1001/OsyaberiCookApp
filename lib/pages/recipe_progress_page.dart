import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

// 実際のプロジェクトの階層に合わせてパスを調整してください
import '../speech_to_text/providers/speech_provider.dart';
import 'voice_interaction_page.dart';

class RecipeProgressPage extends StatelessWidget {
  final String recipeId; // レシピID
  final String recipeName;

  const RecipeProgressPage({
    super.key,
    required this.recipeId,
    required this.recipeName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF2E9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        title: Text(
          recipeName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: const BackButton(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '材料を確認してください。',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '必要な材料',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      future: FirebaseFirestore.instance
                          .collection('recipes')
                          .doc(recipeId)
                          .collection('content')
                          .doc('ingredients')
                          .get(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (!snapshot.hasData || !snapshot.data!.exists) {
                          return const Text(
                            '材料データが見つかりません',
                            style: TextStyle(color: Colors.red),
                          );
                        }

                        final docData = snapshot.data!.data();
                        if (docData == null || docData.isEmpty) {
                          return const Text(
                            '材料が登録されていません',
                            style: TextStyle(color: Colors.red),
                          );
                        }

                        final sortedKeys = docData.keys.toList()..sort();
                        final ingredients = sortedKeys
                            .map((key) => docData[key] as Map<String, dynamic>)
                            .toList();

                        return Table(
                          columnWidths: const {
                            0: FlexColumnWidth(2),
                            1: FlexColumnWidth(1),
                          },
                          children: ingredients.map((data) {
                            return TableRow(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Text(data['name'] ?? ''),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Text(data['amount'] ?? ''),
                                ),
                              ],
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                // ▼▼▼ ここから修正 ▼▼▼
                onPressed: () {
                  // VoiceInteractionPageに遷移し、レシピIDと名前を渡す
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider(
                        create: (_) => SpeechProvider(),
                        child: VoiceInteractionPage(
                          recipeId: recipeId,
                          recipeName: recipeName,
                        ),
                      ),
                    ),
                  );
                },
                // ▲▲▲ ここまで修正 ▲▲▲
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  '調理を開始します。',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
