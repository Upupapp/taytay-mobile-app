import 'package:flutter/widgets.dart';

import '../../features/messaging/domain/message_send_failure.dart';
import '../../features/settings/domain/account_controls.dart';
import '../../l10n/app_localizations.dart';
import '../result/app_failure.dart';
import 'app_locales.dart';

/// What a consent row is called, in the resident's language. The domain's
/// [ConsentKind.label] stays as the no-context English.
String consentKindLabel(AppStrings strings, ConsentKind kind) => switch (kind) {
  ConsentKind.terms => strings.settingsConsentKindTerms,
  ConsentKind.privacy => strings.settingsConsentKindPrivacy,
  ConsentKind.biometric => strings.settingsSelfieConsent,
  ConsentKind.unspecified => strings.settingsConsentKindUnspecified,
};

/// The sentence a consent row of [kind] shows, as [ConsentKind.statement].
String consentKindStatement(
  AppStrings strings,
  ConsentKind kind,
  String? version,
) {
  final String under = version ?? strings.settingsConsentVersionAtTheTime;
  return switch (kind) {
    ConsentKind.terms => strings.settingsConsentStatementTerms(under),
    ConsentKind.privacy => strings.settingsConsentStatementPrivacy(under),
    ConsentKind.biometric => strings.settingsConsentStatementBiometric(under),
    ConsentKind.unspecified => strings.settingsConsentStatementUnspecified(
      under,
    ),
  };
}

/// The version a record's statement was composed under, as the data layer
/// composed it: the key, or none when the server named no version.
String? _versionOf(ConsentRecord consent) =>
    consent.key.isEmpty ? null : consent.key;

/// A consent row's name. Localised only when it is the app's own name for its
/// kind; a name from anywhere else is shown as it came.
String consentRecordLabel(AppStrings strings, ConsentRecord consent) =>
    consent.label == consent.kind.label
    ? consentKindLabel(strings, consent.kind)
    : consent.label;

/// A consent row's statement. Localised only when it is the sentence the app
/// composed for its kind and version; the office's own words pass through.
String consentRecordStatement(AppStrings strings, ConsentRecord consent) =>
    consent.statement == consent.kind.statement(_versionOf(consent))
    ? consentKindStatement(strings, consent.kind, _versionOf(consent))
    : consent.statement;

/// [MessageAct.unconfirmed], in the resident's language.
String messageActUnconfirmed(AppStrings strings, MessageAct act) =>
    switch (act) {
      MessageAct.start => strings.messagingStartUnconfirmed,
      MessageAct.reply => strings.messagingReplyUnconfirmed,
    };

/// [messageSendFailure], in the resident's language: the same branches, with
/// the failure's sentence from [localisedResidentMessage].
String localisedMessageSendFailure(
  BuildContext context,
  AppFailure failure, {
  required MessageAct act,
  bool unconfirmed = false,
}) {
  final AppStrings strings = AppStrings.of(context);
  return switch (failure) {
    _ when failure.outcomeUnknown || unconfirmed => messageActUnconfirmed(
      strings,
      act,
    ),
    NetworkFailure() => <String>[
      strings.messagingNotSent,
      localisedResidentMessage(context, failure),
    ].join(' '),
    ConflictFailure() when act == MessageAct.start =>
      strings.messagingStartConflict,
    _ => localisedResidentMessage(context, failure),
  };
}
