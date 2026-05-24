import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linthra/data/repositories/download_repository_provider.dart';
import 'package:linthra/data/repositories/in_memory_download_preferences.dart';
import 'package:linthra/features/downloads/download_providers.dart';
import 'package:linthra/features/settings/precache/precache_settings_section.dart';

void main() {
  group('PrecacheSettingsSection', () {
    late InMemoryDownloadPreferences preferences;

    Future<ProviderContainer> pump(WidgetTester tester) async {
      preferences = InMemoryDownloadPreferences();
      final container = ProviderContainer(
        overrides: [
          downloadPreferencesProvider.overrideWithValue(preferences),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: PrecacheSettingsSection()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets('shows the smart pre-cache copy and controls', (tester) async {
      await pump(tester);

      expect(find.text('Smart pre-cache'), findsOneWidget);
      expect(find.text('Pre-cache upcoming tracks'), findsOneWidget);
      expect(find.text('Upcoming tracks to cache'), findsOneWidget);
      // The automatic/evictable vs. Keep offline (protected) distinction.
      expect(find.textContaining('removed automatically'), findsWidgets);
      expect(find.textContaining('Keep offline'), findsOneWidget);
      // The count options render, with the default (3) selected.
      for (final String label in <String>['1', '3', '5', '10']) {
        expect(find.text(label), findsOneWidget);
      }
    });

    testWidgets('toggling smart pre-cache off persists the choice',
        (tester) async {
      final container = await pump(tester);
      expect(await preferences.preloadEnabled(), isTrue);

      await tester.tap(find.text('Pre-cache upcoming tracks'));
      await tester.pumpAndSettle();

      expect(await preferences.preloadEnabled(), isFalse);
      expect(container.read(smartPrecacheEnabledProvider).valueOrNull, isFalse);
    });

    testWidgets('choosing a different count persists the new value',
        (tester) async {
      final container = await pump(tester);
      expect(await preferences.precacheCount(), 3);

      await tester.tap(find.text('10'));
      await tester.pumpAndSettle();

      expect(await preferences.precacheCount(), 10);
      expect(container.read(precacheCountProvider).valueOrNull, 10);
    });

    testWidgets('the count selector is inert while pre-cache is off',
        (tester) async {
      await pump(tester);

      // Turn smart pre-cache off, then try to change the count.
      await tester.tap(find.text('Pre-cache upcoming tracks'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('10'));
      await tester.pumpAndSettle();

      // The selector is disabled, so the count is unchanged.
      expect(await preferences.precacheCount(), 3);
    });
  });
}
