import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart'; // Import AuthService for token refresh

class CommentApiService {
  static const String baseUrl = 'https://icbs.my.id/api';
  static const Duration _timeoutDuration = Duration(seconds: 10);
  final AuthService _authService = AuthService();

  // Get JWT token with automatic refresh if expired
  Future<String?> _getValidToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwt');
      
      if (token == null) {
        print('DEBUG: No JWT token found');
        return null;
      }

      // Test if current token is valid with a simple endpoint
      try {
        final testResponse = await http.get(
          Uri.parse('$baseUrl/auth/profile'), // Changed to a simpler endpoint
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ).timeout(const Duration(seconds: 5));

        if (testResponse.statusCode == 401) {
          print('DEBUG: Token expired, attempting refresh...');
          
          // Try to refresh token
          final refreshSuccess = await _authService.refreshToken();
          if (refreshSuccess) {
            token = prefs.getString('jwt');
            print('DEBUG: Token refreshed successfully');
            return token;
          } else {
            print('DEBUG: Token refresh failed, user needs to login again');
            return null;
          }
        } else if (testResponse.statusCode == 200) {
          print('DEBUG: Token is valid');
          return token;
        } else {
          print('DEBUG: Unexpected response: ${testResponse.statusCode}');
          return token; // Return token anyway, let the actual request handle the error
        }
      } catch (e) {
        print('DEBUG: Error testing token: $e');
        return token; // Return token anyway, let the actual request handle the error
      }
    } catch (e) {
      print('DEBUG: Error checking token validity: $e');
      // Return the token anyway, let the actual request handle the error
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('jwt');
    }
  }

  // Helper method to handle 401 responses
  Future<T> _makeAuthenticatedRequest<T>(
    Future<http.Response> Function(String token) request,
    T Function(http.Response response) onSuccess,
    T Function() onFailure,
  ) async {
    final token = await _getValidToken();
    
    if (token == null) {
      print('ERROR: No valid token available');
      return onFailure();
    }

    try {
      final response = await request(token);
      
      if (response.statusCode == 401) {
        print('ERROR: Still getting 401 after token refresh. User needs to login again.');
        // Clear invalid token
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('jwt');
        return onFailure();
      }
      
      return onSuccess(response);
    } catch (e) {
      print('ERROR: Request failed: $e');
      return onFailure();
    }
  }

  // Get article statistics with auto token refresh
  Future<Map<String, dynamic>> getArticleStats(String articleUrl) async {
    return await _makeAuthenticatedRequest<Map<String, dynamic>>(
      (token) => http.get(
        Uri.parse('$baseUrl/article/stats').replace(
          queryParameters: {'url': articleUrl}
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(_timeoutDuration),
      (response) {
        print('Article Stats Response: ${response.statusCode} - ${response.body}');
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return {
            'likeCount': data['likeCount'] ?? 0,
            'commentCount': data['commentCount'] ?? 0,
            'isLiked': data['isLiked'] ?? false,
            'isSaved': data['isSaved'] ?? false,
          };
        } else {
          return {
            'likeCount': 0,
            'commentCount': 0,
            'isLiked': false,
            'isSaved': false,
          };
        }
      },
      () => {
        'likeCount': 0,
        'commentCount': 0,
        'isLiked': false,
        'isSaved': false,
      },
    );
  }

  // Like/Unlike article with auto token refresh
  Future<Map<String, dynamic>> likeArticle(String articleUrl, bool isLiked) async {
    return await _makeAuthenticatedRequest<Map<String, dynamic>>(
      (token) => http.post(
        Uri.parse('$baseUrl/article/like'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'articleUrl': articleUrl,
          'isLiked': isLiked,
        }),
      ).timeout(_timeoutDuration),
      (response) {
        print('Like Article Response: ${response.statusCode} - ${response.body}');
        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body);
          return {
            'success': true,
            'likeCount': data['likeCount'] ?? 0,
            'isLiked': data['isLiked'] ?? false,
            'message': data['message'] ?? 'Success',
          };
        } else {
          return {
            'success': false,
            'message': 'Failed to update like status: ${response.statusCode}',
          };
        }
      },
      () => {
        'success': false,
        'message': 'Authentication failed. Please login again.',
      },
    );
  }

  // Save/Unsave article with auto token refresh
  Future<bool> saveArticle(String articleUrl, bool isSaved) async {
    return await _makeAuthenticatedRequest<bool>(
      (token) => http.post(
        Uri.parse('$baseUrl/article/save'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'articleUrl': articleUrl,
          'isSaved': isSaved,
        }),
      ).timeout(_timeoutDuration),
      (response) {
        print('Save Article Response: ${response.statusCode} - ${response.body}');
        return response.statusCode == 200 || response.statusCode == 201;
      },
      () => false,
    );
  }

  // Get comments for article - ✅ Sesuai dengan backend GET /api/article/comments
  Future<List<Map<String, dynamic>>> getComments(String articleUrl, {int page = 1, int limit = 20}) async {
    try {
      final token = await _getValidToken();
      if (token == null) throw Exception('User not authenticated');

      final response = await http.get(
        Uri.parse('$baseUrl/article/comments').replace(
          queryParameters: {
            'url': articleUrl,
            'page': page.toString(),
            'limit': limit.toString(),
          }
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(_timeoutDuration);

      print('Get Comments Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['comments'] ?? []);
      } else {
        print('Get Comments Error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error fetching comments: $e');
      return [];
    }
  }

  // Add comment - ✅ Sesuai dengan backend POST /api/article/comments
  Future<Map<String, dynamic>> addComment(String articleUrl, String comment, {String? parentId}) async {
    try {
      final token = await _getValidToken();
      if (token == null) throw Exception('User not authenticated');

      final body = {
        'articleUrl': articleUrl,
        'comment': comment,
      };

      // Add parentId only if it's provided (for replies)
      if (parentId != null && parentId.isNotEmpty) {
        body['parentId'] = parentId;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/article/comments'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      ).timeout(_timeoutDuration);

      print('Add Comment Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'comment': data['comment'],
          'commentCount': data['commentCount'] ?? 0,
          'message': data['message'] ?? 'Comment added successfully',
        };
      } else {
        print('Add Comment Error: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'message': 'Failed to add comment',
        };
      }
    } catch (e) {
      print('Error adding comment: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Delete comment - ✅ Sesuai dengan backend DELETE /api/article/comments/:id
  Future<bool> deleteComment(String commentId) async {
    try {
      final token = await _getValidToken();
      if (token == null) throw Exception('User not authenticated');

      final response = await http.delete(
        Uri.parse('$baseUrl/article/comments/$commentId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(_timeoutDuration);

      print('Delete Comment Response: ${response.statusCode} - ${response.body}');

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Error deleting comment: $e');
      return false;
    }
  }

  // Get saved articles - ✅ Sesuai dengan backend GET /api/article/saved
  Future<List<Map<String, dynamic>>> getSavedArticles({int page = 1, int limit = 20}) async {
    try {
      final token = await _getValidToken();
      if (token == null) throw Exception('User not authenticated');

      final response = await http.get(
        Uri.parse('$baseUrl/article/saved').replace(
          queryParameters: {
            'page': page.toString(),
            'limit': limit.toString(),
          }
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(_timeoutDuration);

      print('Get Saved Articles Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['articles'] ?? []);
      } else {
        print('Get Saved Articles Error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error fetching saved articles: $e');
      return [];
    }
  }

  // Like/Unlike comment - ✅ Sesuai dengan backend POST /api/comment/:commentId/like
  Future<Map<String, dynamic>> likeComment(String commentId, bool isLiked) async {
    try {
      final token = await _getValidToken();
      if (token == null) throw Exception('User not authenticated');

      final response = await http.post(
        Uri.parse('$baseUrl/comment/$commentId/like'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'isLiked': isLiked,
        }),
      ).timeout(_timeoutDuration);

      print('Like Comment Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'likeCount': data['likeCount'] ?? 0,
          'isLiked': data['isLiked'] ?? false,
          'message': data['message'] ?? '',
        };
      } else {
        print('Like Comment Error: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'message': 'Failed to update comment like',
        };
      }
    } catch (e) {
      print('Like Comment Exception: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Debug method to check token validity
  Future<void> debugTokenStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt');
      
      if (token == null) {
        print('DEBUG: No JWT token found');
        return;
      }
      
      print('DEBUG: JWT token found: ${token.substring(0, 20)}...');
      
      // Test token with the backend
      final response = await http.get(
        Uri.parse('$baseUrl/user/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(_timeoutDuration);
      
      print('DEBUG: Token test response: ${response.statusCode}');
      if (response.statusCode == 401) {
        print('DEBUG: Token is invalid or expired');
        // Try automatic refresh
        final refreshSuccess = await _authService.refreshToken();
        print('DEBUG: Token refresh result: $refreshSuccess');
      } else if (response.statusCode == 200) {
        print('DEBUG: Token is valid');
      }
    } catch (e) {
      print('DEBUG: Token check error: $e');
    }
  }
}
