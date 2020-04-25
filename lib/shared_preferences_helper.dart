import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesHelper {

  static final String _kNumberOfArticles = "NB_OF_ARTICLES";
  static final String _kArticleSourcesToFetch = "ARTICLES_SRC_TO_FETCH";
  static final String _kArticleSourcesToDisplay = "ARTICLES_SRC_TO_DISPLAY";
  static final String _kJSEnabled = "JS_ENABLED";

  static final int _kDefaultNumberOfArticles = 30;
  static final List<String> _kDefaultArticleSourcesToFetch = [
    'dev-to',
    'uber',
    'netflix',
    'androidpolice',
    'hackernews'
  ];
  static final List<String> _kDefaultArticleSourcesToDisplay = [
    ..._kDefaultArticleSourcesToFetch
  ];
  static final bool _kDefaultJSEnabled = false;

  static Future<int> getNumberOfArticles() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kNumberOfArticles) ?? _kDefaultNumberOfArticles;
  }

  static Future<bool> setLanguageCode(int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_kNumberOfArticles, value);
  }

  static Future<List<String>> getSourcesToFetchFrom() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kArticleSourcesToFetch) ?? _kDefaultArticleSourcesToFetch;
  }

  static Future<bool> setSourcesToFetchFrom(List<String> sources) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setStringList(_kArticleSourcesToFetch, sources);
  }

  static Future<List<String>> getSourcesToDisplay() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kArticleSourcesToDisplay) ?? _kDefaultArticleSourcesToDisplay;
  }

  static Future<bool> setSourcesToDisplay(List<String> sources) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setStringList(_kArticleSourcesToDisplay, sources);
  }

  static Future<bool> isJSEnabled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kJSEnabled) ?? _kDefaultJSEnabled;
  }

  static Future<bool> setJSEnabled(bool enableJS) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kJSEnabled, enableJS);
  }

}
