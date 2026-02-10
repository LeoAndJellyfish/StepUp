import 'package:shared_preferences/shared_preferences.dart';

/// AI 配置服务
class AIConfigService {
  static const String _apiKeyKey = 'deepseek_api_key';
  static const String _baseUrlKey = 'deepseek_base_url';
  static const String _enabledKey = 'ai_classification_enabled';
  static const String _defaultBaseUrl = 'https://api.deepseek.com';

  static final AIConfigService _instance = AIConfigService._internal();
  factory AIConfigService() => _instance;
  AIConfigService._internal();

  SharedPreferences? _prefs;
  bool _isInitialized = false;

  Future<void> init() async {
    if (!_isInitialized) {
      try {
        _prefs = await SharedPreferences.getInstance();
        _isInitialized = true;
      } catch (e) {
        _isInitialized = false;
        rethrow;
      }
    }
  }

  /// 获取 API Key
  Future<String?> getApiKey() async {
    try {
      await init();
      return _prefs?.getString(_apiKeyKey);
    } catch (e) {
      return null;
    }
  }

  /// 设置 API Key
  Future<bool> setApiKey(String apiKey) async {
    try {
      await init();
      if (_prefs == null) return false;
      return await _prefs!.setString(_apiKeyKey, apiKey);
    } catch (e) {
      return false;
    }
  }

  /// 清除 API Key
  Future<bool> clearApiKey() async {
    try {
      await init();
      if (_prefs == null) return false;
      return await _prefs!.remove(_apiKeyKey);
    } catch (e) {
      return false;
    }
  }

  /// 获取 Base URL
  Future<String> getBaseUrl() async {
    try {
      await init();
      final url = _prefs?.getString(_baseUrlKey);
      if (url != null && url.isNotEmpty) {
        return url;
      }
      return _defaultBaseUrl;
    } catch (e) {
      return _defaultBaseUrl;
    }
  }

  /// 设置 Base URL
  Future<bool> setBaseUrl(String baseUrl) async {
    try {
      await init();
      if (_prefs == null) return false;
      if (baseUrl.isEmpty) {
        return await _prefs!.remove(_baseUrlKey);
      }
      return await _prefs!.setString(_baseUrlKey, baseUrl);
    } catch (e) {
      return false;
    }
  }

  /// 检查是否启用 AI 分类
  Future<bool> isEnabled() async {
    try {
      await init();
      return _prefs?.getBool(_enabledKey) ?? true;
    } catch (e) {
      return true;
    }
  }

  /// 设置是否启用 AI 分类
  Future<bool> setEnabled(bool enabled) async {
    try {
      await init();
      if (_prefs == null) return false;
      return await _prefs!.setBool(_enabledKey, enabled);
    } catch (e) {
      return false;
    }
  }

  /// 检查是否已配置 API Key
  Future<bool> isConfigured() async {
    try {
      final apiKey = await getApiKey();
      return apiKey != null && apiKey.trim().isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
