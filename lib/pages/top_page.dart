import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'recipe_progress_page.dart';
import '../providers/recipe_provider.dart';
import '../providers/auth_provider.dart';

class TopPage extends ConsumerWidget {
  const TopPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipesAsyncValue = ref.watch(recipesStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFDF2E9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        centerTitle: true,
        title: Column(
          children: [
            const Text(
              "おしゃべりクック",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Container(
              margin: const EdgeInsets.only(top: 4),
              height: 3,
              width: 120,
              color: Colors.orangeAccent,
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CustomAppHeader(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: recipesAsyncValue.when(
                data: (snapshot) {
                  if (snapshot.docs.isEmpty) {
                    return const Center(child: Text('投稿されたレシピがまだありません。'));
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: snapshot.docs.length,
                    itemBuilder: (context, index) {
                      final recipeDoc = snapshot.docs[index];
                      return RecipeCard(recipeDoc: recipeDoc);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) =>
                    Center(child: Text('エラーが発生しました: $error')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomAppHeader extends StatelessWidget {
  const CustomAppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '今日のごはん何にする？',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Icon(Icons.search, size: 30),
        ],
      ),
    );
  }
}

class RecipeCard extends ConsumerWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> recipeDoc;

  const RecipeCard({super.key, required this.recipeDoc});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipeData = recipeDoc.data();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 24.0, top: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CachedNetworkImage(
            imageUrl: recipeData['photoUrl'] ?? '',
            placeholder: (context, url) => Container(
              height: 200,
              color: Colors.grey[200],
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => Container(
              height: 200,
              color: Colors.grey[200],
              child: const Icon(Icons.error),
            ),
            fit: BoxFit.cover,
            width: double.infinity,
            height: 200,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipeData['recipeName'] ?? 'タイトルなし',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  recipeData['Description'] ?? '',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text('${recipeData['time'] ?? '?'}分'),
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.people_outline,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text('${recipeData['servings'] ?? '?'}人分'),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final content = recipeData['content'] ?? {};
                      final ingredients =
                          (content['ingredients'] as List<dynamic>?)
                              ?.map((e) => Map<String, dynamic>.from(e))
                              .toList() ??
                          [];
                      final steps =
                          (content['steps'] as List<dynamic>?)
                              ?.map((e) => Map<String, dynamic>.from(e))
                              .toList() ??
                          [];
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RecipeProgressPage(
                            recipeName: recipeData['recipeName'] ?? '',
                            ingredients: ingredients,
                            steps: steps,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'このレシピで料理を始める',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
