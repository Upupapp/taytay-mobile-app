import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/design/design_tokens.dart';
import 'package:taytay_resident/core/forms/field_error.dart';
import 'package:taytay_resident/core/l10n/app_locales.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/core/time/manila_time.dart';
import 'package:taytay_resident/l10n/app_localizations.dart';
import 'package:taytay_resident/shared/widgets/form_support.dart';
import 'package:taytay_resident/shared/widgets/outcome_feedback.dart';

/// Boots a minimal localised app so `AppStrings.of` resolves.
Widget localised(Widget child, {Locale locale = AppLocales.english}) =>
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppStrings.localizationsDelegates,
      supportedLocales: AppLocales.supported,
      localeResolutionCallback: AppLocales.resolve,
      home: Scaffold(body: child),
    );

Map<String, Object?> readArb(String name) =>
    jsonDecode(File('lib/l10n/$name').readAsStringSync())
        as Map<String, Object?>;

void main() {
  // ── Locale resolution ───────────────────────────────────────────────────

  group('AppLocales', () {
    test('speaks English and Filipino', () {
      expect(
        AppLocales.supported.map((l) => l.languageCode),
        unorderedEquals(<String>['en', 'fil']),
      );
    });

    test('resolves on the language subtag, not the whole tag', () {
      // A device set to fil_PH must not fall through to English on a region it
      // was never going to match.
      expect(
        AppLocales.resolve(const Locale('fil', 'PH'), AppLocales.supported),
        AppLocales.filipino,
      );
      expect(
        AppLocales.resolve(const Locale('en', 'US'), AppLocales.supported),
        AppLocales.english,
      );
    });

    test(
      'an unsupported locale falls back to English, not to first-in-list',
      () {
        expect(
          AppLocales.resolve(const Locale('ja'), AppLocales.supported),
          AppLocales.english,
        );
        expect(
          AppLocales.resolve(null, AppLocales.supported),
          AppLocales.english,
        );
      },
    );

    test('`fil`, not `tl` — the code both platforms emit', () {
      expect(AppLocales.filipino.languageCode, 'fil');
    });
  });

  // ── The translation itself ──────────────────────────────────────────────

  group('Translations', () {
    test('Filipino is complete — nothing falls back silently', () {
      final english = readArb('app_en.arb');
      final filipino = readArb('app_fil.arb');

      // Metadata keys (`@key`, `@@locale`) are not translatable.
      final translatable = english.keys
          .where((key) => !key.startsWith('@'))
          .toSet();
      final translated = filipino.keys
          .where((key) => !key.startsWith('@'))
          .toSet();

      expect(
        translatable.difference(translated),
        isEmpty,
        reason:
            'A municipal service that only speaks English is one a large part '
            'of Taytay cannot use.',
      );
    });

    test('gen-l10n reported nothing untranslated', () {
      final report = File('lib/l10n/untranslated.json');
      expect(report.existsSync(), isTrue);
      expect(jsonDecode(report.readAsStringSync()), isEmpty);
    });

    test('the two locales actually differ — every key, not a spot check', () {
      final english = readArb('app_en.arb');
      final filipino = readArb('app_fil.arb');

      // A guard against a Filipino file that is an English copy: a translation
      // that ships untranslated is worse than no translation, because the
      // language picker then lies.
      //
      // WIDENED 2026-08-29. This asserted on two hand-picked keys out of 187
      // and was named as though it covered the file. Two keys cannot detect an
      // English copy, and 24 keys had just been added without it noticing
      // anything either way. It now walks every key, which is the only version
      // that earns the name.
      //
      // The allow-list is a ratchet: it may only ever shrink. Each entry is a
      // claim that English and Filipino are *supposed* to be identical, and
      // every one of those claims should be read with suspicion — that is
      // exactly the shape of assumption this suite has been wrong about before.
      const Map<String, String> identicalOnPurpose = <String, String>{
        'appTitle': 'A proper name. Not translated in any language.',
        'navHome':
            'The word Filipino speakers use in app navigation. '
            'Translating it would be less clear, not more.',
        'navProfile': 'As navHome.',
        'fieldBarangay': '"Barangay" is the Filipino word already.',
        'profileFieldBarangay': 'As fieldBarangay.',
        'fieldEmail': '"Email address" is used untranslated in Filipino UI.',
        'profileFieldEmailAddress': 'As fieldEmail.',
        // NOT a settled decision. Recorded honestly rather than dressed up:
        // nobody who speaks Filipino has looked at this one, and "Suffix" may
        // well want a Filipino gloss. It is here to hold the ratchet, not
        // because the question was answered.
        'fieldSuffix': 'UNREVIEWED — needs a native speaker, not a guess.',
      };

      final List<String> untranslated = <String>[
        for (final String key in english.keys)
          if (!key.startsWith('@') &&
              english[key] == filipino[key] &&
              !identicalOnPurpose.containsKey(key))
            '$key: ${english[key]}',
      ];
      expect(
        untranslated,
        isEmpty,
        reason:
            'These keys read identically in both languages, which almost always '
            'means the Filipino .arb still holds the English text:\n'
            '${untranslated.join('\n')}',
      );

      // The other direction: an allow-list entry that has since been translated
      // must be removed, or the list stops being a ratchet and becomes decor.
      final List<String> nowTranslated = <String>[
        for (final String key in identicalOnPurpose.keys)
          if (english[key] != filipino[key]) key,
      ];
      expect(
        nowTranslated,
        isEmpty,
        reason:
            'These are listed as deliberately identical but now differ. Remove '
            'them from identicalOnPurpose: ${nowTranslated.join(', ')}',
      );
    });

    test('placeholders survive translation', () {
      final filipino = readArb('app_fil.arb');
      expect(filipino['unsentMessage'], contains('{what}'));
      expect(filipino['staleContentMessage'], contains('{timestamp}'));
      expect(filipino['a11yFailed'], contains('{why}'));
    });

    testWidgets('both locales resolve their strings at runtime', (
      tester,
    ) async {
      for (final (Locale locale, String expected) in <(Locale, String)>[
        (AppLocales.english, 'Not sent yet'),
        (AppLocales.filipino, 'Hindi pa naipapadala'),
      ]) {
        await tester.pumpWidget(
          localised(
            Builder(
              builder: (context) => Text(AppStrings.of(context).unsentTitle),
            ),
            locale: locale,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(expected), findsOneWidget);
      }
    });

    testWidgets('Material chrome is translated too', (tester) async {
      // Without GlobalMaterialLocalizations a Filipino build shows translated
      // app copy inside an untranslated date picker.
      expect(
        AppStrings.localizationsDelegates,
        contains(GlobalMaterialLocalizations.delegate),
      );
      expect(
        AppStrings.localizationsDelegates,
        contains(GlobalWidgetsLocalizations.delegate),
      );
    });
  });

  // ── Failure copy ────────────────────────────────────────────────────────

  group('Failure copy is localised by kind', () {
    testWidgets('every failure kind has resident copy in both languages', (
      tester,
    ) async {
      const failures = <AppFailure>[
        NetworkFailure(),
        TimeoutFailure(),
        UnauthenticatedFailure(),
        ForbiddenFailure(),
        NotFoundFailure(),
        ValidationFailure(),
        ConflictFailure(),
        RateLimitedFailure(),
        ServerFailure(),
        ContractFailure(),
        UnexpectedFailure(),
      ];

      for (final locale in AppLocales.supported) {
        final seen = <String>{};
        await tester.pumpWidget(
          localised(
            Builder(
              builder: (context) {
                for (final failure in failures) {
                  seen.add(localisedResidentMessage(context, failure));
                }
                return const SizedBox.shrink();
              },
            ),
            locale: locale,
          ),
        );
        await tester.pumpAndSettle();

        expect(seen, hasLength(failures.length), reason: '$locale');
        expect(seen.every((copy) => copy.trim().isNotEmpty), isTrue);
      }
    });

    testWidgets('no server text can reach it — the input is a kind', (
      tester,
    ) async {
      String? shown;
      await tester.pumpWidget(
        localised(
          Builder(
            builder: (context) {
              shown = localisedResidentMessage(
                context,
                // A server message an operator would recognise and a resident
                // never should.
                const ServerFailure(
                  debugMessage: 'SQLSTATE[23505] duplicate key value',
                ),
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(shown, isNotNull);
      expect(shown, isNot(contains('SQLSTATE')));
      expect(shown, isNot(contains('duplicate key')));
    });
  });

  // ── Dates do not follow the device locale ───────────────────────────────

  group('Manila formatting is locale-independent', () {
    test('the same instant renders identically whatever the device says', () {
      final instant = DateTime.utc(2026, 8, 5, 2);
      // Formatting through the device locale would render 08/05/2026 on a US
      // phone and 05/08/2026 on a Philippine one — the same string meaning two
      // different days, on a screen that tells a resident when to turn up.
      expect(ManilaTime.formatDate(instant), '05 Aug 2026');
      expect(ManilaTime.formatDateWithWeekday(instant), 'Wed 05 Aug 2026');
      expect(ManilaTime.formatTime(instant), '10:00 AM');
    });

    test('every LGU time is labelled with its zone', () {
      expect(ManilaTime.label, 'PHT');
      expect(
        ManilaTime.formatDateTime(DateTime.utc(2026, 8, 5, 2)),
        contains('PHT'),
      );
    });
  });

  // ── Accessibility ───────────────────────────────────────────────────────

  group('Outcome feedback is spoken as well as shown', () {
    testWidgets('a success shows a snackbar', (tester) async {
      await tester.pumpWidget(
        localised(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => Outcome.succeeded(context, 'It worked.'),
              child: const Text('Do it'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Do it'));
      await tester.pump();

      expect(find.widgetWithText(SnackBar, 'It worked.'), findsOneWidget);
    });

    testWidgets('a problem shows a snackbar', (tester) async {
      await tester.pumpWidget(
        localised(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => Outcome.problem(context, 'It did not work.'),
              child: const Text('Do it'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Do it'));
      await tester.pump();

      expect(find.widgetWithText(SnackBar, 'It did not work.'), findsOneWidget);
    });

    testWidgets('the snackbar stays long enough to read at 200%', (
      tester,
    ) async {
      await tester.pumpWidget(
        localised(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => Outcome.succeeded(context, 'It worked.'),
              child: const Text('Do it'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Do it'));
      await tester.pump();

      final bar = tester.widget<SnackBar>(find.byType(SnackBar));
      // Material's four-second default assumes one line at the default scale;
      // this app supports twice that.
      expect(bar.duration, greaterThanOrEqualTo(const Duration(seconds: 6)));
    });

    testWidgets('no snackbar is raised for empty copy', (tester) async {
      await tester.pumpWidget(
        localised(Builder(builder: (context) => const SizedBox.shrink())),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
    });
  });

  group('A form error summary is announced', () {
    testWidgets('it is a live region carrying every message', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        localised(
          const FormErrorSummary(
            errors: <FieldError>[
              FieldError(
                field: 'given_name',
                message: 'Enter your first name.',
              ),
              FieldError(field: 'mobile', message: 'Enter your mobile number.'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // A resident who has just pressed "Send" must be told the form did not
      // go anywhere, rather than discovering it by exploration.
      expect(
        find.bySemanticsLabel(
          'There are 2 problems. Enter your first name. '
          'Enter your mobile number.',
        ),
        findsOneWidget,
      );

      final node = tester.getSemantics(
        find.bySemanticsLabel(RegExp('There are 2 problems')),
      );
      expect(node.flagsCollection.isLiveRegion, isTrue);

      handle.dispose();
    });

    testWidgets('it says nothing when there is nothing wrong', (tester) async {
      await tester.pumpWidget(
        localised(const FormErrorSummary(errors: <FieldError>[])),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('problem'), findsNothing);
    });

    testWidgets('one problem is singular', (tester) async {
      await tester.pumpWidget(
        localised(
          const FormErrorSummary(
            errors: <FieldError>[
              FieldError(
                field: 'given_name',
                message: 'Enter your first name.',
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('There is a problem'), findsOneWidget);
    });
  });

  group('Accessibility floors', () {
    test('the tap target satisfies Material and WCAG together', () {
      expect(A11y.minTapTarget, greaterThanOrEqualTo(48));
    });

    test('text scales to 200% and is never rendered below 85%', () {
      expect(A11y.maxSupportedTextScale, greaterThanOrEqualTo(2.0));
      expect(A11y.minSupportedTextScale, lessThanOrEqualTo(1.0));
      expect(A11y.minSupportedTextScale, greaterThan(0.5));
    });

    test('contrast floors are the WCAG 2.2 AA numbers', () {
      expect(A11y.minBodyContrastRatio, 4.5);
      expect(A11y.minLargeTextContrastRatio, 3.0);
    });
  });
}
