import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/features/notifications/domain/notification_filter.dart';
import 'package:taytay_resident/features/notifications/domain/notification_repository.dart';

// The inbox's filters (D-238), as rules: no widget, no clock but the one
// passed in. Fixtures are obviously synthetic.

/// 12:00 UTC on 16 Aug 2026 = 8 PM in Manila.
final DateTime now = DateTime.utc(2026, 8, 16, 12);

ResidentNotification notice({
  String id = 'n-1',
  String title = 'Your application moved',
  String body = 'Taytay LGU is checking your documents.',
  DateTime? sentAt,
  bool unread = true,
  NotificationCategory? category = NotificationCategory.assistanceStatus,
  String? unknownType,
}) => ResidentNotification(
  id: id,
  title: title,
  body: body,
  sentAt: sentAt,
  readAt: unread ? null : now,
  category: switch ((category, unknownType)) {
    (final NotificationCategory known, _) => ServerValue<NotificationCategory>(
      raw: known.wireValue,
      known: known,
    ),
    (null, final String raw) => ServerValue<NotificationCategory>(
      raw: raw,
      known: null,
    ),
    (null, null) => null,
  },
);

List<String> ids(Iterable<ResidentNotification> notices) =>
    notices.map((ResidentNotification n) => n.id).toList();

void main() {
  group('All / Unread', () {
    test('unread only keeps the unread notices, in order', () {
      final List<ResidentNotification> inbox = <ResidentNotification>[
        notice(id: 'a'),
        notice(id: 'b', unread: false),
        notice(id: 'c'),
      ];

      expect(
        ids(
          filterNotifications(
            inbox,
            const NotificationFilter(unreadOnly: true),
            now: now,
          ),
        ),
        <String>['a', 'c'],
      );
      expect(
        ids(filterNotifications(inbox, NotificationFilter.none, now: now)),
        <String>['a', 'b', 'c'],
      );
    });

    test('Unread is its own control: it is not "narrowed", and Clear filters '
        'keeps it', () {
      const NotificationFilter unread = NotificationFilter(unreadOnly: true);
      expect(unread.isNarrowed, isFalse);

      final NotificationFilter narrowed = unread
          .withKind(const NoticeKind(NotificationCategory.officeReply))
          .withPeriod(NotificationPeriod.today)
          .withWords('permit');
      expect(narrowed.isNarrowed, isTrue);
      expect(narrowed.cleared(), unread);
    });
  });

  group('Category', () {
    test('a category shows only its own notices', () {
      final List<ResidentNotification> inbox = <ResidentNotification>[
        notice(id: 'a'),
        notice(id: 'b', category: NotificationCategory.officeReply),
        notice(id: 'c', category: NotificationCategory.officeReply),
      ];
      expect(
        ids(
          filterNotifications(
            inbox,
            const NotificationFilter(
              kind: NoticeKind(NotificationCategory.officeReply),
            ),
            now: now,
          ),
        ),
        <String>['b', 'c'],
      );
    });

    test('a notice of a type this build does not know is "other", and '
        'can be chosen', () {
      final List<ResidentNotification> inbox = <ResidentNotification>[
        notice(id: 'a'),
        notice(id: 'b', category: null, unknownType: 'future_notice'),
        notice(id: 'c', category: null),
      ];
      expect(NoticeKind.of(inbox[1]).isOther, isTrue);
      expect(NoticeKind.of(inbox[2]).isOther, isTrue);
      expect(
        ids(
          filterNotifications(
            inbox,
            const NotificationFilter(kind: NoticeKind.other()),
            now: now,
          ),
        ),
        <String>['b', 'c'],
      );
    });

    test('only the kinds she has are offered, in category order, with '
        'counts, and "other" last', () {
      final List<NoticeKindCount> kinds = kindsPresent(<ResidentNotification>[
        notice(id: 'a', category: NotificationCategory.officeReply),
        notice(id: 'b', category: null, unknownType: 'future_notice'),
        notice(id: 'c', category: NotificationCategory.verificationUpdate),
        notice(id: 'd', category: NotificationCategory.officeReply),
        notice(id: 'e', unread: false),
      ]);

      expect(
        kinds.map((NoticeKindCount k) => (k.kind, k.count)).toList(),
        <(NoticeKind, int)>[
          (const NoticeKind(NotificationCategory.verificationUpdate), 1),
          (const NoticeKind(NotificationCategory.assistanceStatus), 1),
          (const NoticeKind(NotificationCategory.officeReply), 2),
          (const NoticeKind.other(), 1),
        ],
      );
    });

    test('an empty inbox offers no kind', () {
      expect(kindsPresent(const <ResidentNotification>[]), isEmpty);
    });
  });

  group('When, in Manila days (D-107)', () {
    test('today is the Manila day, not the UTC one', () {
      final List<ResidentNotification> inbox = <ResidentNotification>[
        // 17:00 UTC on the 15th is 1 AM on the 16th in Manila: today.
        notice(id: 'early', sentAt: DateTime.utc(2026, 8, 15, 17)),
        // 15:00 UTC on the 15th is 11 PM on the 15th in Manila: yesterday.
        notice(id: 'late', sentAt: DateTime.utc(2026, 8, 15, 15)),
      ];
      expect(
        ids(
          filterNotifications(
            inbox,
            const NotificationFilter(period: NotificationPeriod.today),
            now: now,
          ),
        ),
        <String>['early'],
      );
    });

    test('the last 7 and 30 days count back from now', () {
      final List<ResidentNotification> inbox = <ResidentNotification>[
        notice(id: 'd6', sentAt: now.subtract(const Duration(days: 6))),
        notice(id: 'd8', sentAt: now.subtract(const Duration(days: 8))),
        notice(id: 'd29', sentAt: now.subtract(const Duration(days: 29))),
        notice(id: 'd31', sentAt: now.subtract(const Duration(days: 31))),
      ];
      expect(
        ids(
          filterNotifications(
            inbox,
            const NotificationFilter(period: NotificationPeriod.lastWeek),
            now: now,
          ),
        ),
        <String>['d6'],
      );
      expect(
        ids(
          filterNotifications(
            inbox,
            const NotificationFilter(period: NotificationPeriod.lastMonth),
            now: now,
          ),
        ),
        <String>['d6', 'd8', 'd29'],
      );
    });

    test('a picked day holds that Manila day only', () {
      final List<ResidentNotification> inbox = <ResidentNotification>[
        // 10 Aug, 7:30 AM and 11:59 PM in Manila.
        notice(id: 'morning', sentAt: DateTime.utc(2026, 8, 9, 23, 30)),
        notice(id: 'night', sentAt: DateTime.utc(2026, 8, 10, 15, 59)),
        // 11 Aug, 12:01 AM in Manila.
        notice(id: 'next', sentAt: DateTime.utc(2026, 8, 10, 16, 1)),
      ];
      final NotificationFilter onTenth = NotificationFilter.none.withPeriod(
        NotificationPeriod.onDay,
        day: DateTime.utc(2026, 8, 10),
      );

      expect(onTenth.day, DateTime.utc(2026, 8, 10));
      expect(ids(filterNotifications(inbox, onTenth, now: now)), <String>[
        'morning',
        'night',
      ]);
    });

    test('"On a date" with no day yet hides nothing', () {
      final List<ResidentNotification> inbox = <ResidentNotification>[
        notice(id: 'a', sentAt: now),
      ];
      expect(
        ids(
          filterNotifications(
            inbox,
            const NotificationFilter(period: NotificationPeriod.onDay),
            now: now,
          ),
        ),
        <String>['a'],
      );
    });

    test('another period lets a picked day go', () {
      final NotificationFilter picked = NotificationFilter.none.withPeriod(
        NotificationPeriod.onDay,
        day: DateTime.utc(2026, 8, 10),
      );
      expect(picked.withPeriod(NotificationPeriod.today).day, isNull);
    });

    test('a notice with no date shows only for any time', () {
      final List<ResidentNotification> inbox = <ResidentNotification>[
        notice(id: 'undated'),
      ];
      for (final NotificationPeriod period in NotificationPeriod.values) {
        final NotificationFilter filter = NotificationFilter.none.withPeriod(
          period,
          day: DateTime.utc(2026, 8, 16),
        );
        expect(
          filterNotifications(inbox, filter, now: now).isNotEmpty,
          period == NotificationPeriod.anyTime,
          reason: period.name,
        );
      }
    });
  });

  group('Search', () {
    final List<ResidentNotification> inbox = <ResidentNotification>[
      notice(id: 'title', title: 'Your BARANGAY clearance is ready'),
      notice(id: 'body', body: 'Bring a barangay ID when you collect it.'),
      notice(id: 'neither', title: 'Event reminder', body: 'See you there.'),
    ];

    test('finds words in the title or the body, in any case', () {
      expect(
        ids(
          filterNotifications(
            inbox,
            const NotificationFilter(words: '  Barangay '),
            now: now,
          ),
        ),
        <String>['title', 'body'],
      );
    });

    test('blank words find everything and narrow nothing', () {
      const NotificationFilter blank = NotificationFilter(words: '   ');
      expect(blank.isNarrowed, isFalse);
      expect(ids(filterNotifications(inbox, blank, now: now)), hasLength(3));
    });

    test('filters combine', () {
      final List<ResidentNotification> mixed = <ResidentNotification>[
        notice(id: 'hit', title: 'Permit ready', sentAt: now),
        notice(id: 'read', title: 'Permit ready', sentAt: now, unread: false),
        notice(
          id: 'old',
          title: 'Permit ready',
          sentAt: now.subtract(const Duration(days: 40)),
        ),
        notice(
          id: 'other-kind',
          title: 'Permit ready',
          sentAt: now,
          category: NotificationCategory.officeReply,
        ),
      ];
      const NotificationFilter filter = NotificationFilter(
        unreadOnly: true,
        kind: NoticeKind(NotificationCategory.assistanceStatus),
        period: NotificationPeriod.lastWeek,
        words: 'permit',
      );
      expect(ids(filterNotifications(mixed, filter, now: now)), <String>[
        'hit',
      ]);
    });

    test('the words she searched for never reach toString', () {
      const NotificationFilter filter = NotificationFilter(
        words: 'cash assistance',
      );
      expect(filter.toString(), isNot(contains('cash')));
      expect(filter.toString(), contains('searching: true'));
    });
  });
}
