// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:logging/logging.dart';
import 'package:oktoast/oktoast.dart';
import 'package:technewsaggregator/shared_preferences_helper.dart';
import 'package:technewsaggregator/shared_preferences_screen.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_config.dart';
import 'article.dart';
import 'news_api.dart';

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
      home: TechArticlesWidget(config: config),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.indigoAccent,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.indigoAccent,
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
    super.initState();
    globalKey = GlobalKey<RefreshIndicatorState>();
    log.fine('initState');
    articles = fetchArticles(config.apiUrl, new List());
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
          var refreshArticles = fetchArticles(config.apiUrl, (await articles));
          setState(() {
            articles = refreshArticles;
          });
        },
        child: data,
      ),
      floatingActionButton: buildSpeedDial(),
    );
  }

  AppBar getAppBar() {
    return AppBar(
      title: Text(getAppTitleText()),
      centerTitle: true,
    );
  }

  Future navigateToSettingsPage(context) async {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => SharedPreferencesScreen())
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
    if (_showOnlySavedArticles && _hideReadArticles) {
      list = list.where((element) => element.saved && !element.read).toList();
    } else if (_showOnlySavedArticles) {
      list = list.where((element) => element.saved).toList();
    } else if (_hideReadArticles) {
      list = list.where((element) => !element.read).toList();
    }
    return list;
  }

  String getAppTitleText() {
    if (_showOnlySavedArticles && _hideReadArticles) {
      return 'Saved unread articles';
    } else if (_showOnlySavedArticles) {
      return 'Saved articles';
    } else if (_hideReadArticles) {
      return 'Unread articles';
    } else {
      return 'All articles';
    }
  }

  ListView buildArticleListView(List<Article> filteredList) {
    return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 13.0, vertical: 10),
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
                        maxLines: 2,
                        minFontSize: 15,
                        overflow: TextOverflow.ellipsis,
                      ),
                      contentPadding: EdgeInsets.all(12),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 5.0, bottom: 5.0),
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

  SpeedDial buildSpeedDial() {
    return SpeedDial(
      backgroundColor: Colors.grey,
      animatedIcon: AnimatedIcons.list_view,
      overlayColor: Colors.grey,
      children: [
        SpeedDialChild(
            child: Icon(Icons.settings),
            labelBackgroundColor: Colors.black,
            label: 'Access application settings',
            backgroundColor: Colors.white30,
            onTap: () {
              navigateToSettingsPage(context);
            }),
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
    final enableJS = await SharedPreferencesHelper.isJSEnabled();
    if (await canLaunch(url)) {
      await launch(url, forceWebView: true, enableJavaScript: enableJS);
    } else {
      throw 'Could not launch $url';
    }
  }
}
