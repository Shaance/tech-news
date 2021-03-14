import 'package:technewsaggregator/shared_preferences_helper.dart';

import 'article.dart';
import 'database_creator.dart';

class RepositoryServiceArticle {
  static Future<List<Article>> getAllArticles() async {
    final sql = '''SELECT * FROM ${DatabaseCreator.articleTable}''';
    final data = await db.rawQuery(sql);
    if (data.length != 0) {
      List<Article> articles = [];
      for (final node in data) {
        final article = Article.fromJson(node);
        if (await SharedPreferencesHelper.isSourceEnabled(article.sourceKey)) {
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
    final sql = '''INSERT OR REPLACE INTO ${DatabaseCreator.articleTable}
    (
      ${DatabaseCreator.id},
      ${DatabaseCreator.imageUrl},
      ${DatabaseCreator.author},
      ${DatabaseCreator.date},
      ${DatabaseCreator.title},
      ${DatabaseCreator.sourceKey},
      ${DatabaseCreator.a_sourceTitle},
      ${DatabaseCreator.read},
      ${DatabaseCreator.saved}
    )
    VALUES (?,?,?,?,?,?,?,?, ?)''';
    List<dynamic> params = [
      article.url,
      article.imageUrl,
      article.author,
      article.date.toIso8601String(),
      article.title,
      article.sourceKey,
      article.sourceTitle,
      article.read ? 1 : 0,
      article.saved ? 1 : 0
    ];
    await db.rawInsert(sql, params);
  }

  static Future<void> updateArticleReadStatus(Article article) async {
    final sql = '''UPDATE ${DatabaseCreator.articleTable}
    SET ${DatabaseCreator.read} = ?
    WHERE ${DatabaseCreator.id} = ?
    ''';

    List<dynamic> params = [article.read ? 1 : 0, article.url];
    await db.rawUpdate(sql, params);
  }

  static Future<void> updateArticleSavedStatus(Article article) async {
    final sql = '''UPDATE ${DatabaseCreator.articleTable}
    SET ${DatabaseCreator.saved} = ?
    WHERE ${DatabaseCreator.id} = ?
    ''';

    List<dynamic> params = [article.saved ? 1 : 0, article.url];
    await db.rawUpdate(sql, params);
  }

  static Future<void> deleteAllArticle() async {
    final sql = '''DELETE * FROM ${DatabaseCreator.articleTable}''';

    await db.rawUpdate(sql);
  }

  static Future<int> countAll() async {
    final data = await db
        .rawQuery('''SELECT COUNT(*) FROM ${DatabaseCreator.articleTable}''');
    int count = data[0].values.elementAt(0);
    int idForNewItem = count++;
    return idForNewItem;
  }
}
