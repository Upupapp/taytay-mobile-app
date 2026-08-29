import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every enum that holds resident-facing copy must be classified.
///
/// ## Why this is a coverage guard and not a render-site scan
///
/// The obvious check is "no `presentation/` file renders a raw `.label`". It
/// cannot be written honestly: Dart tests have no type information here, so the
/// scan has to guess from variable names, and `.label` also belongs to
/// `NavigationDestination`, `InputDecoration` and half of Material. An ad-hoc
/// version of that scan was written during the sweep that produced this file and
/// reported every enum as rendered in thirty files — a result so loose it was
/// discarded rather than acted on.
///
/// So the question is inverted. Rather than hunting renders, every enum carrying
/// resident-facing copy must appear in exactly one of the two lists below, and a
/// new one fails the suite until somebody decides which. That cannot be defeated
/// by a variable name, and it forces the decision at the moment the enum is
/// written rather than eight months later when a resident reads English on a
/// Filipino screen.
///
/// ## How this problem was found
///
/// `ResidentProfileField` carried English labels as enum constants and the
/// profile screen rendered them directly, so the one surface where a resident
/// reads their own government record did not translate while the rest of the app
/// did. `ResidentVerificationStage` was worse: its label is the **headline** of
/// the verification screen, the sentence by which somebody learns whether they
/// can hold a digital ID.
///
/// Both were found by reading code, not by any test failing. This is that test.
void main() {
  /// Fields whose value a resident could plausibly read.
  const Set<String> copyFields = <String>{
    'label',
    'title',
    'description',
    'summary',
    'explanation',
    'sectionTitle',
    'sectionExplanation',
    'residentMessage',
    'hint',
    'instruction',
    // Added 2026-08-29. Its absence is why `ResidentVerificationStage`'s button
    // label rendered untranslated on two screens with no guard objecting: the
    // enum was correctly listed as localised, so this file was satisfied, and
    // the field holding the copy was not in the list it checks.
    'nextActionLabel',
  };

  /// Enums whose copy reaches a resident and therefore has a localiser.
  ///
  /// Each of these has either a function in `core/l10n/app_locales.dart` or an
  /// `...In(BuildContext)` accessor of its own, with the English constant kept
  /// as the no-context fallback.
  const Set<String> localised = <String>{
    'ShellDestination', // labelIn(), the pattern the others follow
    'ResidentProfileField', // profileFieldLabel / profileFieldHint
    'FieldOwnership', // profileSectionCopy
    'ResidentVerificationStage', // verificationStageCopy
    'KycDocumentType', // kycDocumentCopy
    'DocumentRejection', // localisedDocumentRejection
    // Moved here from `notResidentFacing` on 2026-08-28. All three were claims
    // that the copy could not reach a screen, and all three were false — see the
    // block below for what each one actually rendered.
    'ResidentCapability', // capabilityLabel
    'ResidentIntentKind', // gateSignInMessage / gateVerificationMessage
    'DocumentSource', // documentSourceLabel
  };

  /// Enums whose copy a resident never reads, each with the reason.
  ///
  /// **Not a backlog.** An entry here is a claim that the string cannot reach a
  /// screen, and it is wrong the moment somebody renders it.
  const Map<String, String> notResidentFacing = <String, String>{
    // CORRECTED 2026-08-28. This list had four entries. Three were wrong, and
    // the fourth was right for the wrong reason. They are recorded rather than
    // quietly deleted, because the failure is the interesting part: every one
    // was written by reading the enum's own doc comment instead of following
    // the value to a widget, and every error pointed the same way — towards
    // less work.
    //
    //  * `ResidentCapability` — WRONG. `capability_gate.dart:111` passes the
    //    label to `StatusView(title:)`, rendered at `titleMedium`, and
    //    `CapabilityGate` is mounted on twelve screens. The claim said the gate
    //    sheet composed its own sentence; the gate sheet is a different widget.
    //  * `ResidentIntentKind` — WRONG. The description is interpolated into
    //    both gate sheets (`access_gate_sheet.dart:147` and `:190`). The claim
    //    called it diagnostic because the doc comment did.
    //  * `DocumentSource` — WRONG. `requirements_screen.dart:478` passes the
    //    label to `AppButton(label:)`. The enum's own field comment reads
    //    "Resident-facing action label", one line under the field, so the claim
    //    contradicted the source it described.
    //
    // All three now have localisers and sit in `localised` above.
    'ServiceCategoryIcon':
        'Right conclusion, wrong reason — and the reason matters. The label '
        'does NOT pick a glyph (`icon` does); it is the semantic name a '
        'screen reader announces, which is resident-facing in the sense '
        'that counts most. It stays here only because `FeatureIcon` has no '
        'production caller at all: both `FeatureIcon.category` and '
        '`.categoryCode` are constructed solely from '
        '`test/shared/illustrations_test.dart`. That is a weaker guarantee '
        'than the old reason claimed and a defect signal in its own right — '
        'a category-icon widget was built and never mounted. Localise this '
        'the moment anything renders it.',
  };

  /// Enums that reach a resident and are **not** localised yet, each with what
  /// it costs. This list must only ever shrink.
  const Map<String, String> knownUntranslated = <String, String>{
    // CORRECTED. These two were first recorded as the worst on this list, on
    // the strength of a grep. Both claims were wrong and the corrections are
    // kept here rather than quietly edited out:
    //
    //  * `ConsentKind` was said to reach `event_registration_controller.dart`.
    //    It does not — that code operates on `ServerConsent`, whose label comes
    //    from the server and is already in the office's own language.
    //  * Both render ONLY in `registration_screen.dart`, and TAB 03 made the
    //    registration wizard unreachable: `route_guard.dart:76` redirects
    //    `/register` to sign-in unless the server publishes self-enrolment,
    //    which it does not.
    //
    // So both are gated, not urgent. Localising them would have been a TAB spent
    // translating a screen no resident can open — the same mistake TAB 04 made
    // on the correction flow.
    'RegistrationStep':
        'registration_screen.dart:88 and :208 (:208 is a semantics label). '
        'GATED — the wizard is unreachable while onboarding is '
        'staff-mediated (TAB 03). Localise when F15 is answered.',
    'ConsentKind':
        'registration_screen.dart:655. GATED behind the same wizard. Not '
        'reached by the events or assistance flows, which use ServerConsent.',
    'VerificationItemCategory':
        'The correction flow, which C-11 established cannot render against the '
        'real backend — dead, so lowest priority of these.',
    'HouseholdCorrectionKind': 'The household correction sheet.',
    'HouseholdRole': 'The household summary card.',
    'ReportReason': 'The comment-reporting sheet.',
    'NotificationCategory': 'The notification inbox.',
    'InboxGroup': 'The inbox grouping headers.',
  };

  Iterable<({String name, String file, Set<String> fields})>
  enumsWithCopy() sync* {
    for (final FileSystemEntity entity in Directory(
      'lib',
    ).listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final String source = entity.readAsStringSync();

      for (final RegExpMatch m in RegExp(
        r'enum (\w+) \{(.*?)\n\}',
        dotAll: true,
      ).allMatches(source)) {
        final String name = m.group(1)!;
        final String body = m.group(2)!;
        final Set<String> fields = RegExp(r'final String\??\s+(\w+);')
            .allMatches(body)
            .map((RegExpMatch f) => f.group(1)!)
            .where(copyFields.contains)
            .toSet();
        if (fields.isEmpty) continue;
        yield (name: name, file: entity.path, fields: fields);
      }
    }
  }

  test('the scan finds enums at all', () {
    // A scan that matches nothing classifies nothing and passes everything.
    expect(
      enumsWithCopy().length,
      greaterThanOrEqualTo(15),
      reason: 'the enum scan has stopped matching; fix it, do not lower this',
    );
  });

  test('every enum holding resident-facing copy is classified', () {
    final Set<String> classified = <String>{
      ...localised,
      ...notResidentFacing.keys,
      ...knownUntranslated.keys,
    };

    final List<String> unclassified = <String>[
      for (final e in enumsWithCopy())
        if (!classified.contains(e.name)) '${e.name}  (${e.file})',
    ];

    expect(
      unclassified,
      isEmpty,
      reason:
          'These enums carry resident-facing copy and nobody has said whether a '
          'resident reads it:\n  ${unclassified.join('\n  ')}\n'
          'Add a localiser and list it in `localised`, or say why it never '
          'reaches a screen in `notResidentFacing`. Do not add to '
          '`knownUntranslated` — that list only shrinks.',
    );
  });

  test('the untranslated list only ever shrinks', () {
    // A ceiling, deliberately. It was eight when this guard was written; every
    // localisation should lower it, and nothing should raise it.
    expect(
      knownUntranslated.length,
      lessThanOrEqualTo(8),
      reason:
          'An enum was added to knownUntranslated. That list records a debt '
          'this app already had; new resident-facing copy is localised when it '
          'is written, not added here.',
    );
  });

  test('nothing is classified twice', () {
    for (final String name in localised) {
      expect(notResidentFacing.containsKey(name), isFalse, reason: name);
      expect(knownUntranslated.containsKey(name), isFalse, reason: name);
    }
    for (final String name in notResidentFacing.keys) {
      expect(knownUntranslated.containsKey(name), isFalse, reason: name);
    }
  });

  test('every enum called localised actually has a localiser', () {
    final String locales = File(
      'lib/core/l10n/app_locales.dart',
    ).readAsStringSync();

    for (final String name in localised) {
      // CORRECTED 2026-08-28. This was `locales.contains(name)`, which asserts
      // only that the enum is *mentioned* somewhere in the file — an import
      // line satisfies it. Red-proofing the three entries added that day found
      // it: `capabilityLabel` was renamed away and this test stayed green,
      // because `ResidentCapability` still appeared in the import, the switch
      // and a doc comment. A check named "actually has a localiser" that passes
      // on a mention is the same defect as the classifications it was meant to
      // police, so it now requires a real signature: a function taking a
      // BuildContext and then the enum itself.
      final bool viaAppLocales = RegExp(
        'BuildContext\\s+context,\\s*$name\\s+\\w+',
      ).hasMatch(locales);
      // Two shapes count, because the codebase legitimately has both:
      // a function in app_locales.dart taking a BuildContext, or an accessor on
      // the enum taking AppStrings. ShellDestination uses the second, and this
      // check first failed by looking only for the first — the guard catching
      // its own author's assumption on the day it was written.
      final bool viaOwnAccessor = enumsWithCopy()
          .where((e) => e.name == name)
          .any(
            (e) => RegExp(
              r'In\((BuildContext|AppStrings)',
            ).hasMatch(File(e.file).readAsStringSync()),
          );

      expect(
        viaAppLocales || viaOwnAccessor,
        isTrue,
        reason:
            '$name is listed as localised and has no localiser — neither a '
            'function in app_locales.dart nor an ...In(BuildContext) accessor.',
      );
    }
  });
}
