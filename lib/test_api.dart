import 'package:flutter/material.dart';
import 'services/comment_api_service.dart';

class TestApiScreen extends StatefulWidget {
  const TestApiScreen({Key? key}) : super(key: key);

  @override
  State<TestApiScreen> createState() => _TestApiScreenState();
}

class _TestApiScreenState extends State<TestApiScreen> {
  String _result = '';
  final CommentApiService _apiService = CommentApiService();

  Future<void> _testApiEndpoints() async {
    setState(() => _result = 'Testing API endpoints...\n');

    try {
      // Test 1: Debug Token
      await _apiService.debugTokenStatus();
      _appendResult('✅ Token check completed\n');

      // Test 2: Get Article Stats
      final stats = await _apiService.getArticleStats('https://test-article.com');
      _appendResult('✅ Article Stats: $stats\n');

      // Test 3: Like Article
      final likeResult = await _apiService.likeArticle('https://test-article.com', true);
      _appendResult('✅ Like Article: $likeResult\n');

      // Test 4: Save Article
      final saveResult = await _apiService.saveArticle('https://test-article.com', true);
      _appendResult('✅ Save Article: $saveResult\n');

      // Test 5: Get Comments
      final comments = await _apiService.getComments('https://test-article.com');
      _appendResult('✅ Get Comments: ${comments.length} comments\n');

      _appendResult('\n🎉 All tests completed!');
    } catch (e) {
      _appendResult('❌ Error: $e');
    }
  }

  void _appendResult(String text) {
    setState(() {
      _result += text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _testApiEndpoints,
              child: const Text('Test API Endpoints'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _result,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
