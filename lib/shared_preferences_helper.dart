import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesHelper {

  static final String kNumberOfArticlesKey = "NB_OF_ARTICLES";
  static final String kArticleSourcesToFetchKey = "ARTICLES_SRC_TO_FETCH";
  static final String kArticleSourcesToDisplayKey = "ARTICLES_SRC_TO_DISPLAY";
  static final String kJSEnabledKey = "JS_ENABLED";
  static final String kDevToCategoryKey = "${kDevToKey}_category";
  static final String kHackernewsCategoryKey = "${kHackernewsKey}_category";
  static final String kGroupBySourceKey = "GROUP_BY_SOURCE";

  static final String kDevToKey = "dev-to";
  static final String kUberKey = "uber";
  static final String kNetflixKey = "netflix";
  static final String kAndroidPoliceKey = "androidpolice";
  static final String kHackernewsKey = "hackernews";
  static final String kFacebookKey = "facebook";
  static final String kHighScalabilityKey = "highscalability";

  static final String kDefaultNumberOfArticles = '25';
  static final bool kDefaultSourceFetch = true;
  static final bool kDefaultGroupBySource = false;
  static final List<String> kDefaultArticleSourcesToFetch = [
    kDevToKey,
    kUberKey,
    kNetflixKey,
    kAndroidPoliceKey,
    kHackernewsKey,
    kFacebookKey,
    kHighScalabilityKey
  ];

  static final bool kDefaultJSEnabled = false;
  static final String kDefaultDevToCategory = ''; // landing page
  static final String kDefaultHackernewsCategory = 'best';

  static Future<String> getNumberOfArticles() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(kNumberOfArticlesKey) ?? kDefaultNumberOfArticles;
  }

  static Future<List<String>> getSourcesToFetchFrom() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(kArticleSourcesToFetchKey) ?? kDefaultArticleSourcesToFetch;
  }

  static Future<bool> setSourcesToDisplay(List<String> sources) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setStringList(kArticleSourcesToDisplayKey, sources);
  }

  static Future<bool> isJSEnabled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(kJSEnabledKey) ?? kDefaultJSEnabled;
  }

  static Future<bool> isGroupBySourceEnabled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(kGroupBySourceKey) ?? kDefaultGroupBySource;
  }

  static Future<bool> isSourceEnabled(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!kDefaultArticleSourcesToFetch.contains(key)) {
      return false;
    }
    return prefs.getBool(key) ?? kDefaultSourceFetch;
  }

  static Future<String> getDevToCategory() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(kDevToCategoryKey) ?? kDefaultDevToCategory;
  }

  static Future<String> getHackernewsCategory() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(kHackernewsCategoryKey) ?? kDefaultHackernewsCategory;
  }

  static Future<bool> isDevToSourceEnabled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(kDevToKey) ?? kDefaultSourceFetch;
  }

  static Future<bool> isUberSourceEnabled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(kUberKey) ?? kDefaultSourceFetch;
  }

  static Future<bool> isNetflixSourceEnabled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(kNetflixKey) ?? kDefaultSourceFetch;
  }

  static Future<bool> isHighScalabilityEnabled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(kHighScalabilityKey) ?? kDefaultSourceFetch;
  }

  static Future<bool> isAndroidPoliceSourceEnabled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(kAndroidPoliceKey) ?? kDefaultSourceFetch;
  }

  static Future<bool> isHackernewsSourceEnabled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(kHackernewsKey) ?? kDefaultSourceFetch;
  }

  static Future<bool> isFacebookSourceEnabled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(kFacebookKey) ?? kDefaultSourceFetch;
  }
  
}
