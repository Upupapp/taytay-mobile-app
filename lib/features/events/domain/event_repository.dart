import 'package:flutter/foundation.dart';

import '../../../core/api/paginated.dart';
import '../../../core/result/result.dart';

/// One LGU event.
///
/// Public content by contract: `GET /api/v1/events` is marked `public` in the
/// endpoint matrix (§12). A venue is a municipal location, not a resident's
/// address — no personal data appears in this type.
@immutable
class LguEvent {
  const LguEvent({
    required this.id,
    required this.title,
    required this.description,
    this.startsAt,
    this.endsAt,
    this.venue,
  });

  /// Opaque server identifier. The deep-link target for `event`.
  final String id;

  final String title;
  final String description;
  final DateTime? startsAt;
  final DateTime? endsAt;

  /// Where it happens — a municipal venue name, as the server sent it.
  final String? venue;

  @override
  String toString() => 'LguEvent($id)';
}

/// LGU events, as the committed contract describes them.
///
/// **Read-only, deliberately.** Registering attendance is a `ResidentIntentKind`
/// (TAB 06) with no endpoint behind it: the matrix has no event-registration
/// row. The intent is still remembered and resumed, and the screen confirms
/// rather than inventing a submission the server has never agreed to accept.
abstract interface class EventRepository {
  Future<Result<Paginated<LguEvent>>> listEvents({int page, int perPage});

  Future<Result<LguEvent>> loadEvent(String id);
}
