// TODO put this in own class
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:technewsaggregator/shared_preferences_helper.dart';
import 'package:technewsaggregator/toast_message_helper.dart';

import 'article.dart';

Future<List<Article>> fetchArticles(String baseUrl, List<Article> oldArticles) async {
  final sourcesResponse = await http.get('$baseUrl/api/v1/info/sources');
  if (sourcesResponse.statusCode == 200) {
    var sources = json.decode(sourcesResponse.body) as List;
    var futures = <Future>[];
    List<Article> result = new List();
    Set<String> seen = oldArticles != null
        ? oldArticles.map((a) => a.url).toSet()
        : new Set();

    final userSources = await SharedPreferencesHelper.getSourcesToFetchFrom();
    final filteredSources = sources
        .where((element) => userSources.contains(element))
        .toList();
    showBottomToast('Fetching articles from ${filteredSources.join(", ")}', 3);
    final articleNb = await SharedPreferencesHelper.getNumberOfArticles();
    for (String source in filteredSources) {
      futures.add(http
          .get('$baseUrl/api/v1/source/$source?articleNumber=$articleNb')
          .then((response) {
        var jsonArticles = json.decode(response.body) as List;
        jsonArticles
            .map((jsonArticle) => Article.fromJson(jsonArticle))
            .forEach((article) {
          if (!seen.contains(article.url)) {
            result.add(article);
            seen.add(article.url);
          }
        });
      }));
    }
    await Future.wait(futures);
    result.addAll(oldArticles);
    return result;
  } else {
    print('Failed to load sources.');
    return Future.value([]);
  }
}