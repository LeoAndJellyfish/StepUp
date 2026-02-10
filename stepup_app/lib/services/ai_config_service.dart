import 'dart:convert';
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

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// 获取 API Key
  Future<String?> getApiKey() async {
    await init();
    return _prefs?.getString(_apiKeyKey);
  }

  /// 设置 API Key
  Future<bool> setApiKey(String apiKey) async {
    await init();
    return await _prefs?.setString(_apiKeyKey, apiKey) ?? false;
  }

  /// 清除 API Key
  Future<bool> clearApiKey() async {
    await init();
    return await _prefs?.remove(_apiKeyKey) ?? false;
  }

  /// 获取 Base URL
  Future<String> getBaseUrl() async {
    await init();
    return _prefs?.getString(_baseUrlKey) ?? _defaultBaseUrl;
  }

  /// 设置 Base URL
  Future<bool> setBaseUrl(String baseUrl) async {
    await init();
    return await _prefs?.setString(_baseUrlKey, baseUrl) ?? false;
  }

  /// 检查是否启用 AI 分类
  Future<bool> isEnabled() async {
    await init();
    return _prefs?.getBool(_enabledKey) ?? true;
  }

  /// 设置是否启用 AI 分类
  Future<bool> setEnabled(bool enabled) async {
    await init();
    return await _prefs?.setBool(_enabledKey, enabled) ?? false;
  }

  /// 检查是否已配置 API Key
  Future<bool> isConfigured() async {
    final apiKey = await getApiKey();
    return apiKey != null && apiKey.isNotEmpty;
  }
}
