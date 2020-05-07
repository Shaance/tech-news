import 'package:technewsaggregator/database_creator.dart';

class Article {
  final String url;
  final String imageUrl;
  final String title;
  final String author;
  final String sourceKey;
  final String sourceTitle;
  final DateTime date;
  bool read;
  bool saved;

  Article(
      {this.url,
      this.imageUrl,
      this.title,
      this.author,
      this.date,
      this.sourceKey,
      this.sourceTitle,
      this.read,
      this.saved});

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
        url: json[DatabaseCreator.id],
        imageUrl: json[DatabaseCreator.imageUrl],
        author: json[DatabaseCreator.author],
        date: DateTime.parse(json[DatabaseCreator.date]),
        title: json[DatabaseCreator.title],
        sourceKey: json[DatabaseCreator.sourceKey],
        sourceTitle: json[DatabaseCreator.a_sourceTitle],
        read: json[DatabaseCreator.read] == 1,
        saved: json[DatabaseCreator.saved] == 1);
  }

  @override
  String toString() {
    return 'Article{url: $url, imageUrl: $imageUrl, title: $title, '
        'author: $author, sourceKey: $sourceKey, sourceTitle: $sourceTitle, '
        'date: $date, read: $read, saved: $saved}';
  }
}
