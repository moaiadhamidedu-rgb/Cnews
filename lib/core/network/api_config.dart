import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  ApiConfig._();

  static const _preferenceKey = 'apiBaseUrl';
  static const _configuredBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const _hostedBaseUrl =
      'https://currency-tracker-backend.currency-tracker-backend.workers.dev/api/v1';

  static String? _savedBaseUrl;

  /// Loads the URL selected by the user. Call this once before creating any
  /// services, including from background isolates.
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedValue = prefs.getString(_preferenceKey);
    if (savedValue == null || savedValue.trim().isEmpty) {
      _savedBaseUrl = null;
      return;
    }

    try {
      _savedBaseUrl = normalizeBaseUrl(savedValue);
    } on FormatException {
      await prefs.remove(_preferenceKey);
      _savedBaseUrl = null;
    }
  }

  static String get baseUrl {
    if (_savedBaseUrl != null) return _savedBaseUrl!;

    if (_configuredBaseUrl.trim().isNotEmpty) {
      return normalizeBaseUrl(_configuredBaseUrl);
    }

    return _hostedBaseUrl;
  }

  /// Prediction endpoints live under `/api`, while the rates API uses
  /// `/api/v1`. Both are derived from the same centrally configured server.
  static String get serverOrigin {
    final uri = Uri.parse(baseUrl);
    final segments = [...uri.pathSegments];
    if (segments.length >= 2 &&
        segments[segments.length - 2] == 'api' &&
        segments.last == 'v1') {
      segments.removeRange(segments.length - 2, segments.length);
    }
    return uri
        .replace(pathSegments: segments)
        .toString()
        .replaceFirst(RegExp(r'/$'), '');
  }

  static bool get hasSavedOverride => _savedBaseUrl != null;

  static Future<void> setBaseUrl(String value) async {
    final normalized = normalizeBaseUrl(value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_preferenceKey, normalized);
    _savedBaseUrl = normalized;
  }

  static Future<void> resetBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_preferenceKey);
    _savedBaseUrl = null;
  }

  /// Accepts either the server origin or the full API base URL. When only an
  /// origin is pasted, `/api/v1` is appended automatically.
  static String normalizeBaseUrl(String value) {
    var normalized = value.trim();
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }

    final uri = Uri.tryParse(normalized);
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        uri.userInfo.isNotEmpty) {
      throw const FormatException('Invalid Backend URL');
    }

    if (uri.path.isEmpty || uri.path == '/') {
      normalized = '$normalized/api/v1';
    }

    return normalized;
  }
}
