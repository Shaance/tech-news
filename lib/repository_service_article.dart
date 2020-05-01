import 'package:technewsaggregator/shared_preferences_helper.dart';

import 'api_helper.dart';
import 'article.dart';
import 'database_creator.dart';

class RepositoryServiceArticle {

  static Future<List<Article>> getAllArticles() async {
    final sql = '''SELECT * FROM ${DatabaseCreator.articleTable}''';
    final data = await db.rawQuery(sql);
    if (data.length != 0) {
      List<Article> articles = List();
      for (final node in data) {
        final article = Article.fromJson(node);
        final sourceKey = articleSourceToApiSourceKey(article.source);
        if (await SharedPreferencesHelper.isSourceEnabled(sourceKey)) {
          articles.add(article);
        }
      }
      articles.sort((a, b) => b.date.compareTo(a.date));
      return articles;
    } else {
      return [];
    }
  }

  static Future<void> addArticle(Article article) async {
    final sql = '''INSERT INTO ${DatabaseCreator.articleTable}
    (
      ${DatabaseCreator.id},
      ${DatabaseCreator.imageUrl},
      ${DatabaseCreator.author},
      ${DatabaseCreator.date},
      ${DatabaseCreator.title},
      ${DatabaseCreator.source},
      ${DatabaseCreator.read},
      ${DatabaseCreator.saved}
    )
    VALUES (?,?,?,?,?,?,?,?)''';
    List<dynamic> params = [article.url, article.imageUrl, article.author,
      article.date.toIso8601String(), article.title, article.source,
      article.read ? 1 : 0, article.saved ? 1 : 0];
    final result = await db.rawInsert(sql, params);
//    DatabaseCreator.databaseLog('Add article', sql, null, result, params);
  }

  static Future<void> updateArticleReadStatus(Article article) async {

    final sql = '''UPDATE ${DatabaseCreator.articleTable}
    SET ${DatabaseCreator.read} = ?
    WHERE ${DatabaseCreator.id} = ?
    ''';

    List<dynamic> params = [article.read ? 1 : 0, article.url];
    final result = await db.rawUpdate(sql, params);

//    DatabaseCreator.databaseLog('Update article', sql, null, result, params);
  }

  static Future<void> updateArticleSavedStatus(Article article) async {

    final sql = '''UPDATE ${DatabaseCreator.articleTable}
    SET ${DatabaseCreator.saved} = ?
    WHERE ${DatabaseCreator.id} = ?
    ''';

    List<dynamic> params = [article.saved ? 1 : 0, article.url];
    final result = await db.rawUpdate(sql, params);

//    DatabaseCreator.databaseLog('Update article', sql, null, result, params);
  }

  static Future<void> deleteAllArticle() async {

    final sql = '''DELETE * FROM ${DatabaseCreator.articleTable}''';

    final result = await db.rawUpdate(sql);
//    DatabaseCreator.databaseLog('Delete all', sql, null, result);
  }

  static Future<int> countAll() async {
    final data = await db.rawQuery('''SELECT COUNT(*) FROM ${DatabaseCreator.articleTable}''');
    int count = data[0].values.elementAt(0);
    int idForNewItem = count++;
    return idForNewItem;
  }

}