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
      getNumberOfArticlesSettingsTile(),
      getJSEnableSettingsTile()
    ],
  );
}


RadioPickerSettingsTile getNumberOfArticlesSettingsTile() {
  return RadioPickerSettingsTile(
    settingKey: SharedPreferencesHelper.kNumberOfArticlesKey,
    title: 'Number of articles per source',
    defaultKey: SharedPreferencesHelper.kDefaultNumberOfArticles,
    values: {
      '10': '10 articles',
      '25': '25 articles',
      '50': '50 articles',
      '75': '75 articles',
    },
  );
}

CheckboxSettingsTile getJSEnableSettingsTile() {
  return CheckboxSettingsTile(
    settingKey: SharedPreferencesHelper.kJSEnabledKey,
    defaultValue: SharedPreferencesHelper.kDefaultJSEnabled,
    title: 'Enable JavaScript',
    subtitle: 'Enabled, will load full web pages',
    subtitleIfOff: 'Disabled, web pages will load faster',
  );
}
