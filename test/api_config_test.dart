import 'package:flutter_test/flutter_test.dart';
import 'package:mpcurrencytracker/core/network/api_config.dart';

void main() {
  group('ApiConfig.normalizeBaseUrl', () {
    test('appends the API path to a server origin', () {
      expect(
        ApiConfig.normalizeBaseUrl('https://backend.example.com/'),
        'https://backend.example.com/api/v1',
      );
    });

    test('keeps a complete API base URL and removes trailing slashes', () {
      expect(
        ApiConfig.normalizeBaseUrl(
          ' https://backend.example.com/custom/api/v1/// ',
        ),
        'https://backend.example.com/custom/api/v1',
      );
    });

    test('rejects an invalid or unsafe URL', () {
      expect(
        () => ApiConfig.normalizeBaseUrl('backend.example.com'),
        throwsFormatException,
      );
      expect(
        () => ApiConfig.normalizeBaseUrl(
          'https://backend.example.com/api/v1?token=secret',
        ),
        throwsFormatException,
      );
    });
  });

  test('derives non-v1 endpoints from the same server origin', () {
    expect(ApiConfig.serverOrigin, isNot(contains('/api/v1/api/')));
  });
}
