import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  bool _isDarkMode = false;
  Locale _locale = const Locale('en');

  // Plan Pinning logic
  bool _isPlanPinned = false;
  String? _pinnedPlanTopic;
  double _pinnedPlanProgress = 0.0;
  String? _pinnedPlanData;
  String? _pinnedPlanTasksState; // JSON string of completed tasks

  bool get isDarkMode => _isDarkMode;
  Locale get locale => _locale;
  bool get isPlanPinned => _isPlanPinned;
  String? get pinnedPlanTopic => _pinnedPlanTopic;
  double get pinnedPlanProgress => _pinnedPlanProgress;
  String? get pinnedPlanData => _pinnedPlanData;
  String? get pinnedPlanTasksState => _pinnedPlanTasksState;

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _isDarkMode = _prefs?.getBool('isDarkMode') ?? false;
    final langCode = _prefs?.getString('languageCode') ?? 'en';
    _locale = Locale(langCode);
    
    _isPlanPinned = _prefs?.getBool('isPlanPinned') ?? false;
    _pinnedPlanTopic = _prefs?.getString('pinnedPlanTopic');
    _pinnedPlanProgress = _prefs?.getDouble('pinnedPlanProgress') ?? 0.0;
    _pinnedPlanData = _prefs?.getString('pinnedPlanData');
    _pinnedPlanTasksState = _prefs?.getString('pinnedPlanTasksState');
    
    notifyListeners();
  }

  void toggleTheme(bool isDark) {
    _isDarkMode = isDark;
    _prefs?.setBool('isDarkMode', isDark);
    notifyListeners();
  }

  void setLocale(Locale locale) {
    _locale = locale;
    _prefs?.setString('languageCode', locale.languageCode);
    notifyListeners();
  }

  void pinPlan(String topic, double progress, String data, {String? tasksState}) {
    _isPlanPinned = true;
    _pinnedPlanTopic = topic;
    _pinnedPlanProgress = progress;
    _pinnedPlanData = data;
    _pinnedPlanTasksState = tasksState;
    
    _prefs?.setBool('isPlanPinned', true);
    _prefs?.setString('pinnedPlanTopic', topic);
    _prefs?.setDouble('pinnedPlanProgress', progress);
    _prefs?.setString('pinnedPlanData', data);
    if (tasksState != null) {
      _prefs?.setString('pinnedPlanTasksState', tasksState);
    }
    
    notifyListeners();
  }

  void unpinPlan() {
    _isPlanPinned = false;
    _pinnedPlanTopic = null;
    _pinnedPlanProgress = 0.0;
    _pinnedPlanData = null;
    _pinnedPlanTasksState = null;
    
    _prefs?.setBool('isPlanPinned', false);
    _prefs?.remove('pinnedPlanTopic');
    _prefs?.remove('pinnedPlanProgress');
    _prefs?.remove('pinnedPlanData');
    _prefs?.remove('pinnedPlanTasksState');
    
    notifyListeners();
  }

  void clearUserData() {
    unpinPlan();
  }
  
  void updatePinnedProgress(double progress, {String? tasksState}) {
    if (_isPlanPinned) {
      _pinnedPlanProgress = progress;
      _prefs?.setDouble('pinnedPlanProgress', progress);
      if (tasksState != null) {
        _pinnedPlanTasksState = tasksState;
        _prefs?.setString('pinnedPlanTasksState', tasksState);
      }
      notifyListeners();
    }
  }
}
