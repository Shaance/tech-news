import 'package:flutter/cupertino.dart';
import 'package:shared_preferences_settings/shared_preferences_settings.dart';
import 'package:technewsaggregator/shared_preferences_helper.dart';

class SharedPreferencesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
        _getSourcesSettingsTile(),
        _getNumberOfArticlesSettingsTile(),
        _getJSEnableSettingsTile(),
      ],
    );
  }
}

RadioPickerSettingsTile _getNumberOfArticlesSettingsTile() {
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

CheckboxSettingsTile _getJSEnableSettingsTile() {
  return CheckboxSettingsTile(
    settingKey: SharedPreferencesHelper.kJSEnabledKey,
    defaultValue: SharedPreferencesHelper.kDefaultJSEnabled,
    title: 'Enable JavaScript',
    subtitle: 'Enabled, will load full web pages',
    subtitleIfOff: 'Disabled, web pages will load faster',
  );
}

SimpleSettingsTile _getSourcesSettingsTile() {
  return SimpleSettingsTile(
    title: 'Article source settings',
    subtitle: 'Set the sources you want to read from',
    screen: SettingsScreen(
      title: 'Your article sources',
      children: [
        SettingsContainer(
            children: [
              CheckboxSettingsTile(
                settingKey: SharedPreferencesHelper.kDevToKey,
                defaultValue: SharedPreferencesHelper.kDefaultSourceFetch,
                title: 'Dev.to website',
              ),
              CheckboxSettingsTile(
                settingKey: SharedPreferencesHelper.kUberKey,
                defaultValue: SharedPreferencesHelper.kDefaultSourceFetch,
                title: 'Uber engineering blog',
              ),
              CheckboxSettingsTile(
                settingKey: SharedPreferencesHelper.kNetflixKey,
                defaultValue: SharedPreferencesHelper.kDefaultSourceFetch,
                title: 'Netflix technology blog',
              ),
              CheckboxSettingsTile(
                settingKey: SharedPreferencesHelper.kAndroidPoliceKey,
                defaultValue: SharedPreferencesHelper.kDefaultSourceFetch,
                title: 'AndroidPolice website',
              ),
              CheckboxSettingsTile(
                settingKey: SharedPreferencesHelper.kHackernewsKey,
                defaultValue: SharedPreferencesHelper.kDefaultSourceFetch,
                title: 'Hackernews website',
              ),
            ]
        )
      ],
    ),
  );
}
