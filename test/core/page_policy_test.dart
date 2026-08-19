import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/api/page_policy.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/core/startup/platform_controller.dart';
import 'package:taytay_resident/features/platform/domain/app_bootstrap.dart';
import 'package:taytay_resident/features/platform/domain/platform_repository.dart';

void main() {
  group('taking the size the server chose', () {
    test('a served value is adopted and labelled', () {
      final policy = PagePolicy.adopt(15);

      expect(policy.defaultPerPage, 15);
      expect(policy.source, PagePolicySource.served);
    });

    test('an absent or nonsensical value falls back, labelled', () {
      for (final int? served in <int?>[null, 0, -1]) {
        final policy = PagePolicy.adopt(served);
        expect(policy.defaultPerPage, 25, reason: 'served: $served');
        expect(policy.source, PagePolicySource.fallback);
      }
    });

    test('an absurd value is clamped, and says it was', () {
      // A client that renders whatever it is told is one bad config away from
      // four thousand rows over a municipal connection.
      final policy = PagePolicy.adopt(5000);

      expect(policy.defaultPerPage, PagePolicy.maxPerPage);
      expect(policy.source, PagePolicySource.served);
      expect(policy.wasClamped(5000), isTrue);
      expect(policy.wasClamped(100), isFalse);
    });

    test('the fallback is 25 — what this app sent before TAB 05', () {
      // Deliberately not lowered to the server's 15. An app that quietly halved
      // its page size on every screen the moment a fallback engaged would look
      // like a performance regression with no cause anybody could find.
      expect(PagePolicy.fallback.defaultPerPage, 25);
      expect(PagePolicy.fallback.source, PagePolicySource.fallback);
    });

    test('a caller’s own request is brought into range', () {
      const policy = PagePolicy.fallback;

      expect(policy.clampRequest(0), 1);
      expect(policy.clampRequest(50), 50);
      expect(policy.clampRequest(5000), PagePolicy.maxPerPage);
    });
  });

  group('there is one page size, and this is what keeps it that way', () {
    Iterable<({String path, String source})> libFiles() sync* {
      for (final FileSystemEntity entity
          in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.path.endsWith('core/api/page_policy.dart')) continue;
        yield (path: entity.path, source: entity.readAsStringSync());
      }
    }

    test('no repository declares a default page size of its own', () {
      // There were THREE before TAB 05 — PageMeta, ProgramApiRepository and
      // ServiceCatalogApiRepository — and four different hardcoded defaults
      // across the paged methods: 20, 25 and two named constants. None of them
      // was the 15 the server publishes for this channel.
      final RegExp declared = RegExp(
        r'(?:static\s+)?const\s+int\s+\w*(?:[Pp]erPage|[Pp]ageSize)\w*\s*=\s*\d',
      );

      final List<String> offenders = <String>[
        for (final file in libFiles())
          if (declared.hasMatch(file.source)) file.path,
      ];

      expect(
        offenders,
        isEmpty,
        reason:
            'a page size is declared in:\n  ${offenders.join('\n  ')}\n'
            'The server publishes one per channel on app/bootstrap. Read it; '
            'do not copy it.',
      );
    });

    test('no call site writes its own ceiling', () {
      final List<String> offenders = <String>[
        for (final file in libFiles())
          if (file.source.contains('clamp(1, 100)')) file.path,
      ];

      expect(
        offenders,
        isEmpty,
        reason:
            'an inline ceiling survives in:\n  ${offenders.join('\n  ')}\n'
            'PagePolicy.maxPerPage is the contract’s, in one place.',
      );
    });

    test('the scan reaches the repositories it is meant to police', () {
      // A scope that matched nothing would make both guards above vacuous.
      expect(
        libFiles().map((f) => f.path),
        contains(endsWith('newsfeed_api_repository.dart')),
      );
    });
  });

  group('the served size reaches the client that sends it', () {
    test('PlatformController publishes what the bootstrap said', () async {
      // The seam TAB 05 added, asserted end to end at the controller: what the
      // server publishes for this channel is what the paged repositories will
      // send, because they all read it off the one client they already hold.
      PagePolicy? published;

      final controller = PlatformController(
        repository: _BootstrapSaying(15),
        onPagePolicy: (policy) => published = policy,
      );
      addTearDown(controller.dispose);

      await controller.refresh();

      expect(published?.defaultPerPage, 15);
      expect(published?.source, PagePolicySource.served);
    });

    test('and publishes the labelled fallback when it said nothing usable', () async {
      PagePolicy? published;

      final controller = PlatformController(
        repository: _BootstrapSaying(0),
        onPagePolicy: (policy) => published = policy,
      );
      addTearDown(controller.dispose);

      await controller.refresh();

      expect(published?.defaultPerPage, 25);
      expect(published?.source, PagePolicySource.fallback);
    });
  });
}

/// A bootstrap that answers with one page size and nothing else of interest.
class _BootstrapSaying implements PlatformRepository {
  _BootstrapSaying(this.pageSize);

  final int pageSize;

  @override
  Future<Result<AppBootstrap>> loadBootstrap() async => Ok<AppBootstrap>(
    AppBootstrap(
      service: 'taytay',
      apiVersion: 'v1',
      timezone: 'Asia/Manila',
      channel: 'citizen-mobile',
      defaultPageSize: pageSize,
      minimumVersion: '',
      features: FeatureFlags.none,
      support: SupportContact.none,
    ),
  );

  @override
  Future<Result<ServiceHealth>> checkHealth() async =>
      const Err<ServiceHealth>(NetworkFailure());
}
