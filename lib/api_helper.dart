import 'package:technewsaggregator/shared_preferences_helper.dart';

final articleSourceToApiSourceKeyMap = {
  'Uber': SharedPreferencesHelper.kUberKey,
  'Android Police': SharedPreferencesHelper.kAndroidPoliceKey,
  'Dev.to': SharedPreferencesHelper.kDevToKey,
  'High scalability': SharedPreferencesHelper.kHighScalabilityKey,
  'HackerNews': SharedPreferencesHelper.kHackernewsKey,
  'Netflix': SharedPreferencesHelper.kNetflixKey,
  'Facebook': SharedPreferencesHelper.kFacebookKey,
};


String articleSourceToApiSourceKey(String source) {
  return articleSourceToApiSourceKeyMap[source];
}