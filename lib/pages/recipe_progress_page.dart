import 'package:flutter/material.dart';

class RecipeProgressPage extends StatelessWidget {
  final String recipeName;
  final List<Map<String, dynamic>> ingredients;
  final List<Map<String, dynamic>> steps;

  const RecipeProgressPage({
    super.key,
    required this.recipeName,
    required this.ingredients,
    required this.steps,
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
            // 進行状況バー
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '進行状況',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('0/${steps.length} 完了'),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: 0,
              minHeight: 8,
              backgroundColor: Colors.grey[300],
            ),
            const SizedBox(height: 24),
            const Text(
              '材料を確認してください。',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            // 材料リスト
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(1),
                  },
                  children: [
                    const TableRow(
                      children: [
                        Text(
                          '必要な材料',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    ...ingredients.map(
                      (item) => TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(item['name'] ?? ''),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(item['amount'] ?? ''),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // 今後、手順画面へ遷移する処理を追加
                },
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
