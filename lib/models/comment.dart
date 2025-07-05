class Comment {
  final String id;
  final String articleIdentifier;
  final String author;
  final String text;
  final String? authorPhoto;
  final DateTime timestamp;
  final int likeCount;
  final int replyCount;
  final bool isLiked;
  final List<Comment> replies;

  Comment({
    required this.id,
    required this.articleIdentifier,
    required this.author,
    required this.text,
    this.authorPhoto,
    required this.timestamp,
    this.likeCount = 0,
    this.replyCount = 0,
    this.isLiked = false,
    this.replies = const [],
  });

  // Factory untuk membaca data JSON dari API backend (Node.js)
  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['_id'],
      articleIdentifier: json['articleIdentifier'],
      author: json['author'],
      text: json['text'],
      authorPhoto: json['authorPhoto'],
      timestamp: DateTime.parse(json['timestamp']),
      likeCount: json['likeCount'] ?? 0,
      replyCount: json['replyCount'] ?? 0,
      isLiked: json['isLiked'] ?? false,
      replies: (json['replies'] as List<dynamic>?)
          ?.map((reply) => Comment.fromJson(reply))
          .toList() ?? [],
    );
  }

  // Untuk kirim kembali ke server
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'articleIdentifier': articleIdentifier,
      'author': author,
      'text': text,
      'authorPhoto': authorPhoto,
      'timestamp': timestamp.toIso8601String(),
      'likeCount': likeCount,
      'replyCount': replyCount,
      'isLiked': isLiked,
      'replies': replies.map((reply) => reply.toJson()).toList(),
    };
  }

  // Method untuk membuat copy dengan perubahan tertentu
  Comment copyWith({
    String? id,
    String? articleIdentifier,
    String? author,
    String? text,
    String? authorPhoto,
    DateTime? timestamp,
    int? likeCount,
    int? replyCount,
    bool? isLiked,
    List<Comment>? replies,
  }) {
    return Comment(
      id: id ?? this.id,
      articleIdentifier: articleIdentifier ?? this.articleIdentifier,
      author: author ?? this.author,
      text: text ?? this.text,
      authorPhoto: authorPhoto ?? this.authorPhoto,
      timestamp: timestamp ?? this.timestamp,
      likeCount: likeCount ?? this.likeCount,
      replyCount: replyCount ?? this.replyCount,
      isLiked: isLiked ?? this.isLiked,
      replies: replies ?? this.replies,
    );
  }

  @override
  String toString() {
    return 'Comment(id: $id, articleIdentifier: $articleIdentifier, author: $author, text: $text, authorPhoto: $authorPhoto, timestamp: $timestamp, likeCount: $likeCount, replyCount: $replyCount, isLiked: $isLiked, replies: ${replies.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Comment &&
        other.id == id &&
        other.articleIdentifier == articleIdentifier &&
        other.author == author &&
        other.text == text &&
        other.authorPhoto == authorPhoto &&
        other.timestamp == timestamp &&
        other.likeCount == likeCount &&
        other.replyCount == replyCount &&
        other.isLiked == isLiked;
  }

  @override
  int get hashCode {
    return id.hashCode ^
    articleIdentifier.hashCode ^
    author.hashCode ^
    text.hashCode ^
    authorPhoto.hashCode ^
    timestamp.hashCode ^
    likeCount.hashCode ^
    replyCount.hashCode ^
    isLiked.hashCode;
  }
}