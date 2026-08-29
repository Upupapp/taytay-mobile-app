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
import 'package:taytay_resident/features/household/domain/household_summary.dart';
import 'package:taytay_resident/features/news/domain/post_interaction.dart';
import 'package:taytay_resident/features/notifications/domain/notification_repository.dart';
import 'package:taytay_resident/features/notifications/presentation/notification_inbox_controller.dart';
import 'package:taytay_resident/features/services/domain/lgu_service.dart';
import 'package:taytay_resident/features/verification/domain/verification_status_detail.dart';
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

  group('the locked view is Filipino end to end', () {
    testWidgets('heading, explanation and both actions', (tester) async {
      await pump(
        tester,
        const CapabilityLockedView(
          capability: ResidentCapability.holdDigitalId,
          verdict: CapabilityNeedsVerification(),
        ),
        locale: AppLocales.filipino,
      );

      // Heading, message and buttons all came from the .arb, so a resident sees
      // one language rather than a Filipino headline over English controls.
      expect(find.text('Magkaroon ng iyong Taytay digital ID'), findsOneWidget);
      expect(
        find.text(
          'Kailangang kumpirmahin ng Taytay LGU ang iyong pagkakakilanlan '
          'bago mo ito magamit.',
        ),
        findsOneWidget,
      );
      expect(find.text('I-verify ang aking pagkakakilanlan'), findsOneWidget);
      expect(find.text('Bumalik sa Home'), findsOneWidget);

      // And none of the English fallbacks leaked through.
      for (final String english in <String>[
        'Hold your Taytay digital ID',
        'Verify my identity',
        'Back to Home',
        CapabilityService.explain(const CapabilityNeedsVerification()),
      ]) {
        expect(
          find.text(english),
          findsNothing,
          reason: '"$english" is the no-context fallback and must not render.',
        );
      }
    });

    testWidgets('every verdict has a Filipino explanation and action', (
      tester,
    ) async {
      const verdicts = <CapabilityVerdict>[
        CapabilityNeedsSignIn(),
        CapabilityNeedsVerification(),
        CapabilityNotYetAvailable(),
      ];
      for (final verdict in verdicts) {
        late String explanation;
        late String action;
        late String? requirement;
        await pump(
          tester,
          Builder(
            builder: (context) {
              explanation = capabilityExplanation(context, verdict);
              action = capabilityActionLabel(context, verdict);
              requirement = capabilityRequirementLabel(context, verdict);
              return const SizedBox.shrink();
            },
          ),
          locale: AppLocales.filipino,
        );
        expect(explanation, isNot(CapabilityService.explain(verdict)));
        expect(requirement, isNot(CapabilityService.requirementLabel(verdict)));
        expect(explanation, isNotEmpty);
        expect(action, isNotEmpty);
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

  group('verification stage actions', () {
    testWidgets('are Filipino, and still null where there is nothing to press', (
      tester,
    ) async {
      final labels = <ResidentVerificationStage, String?>{};
      await pump(
        tester,
        Builder(
          builder: (context) {
            for (final stage in ResidentVerificationStage.values) {
              labels[stage] = verificationStageActionLabel(context, stage);
            }
            return const SizedBox.shrink();
          },
        ),
        locale: AppLocales.filipino,
      );

      // The null cases are the point: a stage with nothing to do must not grow
      // a button just because it now has a localiser.
      for (final stage in ResidentVerificationStage.values) {
        expect(
          labels[stage] == null,
          stage.nextActionLabel == null,
          reason:
              '${stage.name} disagrees with the fallback about whether '
              'there is an action.',
        );
        if (labels[stage] != null) {
          expect(labels[stage], isNot(stage.nextActionLabel));
        }
      }
      expect(
        labels[ResidentVerificationStage.notStarted],
        'Simulan ang verification',
      );
    });
  });

  group('the last five enums', () {
    testWidgets('every constant returns Filipino, not the English fallback', (
      tester,
    ) async {
      // The other three guards cover the other three failure modes: the
      // classification guard proves a localiser exists, the .arb ratchet proves
      // every key is translated, and the raw-render guard proves screens call
      // the localiser. None of them can catch a localiser wired to the WRONG
      // key — only reading the output can.
      final wrong = <String>[];
      await pump(
        tester,
        Builder(
          builder: (context) {
            final strings = AppStrings.of(context);
            for (final kind in HouseholdCorrectionKind.values) {
              final copy = householdCorrectionCopy(context, kind);
              if (copy.label == kind.label) wrong.add('${kind.name}.label');
              if (copy.description == kind.description) {
                wrong.add('${kind.name}.description');
              }
            }
            for (final role in HouseholdRole.values) {
              if (householdRoleLabel(context, role) == role.label) {
                wrong.add('${role.name}.label');
              }
            }
            for (final reason in ReportReason.values) {
              final copy = reportReasonCopy(context, reason);
              if (copy.label == reason.label) wrong.add('${reason.name}.label');
              if (copy.description == reason.description) {
                wrong.add('${reason.name}.description');
              }
            }
            for (final category in NotificationCategory.values) {
              if (notificationCategoryLabel(context, category) ==
                  category.label) {
                wrong.add('${category.name}.label');
              }
            }
            for (final group in InboxGroup.values) {
              if (group.labelIn(strings) == group.label) {
                wrong.add('${group.name}.label');
              }
            }
            return const SizedBox.shrink();
          },
        ),
        locale: AppLocales.filipino,
      );

      expect(
        wrong,
        isEmpty,
        reason:
            'These returned the English constant on a Filipino device, '
            'which means the localiser is missing them or mapped to the wrong '
            'key: ${wrong.join(', ')}',
      );
    });

    testWidgets('and the copy is the copy it should be', (tester) async {
      // Spot checks against a mis-mapped switch: a localiser can return
      // Filipino and still return the WRONG Filipino, which nothing above
      // detects. One representative per enum.
      late String correction;
      late String role;
      late String reason;
      late String category;
      late String group;
      await pump(
        tester,
        Builder(
          builder: (context) {
            correction = householdCorrectionCopy(
              context,
              HouseholdCorrectionKind.notMyHousehold,
            ).label;
            role = householdRoleLabel(context, HouseholdRole.head);
            reason = reportReasonCopy(context, ReportReason.spam).label;
            category = notificationCategoryLabel(
              context,
              NotificationCategory.accountSecurity,
            );
            group = InboxGroup.thisWeek.labelIn(AppStrings.of(context));
            return const SizedBox.shrink();
          },
        ),
        locale: AppLocales.filipino,
      );

      expect(correction, 'Hindi ito ang aking sambahayan');
      expect(role, 'Puno ng sambahayan');
      expect(reason, 'Spam o patalastas');
      expect(category, 'Account at seguridad');
      expect(group, 'Mas maaga ngayong linggo');
    });
  });

  group('service categories', () {
    testWidgets('read as names, not as the backend\'s codes', (tester) async {
      final labels = <ServiceCategory, String>{};
      await pump(
        tester,
        Builder(
          builder: (context) {
            for (final category in ServiceCategory.values) {
              labels[category] = serviceCategoryLabel(context, category);
            }
            return const SizedBox.shrink();
          },
        ),
        locale: AppLocales.filipino,
      );

      for (final category in ServiceCategory.values) {
        expect(
          labels[category],
          isNot(category.wireValue),
          reason:
              '${category.name} still reads as its wire code. Four of these '
              'are Filipino words by coincidence, which is how the original '
              'defect survived — so this compares against the code itself, '
              'not against whether the result looks Filipino.',
        );
      }
      expect(labels[ServiceCategory.ids], 'Pagkakakilanlan');
      expect(labels[ServiceCategory.national], 'Mga serbisyong pambansa');
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
