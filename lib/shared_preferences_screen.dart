import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences_settings/shared_preferences_settings.dart';
import 'package:technewsaggregator/shared_preferences_helper.dart';
import 'package:technewsaggregator/source_selection_settings.dart';

class SharedPreferencesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SettingsScreen(
      title: "Application Settings",
      children: [
        SettingsContainer(children: [
          _getSourcesSettingsTile(),
          _getNumberOfArticlesSettingsTile(),
          _getSourcesCategoriesSettingsTile(),
          _openInWebViewSettingsTile(),
          _getJSEnableSettingsTile(),
        ]),
      ],
    );
  }
}

Future navigateToSourceSettingsPage(context) async {
  Navigator.push(context,
      MaterialPageRoute(builder: (context) => SourceSelectionSettings()));
}

RadioPickerSettingsTile _getNumberOfArticlesSettingsTile() {
  return RadioPickerSettingsTile(
    settingKey: SharedPreferencesHelper.kNumberOfArticlesKey,
    title: 'Number of articles per source',
    defaultKey: SharedPreferencesHelper.kDefaultNumberOfArticles,
    values: {
      '25': '25 articles',
      '50': '50 articles',
      '75': '75 articles',
      '100': '100 articles',
      '125': '125 articles',
    },
  );
}

CheckboxSettingsTile _openInWebViewSettingsTile() {
  return CheckboxSettingsTile(
    settingKey: SharedPreferencesHelper.kOpenInWebViewKey,
    defaultValue: SharedPreferencesHelper.kDefaultOpenInWebView,
    title: 'Use WebView instead of browser',
    subtitle: 'Currently opens links in WebView',
    subtitleIfOff: 'Currently opens links in the browser',
  );
}

CheckboxSettingsTile _getJSEnableSettingsTile() {
  return CheckboxSettingsTile(
    settingKey: SharedPreferencesHelper.kJSEnabledKey,
    defaultValue: SharedPreferencesHelper.kDefaultJSEnabled,
    visibleIfKey: SharedPreferencesHelper.kOpenInWebViewKey,
    visibleByDefault: !SharedPreferencesHelper.kDefaultOpenInWebView,
    title: 'Enable JavaScript',
    subtitle: 'Enabled, will load full web pages',
    subtitleIfOff: 'Disabled, web pages will load faster',
  );
}

SimpleSettingsTile _getSourcesSettingsTile() {
  return SimpleSettingsTile(
    title: 'Article source settings',
    subtitle: 'Set the sources you want to read from',
    screen: SourceSelectionSettings(),
  );
}

SimpleSettingsTile _getSourcesCategoriesSettingsTile() {
  return SimpleSettingsTile(
    title: 'Article source category settings',
    subtitle: 'Set category you want to read from',
    screen: SettingsScreen(
      title: 'Category settings',
      children: [
        SettingsContainer(children: [
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
        ])
      ],
    ),
  );
}
