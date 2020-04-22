// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:oktoast/oktoast.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import 'app_config.dart';
import 'article.dart';

void main({String env}) async {
  WidgetsFlutterBinding.ensureInitialized();
  Logger.root.level = Level.ALL; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
  final config = await AppConfig.forEnvironment(env);
  runApp(MyApp(config: config));
}

class MyApp extends StatelessWidget {
  final AppConfig config;

  MyApp({this.config});

  @override
  Widget build(BuildContext context) {
    return OKToast(
        child: MaterialApp(
      title: 'Tech news',
      home: TechArticlesWidget(config: config),
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.blue,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
      ),
    ));
  }
}

class TechArticlesWidget extends StatefulWidget {
  final AppConfig config;
  TechArticlesWidget({this.config});

  @override
  TechArticlesWidgetState createState() =>
      TechArticlesWidgetState(config: config);
}

class TechArticlesWidgetState extends State<TechArticlesWidget> {
  final log = Logger('TechArticlesWidget');
  final AppConfig config;
  bool _hideReadArticles = false;
  bool _showOnlySavedArticles = false;
  Future<List<Article>> articles;
  GlobalKey<RefreshIndicatorState> globalKey;

  TechArticlesWidgetState({this.config});

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    globalKey = GlobalKey<RefreshIndicatorState>();
    log.fine('initState');
    articles = fetchArticles();
  }

  @override
  Widget build(BuildContext context) {
    var data = buildDataFutureBuilder();

    return Scaffold(
      appBar: AppBar(
        title: Text('Tech news'),
      ),
      body: RefreshIndicator(
        color: Colors.black,
        backgroundColor: Colors.grey,
        key: globalKey,
        onRefresh: () async {
          final oldArticles = await articles;
          final seen = oldArticles.map((e) => e.url).toSet();
          final newArticles = await fetchArticles();
          final refreshedArticles = newArticles
              .where((article) => !seen.contains(article.url))
              .toList();
          refreshedArticles.addAll(oldArticles);
          setState(() {
            articles = Future.value(refreshedArticles);
          });
          showBottomToast('All articles loaded!');
        },
        child: data,
      ),
      floatingActionButton: buildSpeedDial(),
    );
  }

  FutureBuilder<List<Article>> buildDataFutureBuilder() {
    return new FutureBuilder<List<Article>>(
      future: articles,
      builder: (BuildContext context, AsyncSnapshot<List<Article>> snapshot) {
        if (snapshot.hasData) {
          List<Article> filteredList = snapshot.data;
          if (_showOnlySavedArticles) {
            filteredList =
                filteredList.where((element) => element.saved).toList();
          } else if (_hideReadArticles) {
            filteredList =
                filteredList.where((element) => !element.read).toList();
          }

          return ListView.separated(
              padding: const EdgeInsets.all(13.0),
              itemCount: filteredList.length,
              itemBuilder: (BuildContext context, int index) {
                var textColor =
                filteredList[index].read ? Colors.white30 : Colors.white;
                return AnimationConfiguration.synchronized(
                  duration: const Duration(milliseconds: 500),
                  child: SlideAnimation(
                      verticalOffset: 100.0,
                      child: FadeInAnimation(
                        child: Card(
                          child: ListTile(
                            title: Text(filteredList[index].title,
                                style: TextStyle(color: textColor, fontSize: 15.0)),
                            subtitle: buildSubtitleRichText(filteredList[index]),
                            trailing:
                            buildBookmarkIconButton(filteredList[index], context),
                              onTap: () {
                                _launchURL(filteredList[index].url);
                                setState(() {
                                  filteredList[index].read = true;
                                });
                              }),
                          ),
                        ),
                      ),
                );
              }, separatorBuilder: (BuildContext context, int index) => Divider());

        } else if (snapshot.hasError) {
          return Text("${snapshot.error}");
        }

        // By default, show a loading spinner.
        return Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  Future<List<Article>> fetchArticles() async {
    final host = config.apiUrl;
    final sourcesResponse = await http.get('$host/api/v1/info/sources');
    if (sourcesResponse.statusCode == 200) {
      var sources = json.decode(sourcesResponse.body) as List;
      List<Article> articles = new List();
      for (String source in sources) {
        showBottomToast('Fetching articles from $source');
        final response = await http.get('$host/api/v1/source/$source?articleNumber=35');
        if (response.statusCode != 200) {
          showBottomToast('Failed to fetch arcticle from $source');
        }

        var jsonArticles = json.decode(response.body) as List;
        jsonArticles
            .map((jsonArticle) => Article.fromJson(jsonArticle))
            .forEach((article) => articles.add(article));
      }
      return articles;
    } else {
      throw Exception('Failed to load sources.');
    }
  }

  void showBottomToast(String message) {
    showToast(message,
      duration: Duration(seconds: 2),
      position: ToastPosition.bottom,
      backgroundColor: Colors.white,
      radius: 5.0,
      textStyle: TextStyle(fontSize: 16.0, color: Colors.black),
    );
  }

  SpeedDial buildSpeedDial() {
    return SpeedDial(
      backgroundColor: Colors.grey,
      animatedIcon: AnimatedIcons.list_view,
      overlayColor: Colors.grey,
      children: [
        SpeedDialChild(
            child: Icon(
                _hideReadArticles ? Icons.visibility : Icons.visibility_off),
            labelBackgroundColor: Colors.black,
            label: (_hideReadArticles ? 'Show' : 'Hide') + ' read articles',
            backgroundColor: Colors.white30,
            onTap: () {
              setState(() {
                _hideReadArticles = !_hideReadArticles;
              });
            }),
        SpeedDialChild(
            child: Icon(_showOnlySavedArticles ? Icons.star_border : Icons.star,
                color: Colors.yellowAccent),
            labelBackgroundColor: Colors.black,
            label: _showOnlySavedArticles
                ? 'Show all articles'
                : 'Show only saved articles',
            backgroundColor: Colors.white30,
            onTap: () {
              setState(() {
                _showOnlySavedArticles = !_showOnlySavedArticles;
                if (_showOnlySavedArticles) {
                  _hideReadArticles = false;
                }
              });
            })
      ],
    );
  }

  RichText buildSubtitleRichText(Article article) {
    final readSuffix = article.read ? ' · read' : '';
    final color = article.read ? Colors.white30 : Colors.white70;
    return RichText(
        text: TextSpan(
      text: article.date.toString().substring(0, 10) + ' | ' + article.source,
      style: TextStyle(color: color, fontSize: 12.0),
      children: <TextSpan>[
        TextSpan(
            text: readSuffix, style: TextStyle(fontWeight: FontWeight.bold)),
      ],
    ));
  }

  IconButton buildBookmarkIconButton(Article article, BuildContext context) {
    var color;
    if (article.read) {
      color = Colors.white30;
    } else if (article.saved) {
      color = Colors.white;
    }

    return new IconButton(
        icon: Icon(article.saved ? Icons.bookmark : Icons.bookmark_border,
            color: color),
        onPressed: () {
          bookmark(context, article);
        });
  }

  void bookmark(BuildContext context, Article article) {
    setState(() {
      final scaffold = Scaffold.of(context);
      article.saved = !article.saved;
      if (article.saved) {
        scaffold.showSnackBar(SnackBar(
          content: Text('${article.title} article saved!'),
          action: SnackBarAction(
              label: 'UNDO',
              onPressed: () {
                scaffold.hideCurrentSnackBar();
                setState(() {
                  article.saved = !article.saved;
                });
              }),
          duration: Duration(milliseconds: 2000),
        ));
      }
    });
  }

  _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url, forceWebView: true);
    } else {
      throw 'Could not launch $url';
    }
  }
}
