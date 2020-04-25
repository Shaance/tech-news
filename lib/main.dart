// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:oktoast/oktoast.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:auto_size_text/auto_size_text.dart';

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
    articles = fetchArticles(new List());
  }

  @override
  Widget build(BuildContext context) {
    var data = buildDataFutureBuilder();

    return Scaffold(
      appBar: getAppBar(),
      body: RefreshIndicator(
        color: Colors.black,
        backgroundColor: Colors.grey,
        key: globalKey,
        onRefresh: () async {
          var refreshArticles = fetchArticles((await articles));
          setState(() {
            articles = refreshArticles;
          });
        },
        child: data,
      ),
      floatingActionButton: buildSpeedDial(),
    );
  }

  // TODO add logic
  AppBar getAppBar() {
    return AppBar(
      title: Text(getAppTitleText()),
      centerTitle: true,
      leading: GestureDetector(
        onTap: () { /* Write listener code here */ },
        child: Icon(
          Icons.filter_list,  // add custom icons also
        ),
      ),
      actions: <Widget>[
        Padding(
            padding: EdgeInsets.only(right: 20.0),
            child: GestureDetector(
              onTap: () {
//                log.info('Tappped on gear icon');
              },
              child: Icon(
                  Icons.settings
              ),
            )
        ),
      ],
    );
  }

  FutureBuilder<List<Article>> buildDataFutureBuilder() {
    return new FutureBuilder<List<Article>>(
      future: articles,
      builder: (BuildContext context, AsyncSnapshot<List<Article>> snapshot) {
        if (snapshot.hasData) {
          List<Article> filteredList = filterArticles(snapshot.data);
          return buildArticleListView(filteredList);
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

  List<Article> filterArticles(List<Article> list) {
    if (_showOnlySavedArticles) {
      list = list.where((element) => element.saved).toList();
    } else if (_hideReadArticles) {
      list = list.where((element) => !element.read).toList();
    }
    return list;
  }

  String getAppTitleText() {
    if (_showOnlySavedArticles) {
      return 'Saved artciles';
    } else if (_hideReadArticles) {
      return 'Unread articles';
    } else {
      return 'All articles';
    }
  }

  ListView buildArticleListView(List<Article> filteredList) {
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
                      title: AutoSizeText(
                        filteredList[index].title,
                        style: TextStyle(color: textColor, fontSize: 15.0),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      contentPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 5.0),
                        child: buildSubtitleRichText(filteredList[index]),
                      ),
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
        },
        separatorBuilder: (BuildContext context, int index) => Divider());
  }

  Future<List<Article>> fetchArticles(List<Article> oldArticles) async {
    final host = config.apiUrl;
    final sourcesResponse = await http.get('$host/api/v1/info/sources');
    if (sourcesResponse.statusCode == 200) {
      var sources = json.decode(sourcesResponse.body) as List;
      var futures = <Future>[];

      List<Article> result = new List();
      Set<String> seen = new Set();
      if (oldArticles != null) {
        seen = oldArticles.map((a) => a.url).toSet();
      }

      showBottomToast('Fetching articles from ${sources.join(", ")}', 3);
      for (String source in sources) {
        futures.add(http
            .get('$host/api/v1/source/$source?articleNumber=30')
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
      throw Exception('Failed to load sources.');
    }
  }

  void showBottomToast(String message, int durationInSeconds) {
    showToast(
      message,
      duration: Duration(seconds: durationInSeconds),
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
