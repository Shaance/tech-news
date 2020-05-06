import 'package:technewsaggregator/source.dart';

import 'database_creator.dart';

class RepositoryServiceSource {
  static Future<List<Source>> getAllSources() async {
    final sql = '''SELECT * FROM ${DatabaseCreator.sourceTable}''';
    final data = await db.rawQuery(sql);
    if (data.length != 0) {
      List<Source> sources = List();
      for (final node in data) {
        sources.add(Source.fromJson(node));
      }
      return sources;
    } else {
      return [];
    }
  }

  static Future<void> addSource(Source source) async {
    final sql = '''INSERT INTO ${DatabaseCreator.sourceTable}
    (
      ${DatabaseCreator.sourceId},
      ${DatabaseCreator.sourceTitle},
      ${DatabaseCreator.sourceFeedUrl},
      ${DatabaseCreator.sourceUrl}
    )
    VALUES (?,?,?,?)''';
    List<dynamic> params = [
      source.key,
      source.title,
      source.feedUrl,
      source.url
    ];

    await db.rawInsert(sql, params);
  }

  static Future<Source> getSource(String sourceId) async {
    final sql = '''SELECT * FROM ${DatabaseCreator.sourceTable}
    WHERE ${DatabaseCreator.sourceId} = ? ''';
    List<dynamic> params = [sourceId];
    final data = await db.rawQuery(sql, params);
    if (data.length != 0) {
      List<Source> sources = List();
      for (final node in data) {
        sources.add(Source.fromJson(node));
      }
      return sources[0];
    } else {
      return Future.value();
    }
  }

  static Future<void> deleteAllArticle() async {
    final sql = '''DELETE * FROM ${DatabaseCreator.sourceTable}''';

    await db.rawUpdate(sql);
  }

  static Future<int> countAll() async {
    final data = await db
        .rawQuery('''SELECT COUNT(*) FROM ${DatabaseCreator.sourceTable}''');
    int count = data[0].values.elementAt(0);
    int idForNewItem = count++;
    return idForNewItem;
  }
}
