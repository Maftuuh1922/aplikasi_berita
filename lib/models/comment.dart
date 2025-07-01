class Comment {
  final String id;
  final String articleIdentifier;
  final String author;
  final String text;
  final DateTime timestamp;

  Comment({
    required this.id,
    required this.articleIdentifier,
    required this.author,
    required this.text,
    required this.timestamp,
  });

  // Factory untuk membaca data JSON dari API kita
  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['_id'], // MongoDB menggunakan '_id'
      articleIdentifier: json['articleIdentifier'],
      author: json['author'],
      text: json['text'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}