import 'package:flutter/foundation.dart';

/// One line a resident may be asked to bring. Information only.
///
/// [sample] is fixture presentation. The live `requirements` array is a list
/// of strings, so a service read from the API never sets it.
@immutable
class ServiceRequirement {
  const ServiceRequirement({required this.text, this.sample = false});

  final String text;
  final bool sample;

  @override
  String toString() => 'ServiceRequirement(sample: $sample)';
}

/// A phone, a page, or another published contact. `{label, value}`.
@immutable
class ServiceContact {
  const ServiceContact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  String toString() => 'ServiceContact()';
}

/// A place the service names. `{name, address}`.
@immutable
class ServiceLocation {
  const ServiceLocation({required this.name, required this.address});

  final String name;
  final String address;

  @override
  String toString() => 'ServiceLocation()';
}

/// How a dev fixture asks the page to be drawn.
///
/// The Node `Service` schema has no icon, tile, badge, SAMPLE flag, source
/// line, claim steps, schedule, or saved-at. Those stay here, and only the
/// dev fixture sets them. A live service leaves [SocialService.presentation]
/// null.
enum TulongLayout {
  /// Who can avail, requirements, locations, and contacts.
  standard,

  /// The featured-programme specimen: steps, a schedule, and share.
  featured,
}

@immutable
class TulongPresentation {
  const TulongPresentation({
    this.glyph = 'handHeart',
    this.tile = 'blue',
    this.badge,
    this.heroSample = false,
    this.source,
    this.layout = TulongLayout.standard,
    this.headline,
    this.steps = const <String>[],
    this.listed = true,
    this.savedLabel,
    this.listName,
    this.headerTitle,
    this.headerSubtitle,
    this.scheduleLabel,
    this.scheduleValue,
    this.questionsLabel,
    this.questionsValue,
    this.shareLabel,
  });

  /// Lucide name. Presentation chrome, not a server field.
  final String glyph;

  /// `blue`, `green`, `gold`, or `red`.
  final String tile;

  final String? badge;
  final bool heroSample;
  final String? source;
  final TulongLayout layout;

  /// Featured headline. May contain a newline. Not a server field.
  final String? headline;
  final List<String> steps;

  /// Fixture-only. The API has no "hide from list" field. A live service is
  /// listed.
  final bool listed;

  /// Fixture-only. The API has no saved-at.
  final String? savedLabel;

  /// List label when it differs from [SocialService.name].
  final String? listName;
  final String? headerTitle;
  final String? headerSubtitle;
  final String? scheduleLabel;
  final String? scheduleValue;
  final String? questionsLabel;
  final String? questionsValue;
  final String? shareLabel;

  @override
  String toString() => 'TulongPresentation(${layout.name})';
}

/// One published social service. `GET /services` and `GET /services/{slug}`.
///
/// Office name, short name, and hours are joined from `GET /offices`. They
/// are not copied onto the service by the widget.
@immutable
class SocialService {
  const SocialService({
    required this.id,
    required this.name,
    required this.slug,
    required this.summary,
    required this.details,
    this.eligibility,
    this.requirements = const <ServiceRequirement>[],
    this.contacts = const <ServiceContact>[],
    this.locations = const <ServiceLocation>[],
    this.category,
    this.officeId,
    this.officeSlug,
    this.featured = false,
    this.officeName,
    this.officeShortName,
    this.officeHours,
    this.officePhone,
    this.presentation,
  });

  final String id;
  final String name;
  final String slug;
  final String summary;
  final String details;
  final String? eligibility;
  final List<ServiceRequirement> requirements;
  final List<ServiceContact> contacts;
  final List<ServiceLocation> locations;
  final String? category;
  final String? officeId;
  final String? officeSlug;
  final bool featured;

  /// From `GET /offices`, when that read succeeded.
  final String? officeName;
  final String? officeShortName;
  final String? officeHours;
  final String? officePhone;

  final TulongPresentation? presentation;

  String get listTitle {
    final String? named = presentation?.listName;
    if (named != null && named.isNotEmpty) return named;
    return name;
  }

  String get headerTitle {
    final String? named = presentation?.headerTitle;
    if (named != null && named.isNotEmpty) return named;
    return name;
  }

  String get headerSubtitle {
    final String? named = presentation?.headerSubtitle;
    if (named != null && named.isNotEmpty) return named;
    final String? office = officeShortName;
    if (office != null && office.isNotEmpty) return 'Tulong · $office';
    return 'Tulong';
  }

  /// The chip on the hero. A fixture badge wins. Otherwise the office short
  /// name, which the server did send. Never an invented "MSWDO · OSCA".
  String? get heroBadge {
    final String? badge = presentation?.badge;
    if (badge != null && badge.isNotEmpty) return badge;
    final String? office = officeShortName;
    if (office != null && office.isNotEmpty) return office;
    return null;
  }

  bool get showsFeaturedLayout => presentation?.layout == TulongLayout.featured;

  /// The second line on a saved row. A fixture date when one was supplied,
  /// otherwise the summary. No invented "Saved Oct 20".
  String get savedLine {
    final String? saved = presentation?.savedLabel;
    if (saved != null && saved.isNotEmpty) return saved;
    return summary;
  }

  /// Phone the Call button may dial. A contact wins over the office phone.
  String? get dialable {
    for (final ServiceContact contact in contacts) {
      final String label = contact.label.toLowerCase();
      if (label.contains('phone') ||
          label.contains('contact') ||
          label.contains('landline') ||
          label.contains('question')) {
        if (contact.value.trim().isNotEmpty) return contact.value.trim();
      }
    }
    final String? phone = officePhone;
    if (phone != null && phone.trim().isNotEmpty) return phone.trim();
    return null;
  }

  /// Address handed to the map. The first location, nothing invented.
  String? get directionsQuery {
    for (final ServiceLocation location in locations) {
      if (location.address.trim().isNotEmpty) return location.address.trim();
    }
    return null;
  }

  SocialService withOffice({
    String? name,
    String? shortName,
    String? hours,
    String? phone,
  }) {
    return SocialService(
      id: id,
      name: this.name,
      slug: slug,
      summary: summary,
      details: details,
      eligibility: eligibility,
      requirements: requirements,
      contacts: contacts,
      locations: locations,
      category: category,
      officeId: officeId,
      officeSlug: officeSlug,
      featured: featured,
      officeName: name ?? officeName,
      officeShortName: shortName ?? officeShortName,
      officeHours: hours ?? officeHours,
      officePhone: phone ?? officePhone,
      presentation: presentation,
    );
  }

  @override
  String toString() => 'SocialService($slug)';
}
