import 'package:flutter/cupertino.dart';
import 'package:shared_preferences_settings/shared_preferences_settings.dart';
import 'package:technewsaggregator/shared_preferences_helper.dart';

class SharedPreferencesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SettingsScreen(
      title: "Application Settings",
      children: [
        SettingsContainer(
        children: [
          _getSourcesSettingsTile(),
          _getNumberOfArticlesSettingsTile(),
          _getSourcesCategoriesSettingsTile(),
          _getGroupBySourceSettingsTile(),
          _getJSEnableSettingsTile(),
        ]),
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

CheckboxSettingsTile _getGroupBySourceSettingsTile() {
  return CheckboxSettingsTile(
    settingKey: SharedPreferencesHelper.kGroupBySourceKey,
    defaultValue: SharedPreferencesHelper.kDefaultGroupBySource,
    title: 'Group articles by source',
    subtitle: 'Articles will be grouped by source',
    subtitleIfOff: 'Display the latest articles',
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
                settingKey: SharedPreferencesHelper.kFacebookKey,
                defaultValue: SharedPreferencesHelper.kDefaultSourceFetch,
                title: 'Facebook engineering blog',
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
              CheckboxSettingsTile(
                settingKey: SharedPreferencesHelper.kHighScalabilityKey,
                defaultValue: SharedPreferencesHelper.kDefaultSourceFetch,
                title: 'High Scalability website',
              ),
            ]
        )
      ],
    ),
  );
}

SimpleSettingsTile _getSourcesCategoriesSettingsTile() {
  return SimpleSettingsTile(
    title: 'Article source category settings',
    subtitle: 'Set category you want to read from',
    screen: SettingsScreen(
      title: 'Category settings',
      children: [
        SettingsContainer(
            children: [
              RadioPickerSettingsTile(
              settingKey: SharedPreferencesHelper.kDevToCategoryKey,
                title: 'Dev.to categories',
                defaultKey: SharedPreferencesHelper.kDefaultDevToCategory,
                values: {
                  '': 'Default (landing page)',
                  'week': 'Best articles of the week',
                  'month': 'Best articles of the month',
                  'year': 'Best articles of the year',
                  'latest': 'Latest articles',
                  'infinity': 'Best articles of all time',
                },
              ),
              RadioPickerSettingsTile(
                settingKey: SharedPreferencesHelper.kHackernewsCategoryKey,
                title: 'Hackernews categories',
                defaultKey: SharedPreferencesHelper.kDefaultHackernewsCategory,
                values: {
                  'best': 'Best articles',
                  'new': 'Latest articles',
                },
              ),
            ]
        )
      ],
    ),
  );
}
