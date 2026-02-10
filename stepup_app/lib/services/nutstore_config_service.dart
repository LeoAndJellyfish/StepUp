import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:shared_preferences/shared_preferences.dart';

/// 坚果云配置服务
/// 管理坚果云 WebDAV 的连接配置
class NutstoreConfigService {
  static const String _keyServerUrl = 'nutstore_server_url';
  static const String _keyUsername = 'nutstore_username';
  static const String _keyPassword = 'nutstore_password';
  static const String _keyEnabled = 'nutstore_enabled';
  static const String _keyLastBackupTime = 'nutstore_last_backup_time';
  static const String _keyAutoBackup = 'nutstore_auto_backup';

  // 加密密钥（用于加密存储密码）- 必须是32字节
  static final _encryptionKey = encrypt.Key.fromUtf8('StepUpNutstoreBackupKey32Bytes1!');
  static final _iv = encrypt.IV.fromLength(16);

  late encrypt.Encrypter _encrypter;
  SharedPreferences? _prefs;

  NutstoreConfigService() {
    _encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey));
  }

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// 获取默认服务器地址（坚果云 WebDAV）
  String getDefaultServerUrl() {
    return 'https://dav.jianguoyun.com/dav/';
  }

  /// 保存服务器地址
  Future<void> setServerUrl(String url) async {
    final prefs = await _preferences;
    await prefs.setString(_keyServerUrl, url);
  }

  /// 获取服务器地址
  Future<String?> getServerUrl() async {
    final prefs = await _preferences;
    return prefs.getString(_keyServerUrl) ?? getDefaultServerUrl();
  }

  /// 保存用户名
  Future<void> setUsername(String username) async {
    final prefs = await _preferences;
    await prefs.setString(_keyUsername, username);
  }

  /// 获取用户名
  Future<String?> getUsername() async {
    final prefs = await _preferences;
    return prefs.getString(_keyUsername);
  }

  /// 保存密码（加密存储）
  Future<void> setPassword(String password) async {
    final prefs = await _preferences;
    final encrypted = _encrypter.encrypt(password, iv: _iv);
    await prefs.setString(_keyPassword, encrypted.base64);
  }

  /// 获取密码（解密）
  Future<String?> getPassword() async {
    final prefs = await _preferences;
    final encryptedBase64 = prefs.getString(_keyPassword);
    if (encryptedBase64 == null || encryptedBase64.isEmpty) {
      return null;
    }
    try {
      final encrypted = encrypt.Encrypted.fromBase64(encryptedBase64);
      return _encrypter.decrypt(encrypted, iv: _iv);
    } catch (e) {
      return null;
    }
  }

  /// 设置是否启用坚果云备份
  Future<void> setEnabled(bool enabled) async {
    final prefs = await _preferences;
    await prefs.setBool(_keyEnabled, enabled);
  }

  /// 获取是否启用坚果云备份
  Future<bool> isEnabled() async {
    final prefs = await _preferences;
    return prefs.getBool(_keyEnabled) ?? false;
  }

  /// 设置是否自动备份
  Future<void> setAutoBackup(bool autoBackup) async {
    final prefs = await _preferences;
    await prefs.setBool(_keyAutoBackup, autoBackup);
  }

  /// 获取是否自动备份
  Future<bool> isAutoBackup() async {
    final prefs = await _preferences;
    return prefs.getBool(_keyAutoBackup) ?? false;
  }

  /// 保存最后备份时间
  Future<void> setLastBackupTime(DateTime time) async {
    final prefs = await _preferences;
    await prefs.setInt(_keyLastBackupTime, time.millisecondsSinceEpoch);
  }

  /// 获取最后备份时间
  Future<DateTime?> getLastBackupTime() async {
    final prefs = await _preferences;
    final timestamp = prefs.getInt(_keyLastBackupTime);
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  /// 检查配置是否完整
  Future<bool> isConfigured() async {
    final username = await getUsername();
    final password = await getPassword();
    return username != null &&
        username.isNotEmpty &&
        password != null &&
        password.isNotEmpty;
  }

  /// 清除所有配置
  Future<void> clearConfig() async {
    final prefs = await _preferences;
    await prefs.remove(_keyServerUrl);
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyPassword);
    await prefs.remove(_keyEnabled);
    await prefs.remove(_keyLastBackupTime);
    await prefs.remove(_keyAutoBackup);
  }

  /// 获取配置信息（不包含密码）
  Future<Map<String, dynamic>> getConfigInfo() async {
    return {
      'serverUrl': await getServerUrl(),
      'username': await getUsername(),
      'enabled': await isEnabled(),
      'autoBackup': await isAutoBackup(),
      'lastBackupTime': (await getLastBackupTime())?.toIso8601String(),
      'isConfigured': await isConfigured(),
    };
  }
}
