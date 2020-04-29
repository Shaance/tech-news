import 'package:technewsaggregator/database_creator.dart';

class Article {
  final String url;
  final String imageUrl;
  final String title;
  final String author;
  final String source;
  final DateTime date;
  bool read;
  bool saved;

  Article(
      {this.url,
      this.imageUrl,
      this.title,
      this.author,
      this.date,
      this.source,
      this.read,
      this.saved});

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
        url: json[DatabaseCreator.id],
        imageUrl: json[DatabaseCreator.imageUrl],
        author: json[DatabaseCreator.author],
        date: DateTime.parse(json[DatabaseCreator.date]),
        title: json[DatabaseCreator.title],
        source: json[DatabaseCreator.source],
        read: json[DatabaseCreator.read]  == 1,
        saved: json[DatabaseCreator.saved] == 1);
  }

  @override
  String toString() {
    return 'Article{url: $url, imageUrl: $imageUrl, title: $title, author: $author, source: $source, date: $date, read: $read, saved: $saved}';
  }
}
