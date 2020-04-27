import 'dart:convert';
import "package:collection/collection.dart";
import 'package:http/http.dart' as http;
import 'package:technewsaggregator/shared_preferences_helper.dart';
import 'package:technewsaggregator/toast_message_helper.dart';

import 'article.dart';

Future<String> getCategoryQueryParam(String sourceKey) async {
  final base = '&category=';
  if (sourceKey == SharedPreferencesHelper.kDevToKey) {
    return base + await SharedPreferencesHelper.getDevToCategory();
  } else if (sourceKey == SharedPreferencesHelper.kHackernewsKey) {
    return base + await SharedPreferencesHelper.getHackernewsCategory();
  }
  return '';
}

Future<String> getArticleNumberQueryParam() async {
  final base = '?articleNumber=';
  return base + await SharedPreferencesHelper.getNumberOfArticles();
}

List<Article> groupBySource(List<Article> original) {
  final map = groupBy(original, (elem) => elem.source);
  return [...map.values.expand((list) {
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  })];
}

Future<List<Article>> fetchArticles(String baseUrl, List<Article> oldArticles) async {
  final sourcesResponse = await http.get('$baseUrl/api/v1/info/sources');
  if (sourcesResponse.statusCode == 200) {
    var sources = json.decode(sourcesResponse.body) as List;
    var futures = <Future>[];
    List<Article> result = new List();
    Set<String> seen = oldArticles != null
        ? oldArticles.map((a) => a.url).toSet()
        : new Set();

    final filteredSources = new List();
    for (String source in sources) {
      if (await SharedPreferencesHelper.isSourceEnabled(source)) {
        filteredSources.add(source);
      }
    }
    showBottomToast('Fetching articles from ${filteredSources.join(", ")}', 3);
    final articleNbQueryParam = await getArticleNumberQueryParam();
    for (String source in filteredSources) {
      final categoryQueryParam = await getCategoryQueryParam(source);
      futures.add(http
          .get('$baseUrl/api/v1/source/$source$articleNbQueryParam$categoryQueryParam')
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
//    result.forEach((element) {
//      element.imageUrl = 'https://eng.uber.com/wp-content/uploads/2020/03/Header-Piranha-696x298.jpg';
//    });
    if (await SharedPreferencesHelper.isGroupBySourceEnabled()) {
      return groupBySource(result);
    } else {
      result.sort((a, b) => b.date.compareTo(a.date));
      return result;
    }
  } else {
    print('Failed to load sources.');
    return Future.value([]);
  }

}