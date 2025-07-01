import 'dart:convert';
import 'package:flutter/material.dart'; // <-- REVISI: Tambahkan import ini
import 'package:shared_preferences/shared_preferences.dart';
import '../models/article.dart';

class BookmarkService extends ChangeNotifier {
  List<Article> _bookmarkedArticles = [];
  static const _bookmarkKey = 'bookmarked_articles';

  List<Article> get bookmarkedArticles => _bookmarkedArticles;

  BookmarkService() {
    _loadBookmarks();
  }

  bool isBookmarked(Article article) {
    return _bookmarkedArticles.any((item) => item.url == article.url);
  }

  void toggleBookmark(Article article) {
    if (isBookmarked(article)) {
      _bookmarkedArticles.removeWhere((item) => item.url == article.url);
    } else {
      _bookmarkedArticles.add(article);
    }
    _saveBookmarks();
    notifyListeners(); // Sekarang fungsi ini akan dikenali
  }

  Future<void> _saveBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> bookmarksJson = _bookmarkedArticles.map((article) => jsonEncode(article.toJson())).toList();
    await prefs.setStringList(_bookmarkKey, bookmarksJson);
  }

  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarksJson = prefs.getStringList(_bookmarkKey);
    if (bookmarksJson != null) {
      _bookmarkedArticles = bookmarksJson.map((json) => Article.fromJson(jsonDecode(json))).toList();
    }
    notifyListeners(); // Sekarang fungsi ini akan dikenali
  }
}