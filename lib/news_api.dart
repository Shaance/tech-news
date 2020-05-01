import 'dart:convert';
import "package:collection/collection.dart";
import 'package:http/http.dart' as http;
import 'package:technewsaggregator/repository_service_article.dart';
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

Future<List<Article>> groupBySource(List<Article> original) async {
  final limit = int.parse(await SharedPreferencesHelper.getNumberOfArticles());
  final map = groupBy(original, (elem) => elem.source);
  return [...map.values.expand((list) {
    list.sort((a, b) => b.date.compareTo(a.date));
    return  list.sublist(0, limit);
  })];
}


Future<List<Article>> limitBySource(List<Article> original) async {
  final limit = int.parse(await SharedPreferencesHelper.getNumberOfArticles());
  final map = groupBy(original, (elem) => elem.source);

  // get the latest articles from each source + limit
  map.entries.forEach((element) {
    element.value.sort((a, b) => b.date.compareTo(a.date));
    map[element.key] = element.value.sublist(0, limit);
  });

  final allArticles = [... map.values.expand((list) => [... list])];
  allArticles.sort((a, b) => b.date.compareTo(a.date));
  return allArticles;
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
    if (result.isEmpty) {
      showBottomToast('No new articles from ${filteredSources.join(", ")}', 3);
    } else {
      showBottomToast('Fetched ${result.length} articles from ${filteredSources.join(", ")}', 3);
    }
    result.forEach((article) => RepositoryServiceArticle.addArticle(article));
    result.addAll(oldArticles);
    if (await SharedPreferencesHelper.isGroupBySourceEnabled()) {
      return await groupBySource(result);
    } else {
      return await limitBySource(result);
    }
  } else {
    print('Failed to load sources.');
    return Future.value([]);
  }

}