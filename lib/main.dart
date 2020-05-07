// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:oktoast/oktoast.dart';
import 'package:share/share.dart';
import 'package:technewsaggregator/database_creator.dart';
import 'package:technewsaggregator/repository_service_article.dart';
import 'package:technewsaggregator/shared_preferences_helper.dart';
import 'package:technewsaggregator/shared_preferences_screen.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_config.dart';
import 'article.dart';
import 'logo_helper.dart';
import 'news_api.dart';

void main({String env}) async {
  WidgetsFlutterBinding.ensureInitialized();
  Logger.root.level = Level.ALL; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
  await DatabaseCreator.initDatabase();
  await SharedPreferencesHelper.initDefaultSources();
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
        primaryColor: Color.fromRGBO(61, 61, 92, 1),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Color.fromRGBO(61, 61, 92, 1),
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
  final customGrey = Color.fromRGBO(153, 153, 153, 1);
  String _articleListKey;
  bool first = true;
  bool firstError = true;
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
    articles = RepositoryServiceArticle.getAllArticles();
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
          final oldArticles = await RepositoryServiceArticle.getAllArticles();
          var refreshArticles = fetchArticles(config.apiUrl, oldArticles);
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
    final title = getAppTitleText();
    return AppBar(
      title: AnimatedSwitcher(
          duration: Duration(milliseconds: 250),
          child: Text(title, key: ValueKey(title))),
      centerTitle: true,
    );
  }

  Future navigateToSettingsPage(context) async {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => SharedPreferencesScreen()));
  }

  FutureBuilder<List<Article>> buildDataFutureBuilder() {
    return new FutureBuilder<List<Article>>(
      future: articles,
      builder: (BuildContext context, AsyncSnapshot<List<Article>> snapshot) {
        if (snapshot.hasData) {
          List<Article> filteredList = filterArticles(snapshot.data);
          _articleListKey = filteredList.map((a) => a.url).join();
          if (filteredList.isNotEmpty) {
            return AnimatedSwitcher(
                duration: Duration(milliseconds: 250),
                child: buildArticleListView(filteredList),
                key: ValueKey(_articleListKey));
          } else {
            RepositoryServiceArticle.countAll().then((value) {
              if (value == 0) {
                if (first) {
                  first = false;
                  articles = fetchArticles(config.apiUrl, List()).then((value) {
                    setState(() => {});
                    return value;
                  });
                } else {
                  if (firstError) {
                    firstError = false;
                    showSnackBar(
                        Text(
                            'Article fetch failed. Try again with better internet connection'),
                        milliseconds: 2000);
                  }
                }
              }
            });

            return buildNoContentWidget();
          }
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

  Center buildNoContentWidget() {
    return Center(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Stack(
          children: <Widget>[
            Center(
                child: Placeholder(
              fallbackHeight: 230,
              color: Colors.black12,
              strokeWidth: 0,
            )),
            Center(
                child: FadeInImage.memoryNetwork(
                    placeholder: kTransparentImage,
                    image:
                        'https://media.giphy.com/media/l2SpZkQ0XT1XtKus0/giphy.gif')),
          ],
        ),
        SizedBox(height: 20),
        Text(
          "Oops, nothing to see here yet .. 🧐?",
          style: TextStyle(fontSize: 20),
        )
      ],
    ));
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

  Widget buildArticleListView(List<Article> filteredList) {
    final deviceCurrentSize = MediaQuery.of(context).size;

    if (deviceCurrentSize.width > 600) {
      return new StaggeredGridView.countBuilder(
        crossAxisCount: (deviceCurrentSize.width / 450).round(),
        itemCount: filteredList.length,
        itemBuilder: (BuildContext context, int index) {
          var textColor =
              filteredList[index].read ? Colors.white30 : Colors.white;
          return buildAnimationConfiguration(
              filteredList, index, textColor, context, false);
        },
        staggeredTileBuilder: (int index) => new StaggeredTile.fit(1),
        mainAxisSpacing: 4.0,
        crossAxisSpacing: 4.0,
      );
    } else {
      final numberOfArticles = filteredList.length;
      final articlesDates = getDistinctDates(filteredList).toList();

      return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 13.0, vertical: 10),
          itemCount: numberOfArticles,
          key: const PageStorageKey<String>('someKey'),
          itemBuilder: (BuildContext context, int index) {
            var textColor =
                filteredList[index].read ? Colors.white30 : Colors.white;
            if (index == 0) {
              return Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      getSeparator(articlesDates, filteredList, index, true),
                    ],
                  ),
                  SizedBox(height: 10),
                  buildAnimationConfiguration(filteredList, index, textColor, context, true)
                ],
              );
            }
            return buildAnimationConfiguration(
                filteredList, index, textColor, context, true);
          },
          separatorBuilder: (BuildContext context, int index) =>
              getSeparator(articlesDates, filteredList, index, false));
    }
  }

  // 12-13; 12-12; 12-10; dates
  // 12-12; 12-10 articles
  // while article date is different from date list increment date index
  // when equal, increment index to get the next date
  // if next article date == current date item
  // then print date
  // else sizedBox
  // very slow implementation... hacky way because separator is always after item
  Widget getSeparator(
      List<DateTime> dates, List<Article> article, int index, bool first) {
    var dateIndex = 0;

    while (getFormattedDate(article[index].date) !=
        getFormattedDate(dates[dateIndex])) {
      dateIndex++;
    }

    if (!first) {
      dateIndex++;
      if (dates.length == 1) {
        return SizedBox(height: 5);
      }
    }

    if (article.length == 1) {
      index = -1;
    }

    var dateEquals = dates.isNotEmpty &&
        getFormattedDate(article[index + 1].date) ==
            getFormattedDate(dates[dateIndex]);

    if (dateEquals) {
      var text =
          DateFormat('EEE, MMM d, yyyy', 'en_US').format(dates[dateIndex]);
      if (getFormattedDate(DateTime.now()) ==
          getFormattedDate(article[index + 1].date)) {
        text = 'Today';
      } else if (getFormattedDate(
              DateTime.now().subtract(Duration(hours: 24))) ==
          getFormattedDate(article[index + 1].date)) {
        text = 'Yesterday';
      }
      return Container(
          padding: EdgeInsets.only(top: 20, bottom: 10),
          child: Text(
            text,
            style: TextStyle(fontSize: 15, color: Colors.white70),
          ));
    } else {
      return SizedBox(height: 5);
    }
  }

  String getFormattedDate(DateTime date) {
    return date.toString().substring(0, 10);
  }

  ListQueue<DateTime> getDistinctDates(List<Article> articles) {
    Set<String> seen = Set();
    ListQueue<DateTime> result = ListQueue();
    articles.forEach((element) {
      final date = element.date.toString().substring(0, 10);
      if (!seen.contains(date)) {
        seen.add(date);
        result.add(DateTime(
          element.date.year,
          element.date.month,
          element.date.day,
        ));
      }
    });
    return result;
  }

  AnimationConfiguration buildAnimationConfiguration(List<Article> articleList,
      int index, Color textColor, BuildContext context, bool listView) {
    return AnimationConfiguration.synchronized(
      duration: const Duration(milliseconds: 500),
      child: SlideAnimation(
        verticalOffset: 100.0,
        child: FadeInAnimation(
            child: Card(
                clipBehavior: Clip.antiAliasWithSaveLayer,
                child: getArticleCard(articleList[index], textColor, context, listView))),
      ),
    );
  }

  Widget getArticleCard(
      Article currentArticle, Color textColor, BuildContext context, bool listView) {
    if (currentArticle.imageUrl != null) {
      return Column(
        children: <Widget>[
          SizedBox(height: 0),
          GestureDetector(
              onTap: () {
                _launchURL(currentArticle.url);
                currentArticle.read = true;
                RepositoryServiceArticle.updateArticleReadStatus(currentArticle)
                    .then((_) => {setState(() => {})});
              },
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 450),
                child: Stack(
                  children: <Widget>[
                    Center(
                        child: Placeholder(
                      fallbackHeight: 150,
                      color: Colors.black12,
                      strokeWidth: 0,
                    )),
                    Center(
                        child: FadeInImage.memoryNetwork(
                            placeholder: kTransparentImage,
                            image: currentArticle.imageUrl)),
                  ],
                ),
              )),
          SizedBox(height: 0),
          buildListTile(currentArticle, textColor, context, listView)
        ],
      );
    }

    return buildListTile(currentArticle, textColor, context, listView);
  }

  Widget buildListTile(Article article, Color textColor, BuildContext context, bool listView) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 500),
      child: ListTile(
          leading: getLogoForSource(article),
          title: AutoSizeText(
            article.title,
            style: TextStyle(color: textColor, fontSize: 15.0),
            maxLines: 2,
            minFontSize: 15,
            overflow: TextOverflow.ellipsis,
          ),
          contentPadding: EdgeInsets.all(12),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 5.0, bottom: 5.0),
            child: buildSubtitleRichText(article, listView),
          ),
          trailing: getArticlePopupMenuButton(article),
          onTap: () {
            _launchURL(article.url);
            article.read = true;
            RepositoryServiceArticle.updateArticleReadStatus(article)
                .then((_) => setState(() {}));
          }),
    );
  }

  SpeedDial buildSpeedDial() {
    return SpeedDial(
      backgroundColor: customGrey,
      animatedIcon: AnimatedIcons.list_view,
      overlayColor: Color.fromRGBO(140, 140, 140, 1),
      children: [
        SpeedDialChild(
            child: Icon(Icons.refresh),
            labelBackgroundColor: Colors.black54,
            label: 'Refresh article list',
            backgroundColor: customGrey,
            onTap: () async {
              final oldArticles =
                  await RepositoryServiceArticle.getAllArticles();
              var refreshArticles = fetchArticles(config.apiUrl, oldArticles);
              setState(() {
                articles = refreshArticles;
              });
            }),
        SpeedDialChild(
            child: Icon(
                _hideReadArticles ? Icons.visibility : Icons.visibility_off),
            labelBackgroundColor: Colors.black54,
            label: (_hideReadArticles ? 'Show' : 'Hide') + ' read articles',
            backgroundColor: customGrey,
            onTap: () {
              setState(() {
                _hideReadArticles = !_hideReadArticles;
              });
            }),
        SpeedDialChild(
            child:
                Icon(_showOnlySavedArticles ? Icons.all_inclusive : Icons.book),
            labelBackgroundColor: Colors.black54,
            label: _showOnlySavedArticles
                ? 'Show all articles'
                : 'Show only saved articles',
            backgroundColor: customGrey,
            onTap: () {
              setState(() {
                _showOnlySavedArticles = !_showOnlySavedArticles;
                if (_showOnlySavedArticles) {
                  _hideReadArticles = false;
                }
              });
            }),
        SpeedDialChild(
            child: Icon(Icons.settings),
            labelBackgroundColor: Colors.black54,
            label: 'Access application settings',
            backgroundColor: customGrey,
            onTap: () {
              navigateToSettingsPage(context);
            }),
      ],
    );
  }

  RichText buildSubtitleRichText(Article article, bool listView) {
    final readSuffix = article.read ? ' · read' : '';
    final savedSuffix = article.saved ? ' · saved' : '';
    final color = article.read ? Colors.white30 : Colors.white70;
    return RichText(
        text: TextSpan(
      text: listView ? article.sourceTitle : getFormattedDate(article.date) + ' | ' + article.sourceTitle ,
      style: TextStyle(color: color, fontSize: 12.0),
      children: <TextSpan>[
        TextSpan(
            text: readSuffix, style: TextStyle(fontWeight: FontWeight.bold)),
        TextSpan(
            text: savedSuffix, style: TextStyle(fontWeight: FontWeight.bold)),
      ],
    ));
  }

  PopupMenuButton getArticlePopupMenuButton(Article article) {
    return PopupMenuButton<Map<String, Article>>(
        icon: Icon(Icons.expand_more),
        color: customGrey,
        onSelected: popupMenuButtonAction,
        padding: EdgeInsets.symmetric(horizontal: 5),
        itemBuilder: (BuildContext context) {
          return [
            PopupMenuItem(
                value: {'save': article}, child: getSaveArticleText(article)),
            PopupMenuItem(
                value: {'share': article},
                child: Center(
                  child: Text("Share article",
                      style: TextStyle(color: Colors.black)),
                )),
            PopupMenuItem(
                value: {'read': article}, child: getMarkAsReadText(article)),
          ];
        });
  }

  Widget getMarkAsReadText(Article article) {
    return Center(
      child: Text(
        article.read ? "Mark as unread" : "Mark as read",
        style: TextStyle(color: Colors.black),
      ),
    );
  }

  Widget getSaveArticleText(Article article) {
    return Center(
      child: Text(
        article.saved ? "Unsave article" : "Save article",
        style: TextStyle(color: Colors.black),
      ),
    );
  }

  void popupMenuButtonAction(Map<String, Article> choice) {
    if (choice.containsKey('save')) {
      choice['save'].saved = !choice['save'].saved;
      RepositoryServiceArticle.updateArticleSavedStatus(choice['save'])
          .then((_) => setState(() {}));

      if (!choice['save'].saved) {
        showSnackBar(Text('Unsaved ${choice['save'].title}'));
      } else {
        showSnackBar(Text('${choice['save'].title} saved!'));
      }
    } else if (choice.containsKey('read')) {
      choice['read'].read = !choice['read'].read;
      RepositoryServiceArticle.updateArticleReadStatus(choice['read'])
          .then((_) => setState(() {}));

      if (choice['read'].read) {
        showSnackBar(Text('${choice['read'].title} marked as read'));
      } else {
        showSnackBar(Text('${choice['read'].title} marked as unread'));
      }
    } else {
      Share.share(choice['share'].url);
    }
  }

  void showSnackBar(Text text, {milliseconds = 1500}) {
    final scaffold = Scaffold.of(globalKey.currentState.context);
    scaffold.showSnackBar(SnackBar(
        content: text, duration: Duration(milliseconds: milliseconds)));
  }

  _launchURL(String url) async {
    final enableWebView = await SharedPreferencesHelper.isWebViewEnabled();
    final enableJS = await SharedPreferencesHelper.isJSEnabled();
    if (await canLaunch(url)) {
      await launch(url,
          forceWebView: enableWebView, enableJavaScript: enableJS);
    } else {
      throw 'Could not launch $url';
    }
  }
}
