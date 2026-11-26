import '../../features/directory/domain/office.dart';
import '../../features/home/domain/home_content.dart';
import '../../features/tulong/domain/social_service.dart';
import '../../l10n/app_localizations.dart';

// Directory, Tulong, Home and programme words that the domain and data
// layers keep in English (their no-context fallback), drawn here in the
// resident's language. Server text (office, hotline and programme names,
// categories, Tulong titles) is passed through unchanged.

/// A category chip. [Office.allChip] is the app's own word; every other chip
/// is a category the office published.
String directoryChipLabel(AppStrings strings, String chip) =>
    chip == Office.allChip ? strings.dirChipAll : chip;

/// The call action on an office page. An API office carries
/// [Office.defaultCallLabel]; a fixture office keeps its own words.
String officeCallLabel(AppStrings strings, Office office) =>
    office.callLabel == Office.defaultCallLabel
    ? strings.dirActionCall
    : office.callLabel;

/// A fact's label on an office page.
String officeFactLabel(AppStrings strings, OfficeFact fact) =>
    switch (fact.kind) {
      final OfficeFactKind kind => officeFactKindLabel(strings, kind),
      null => fact.label,
    };

/// The label for each kind of office fact, in the reader's language.
String officeFactKindLabel(AppStrings strings, OfficeFactKind kind) =>
    switch (kind) {
      OfficeFactKind.location => strings.dirFactLocation,
      OfficeFactKind.hours => strings.dirFactHours,
      OfficeFactKind.phone => strings.dirFactPhone,
      OfficeFactKind.email => strings.dirFactEmail,
      OfficeFactKind.head => strings.dirFactHead,
    };

/// The compose topic as shown. [Office.generalTopic] is sent to the office
/// in English (the office inbox lists it); the resident reads it in theirs.
/// An office's own topic is its own words.
String directoryTopicLabel(AppStrings strings, String topic) =>
    topic == Office.generalTopic ? strings.dirGeneralTopic : topic;

/// A Tulong contact's label: the server's own label when it sent one,
/// otherwise a name for its type ([ServiceContact.displayLabel] in English).
String serviceContactLabel(AppStrings strings, ServiceContact contact) {
  final String? named = contact.label?.trim();
  if (named != null && named.isNotEmpty) return named;
  return switch (contact.type) {
    ServiceContactType.facebook => 'Facebook',
    ServiceContactType.landline => strings.tulongContactLandline,
    ServiceContactType.hotline => strings.tulongContactHotline,
    ServiceContactType.email => strings.tulongContactEmail,
    ServiceContactType.mobile => strings.tulongContactMobile,
    ServiceContactType.unknown => strings.tulongContactOther,
  };
}

/// A Home slide's eyebrow. The words [HomeSlideWords] gives a banner's route
/// are the app's own and are drawn in the resident's language; an eyebrow
/// written for a bundled slide is its own words.
String homeSlideEyebrow(AppStrings strings, HomeSlide slide) {
  if (slide.eyebrow != HomeSlideWords.eyebrowFor(slide.routeName)) {
    return slide.eyebrow;
  }
  return switch (slide.routeName) {
    'services' => strings.navServices.toUpperCase(),
    'hotlines' => strings.homeHotlines.toUpperCase(),
    'events' => strings.homeEvents.toUpperCase(),
    _ => slide.eyebrow,
  };
}

/// A Home slide's button, named by where it goes ([HomeSlideWords]). A
/// button written for a bundled slide in other words keeps them.
String homeSlideAction(AppStrings strings, HomeSlide slide) {
  if (slide.action != HomeSlideWords.actionFor(slide.routeName)) {
    return slide.action;
  }
  return switch (slide.routeName) {
    'news' => strings.homeReadBalita,
    'programs' => strings.homeExploreTulong,
    'services' => strings.homeOpenDirectory,
    'hotlines' => strings.homeSeeHotlines,
    'events' => strings.homeSeeEvents,
    _ => strings.homeOpen,
  };
}
