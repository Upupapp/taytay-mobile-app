import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/core/router/app_routes.dart';
import 'package:taytay_resident/core/session/local_authenticator.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/startup/launch_controller.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';
import 'package:taytay_resident/features/account/presentation/account_pages.dart';
import 'package:taytay_resident/features/profile/domain/name_lock.dart';
import 'package:taytay_resident/features/profile/domain/profile_fields.dart';
import 'package:taytay_resident/features/profile/domain/resident_profile_detail.dart';
import 'package:taytay_resident/features/profile/domain/resident_profile_repository.dart';
import 'package:taytay_resident/features/registration/domain/registration_domain.dart';
import 'package:taytay_resident/features/verification/presentation/verification_status_pages.dart';
import 'package:taytay_resident/shared/widgets/taytay_icon.dart';

/// D-195: the account's name is checked against the ID, so it is the
/// resident's to change only while no ID is pending or approved.
void main() {
  test('the status word decides whether the name is open', () {
    expect(NameLock.forTier('unverified'), NameLock.open);
    expect(NameLock.forTier('rejected'), NameLock.open);
    expect(NameLock.forTier('pending'), NameLock.underReview);
    expect(NameLock.forTier('verified'), NameLock.checked);
    // Fails closed: a word this build does not know offers no change.
    expect(NameLock.forTier('gold'), NameLock.unknown);
    expect(NameLock.forTier(''), NameLock.unknown);
    expect(NameLock.forTier(null), NameLock.unknown);
    expect(
      NameLock.values.where((NameLock lock) => lock.allowsChange),
      <NameLock>[NameLock.open],
    );
  });

  group('Edit profile', () {
    for (final String tier in <String>['unverified', 'rejected']) {
      testWidgets('$tier: the name is a field and a change is sent as name', (
        tester,
      ) async {
        final _Profile profile = _Profile(<ResidentProfileDetail>[
          _detail(tier),
        ]);
        await _open(tester, profile);

        expect(find.text(NameCheckCopy.fieldLabel), findsOneWidget);
        expect(find.text(NameCheckCopy.asPrinted), findsOneWidget);
        expect(find.byType(TextField), findsNWidgets(3));
        expect(_textField('Juana Dela Cruz'), findsOneWidget);

        await tester.enterText(
          _textField('Juana Dela Cruz'),
          '  Juana Santos Dela Cruz ',
        );
        await _save(tester);

        expect(profile.changes, <Map<String, Object?>>[
          <String, Object?>{'name': 'Juana Santos Dela Cruz'},
        ]);
        expect(find.text('saved'), findsOneWidget);
      });
    }

    testWidgets('an unchanged open name is not sent', (tester) async {
      final _Profile profile = _Profile(<ResidentProfileDetail>[
        _detail('unverified'),
      ]);
      await _open(tester, profile);

      await tester.enterText(_textField('09170000000'), '09171111111');
      await _save(tester);

      expect(profile.changes.single.keys, <String>['mobile']);
    });

    final Map<String, String> locked = <String, String>{
      'pending': NameCheckCopy.underReview,
      'verified': NameCheckCopy.checked,
      'gold': NameCheckCopy.unknown,
    };
    for (final MapEntry<String, String> entry in locked.entries) {
      testWidgets('${entry.key}: the name is shown locked with its reason', (
        tester,
      ) async {
        final _Profile profile = _Profile(<ResidentProfileDetail>[
          _detail(entry.key),
        ]);
        await _open(tester, profile);

        expect(find.text('Juana Dela Cruz'), findsOneWidget);
        expect(_textField('Juana Dela Cruz'), findsNothing);
        expect(find.byType(TextField), findsNWidgets(2));
        expect(find.text(entry.value), findsOneWidget);
        expect(find.text(NameCheckCopy.asPrinted), findsNothing);
        expect(
          find.byWidgetPredicate(
            (Widget widget) =>
                widget is TaytayIcon &&
                widget.semanticLabel == 'Cannot be changed here',
          ),
          findsOneWidget,
        );

        await tester.enterText(_textField('09170000000'), '09171111111');
        await _save(tester);

        expect(profile.changes.single.keys, <String>['mobile']);
        expect(profile.changes.single.containsKey('name'), isFalse);
      });
    }

    testWidgets(
      'a failed read locks the name and says the app could not tell',
      (tester) async {
        final _Profile profile = _Profile(
          const <ResidentProfileDetail>[],
          read: const Err<ResidentProfileDetail>(NetworkFailure()),
        );
        await _open(tester, profile);

        expect(find.text(NameCheckCopy.unknown), findsOneWidget);
        expect(find.byType(TextField), findsNWidgets(2));
      },
    );

    testWidgets('an emptied or overlong name is refused before sending', (
      tester,
    ) async {
      final _Profile profile = _Profile(<ResidentProfileDetail>[
        _detail('rejected'),
      ]);
      await _open(tester, profile);

      await tester.enterText(_textField('Juana Dela Cruz'), '   ');
      await _save(tester);
      expect(find.text('Nothing was changed'), findsOneWidget);
      expect(find.text(NameCheckCopy.emptyName), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'J' * 121);
      await _save(tester);
      expect(find.text(NameCheckCopy.tooLong), findsOneWidget);
      expect(profile.changes, isEmpty);
    });

    testWidgets(
      'a 409 after the check began locks the name and says why, never the '
      "server's words",
      (tester) async {
        final _Profile profile = _Profile(
          <ResidentProfileDetail>[_detail('unverified'), _detail('pending')],
          answer: const Err<void>(
            ConflictFailure(
              debugMessage:
                  'Your name and birth date are checked against your ID, so '
                  'they cannot be changed while that check is pending or '
                  'after it was approved.',
            ),
          ),
        );
        await _open(tester, profile);

        await tester.enterText(_textField('Juana Dela Cruz'), 'Ana Reyes');
        await tester.enterText(_textField('09170000000'), '09171111111');
        await _save(tester);

        expect(profile.changes.single['name'], 'Ana Reyes');
        expect(profile.reads, 2);
        expect(find.text('Your name was not changed'), findsOneWidget);
        expect(
          find.text(
            '${NameCheckCopy.underReview} Nothing was saved. Save again to '
            'keep your other changes.',
          ),
          findsOneWidget,
        );
        expect(find.textContaining('birth date'), findsNothing);

        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        expect(find.byType(TextField), findsNWidgets(2));
        expect(find.text('Juana Dela Cruz'), findsOneWidget);
        expect(find.text(NameCheckCopy.underReview), findsOneWidget);
        expect(find.text('saved'), findsNothing);
      },
    );

    testWidgets(
      'a 409 while the name is still open keeps the general message',
      (tester) async {
        final _Profile profile = _Profile(<ResidentProfileDetail>[
          _detail('unverified'),
        ], answer: const Err<void>(ConflictFailure()));
        await _open(tester, profile);

        await tester.enterText(_textField('Juana Dela Cruz'), 'Ana Reyes');
        await _save(tester);

        expect(profile.reads, 2);
        expect(find.text('Nothing was changed'), findsOneWidget);
        expect(find.text('Your name was not changed'), findsNothing);
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        expect(find.byType(TextField), findsNWidgets(3));
      },
    );
  });

  group('before an ID is sent', () {
    testWidgets('the resubmit page says the name is checked, ahead of the ID', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      var opened = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: NeedsCorrectionPage(
            onResubmit: () {},
            onCheckName: () => opened++,
          ),
        ),
      );

      expect(find.text(NameCheckCopy.beforeSendingTitle), findsOneWidget);
      expect(_lines(NameCheckCopy.beforeSending), findsOneWidget);
      expect(
        tester.getTopLeft(_lines(NameCheckCopy.beforeSending)).dy,
        lessThan(tester.getTopLeft(find.text('Send a new valid ID')).dy),
      );
      expect(
        tester.getTopLeft(_lines(NameCheckCopy.beforeSending)).dy,
        lessThan(tester.getTopLeft(find.text('Resubmit for verification')).dy),
      );

      await tester.tap(find.text(NameCheckCopy.checkName));
      await tester.pump();
      expect(opened, 1);
    });

    testWidgets('without a way to Edit profile the sentence stands alone', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: NeedsCorrectionPage()));
      expect(_lines(NameCheckCopy.beforeSending), findsOneWidget);
      expect(find.text(NameCheckCopy.checkName), findsNothing);
    });
  });
}

ResidentProfileDetail _detail(String? tier) => ResidentProfileDetail(
  values: const <ResidentProfileField, String>{
    ResidentProfileField.fullName: 'Juana Dela Cruz',
    ResidentProfileField.mobileNumber: '09170000000',
    ResidentProfileField.emailAddress: 'juana@example.com',
    ResidentProfileField.barangay: 'San Juan',
  },
  verificationTier: tier,
);

Finder _textField(String text) => find.byWidgetPredicate(
  (Widget widget) => widget is TextField && widget.controller?.text == text,
);

Future<void> _save(WidgetTester tester) async {
  await tester.tap(
    find.byWidgetPredicate(
      (Widget widget) => widget is Text && widget.data == 'Save changes',
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _open(WidgetTester tester, _Profile profile) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final InMemorySecretStore secrets = InMemorySecretStore();
  await secrets.write(LaunchController.welcomeCompletedKey, 'true');
  final AppDependencies base = AppDependencies.build(
    config: AppConfig.from(
      rawEnvironment: 'dev',
      rawApiBaseUrl: 'https://example.test/api/v1',
      isReleaseBuild: false,
    ),
    secrets: secrets,
    sessionStore: InMemorySessionStore(),
    localAuthenticator: const UnavailableLocalAuthenticator(),
  );
  final AppDependencies dependencies = AppDependencies(
    config: base.config,
    session: base.session,
    launch: base.launch,
    intents: base.intents,
    appLock: base.appLock,
    apiClient: base.apiClient,
    cache: base.cache,
    network: base.network,
    telemetry: base.telemetry,
    authRepository: base.authRepository,
    deviceSessionRepository: base.deviceSessionRepository,
    platformRepository: base.platformRepository,
    serviceCatalogRepository: base.serviceCatalogRepository,
    programRepository: base.programRepository,
    announcementRepository: base.announcementRepository,
    eventRepository: base.eventRepository,
    residentProfileRepository: profile,
    householdRepository: base.householdRepository,
    credentialRepository: base.credentialRepository,
    verificationRepository: base.verificationRepository,
    serviceRequestRepository: base.serviceRequestRepository,
    requirementRepository: base.requirementRepository,
    documentPicker: base.documentPicker,
    shareService: base.shareService,
    externalLinks: base.externalLinks,
    accountControlsRepository: base.accountControlsRepository,
    notificationRepository: base.notificationRepository,
    registrationRepository: base.registrationRepository,
    barangayDirectory: const _Barangays(),
    platform: base.platform,
    onDispose: base.onDispose,
  );
  addTearDown(dependencies.dispose);

  final GoRouter router = GoRouter(
    initialLocation: '/edit',
    routes: <RouteBase>[
      GoRoute(
        path: '/edit',
        builder: (BuildContext context, GoRouterState state) =>
            const EditProfileScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: AppRoute.profile.routeName,
        builder: (BuildContext context, GoRouterState state) =>
            const Scaffold(body: Text('saved')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    AppDependenciesScope(
      dependencies: dependencies,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

/// Serves [details] one read at a time, repeating the last, and records what
/// Save sends.
class _Profile implements ResidentProfileRepository {
  _Profile(this.details, {this.read, this.answer = const Ok<void>(null)});

  final List<ResidentProfileDetail> details;

  /// When set, every read answers this instead.
  final Result<ResidentProfileDetail>? read;
  final Result<void> answer;
  final List<Map<String, Object?>> changes = <Map<String, Object?>>[];
  int reads = 0;

  @override
  Future<Result<ResidentProfileDetail>> loadOwnDetail() async {
    final Result<ResidentProfileDetail>? fixed = read;
    final int index = reads < details.length ? reads : details.length - 1;
    reads++;
    return fixed ?? Ok<ResidentProfileDetail>(details[index]);
  }

  @override
  Future<Result<ResidentProfileSummary>> loadOwnSummary() async =>
      const Err<ResidentProfileSummary>(NetworkFailure());

  @override
  Future<Result<void>> updateContactDetails({
    required ContactDetailsUpdate update,
    required String idempotencyKey,
  }) async => const Err<void>(NetworkFailure());

  @override
  Future<Result<void>> submitOwnUpdate({
    required Map<String, Object?> changes,
    required String idempotencyKey,
  }) async {
    this.changes.add(changes);
    return answer;
  }
}

class _Barangays implements BarangayDirectory {
  const _Barangays();

  @override
  Future<Result<List<Barangay>>> listBarangays() async =>
      const Ok<List<Barangay>>(<Barangay>[
        Barangay(id: 'brgy-san-juan', name: 'San Juan'),
      ]);
}

/// The name-check statement. The redesign draws it as one plain [Text]
/// (it was split line by line by the retired S3Lines).
Finder _lines(String text) => find.text(text);
