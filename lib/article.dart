// TODO put this in its own class
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
        url: json['url'],
        imageUrl: json['imageUrl'],
        author: json['author'],
        date: DateTime.parse(json['date']),
        title: json['title'],
        source: json['source'],
        read: false,
        saved: false);
  }

  @override
  String toString() {
    return 'Article{url: $url, imageUrl: $imageUrl, title: $title, author: $author, source: $source, date: $date, read: $read, saved: $saved}';
  }
}