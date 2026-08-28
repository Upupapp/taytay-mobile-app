import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/documents/document_capture.dart';
import 'package:taytay_resident/core/intent/resident_intent.dart';
import 'package:taytay_resident/core/l10n/app_locales.dart';
import 'package:taytay_resident/core/session/local_authenticator.dart';
import 'package:taytay_resident/core/session/resident_capability.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';
import 'package:taytay_resident/l10n/app_localizations.dart';
import 'package:taytay_resident/shared/widgets/capability_gate.dart';

/// Proves the gate copy a resident reads is actually in their language.
///
/// ## Why a coverage guard was not enough
///
/// `test/core/resident_copy_localisation_test.dart` requires every copy-bearing
/// enum to be *classified*. That catches an enum nobody has thought about. It
/// cannot catch an enum classified **wrongly** — and on 2026-08-28 three of the
/// four entries in its `notResidentFacing` list turned out to be wrong, each one
/// asserting that a string could not reach a screen while it was rendering on
/// twelve of them. Every one of those claims was written by reading code.
///
/// So this file does the other thing: it pumps the real widget in Filipino and
/// looks at what came out. A claim about where a string goes is worth exactly as
/// much as the render that confirms it, and `CapabilityGate` — mounted on twelve
/// screens — had no test of any kind before this one.
void main() {
  Future<AppDependencies> deps() async {
    final secrets = InMemorySecretStore();
    final sessionStore = InMemorySessionStore();
    return AppDependencies.build(
      config: AppConfig.from(
        rawEnvironment: 'dev',
        rawApiBaseUrl: 'https://example.test/api/v1',
        isReleaseBuild: false,
      ),
      secrets: secrets,
      sessionStore: sessionStore,
      localAuthenticator: const UnavailableLocalAuthenticator(),
    );
  }

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    required Locale locale,
  }) async {
    final dependencies = await deps();
    await tester.pumpWidget(
      AppDependenciesScope(
        dependencies: dependencies,
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppStrings.localizationsDelegates,
          supportedLocales: AppLocales.supported,
          localeResolutionCallback: AppLocales.resolve,
          home: Scaffold(body: child),
        ),
      ),
    );
    await tester.pump();
  }

  group('CapabilityGate heading', () {
    testWidgets('renders the capability name in Filipino', (tester) async {
      await pump(
        tester,
        const CapabilityLockedView(
          capability: ResidentCapability.viewHouseholdSummary,
          verdict: CapabilityNeedsSignIn(),
        ),
        locale: AppLocales.filipino,
      );

      expect(find.text('Tingnan ang buod ng iyong sambahayan'), findsOneWidget);
      // The English constant is the fallback, not the render.
      expect(find.text('See your household summary'), findsNothing);
    });

    testWidgets('still renders English on an English device', (tester) async {
      await pump(
        tester,
        const CapabilityLockedView(
          capability: ResidentCapability.viewHouseholdSummary,
          verdict: CapabilityNeedsSignIn(),
        ),
        locale: AppLocales.english,
      );

      expect(find.text('See your household summary'), findsOneWidget);
    });

    testWidgets('every capability has a Filipino heading that differs from '
        'its English one', (tester) async {
      // A missing translation in an .arb shows up as the English string, which
      // reads as "working" on screen. Comparing the two renders is the only way
      // to see it.
      for (final capability in ResidentCapability.values) {
        final rendered = <Locale, String>{};
        for (final locale in <Locale>[
          AppLocales.english,
          AppLocales.filipino,
        ]) {
          late String seen;
          await pump(
            tester,
            Builder(
              builder: (context) {
                seen = capabilityLabel(context, capability);
                return const SizedBox.shrink();
              },
            ),
            locale: locale,
          );
          rendered[locale] = seen;
        }
        expect(
          rendered[AppLocales.filipino],
          isNot(equals(rendered[AppLocales.english])),
          reason:
              '${capability.name} reads the same in both languages — its '
              'Filipino .arb entry is probably still the English text.',
        );
      }
    });
  });

  group('gate sheet sentences', () {
    testWidgets('are whole Filipino sentences, not an English fragment inside '
        'a Filipino frame', (tester) async {
      for (final intent in ResidentIntentKind.values) {
        late String signIn;
        late String verify;
        await pump(
          tester,
          Builder(
            builder: (context) {
              signIn = gateSignInMessage(context, intent);
              verify = gateVerificationMessage(context, intent);
              return const SizedBox.shrink();
            },
          ),
          locale: AppLocales.filipino,
        );

        // The old code interpolated `intent.description`, a lower-case English
        // verb phrase, into the sentence. If anything ever does that again the
        // fragment lands here verbatim.
        expect(
          signIn,
          isNot(contains(intent.description)),
          reason:
              'The Filipino sign-in gate for ${intent.name} still contains the '
              'English fragment "${intent.description}".',
        );
        expect(
          verify,
          isNot(contains(intent.description)),
          reason:
              'The Filipino verification gate for ${intent.name} still contains '
              'the English fragment "${intent.description}".',
        );
        expect(signIn, startsWith('Kailangan mo ng Taytay LGU account'));
        expect(verify, startsWith('Kailangang kumpirmahin ng Taytay LGU'));
      }
    });
  });

  group('upload buttons', () {
    testWidgets('are labelled in Filipino', (tester) async {
      final labels = <String>[];
      await pump(
        tester,
        Builder(
          builder: (context) {
            for (final source in DocumentSource.values) {
              labels.add(documentSourceLabel(context, source));
            }
            return const SizedBox.shrink();
          },
        ),
        locale: AppLocales.filipino,
      );

      expect(labels, <String>[
        'Kumuha ng larawan',
        'Pumili ng larawan',
        'Pumili ng file',
      ]);
      for (final source in DocumentSource.values) {
        expect(labels, isNot(contains(source.label)));
      }
    });
  });
}
