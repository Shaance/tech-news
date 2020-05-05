import 'dart:convert';
import "package:collection/collection.dart";
import 'package:http/http.dart' as http;
import 'package:technewsaggregator/repository_service_article.dart';
import 'package:technewsaggregator/repository_service_source.dart';
import 'package:technewsaggregator/shared_preferences_helper.dart';
import 'package:technewsaggregator/source.dart';
import 'package:technewsaggregator/toast_message_helper.dart';

import 'article.dart';
import 'database_creator.dart';

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
  final map = groupBy(original, (elem) => elem.sourceKey);
  return [
    ...map.values.expand((list) {
      list.sort((a, b) => b.date.compareTo(a.date));
      final lim = list.length > limit ? limit : list.length;
      return list.sublist(0, lim);
    })
  ];
}

Future<List<Article>> limitBySource(List<Article> original) async {
  final limit = int.parse(await SharedPreferencesHelper.getNumberOfArticles());
  final map = groupBy(original, (elem) => elem.sourceKey);

  // get the latest articles from each source + limit
  map.entries.forEach((element) {
    element.value.sort((a, b) => b.date.compareTo(a.date));
    final lim = element.value.length > limit ? limit : element.value.length;
    map[element.key] = element.value.sublist(0, lim);
  });

  final allArticles = [
    ...map.values.expand((list) => [...list])
  ];
  allArticles.sort((a, b) => b.date.compareTo(a.date));
  return allArticles;
}

Future<List<Source>> fetchRssSources(String baseUrl) async {
  return fetchSources('$baseUrl/api/v2/source/rss');
}

Future<List<Source>> fetchArchiveSources(String baseUrl) async {
  return fetchSources('$baseUrl/api/v2/source/archive');
}

Future<List<Source>> fetchSources(String sourceApiUrl) async {
  final sourcesResponse = await http.get(sourceApiUrl);
  if (sourcesResponse.statusCode == 200) {
    var jsonSources = json.decode(sourcesResponse.body) as List;
    final oldSources = await RepositoryServiceSource.getAllSources();
    final sources =
        jsonSources.map((source) => Source.fromJson(source)).toList();
    final seen = oldSources.map((source) => source.key).toSet();
    final newSources =
        sources.where((element) => !seen.contains(element.key)).toList();
    final filteredSources = new List<Source>();
    for (Source source in sources) {
      if (await SharedPreferencesHelper.isSourceEnabled(source.key)) {
        filteredSources.add(source);
      }
    }
    newSources.forEach((element) => RepositoryServiceSource.addSource(element));
    return filteredSources;
  }
  return Future.value([]);
}

Future articleApiCall(
    String url, List<Article> result, Set<String> seen, String sourceTitle) {
  return http.get(url).then((response) {
    var jsonArticles = json.decode(response.body) as List;
    jsonArticles.map((jsonArticle) {
      jsonArticle[DatabaseCreator.a_sourceTitle] = sourceTitle;
      return Article.fromJson(jsonArticle);
    }).forEach((article) {
      if (!seen.contains(article.url)) {
        result.add(article);
        seen.add(article.url);
      }
    });
  });
}

Future<List<Article>> fetchArticles(
    String baseUrl, List<Article> oldArticles) async {
  try {
    var sources = await fetchRssSources(baseUrl);
    if (sources.length > 0) {
      var futures = <Future>[];
      List<Article> result = new List();
      Set<String> seen = oldArticles != null
          ? oldArticles.map((a) => a.url).toSet()
          : new Set();

      showBottomToast(
          'Fetching articles from ${sources.map((s) => s.title).join(", ")}',
          3);
      final articleNbQueryParam = await getArticleNumberQueryParam();
      for (Source source in sources) {
        final categoryQueryParam = await getCategoryQueryParam(source.key);
        futures.add(articleApiCall(
            '$baseUrl/api/v2/source/rss/${source.key}$articleNbQueryParam$categoryQueryParam',
            result,
            seen,
            source.title));
      }
      await Future.wait(futures);
      if (result.isEmpty) {
        showBottomToast(
            'No new articles from ${sources.map((s) => s.title).join(", ")}',
            3);
      } else {
        showBottomToast(
            'Fetched ${result.length} articles from ${sources.map((s) => s.title).join(", ")}',
            3);
      }
      result.forEach((article) => RepositoryServiceArticle.addArticle(article));
      result.addAll(oldArticles);
      if (await SharedPreferencesHelper.isGroupBySourceEnabled()) {
        return await groupBySource(result);
      } else {
        return await limitBySource(result);
      }
    }
  } catch (err) {
    print(err);
    showBottomToast('An error occured during article fetch!', 2);
  }

  return Future.value(oldArticles);
}
