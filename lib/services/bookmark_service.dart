import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/article.dart';

class BookmarkService extends ChangeNotifier {
  List<Article> _bookmarkedArticles = [];

  List<Article> get bookmarkedArticles => List.unmodifiable(_bookmarkedArticles);

  BookmarkService() {
    _loadBookmarks();
  }

  bool isBookmarked(Article article) {
    return _bookmarkedArticles.any((a) => a.url == article.url);
  }

  void toggleBookmark(Article article) {
    if (isBookmarked(article)) {
      _bookmarkedArticles.removeWhere((a) => a.url == article.url);
    } else {
      _bookmarkedArticles.add(article);
    }
    _saveBookmarks();
    notifyListeners();
  }

  void addBookmark(Article article) {
    if (!isBookmarked(article)) {
      _bookmarkedArticles.add(article);
      _saveBookmarks();
      notifyListeners();
    }
  }

  void removeBookmark(Article article) {
    _bookmarkedArticles.removeWhere((a) => a.url == article.url);
    _saveBookmarks();
    notifyListeners();
  }

  void clearAllBookmarks() {
    _bookmarkedArticles.clear();
    _saveBookmarks();
    notifyListeners();
  }

  // Load bookmarks from SharedPreferences
  Future<void> _loadBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarksJson = prefs.getStringList('bookmarks') ?? [];
      _bookmarkedArticles = bookmarksJson
          .map((json) => Article.fromJson(jsonDecode(json)))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load bookmarks: $e');
    }
  }

  // Save bookmarks to SharedPreferences
  Future<void> _saveBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarksJson = _bookmarkedArticles
          .map((article) => jsonEncode(article.toJson()))
          .toList();
      await prefs.setStringList('bookmarks', bookmarksJson);
    } catch (e) {
      debugPrint('Failed to save bookmarks: $e');
    }
  }
}