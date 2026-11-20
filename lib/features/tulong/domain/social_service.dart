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

/// Whether the programme behind a Tulong page asks for a document always,
/// sometimes, or only in a circumstance it states (DL-76, D-226).
enum ApplicationObligation {
  required,
  optional,

  /// Needed only when [ApplicationRequirement.condition] applies. An
  /// obligation this build does not know is read as this one: the app never
  /// guesses that a document is required, and the office says so when it is.
  conditional,
}

/// One document the programme behind a Tulong page asks for, when the page
/// takes applications in the app (`application_requirements`, backend
/// `6794f8d`, ADR 0004 decision 2).
///
/// [code] is the multipart field its file is sent under. [condition] is the
/// office's own words for when a conditional document is needed. Nothing else
/// of the programme reaches the app: not its id, funding, guidance or notes.
@immutable
class ApplicationRequirement {
  const ApplicationRequirement({
    required this.code,
    required this.name,
    required this.obligation,
    this.condition,
  });

  final String code;
  final String name;
  final ApplicationObligation obligation;
  final String? condition;

  bool get required => obligation == ApplicationObligation.required;

  @override
  String toString() => 'ApplicationRequirement($code, ${obligation.name})';
}

/// How a published contact is reached. An unrecognised wire value is
/// [unknown] and is still shown.
enum ServiceContactType {
  facebook,
  landline,
  hotline,
  email,
  mobile,

  /// A type string this app does not name. The contact is still shown.
  unknown,
}

/// A phone, a page, or another published contact.
///
/// `type` and `value` are required on the wire. [label] may be null.
@immutable
class ServiceContact {
  const ServiceContact({required this.type, required this.value, this.label});

  final ServiceContactType type;
  final String? label;
  final String value;

  /// The label a resident reads. The server's label when it sent one,
  /// otherwise a name for [type].
  String get displayLabel {
    final String? named = label?.trim();
    if (named != null && named.isNotEmpty) return named;
    return switch (type) {
      ServiceContactType.facebook => 'Facebook',
      ServiceContactType.landline => 'Landline',
      ServiceContactType.hotline => 'Hotline',
      ServiceContactType.email => 'Email',
      ServiceContactType.mobile => 'Mobile',
      ServiceContactType.unknown => 'Contact',
    };
  }

  @override
  String toString() => 'ServiceContact(${type.name})';
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

/// Specimen chrome the `Service` schema does not publish.
///
/// Saved dates, the SAMPLE hero chip, a list name that differs from
/// [SocialService.name], and the featured page's questions row. The dev
/// fixture may set these. A live read leaves [SocialService.presentation]
/// null.
@immutable
class TulongPresentation {
  const TulongPresentation({
    this.heroSample = false,
    this.savedLabel,
    this.listName,
    this.headerTitle,
    this.headerSubtitle,
    this.questionsLabel,
    this.questionsValue,
    this.shareLabel,
  });

  final bool heroSample;

  /// Fixture-only. The API has no saved-at.
  final String? savedLabel;

  /// List label when it differs from [SocialService.name].
  final String? listName;
  final String? headerTitle;
  final String? headerSubtitle;
  final String? questionsLabel;
  final String? questionsValue;
  final String? shareLabel;

  @override
  String toString() => 'TulongPresentation()';
}

/// Lucide name stored on a service.
///
/// Hyphens, underscores, and case are ignored. `users-round` stays
/// `usersRound`; it is not `users`. An unknown name, including null and
/// empty, is `handHeart`.
String canonicalServiceIconKey(String? raw) {
  final String compact = (raw ?? '').trim().toLowerCase().replaceAll(
    RegExp(r'[\s_-]'),
    '',
  );
  return switch (compact) {
    'accessibility' => 'accessibility',
    'usersround' => 'usersRound',
    'users' => 'users',
    'baby' => 'baby',
    'handcoins' => 'handCoins',
    'graduationcap' => 'graduationCap',
    'heartpulse' => 'heartPulse',
    'heart' => 'heart',
    'briefcasebusiness' => 'briefcaseBusiness',
    'briefcase' => 'briefcase',
    'handheart' || '' => 'handHeart',
    _ => 'handHeart',
  };
}

/// One published social service. `GET /services` and `GET /services/{slug}`.
///
/// Office name, short name, and hours are joined from `GET /offices`. They
/// are not copied onto the service by the widget. There is no hours field.
/// Whether the page takes applications in the app is [takesApplications] (D-226).
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
    this.iconKey = 'handHeart',
    this.tileColor,
    this.badge,
    this.legalBasis,
    this.claimSteps = const <String>[],
    this.featuredHeadline,
    this.schedule,
    this.heroUrl,
    this.hiddenFromList = false,
    this.officeName,
    this.officeShortName,
    this.officeHours,
    this.officePhone,
    this.presentation,
    this.takesApplications = false,
    this.applicationRequirements = const <ApplicationRequirement>[],
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

  /// Canonical Lucide key. See [canonicalServiceIconKey].
  final String iconKey;

  /// Opaque `#RRGGBB` as `0xAARRGGBB`. Null when the server sent nothing
  /// or a colour this app will not paint.
  final int? tileColor;
  final String? badge;
  final String? legalBasis;
  final List<String> claimSteps;
  final String? featuredHeadline;
  final String? schedule;

  /// Public URL of `GET /services/{slug}/hero` when an image is stored.
  /// Null keeps the icon tile. The list does not paint the photograph.
  final String? heroUrl;

  /// Omitted from `GET /services` unless `featured=true`. Still readable
  /// by slug.
  final bool hiddenFromList;

  /// From `GET /offices`, when that read succeeded.
  final String? officeName;
  final String? officeShortName;
  final String? officeHours;
  final String? officePhone;

  final TulongPresentation? presentation;

  /// The page offers Apply: it is live, takes applications in the app, and
  /// names an office programme that is open (`can_apply`, D-226). False on
  /// anything the API did not say.
  final bool takesApplications;

  /// What the programme asks for, read on `GET /services/{slug}` only, and
  /// empty unless [takesApplications]. A list read carries none.
  final List<ApplicationRequirement> applicationRequirements;

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

  /// The chip on the hero. The service badge wins. Otherwise the office
  /// short name, which the server did send.
  String? get heroBadge {
    final String? named = badge?.trim();
    if (named != null && named.isNotEmpty) return named;
    final String? office = officeShortName;
    if (office != null && office.isNotEmpty) return office;
    return null;
  }

  /// The featured programme page. The `featured` boolean alone does not
  /// switch the layout: both a headline and at least one claim step have
  /// to be present.
  bool get showsFeaturedLayout {
    final String? headline = featuredHeadline?.trim();
    return headline != null && headline.isNotEmpty && claimSteps.isNotEmpty;
  }

  /// The second line on a saved row. A fixture date when one was supplied,
  /// otherwise the summary. No invented "Saved Oct 20".
  String get savedLine {
    final String? saved = presentation?.savedLabel;
    if (saved != null && saved.isNotEmpty) return saved;
    return summary;
  }

  /// Phone the Call button may dial. A phone-shaped contact wins over the
  /// office phone. Email and Facebook are not dialled.
  String? get dialable {
    for (final ServiceContact contact in contacts) {
      final String label = contact.label?.toLowerCase() ?? '';
      final bool phoneType =
          contact.type == ServiceContactType.mobile ||
          contact.type == ServiceContactType.landline ||
          contact.type == ServiceContactType.hotline;
      final bool phoneLabel =
          label.contains('phone') ||
          label.contains('contact') ||
          label.contains('landline') ||
          label.contains('question');
      if ((phoneType || phoneLabel) && contact.value.trim().isNotEmpty) {
        return contact.value.trim();
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
      iconKey: iconKey,
      tileColor: tileColor,
      badge: badge,
      legalBasis: legalBasis,
      claimSteps: claimSteps,
      featuredHeadline: featuredHeadline,
      schedule: schedule,
      heroUrl: heroUrl,
      hiddenFromList: hiddenFromList,
      officeName: name ?? officeName,
      officeShortName: shortName ?? officeShortName,
      officeHours: hours ?? officeHours,
      officePhone: phone ?? officePhone,
      presentation: presentation,
      takesApplications: takesApplications,
      applicationRequirements: applicationRequirements,
    );
  }

  @override
  String toString() => 'SocialService($slug)';
}
