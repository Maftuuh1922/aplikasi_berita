class Comment {
  final String id;
  final String author;
  final String text;
  final DateTime timestamp; // Use timestamp instead of createdAt
  final int likeCount;
  final String? authorPhoto;
  final bool isLiked;
  final int replyCount;

  Comment({
    required this.id,
    required this.author,
    required this.text,
    required this.timestamp,
    this.likeCount = 0,
    this.authorPhoto,
    this.isLiked = false,
    this.replyCount = 0,
  });

  // Add createdAt getter for backward compatibility
  DateTime get createdAt => timestamp;

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] ?? '',
      author: json['author'] ?? 'Anonymous',
      text: json['text'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? json['createdAt'] ?? '') ?? DateTime.now(),
      likeCount: json['likeCount'] ?? 0,
      authorPhoto: json['authorPhoto'],
      isLiked: json['isLiked'] ?? false,
      replyCount: json['replyCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author': author,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'likeCount': likeCount,
      'authorPhoto': authorPhoto,
      'isLiked': isLiked,
      'replyCount': replyCount,
    };
  }
}