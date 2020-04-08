// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:url_launcher/url_launcher.dart';

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
    return MaterialApp(
      title: 'Tech news',
      home: TechArticlesWidget(config:config),
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.blue,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
      ),
    );
  }
}

class TechArticlesWidget extends StatefulWidget {

  final AppConfig config;
  TechArticlesWidget({this.config});

  @override
  TechArticlesWidgetState createState() => TechArticlesWidgetState(config: config);
}


class TechArticlesWidgetState extends State<TechArticlesWidget> {
  final log = Logger('TechArticlesWidget');
  final AppConfig config;
  bool _hideReadArticles = false;
  bool _showOnlySavedArticles = false;
  Future<List<Article>> articles;

  TechArticlesWidgetState({this.config});

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    log.fine('initState');
    articles = fetchArticles();
  }

  @override
  Widget build(BuildContext context) {
    var data = new FutureBuilder<List<Article>>(
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
              itemBuilder: (context, index) {
                var readSuffix = filteredList[index].read ? ' · read' : '';
                return Card(
                  child: ListTile(
                    title: Text(filteredList[index].title,
                        style: TextStyle(fontSize: 15.0)),
                    subtitle:
                        buildSubtitleRichText(snapshot, index, readSuffix),
                    trailing: buildBookmarkIconButton(snapshot, index, context),
                    onTap: () {
                      _launchURL(filteredList[index].url);
                      setState(() {
                        filteredList[index].read = true;
                      });
                    },
                  ),
                );
              },
              separatorBuilder: (BuildContext context, int index) => Divider());
        } else if (snapshot.hasError) {
          return Text("${snapshot.error}");
        }

        // By default, show a loading spinner.
        return Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Tech news'),
      ),
      body: data,
      floatingActionButton: buildSpeedDial(),
    );
  }

  Future<List<Article>> fetchArticles() async {
    final host = config.apiUrl;
    final sourcesResponse = await http.get('$host/api/v1/info/sources');
    if (sourcesResponse.statusCode == 200) {
      var sources = json.decode(sourcesResponse.body) as List;
      List<Article> articles = new List();
      for (String source in sources) {
        final response = await http.get('$host/api/v1/source/$source');
        if (response.statusCode != 200) {
          throw Exception('Failed to load Articles');
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

  RichText buildSubtitleRichText(
      AsyncSnapshot<List<Article>> snapshot, int index, String readSuffix) {
    return RichText(
        text: TextSpan(
      text: snapshot.data[index].date.toString().substring(0, 10) +
          ' | ' +
          snapshot.data[index].source,
      style: TextStyle(color: Colors.white70, fontSize: 12.0),
      children: <TextSpan>[
        TextSpan(
            text: readSuffix, style: TextStyle(fontWeight: FontWeight.bold)),
      ],
    ));
  }

  IconButton buildBookmarkIconButton(
      AsyncSnapshot<List<Article>> snapshot, int index, BuildContext context) {
    return new IconButton(
        icon: Icon(
            snapshot.data[index].saved ? Icons.bookmark : Icons.bookmark_border,
            color: snapshot.data[index].saved ? Colors.white : null),
        onPressed: () {
          bookmark(context, snapshot, index);
        });
  }

  void bookmark(
      BuildContext context, AsyncSnapshot<List<Article>> snapshot, int index) {
    setState(() {
      final scaffold = Scaffold.of(context);
      snapshot.data[index].saved = !snapshot.data[index].saved;
      if (snapshot.data[index].saved) {
        scaffold.showSnackBar(SnackBar(
          content: Text('${snapshot.data[index].title} article saved!'),
          action: SnackBarAction(
              label: 'UNDO',
              onPressed: () {
                scaffold.hideCurrentSnackBar();
                setState(() {
                  snapshot.data[index].saved = !snapshot.data[index].saved;
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

  PopupMenuButton getFilterActionButtonPopup() {
    return PopupMenuButton<String>(
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        CheckedPopupMenuItem<String>(
          checked: _hideReadArticles,
          child: const Text('Hide read articles'),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          child: ListTile(leading: Icon(null), title: Text('yaaah')),
        ),
      ],
    );
  }
}
