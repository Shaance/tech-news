import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesHelper {

  static final String kNumberOfArticlesKey = "NB_OF_ARTICLES";
  static final String kArticleSourcesToFetchKey = "ARTICLES_SRC_TO_FETCH";
  static final String kArticleSourcesToDisplayKey = "ARTICLES_SRC_TO_DISPLAY";
  static final String kJSEnabledKey = "JS_ENABLED";

  static final String kDefaultNumberOfArticles = '25';
  static final List<String> kDefaultArticleSourcesToFetch = [
    'dev-to',
    'uber',
    'netflix',
    'androidpolice',
    'hackernews'
  ];
  static final List<String> kDefaultArticleSourcesToDisplay = [
    ...kDefaultArticleSourcesToFetch
  ];
  static final bool kDefaultJSEnabled = false;

  static Future<String> getNumberOfArticles() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(kNumberOfArticlesKey) ?? kDefaultNumberOfArticles;
  }

  static Future<List<String>> getSourcesToFetchFrom() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(kArticleSourcesToFetchKey) ?? kDefaultArticleSourcesToFetch;
  }

  static Future<List<String>> getSourcesToDisplay() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(kArticleSourcesToDisplayKey) ?? kDefaultArticleSourcesToDisplay;
  }

  static Future<bool> setSourcesToDisplay(List<String> sources) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setStringList(kArticleSourcesToDisplayKey, sources);
  }

  static Future<bool> isJSEnabled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(kJSEnabledKey) ?? kDefaultJSEnabled;
  }
  
}
