import 'package:flutter/foundation.dart';

/// A value the server sent that this build may or may not recognise.
///
/// ---
///
/// **Why enums alone are not enough here.** The backend contract is explicit
/// that adding a new enum value is *not* a breaking change
/// (`docs/api/conventions.md` §1: "Adding an optional field or a new error
/// `code` for a new condition is **not** breaking", and "Clients must ignore
/// unknown fields"). A released app therefore has to meet values it has never
/// heard of, and it must not crash, must not silently drop them, and must not
/// guess what they mean.
///
/// So a server value is carried as a pair: the [raw] string exactly as sent, and
/// [known], the enum case when this build recognises it. Screens branch on
/// [known] and fall back gracefully; logs and support quote [raw].
@immutable
class ServerValue<T extends Enum> {
  const ServerValue({required this.raw, required this.known});

  /// Exactly what the server sent. Never normalised, never discarded.
  final String raw;

  /// The matching case, or `null` when this build does not recognise [raw].
  final T? known;

  bool get isRecognised => known != null;

  static ServerValue<T> parse<T extends Enum>(
    String? raw,
    List<T> values,
    String Function(T) wireValueOf,
  ) {
    final value = raw ?? '';
    for (final candidate in values) {
      if (wireValueOf(candidate) == value) {
        return ServerValue<T>(raw: value, known: candidate);
      }
    }
    return ServerValue<T>(raw: value, known: null);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ServerValue<T> && other.raw == raw && other.known == known);

  @override
  int get hashCode => Object.hash(raw, known);

  @override
  String toString() => 'ServerValue($raw${isRecognised ? '' : ', unknown'})';
}

/// Service groupings published by the backend
/// (`Modules\ServiceCatalog\Domain\ServiceCategory`, commit `7844859`).
enum ServiceCategory {
  dokumento('dokumento'),
  buwis('buwis'),
  kalusugan('kalusugan'),
  trabaho('trabaho'),
  ids('ids'),
  national('national');

  const ServiceCategory(this.wireValue);

  final String wireValue;
}

/// Publication lifecycle (`Modules\ServiceCatalog\Domain\PublicationStatus`).
///
/// The app receives only `published` entries unless the actor holds
/// `services.view_unpublished`, which no resident does — `Role::Resident`
/// resolves to an empty permission list. The field is still modelled rather than
/// dropped, because discarding a value the server chose to send means the app
/// cannot report what it actually received when something looks wrong.
enum ServicePublicationStatus {
  draft('draft'),
  published('published'),
  retired('retired');

  const ServicePublicationStatus(this.wireValue);

  final String wireValue;
}

/// Client channels (`Modules\Shared\Application\ClientChannel`).
enum ServiceChannel {
  citizenWeb('citizen-web'),
  citizenMobile('citizen-mobile'),
  adminConsole('admin-console'),
  verifierDevice('verifier-device'),
  unknown('unknown');

  const ServiceChannel(this.wireValue);

  final String wireValue;
}

/// One entry in the LGU service catalogue.
///
/// ---
///
/// **This type carries the server's answers; it does not compute its own.**
///
/// [status] and [availableChannels] are *facts the server reported*, preserved
/// verbatim. The app uses them to decide what to **show** — the catalogue is
/// public, and a channel filter is a presentation filter — and never to decide
/// what a resident is **allowed** to do. Eligibility, approval and authorisation
/// are server-side decisions (backend ADR 0002); duplicating them here would
/// create a second rule set that drifts from the real one and is wrong in a
/// released build nobody can patch quickly.
///
/// Concretely, there is no `canApply`, no `isEligible` and no `requiresLevel` on
/// this class, and there should not be.
@immutable
class LguService {
  const LguService({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.category,
    required this.status,
    required this.availableChannels,
  });

  /// Server-issued UUID. Never an auto-increment key (conventions §6).
  final String id;

  /// Stable machine code, e.g. `CEDULA`. Safe to key behaviour off.
  final String code;

  final String name;
  final String description;

  final ServerValue<ServiceCategory> category;
  final ServerValue<ServicePublicationStatus> status;

  /// Channels the LGU offers this service on, exactly as reported.
  final List<ServerValue<ServiceChannel>> availableChannels;

  /// Whether the server listed this service as available on this app's channel.
  ///
  /// A *reported capability*, not a permission: it answers "does the LGU offer
  /// this here?", which is a question about the service, not about the resident.
  bool get isOfferedOnMobile => availableChannels.any(
    (channel) => channel.known == ServiceChannel.citizenMobile,
  );

  /// True when this build did not recognise the category or the status.
  ///
  /// Surfaced so a screen can fall back to a neutral presentation instead of
  /// pretending it understood.
  bool get hasUnrecognisedValues =>
      !category.isRecognised ||
      !status.isRecognised ||
      availableChannels.any((channel) => !channel.isRecognised);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is LguService && other.id == id);

  @override
  int get hashCode => id.hashCode;

  /// Redacted of nothing — a catalogue entry is public information — but kept
  /// short so it is useful in a log.
  @override
  String toString() => 'LguService($code, ${category.raw})';
}

/// One page of a paginated collection (conventions §5).
@immutable
class Paginated<T> {
  const Paginated({
    required this.items,
    required this.page,
    required this.perPage,
    required this.total,
    required this.totalPages,
    required this.hasMore,
  });

  const Paginated.single(this.items)
    : page = 1,
      perPage = 0,
      total = 0,
      totalPages = 1,
      hasMore = false;

  final List<T> items;
  final int page;
  final int perPage;
  final int total;
  final int totalPages;
  final bool hasMore;
}
