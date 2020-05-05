import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences_settings/shared_preferences_settings.dart';
import 'package:technewsaggregator/repository_service_source.dart';

class SourceSelectionSettings extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new SourceSelectionSettingsState();
  }
}

class SourceSelectionSettingsState extends State<SourceSelectionSettings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Source selection'),
          centerTitle: true,
        ),
        body: getFutureBuilder());
  }

  FutureBuilder<List<CheckboxSettingsTile>> getFutureBuilder() {
    return new FutureBuilder<List<CheckboxSettingsTile>>(
        future: getCheckboxSettingsTileList(),
        builder: (BuildContext context,
            AsyncSnapshot<List<CheckboxSettingsTile>> snapshot) {
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

  Future<List<CheckboxSettingsTile>> getCheckboxSettingsTileList() async {
    final sources = await RepositoryServiceSource.getAllSources();
    sources.sort((a, b) => a.title.compareTo(b.title));
    return sources
        .map((source) => CheckboxSettingsTile(
              settingKey: source.key,
              defaultValue: false, // get from sharedPrefs
              title: source.title,
            ))
        .toList();
  }
}
