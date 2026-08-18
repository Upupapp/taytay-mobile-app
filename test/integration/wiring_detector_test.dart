import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/core/api/backend_gap.dart';
import 'package:taytay_resident/core/api/unwired_repository.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/documents/document_capture.dart';
import 'package:taytay_resident/core/session/local_authenticator.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';

/// The wiring detector.
///
/// ---
///
/// **What it is for.** Every TAB from 02 to 13 will end with a claim that a
/// feature is wired. This test decides what that claim costs. It walks the real
/// composition root — not a fixture, not a hand-built dependency bag — and
/// asserts, repository by repository, whether the app is calling a server or
/// declining to.
///
/// The registry below is the ledger. A TAB that wires a repository moves its
/// entry from `stubbed` to `wired` and this test proves the move; a TAB that
/// reports a feature done without touching the registry fails here. Equally, a
/// repository that is quietly re-stubbed later — during a revert, a merge, a
/// hurried fix — fails here rather than shipping as a screen that says
/// "temporarily unavailable" to every resident who opens it.
///
/// That is not hypothetical on this platform. The app shipped for its entire
/// life with sixteen repositories in the composition root, fourteen of them
/// declining, while its own status documents reported twenty-eight completed
/// TABs and release readiness. Nothing anywhere compared the two.
///
/// **Why runtime types rather than a static check.** The question is not what
/// the source says; it is what the composition root actually binds. A route can
/// pass every widget test against an injected fake while production wires a stub
/// — the precise failure mode this whole programme addresses.
void main() {
  /// What each repository in the composition root should be bound to today.
  ///
  /// `stubbed` names the TAB that will replace it, so an entry is a work item
  /// with an owner rather than a note. The strings are matched against the
  /// runtime type name of the bound instance.
  const Map<String, String> stubbed = <String, String>{
    'registrationRepository': 'blocked — F15',
    'requirementRepository': 'TAB 10',
    'announcementRepository': 'TAB 11',
    'eventRepository': 'TAB 12',
    'notificationRepository': 'TAB 13',
    'accountControlsRepository': 'TAB 18',
  };

  /// Repositories that already call the server.
  const Set<String> wired = <String>{
    'platformRepository',
    'serviceCatalogRepository',
    // TAB 07
    'programRepository',
    // TAB 02
    'authRepository',
    // TAB 03
    'deviceSessionRepository',
    // TAB 04
    'residentProfileRepository',
    // TAB 05
    'householdRepository',
    // TAB 06
    'credentialRepository',
    // TAB 08
    'serviceRequestRepository',
    'verificationRepository',
  };

  AppDependencies build() => AppDependencies.build(
    config: AppConfig.from(
      rawEnvironment: 'dev',
      rawApiBaseUrl: 'https://example.test/api/v1',
      isReleaseBuild: false,
    ),
    secrets: InMemorySecretStore(),
    sessionStore: InMemorySessionStore(),
    localAuthenticator: const UnavailableLocalAuthenticator(),
    documentPicker: const UnavailableDocumentPicker(),
  );

  /// Every repository the composition root binds, by field name.
  Map<String, Object> repositoriesOf(AppDependencies d) => <String, Object>{
    'authRepository': d.authRepository,
    'deviceSessionRepository': d.deviceSessionRepository,
    'platformRepository': d.platformRepository,
    'serviceCatalogRepository': d.serviceCatalogRepository,
    'programRepository': d.programRepository,
    'announcementRepository': d.announcementRepository,
    'eventRepository': d.eventRepository,
    'residentProfileRepository': d.residentProfileRepository,
    'householdRepository': d.householdRepository,
    'registrationRepository': d.registrationRepository,
    'credentialRepository': d.credentialRepository,
    'verificationRepository': d.verificationRepository,
    'serviceRequestRepository': d.serviceRequestRepository,
    'requirementRepository': d.requirementRepository,
    'notificationRepository': d.notificationRepository,
    'accountControlsRepository': d.accountControlsRepository,
  };

  bool looksStubbed(Object repository) {
    final String name = repository.runtimeType.toString();
    return name.startsWith('Planned') || name.startsWith('Pending');
  }

  late AppDependencies dependencies;
  setUp(() => dependencies = build());
  tearDown(() => dependencies.dispose());

  group('the composition root is what the ledger says it is', () {
    test('the ledger covers every repository the root binds, and no more', () {
      // A repository added without an entry is a feature nobody is tracking.
      expect(
        repositoriesOf(dependencies).keys,
        unorderedEquals(<String>{...stubbed.keys, ...wired}),
      );
    });

    test('every repository the ledger calls wired is calling the server', () {
      repositoriesOf(dependencies).forEach((String name, Object repository) {
        if (!wired.contains(name)) return;
        expect(
          looksStubbed(repository),
          isFalse,
          reason:
              '$name is bound to ${repository.runtimeType}, which is a stub. '
              'A repository does not move from wired back to stubbed without a '
              'decision; if this is deliberate, move it and name the TAB that '
              'will wire it again.',
        );
      });
    });

    test('every repository the ledger calls stubbed still is', () {
      repositoriesOf(dependencies).forEach((String name, Object repository) {
        if (!stubbed.containsKey(name)) return;
        expect(
          looksStubbed(repository),
          isTrue,
          reason:
              '$name is now bound to ${repository.runtimeType}, which is not a '
              'stub. If ${stubbed[name]} wired it, move it into `wired` — that '
              'move is how a TAB proves its claim.',
        );
      });
    });

    test('every stub names the TAB that will replace it', () {
      // The point of the ledger. "Stubbed" with no owner is how fourteen
      // repositories outlived the backend they were waiting for by 45 commits.
      for (final MapEntry<String, String> entry in stubbed.entries) {
        expect(
          entry.value,
          anyOf(matches(RegExp(r'^TAB \d\d$')), startsWith('blocked')),
          reason: '${entry.key} has no indexed owner',
        );
      }
    });
  });

  group('the stubs decline for a reason somebody owns', () {
    test('no repository is stubbed against a genuinely planned module', () {
      // TAB 00's finding, held mechanically: zero repositories are blocked on
      // `Verification` or `ServiceDelivery`. Every stub below is either our
      // wiring work or a named backend gap.
      final Set<String> owners = <String>{
        ...UnwiredRepository.values.map((UnwiredRepository r) => r.wiredBy),
        ...BackendGap.values.map((BackendGap g) => g.finding),
      };
      expect(owners, isNotEmpty);

      for (final MapEntry<String, String> entry in stubbed.entries) {
        final bool owned = owners.any(
          (String owner) =>
              entry.value.contains(owner) || owner.contains(entry.value),
        );
        expect(
          owned,
          isTrue,
          reason:
              '${entry.key} is owned by "${entry.value}", which matches no '
              'UnwiredRepository.wiredBy and no BackendGap finding. Either the '
              'seam is missing an entry or the ledger names an owner nobody has.',
        );
      }
    });

    test('the count of stubs only ever falls', () {
      // A number, checked, because "we wired some things" is not a measurement.
      // TABs 02–13 each drop this; if one rises, something was reverted.
      const int atTab01 = 14;
      expect(
        stubbed.length,
        lessThanOrEqualTo(atTab01),
        reason:
            'There were $atTab01 stubs when the detector was written. More than '
            'that means a repository was re-stubbed or added without wiring.',
      );
    });
  });
}
