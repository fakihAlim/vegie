class DailyQuote {
  final int? id;
  final String quoteText;
  final String author;

  DailyQuote({
    this.id,
    required this.quoteText,
    required this.author,
  });

  factory DailyQuote.fromJson(Map<String, dynamic> json) {
    return DailyQuote(
      id: json['id'],
      quoteText: json['quote_text'] ?? '',
      author: json['author'] ?? 'Anonim',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quote_text': quoteText,
      'author': author,
    };
  }
}
