import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

Database db;

class DatabaseCreator {
  static const articleTable = 'article';
  static const id = 'url';
  static const title = 'title';
  static const imageUrl = 'imageUrl';
  static const sourceKey = 'source';
  static const a_sourceTitle = 'sourceTitle';
  static const author = 'author';
  static const date = 'date';
  static const read = 'read';
  static const saved = 'saved';

  static const sourceTable = 'source';
  static const sourceId = 'key';
  static const sourceTitle = 'title';
  static const sourceFeedUrl = 'feedUrl';
  static const sourceUrl = 'url';

  static void databaseLog(String functionName, String sql,
      [List<Map<String, dynamic>> selectQueryResult, int insertAndUpdateQueryResult, List<dynamic> params]) {
    print(functionName);
    print(sql);
    if (params != null) {
      print(params);
    }
    if (selectQueryResult != null) {
      print(selectQueryResult);
    } else if (insertAndUpdateQueryResult != null) {
      print(insertAndUpdateQueryResult);
    }
  }

  static Future<void> createArticleTable(Database db) async {
    final articleSql = '''CREATE TABLE $articleTable
    (
      $id TEXT PRIMARY KEY,
      $imageUrl TEXT,
      $author TEXT,
      $date TEXT,
      $title TEXT,
      $sourceKey TEXT,
      $a_sourceTitle TEXT,
      $read BIT NOT NULL,
      $saved BIT NOT NULL
    )''';

    await db.execute(articleSql);
  }

  static Future<void> createSourceTable(Database db) async {
    final sourceSql = '''CREATE TABLE $sourceTable
    (
      $sourceId TEXT PRIMARY KEY,
      $sourceTitle TEXT,
      $sourceFeedUrl TEXT,
      $sourceUrl TEXT
    )''';

    await db.execute(sourceSql);
  }

  static Future<String> getDatabasePath(String dbName) async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, dbName);

    //make sure the folder exists
    if (await Directory(dirname(path)).exists()) {
      await deleteDatabase(path);
    } else {
      await Directory(dirname(path)).create(recursive: true);
    }
    return path;
  }

  static Future<void> initDatabase() async {
    final path = await getDatabasePath('article_db');
    db = await openDatabase(path, version: 2, onCreate: onCreate);
    print(db);
  }

  static Future<void> onCreate(Database db, int version) async {
    await createArticleTable(db);
    await createSourceTable(db);
  }
}