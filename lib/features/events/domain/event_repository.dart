import 'package:flutter/foundation.dart';

import '../../../core/api/paginated.dart';
import '../../../core/links/external_link_service.dart';
import '../../../core/result/result.dart';
import '../../../core/time/manila_time.dart';
import '../../news/domain/announcement_repository.dart' show PublicationState;
import 'event_registration.dart';

export '../../../core/api/server_value.dart';
export '../../news/domain/announcement_repository.dart' show PublicationState;
export 'event_registration.dart';

/// Which part of the events list is being asked for.
///
/// **Three views of one collection, filtered by the server.** The same reasoning
/// as the assistance history in TAB 18: a resident should not have to know which
/// screen an event has moved to when it happens.
enum EventScope {
  upcoming,

  /// Events the signed-in resident has a registration for.
  ///
  /// Offered only to an authenticated resident — a guest has no registrations,
  /// and showing them an empty "My events" would imply they had lost some.
  registered,

  past;

  bool get needsAccount => this == EventScope.registered;
}

/// Where the resident stands with one event.
///
/// ---
///
/// **Displayed here; acted on in TAB 22.** This TAB shows the state the server
/// reports and offers no register button — a control that cannot complete is
/// worse than an absent one, and registration has its own flow with capacity and
/// waitlist rules that belong together.
enum EventRegistrationState {
  /// Registration has not opened.
  notOpen('not_open'),

  /// Open, and this resident has not registered.
  open('open'),

  /// This resident is registered.
  registered('registered'),

  /// This resident is on the waitlist.
  waitlisted('waitlisted'),

  /// This resident cancelled.
  cancelled('cancelled'),

  /// Nobody else can register.
  full('full'),

  /// Registration has closed.
  closed('closed');

  const EventRegistrationState(this.wireValue);

  final String wireValue;

  /// Whether the resident personally holds a place or a waitlist position.
  bool get isResidentRegistered =>
      this == EventRegistrationState.registered ||
      this == EventRegistrationState.waitlisted;
}

/// A municipal venue.
///
/// **No personal data.** A venue is a public place: a covered court, a barangay
/// hall, a plaza. Nothing here describes a resident.
@immutable
class EventVenue {
  const EventVenue({required this.name, this.address, this.directionsUrl});

  final String name;
  final String? address;

  /// A map link **the server supplied**, never composed by the app.
  ///
  /// The same rule as an announcement's share link (D-104): this client does not
  /// know which mapping service the LGU uses or how it addresses a barangay
  /// hall, and a guessed URL sends a resident to the wrong place — the exact
  /// failure a directions link exists to prevent.
  ///
  /// Validated as `https` before it is ever opened; see [hasSafeDirections].
  final String? directionsUrl;

  /// Whether a directions control should be offered at all.
  bool get hasSafeDirections => ExternalLink.isSafe(directionsUrl);

  @override
  String toString() => 'EventVenue($name)';
}

/// How many places are left, when the office chooses to say.
///
/// ---
///
/// **Every field is nullable and absent means "not stated".** The Master Command
/// is explicit that remaining slots appear *only if the backend chooses to
/// expose them*, and the reason is practical: a number the app computed from a
/// stale page tells a resident there is room when there is not, and they travel
/// for nothing.
///
/// The app therefore never subtracts `registered` from `capacity` to produce a
/// remaining count. If the server did not send [remaining], none is shown.
@immutable
class EventCapacity {
  const EventCapacity({this.capacity, this.remaining});

  final int? capacity;
  final int? remaining;

  bool get isStated => capacity != null || remaining != null;

  /// True only when the server said so — never inferred from arithmetic.
  bool get isFull => remaining != null && remaining! <= 0;

  @override
  String toString() => 'EventCapacity($remaining/$capacity)';
}

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
    this.category,
    this.coverImageUrl,
    this.organiser,
    this.contact,
    this.registrationRules,
    this.whatToBring,
    this.shareUrl,
    this.capacity = const EventCapacity(),
    this.registrationState,
    this.publicationState,
    this.myRegistration,
  });

  /// Opaque server identifier. The deep-link target for `event`.
  final String id;

  final String title;
  final String description;

  /// Instants. Rendered in Manila time by [ManilaTime], because a phone can be
  /// set to any timezone and an event happens in Taytay regardless.
  final DateTime? startsAt;
  final DateTime? endsAt;

  final EventVenue? venue;

  /// The server's own label, shown as sent. Not mapped to an enum because the
  /// app takes no decision from it.
  final String? category;

  final String? coverImageUrl;

  /// The Taytay office running it.
  final String? organiser;

  /// A published contact for questions. Only ever what the office chose to
  /// publish — never a staff member's personal line.
  final String? contact;

  /// Who may register and how, in the office's words.
  final String? registrationRules;

  /// Reminders authored by the LGU.
  final String? whatToBring;

  /// The canonical public link, exactly as the server supplied it.
  final String? shareUrl;

  final EventCapacity capacity;

  final ServerValue<EventRegistrationState>? registrationState;
  final ServerValue<PublicationState>? publicationState;

  /// The signed-in resident's own registration, when the server sent one.
  ///
  /// Absent for a guest by construction — the endpoint has nothing to attach —
  /// which is why nothing on the public screens has to guard against it.
  final EventRegistration? myRegistration;

  /// Whether this event may be shown to a resident.
  ///
  /// Same asymmetry as an announcement (D-92): a state this build does not
  /// recognise is **shown**, because the server chose to send it and hiding
  /// unknown states turns one backend change into an empty screen on every
  /// unpatched phone. A state it recognises as non-public — a draft, a
  /// scheduled-but-unpublished entry, an archived one — is **hidden**, because
  /// there the app knows what it was told and a cancelled fun run advertised as
  /// current sends people out on a Saturday morning for nothing.
  bool get isResidentVisible => switch (publicationState?.known) {
    PublicationState.draft ||
    PublicationState.scheduled ||
    PublicationState.archived => false,
    PublicationState.published => true,
    null => true,
  };

  /// Whether the resident holds a place. Presentation emphasis only.
  bool get isRegistered =>
      registrationState?.known?.isResidentRegistered ?? false;

  /// This event with the resident's registration replaced by the server's
  /// latest version of it.
  ///
  /// Used after a cancellation, so the screen adopts the server's answer rather
  /// than editing the copy it already had. Everything else is carried across
  /// untouched: cancelling a place changes the resident's registration, not the
  /// event's schedule, venue or capacity, and re-deriving those from a partial
  /// response is how a screen loses its own content.
  LguEvent withRegistration(EventRegistration registration) => LguEvent(
    id: id,
    title: title,
    description: description,
    startsAt: startsAt,
    endsAt: endsAt,
    venue: venue,
    category: category,
    coverImageUrl: coverImageUrl,
    organiser: organiser,
    contact: contact,
    registrationRules: registrationRules,
    whatToBring: whatToBring,
    shareUrl: shareUrl,
    capacity: capacity,
    registrationState: registrationState,
    publicationState: publicationState,
    myRegistration: registration,
  );

  /// Whether the event has already happened, by its **end** where there is one.
  ///
  /// Using the end rather than the start means an event still running is not
  /// filed as past halfway through it.
  bool isPast({DateTime? now}) {
    final reference = endsAt ?? startsAt;
    if (reference == null) return false;
    return ManilaTime.isPast(reference, now: now);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is LguEvent && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'LguEvent($id)';
}

/// LGU events, as the committed contract describes them.
///
/// **Read-only, deliberately.** There is no create, edit, publish, cancel or
/// capacity method here and there cannot be one: creating and managing events is
/// an admin-console act. Registering attendance arrives in TAB 22, against the
/// registration endpoints when the contract publishes them.
abstract interface class EventRepository {
  /// Events in the given [scope].
  ///
  /// `registered` is `/me`-scoped and takes no resident identifier, so there is
  /// no code path that could ask for somebody else's registrations.
  Future<Result<Paginated<LguEvent>>> listEvents({
    EventScope scope,
    int page,
    int perPage,
  });

  Future<Result<LguEvent>> loadEvent(String id);

  // ── Registration ─────────────────────────────────────────────────────────
  //
  // The server is authoritative for capacity and eligibility. Nothing here
  // lets the app decide a place is available; it asks, and reports the answer.

  /// What this event asks before it will accept a registration.
  ///
  /// Also carries whether an unverified resident may register — the Master
  /// Command's middle case, which is a per-event policy the client asks about
  /// rather than assumes.
  Future<Result<EventRegistrationForm>> loadRegistrationForm(String eventId);

  /// Registers the signed-in resident.
  ///
  /// [idempotencyKey] is required: a dropped connection after the server took
  /// the last place is indistinguishable from one before, and a resident who
  /// retried into a double registration would be holding a place somebody else
  /// could have had.
  ///
  /// A full or closed event is an ordinary outcome carried in the result, not a
  /// failure — see [RegistrationOutcome].
  Future<Result<RegistrationAttempt>> register({
    required String eventId,
    required Map<String, Object?> answers,
    required List<String> consentKeys,
    required String idempotencyKey,
  });

  /// Gives up a place, when the office allows it.
  ///
  /// `/me`-scoped: it names the resident's own registration and takes no
  /// resident identifier.
  Future<Result<EventRegistration>> cancelRegistration({
    required String eventId,
    required String registrationId,
    required String idempotencyKey,
  });
}
