import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:technewsaggregator/repository_service_source.dart';
import 'package:technewsaggregator/shared_preferences_helper.dart';
import 'package:technewsaggregator/source.dart';

class SourceSelectionSettings extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new SourceSelectionSettingsState();
  }
}

class SourceSelectionSettingsState extends State<SourceSelectionSettings> {
  final TextEditingController _filter = new TextEditingController();
  Future<List<Widget>> _sourceList;
  bool _filteredState;
  Widget _appTitle;
  Icon _searchIcon;
  String _searchText;

  @override
  void initState() {
    super.initState();
    _sourceList = getCheckboxSettingsTileList();
    _filteredState = false;
    _appTitle = Text('Source selection');
    _searchIcon = Icon(Icons.search);
    _searchText = "";
    _filter.addListener(() {
      setState(() {
        _searchText = _filter.text;
        _sourceList = getCheckboxSettingsTileList();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: AnimatedSwitcher(
            duration: Duration(milliseconds: 250),
            child: _appTitle,
          ),
          centerTitle: true,
          automaticallyImplyLeading: false,
          leading: IconButton(
            onPressed: _searchPressed,
            icon: _searchIcon,
          ),
          actions: <Widget>[
            Padding(
                padding: EdgeInsets.only(right: 20.0),
                child: GestureDetector(
                  onTap: () {
                    _filteredState = !_filteredState;
                    _appTitle =
                        Text(getTitleString(), key: ValueKey(getTitleString()));
                    if (_searchIcon.icon == Icons.close) {
                      _searchIcon = Icon(Icons.search);
                    }
                    _sourceList = getCheckboxSettingsTileList().then((value) {
                      setState(() {});
                      return value;
                    });
                  },
                  child: Icon(Icons.filter_list),
                )),
          ],
        ),
        body: getFutureBuilder());
  }

  String getTitleString() {
    if (_filteredState) {
      return 'Active sources';
    } else {
      return 'Source selection';
    }
  }

  FutureBuilder<List<Widget>> getFutureBuilder() {
    return new FutureBuilder<List<Widget>>(
        future: _sourceList,
        builder: (BuildContext context, AsyncSnapshot<List<Widget>> snapshot) {
          if (snapshot.hasData) {
            return ListView(
              padding: EdgeInsets.all(10),
              children: snapshot.data,
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        });
  }

  void _searchPressed() {
    setState(() {
      if (this._searchIcon.icon == Icons.search) {
        this._searchIcon = Icon(Icons.close);
        this._appTitle = TextField(
          controller: _filter,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search...',
          ),
        );
      } else {
        this._searchIcon = Icon(Icons.search);
        this._appTitle = Text('Source selection');
        _sourceList = getCheckboxSettingsTileList().then((value) {
          setState(() {});
          return value;
        });
        _filter.clear();
      }
    });
  }

  Future<List<Widget>> getCheckboxSettingsTileList() async {
    var sources = await RepositoryServiceSource.getAllSources();

    if (_searchText.isNotEmpty) {
      sources = sources
          .where((element) =>
              element.title.toLowerCase().contains(_searchText.toLowerCase()))
          .toList();
    }

    var filteredSources = List<Source>();

    if (_filteredState) {
      for (Source source in sources) {
        final enabled =
            await SharedPreferencesHelper.isSourceEnabled(source.key);
        if (enabled) {
          filteredSources.add(source);
        }
      }
    } else {
      filteredSources = sources;
    }

    filteredSources.sort((a, b) => a.title.compareTo(b.title));
    final res = List<Widget>();
    for (Source source in filteredSources) {
      res.add(Column(
        children: <Widget>[
          GestureDetector(
            onTap: () async {
              final SharedPreferences prefs =
                  await SharedPreferences.getInstance();
              final enabled =
                  await SharedPreferencesHelper.isSourceEnabled(source.key);
              await prefs.setBool(source.key, !enabled);
              _sourceList = getCheckboxSettingsTileList().then((value) {
                setState(() {});
                return value;
              });
            },
            child: ListTile(
              title: Text(source.title),
              trailing: Checkbox(
                value:
                    await SharedPreferencesHelper.isSourceEnabled(source.key),
                onChanged: (bool value) async {
                  final SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  await prefs.setBool(source.key, value);
                  _sourceList = getCheckboxSettingsTileList().then((value) {
                    setState(() {});
                    return value;
                  });
                },
              ),
            ),
          ),
          Divider()
        ],
      ));
    }
    return res;
  }
}
