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

final String kSourceApi = '/dev/api/v2/source';

Future<Map<String, String>> getCategoryQueryParam(String sourceKey) async {
  if (sourceKey == SharedPreferencesHelper.kDevToKey) {
    return {
      'category' : await SharedPreferencesHelper.getDevToCategory()
    };
  } else if (sourceKey == SharedPreferencesHelper.kHackernewsKey) {
    return {
      'category' : await SharedPreferencesHelper.getHackernewsCategory()
    };
  }
  return {};
}

Future<Map<String, String>> getArticleNumberQueryParam() async {
  return {
    'articleNumber' : await SharedPreferencesHelper.getNumberOfArticles()
  };
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
  if (baseUrl.contains('localhost')) {
    return fetchSources(new Uri.http(baseUrl, '$kSourceApi/rss'));
  }
  return fetchSources(new Uri.https(baseUrl, '$kSourceApi/rss'));
}

Future<List<Source>> fetchArchiveSources(String baseUrl) async {
  if (baseUrl.contains('localhost')) {
    return fetchSources(new Uri.http(baseUrl, '$kSourceApi/archive'));
  }
  return fetchSources(new Uri.https(baseUrl, '$kSourceApi/archive'));
}

String stripUrlSlash(String baseUrl) {
  if (baseUrl.endsWith('/')) {
    return baseUrl.substring(0, baseUrl.length -1);
  }
  return baseUrl;
}

Future<List<Source>> fetchSources(Uri sourceApiUrl) async {
  final sourcesResponse = await http.get(sourceApiUrl);
  final oldSources = await RepositoryServiceSource.getAllSources();
  if (sourcesResponse.statusCode == 200) {
    var jsonSources = json.decode(sourcesResponse.body) as List;
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
  return Future.value(oldSources);
}

Future articleApiCall(
    Uri url, List<Article> result, Set<String> seen, String sourceTitle) {
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

Future<List<Article>> fetchArticles(String baseUrl, List<Article> oldArticles) async {
  List<Article> result = [];
  List<Source> sources = [];
  final host = stripUrlSlash(baseUrl);
  try {
    showBottomToast('Fetching your articles', 3);
    sources = await fetchRssSources(host);
    if (sources.length > 0) {
      var futures = <Future>[];
      Set<String> seen = oldArticles != null
          ? oldArticles.map((a) => a.url).toSet()
          : new Set();

      final articleNbQueryParam = await getArticleNumberQueryParam();
      for (Source source in sources) {
        final categoryQueryParam = await getCategoryQueryParam(source.key);
        final queryParams = {...articleNbQueryParam, ...categoryQueryParam};
        futures.add(articleApiCall(
            new Uri.http(host, '$kSourceApi/rss/${source.key}', queryParams),
            result,
            seen,
            source.title));
      }
      await Future.wait(futures);
      showResultToast(result, sources);
      result.forEach((article) => RepositoryServiceArticle.addArticle(article));
      result.addAll(oldArticles);
      return await limitBySource(result);
    }
  } catch (err) {
    print(err);
    showResultToast(result, sources);
    result.forEach((article) => RepositoryServiceArticle.addArticle(article));
    result.addAll(oldArticles);
  }

  return Future.value(oldArticles);
}

showResultToast(List<Article> result, List<Source> sources) {
  if (result.isEmpty) {
    showBottomToast(
        'No new articles from ${sources.map((s) => s.title).join(", ")}',
        3);
  } else {
    String baseMessage = 'Fetched ${result.length} articles';
    if (sources.length > 10) {
      showBottomToast(baseMessage, 3);
    } else {
      showBottomToast(
          '$baseMessage from ${sources.map((s) => s.title).join(", ")}',
          3);
    }
  }
}
