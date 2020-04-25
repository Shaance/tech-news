import 'package:flutter/cupertino.dart';
import 'package:shared_preferences_settings/shared_preferences_settings.dart';
import 'package:technewsaggregator/shared_preferences_helper.dart';
class SharedPreferencesScreen extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return getSettingsScreen();
  }
}

SettingsScreen getSettingsScreen() {
  return SettingsScreen(
    title: "Application Settings",
    children: [
//      SimpleSettingsTile(title: 'Article fetch settings', subtitle: 'Set the number of articles to fetch from sources',
//        screen: SettingsScreen(
//          title: 'Fetch settings',
//          children: <Widget>[
//            SettingsContainer(child: getNumberOfArticlesSettingsTile())
//          ],
//      )),
      getNumberOfArticlesSettingsTile()
    ],
  );
}


RadioPickerSettingsTile getNumberOfArticlesSettingsTile() {

  return RadioPickerSettingsTile(
    settingKey: SharedPreferencesHelper.kNumberOfArticlesKey,
    title: 'Number of articles per source',
    defaultKey: SharedPreferencesHelper.kDefaultNumberOfArticles,
    values: {
      '10': '10',
      '25': '25',
      '50': '50',
      '75': '75',
    },
  );
}
