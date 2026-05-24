import 'package:flutter_test/flutter_test.dart';
import 'package:linthra/core/repositories/download_preferences.dart';
import 'package:linthra/data/repositories/in_memory_download_preferences.dart';
import 'package:linthra/data/repositories/shared_preferences_download_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('sanitizePrecacheCount', () {
    test('passes through an offered count', () {
      for (final int option in kPrecacheCountOptions) {
        expect(sanitizePrecacheCount(option), option);
      }
    });

    test('falls back to the default for an unoffered or junk value', () {
      expect(sanitizePrecacheCount(2), kDefaultPrecacheCount);
      expect(sanitizePrecacheCount(0), kDefaultPrecacheCount);
      expect(sanitizePrecacheCount(-5), kDefaultPrecacheCount);
      expect(sanitizePrecacheCount(9999), kDefaultPrecacheCount);
    });
  });

  group('precacheCount preference', () {
    test('in-memory defaults to the default and round-trips an offered value',
        () async {
      final prefs = InMemoryDownloadPreferences();
      expect(await prefs.precacheCount(), kDefaultPrecacheCount);

      await prefs.setPrecacheCount(10);
      expect(await prefs.precacheCount(), 10);
    });

    test('in-memory clamps an unoffered value to the default', () async {
      final prefs = InMemoryDownloadPreferences(precacheCount: 7);
      expect(await prefs.precacheCount(), kDefaultPrecacheCount);

      await prefs.setPrecacheCount(4);
      expect(await prefs.precacheCount(), kDefaultPrecacheCount);
    });

    group('shared_preferences', () {
      setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

      test('defaults to the default when never set', () async {
        const prefs = SharedPreferencesDownloadPreferences();
        expect(await prefs.precacheCount(), kDefaultPrecacheCount);
      });

      test('persists an offered count across instances', () async {
        const prefs = SharedPreferencesDownloadPreferences();
        await prefs.setPrecacheCount(5);

        const reopened = SharedPreferencesDownloadPreferences();
        expect(await reopened.precacheCount(), 5);
      });

      test('sanitizes an out-of-range stored value on read', () async {
        // Simulate a value written outside the offered set.
        SharedPreferences.setMockInitialValues(<String, Object>{
          'downloads_precache_count': 42,
        });
        const prefs = SharedPreferencesDownloadPreferences();
        expect(await prefs.precacheCount(), kDefaultPrecacheCount);
      });
    });
  });
}
