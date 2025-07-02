class Comment {
  final String id;
  final String articleIdentifier;
  final String author;
  final String text;
  final String? authorPhoto; // ← Foto profil opsional
  final DateTime timestamp;

  Comment({
    required this.id,
    required this.articleIdentifier,
    required this.author,
    required this.text,
    this.authorPhoto,
    required this.timestamp,
  });

  // Factory untuk membaca data JSON dari API backend (Node.js)
  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['_id'],
      articleIdentifier: json['articleIdentifier'],
      author: json['author'],
      text: json['text'],
      authorPhoto: json['authorPhoto'], // ← Ambil dari backend jika ada
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  // Jika nanti ingin kirim kembali ke server (opsional)
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'articleIdentifier': articleIdentifier,
      'author': author,
      'text': text,
      'authorPhoto': authorPhoto,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
