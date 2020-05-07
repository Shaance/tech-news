class Source {
  final String key;
  final String title;
  final String feedUrl;
  final String url;

  Source({this.key, this.title, this.feedUrl, this.url});

  factory Source.fromJson(Map<String, dynamic> json) {
    return Source(
        key: json['key'],
        title: json['title'],
        feedUrl: json['feedUrl'],
        url: json['url']);
  }

  @override
  String toString() {
    return 'Source{key: $key, title: $title, feedUrl: $feedUrl, url: $url}';
  }
}
