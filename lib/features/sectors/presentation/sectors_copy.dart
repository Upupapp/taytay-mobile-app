import 'package:flutter/widgets.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/resident_sector.dart';

/// The words of Sectors and benefits and Apply for a sector (D-215).
///
/// Every line is the app's own. Left out of the mock-ups, as claims the API
/// does not support: a renewal reminder, inclusion in a programme, where a
/// recorded sector came from, and "only MSWDO staff see this photo" (the
/// server lets any LGU staff account read an upload). The notice when the
/// office decides is real: `sector_application_decided`, in the app, never
/// pushed.
abstract final class SectorsCopy {
  static const String title = 'Sectors and benefits';
  static const String subtitle = 'My Account';

  static const String intro =
      'Your sectors are part of your record at Taytay LGU. Offices use them '
      'to see which programmes may fit you.';

  static const String yoursHeading = 'Your sectors';

  /// `GET /me/sectors` stays empty until the office links the account to its
  /// registry record, which a reviewer does on the first approval.
  static const String none =
      'No sectors are on your record in the app yet. They show here once the '
      'MSWDO links your account to its records, which it does when it '
      'approves your first application.';
  static const String applyHeading = 'Apply for a sector';
  static const String nothingToApply =
      'Senior citizen, person with disability and solo parent are each on '
      'your record or being checked. The MSWDO can tell you how to renew an '
      'ID.';
  static const String inPerson =
      'This page shows senior citizen, person with disability and solo '
      'parent. Other sectors are recorded by the MSWDO in person and are not '
      'shown here.';

  static const String loading = 'Loading your sectors';
  static const String failedTitle = 'Your sectors did not load';

  static const String recorded = 'Recorded';
  static const String beingChecked = 'Being checked';
  static const String returned = 'Returned';
  static const String lapsed = 'ID expired';

  static String label(ResidentSector sector) => switch (sector) {
    ResidentSector.seniorCitizen => 'Senior citizen',
    ResidentSector.pwd => 'Person with disability',
    ResidentSector.soloParent => 'Solo parent',
  };

  /// The ID a sector is proved with, for headings and the receipt.
  static String idName(ResidentSector sector) => switch (sector) {
    ResidentSector.seniorCitizen => 'Senior Citizen ID',
    ResidentSector.pwd => 'PWD ID',
    ResidentSector.soloParent => 'Solo Parent ID',
  };

  /// The line under a sector the Sectors page offers.
  static String offer(ResidentSector sector) => switch (sector) {
    ResidentSector.seniorCitizen =>
      '60 and over · your Senior Citizen ID or birth certificate',
    ResidentSector.pwd => 'Your PWD ID from the PDAO',
    ResidentSector.soloParent => 'Your Solo Parent ID',
  };

  /// The line under a choice on step 1.
  static String choiceNote(ResidentSector sector) => switch (sector) {
    ResidentSector.seniorCitizen =>
      'For residents 60 and over. Have your Senior Citizen ID or birth '
          'certificate ready.',
    ResidentSector.pwd => 'Have your PWD ID from the PDAO ready.',
    ResidentSector.soloParent => 'Have your Solo Parent ID ready.',
  };

  /// What a recorded sector's row says under its name.
  static String ownDetail({
    required String? since,
    required String? lastFour,
    required String? validUntil,
  }) => join(<String?>[
    if (since != null) 'Since $since',
    if (lastFour != null) 'ID ending $lastFour',
    if (validUntil != null) 'Valid until $validUntil',
  ]);

  static String appliedOn(String? date) =>
      date == null ? 'You applied' : 'You applied $date';

  static String returnedDetail(String? reason) => reason == null
      ? 'The office returned it. You can apply again.'
      : 'The office said: $reason';

  static String join(List<String?> parts) => parts
      .whereType<String>()
      .where((String part) => part.isNotEmpty)
      .join(' · ');

  // ── Apply for a sector ────────────────────────────────────────────────

  static const String stepOne = 'Step 1 of 3';
  static const String stepTwo = 'Step 2 of 3';
  static const String chooseTitle = 'Apply for a sector';
  static const String chooseSubtitle =
      "Choose the sector that fits you. You'll add a photo of your ID next.";
  static const String choiceGroup = 'Sector';
  static const String next = 'Continue';

  static String proofTitle(ResidentSector sector) =>
      'Add your ${idName(sector)}';
  static const String proofSubtitle =
      'MSWDO staff check it against their records before the sector is added.';
  static const String photoLabel = 'Photo of the ID';
  static const String addPhoto = 'Add a photo';
  static const String change = 'Change';
  static String photoAdded(String size) => 'Photo added · $size';
  static const String photoNote =
      'Taytay LGU staff look at this photo to record your sector. Take it in '
      'good light, with the whole ID in the frame.';
  static const String confirmLabel = 'This ID is mine';
  static const String confirmDescription =
      'I am sending it so Taytay LGU can record this sector on my profile.';
  static const String send = 'Send for checking';
  static const String sourceTitle = 'Add the photo';
  static const String noSource =
      'This phone cannot add a photo here. The MSWDO can record the sector '
      'at the municipal hall.';

  static const String sentTitle = 'Application sent';
  static String sentSubtitle(ResidentSector sector) =>
      '${label(sector)} · Bayan ng Taytay';
  static const String sentSector = 'Sector';
  static const String sentAt = 'Sent';
  static const String nextHeading = 'What happens next';
  static const String stepSent = 'Sent to the MSWDO';
  static const String stepCheck = 'Staff check your ID';
  static const String stepCheckDetail =
      'They may ask for a clearer photo. You will get a notice in this app '
      'when they decide.';
  static const String stepAdded = 'Added to your profile';
  static const String stepAddedDetail =
      'Then it shows as recorded on Sectors and benefits.';
  static const String backToSectors = 'Back to Sectors and benefits';
  static const String home = 'Go to Home';

  // ── Sending ───────────────────────────────────────────────────────────

  static const String nothingSent = 'Nothing was sent.';
  static const String unconfirmedTitle = 'Not confirmed yet';
  static const String unconfirmed =
      'We could not confirm that your application arrived. Before you send '
      'it again, open Sectors and benefits: if it shows as being checked, it '
      'arrived.';
  static const String offlineTitle = 'You are offline';
  static const String offline =
      'Nothing was sent. Your choice and photo are still here on the phone. '
      'Connect to the internet and send again.';
  static const String refusedTitle = 'The photo was not accepted';
  static const String refused =
      'Nothing was sent. Choose a clearer JPEG or PNG photo of the ID, up to '
      '5 MB, and send again.';
  static const String waitingTitle = 'Already on your record or being checked';
  static const String waiting =
      'Nothing new was sent. This sector is already on your record, or an '
      'application for it is with the MSWDO. Sectors and benefits shows '
      'which.';
  static const String notOpenTitle = 'Not available for this account';
  static const String notOpen =
      'Nothing was sent. Applying for a sector is open to verified residents. '
      'The municipal hall can tell you more.';
  static const String failedSendTitle = 'Not sent';
  static const String failedSend =
      'Nothing was sent. Something went wrong on our side. Try again in a '
      'little while.';
}

/// The same words in the resident's language (D-237).
///
/// [SectorsCopy] stays the English and the no-context fallback: the pure
/// `sectorSendFailure` and the tests read it as before. Every screen reads
/// this instead, so a phone set to Filipino shows Filipino. The ID names
/// (Senior Citizen ID, PWD ID, Solo Parent ID) are the names printed on the
/// cards, and are kept as they are in both languages.
final class SectorsText {
  const SectorsText._(this._s);

  factory SectorsText.of(BuildContext context) =>
      SectorsText._(AppStrings.of(context));

  /// English, for a caller with no [BuildContext].
  static const SectorsText english = SectorsText._(null);

  final AppStrings? _s;

  String get title => _s?.sectorsTitle ?? SectorsCopy.title;
  String get subtitle => _s?.navProfile ?? SectorsCopy.subtitle;
  String get intro => _s?.sectorsIntro ?? SectorsCopy.intro;
  String get yoursHeading =>
      _s?.sectorsYoursHeading ?? SectorsCopy.yoursHeading;
  String get none => _s?.sectorsNone ?? SectorsCopy.none;
  String get applyHeading =>
      _s?.sectorsApplyHeading ?? SectorsCopy.applyHeading;
  String get nothingToApply =>
      _s?.sectorsNothingToApply ?? SectorsCopy.nothingToApply;
  String get inPerson => _s?.sectorsInPerson ?? SectorsCopy.inPerson;
  String get loading => _s?.sectorsLoading ?? SectorsCopy.loading;
  String get recorded => _s?.sectorsRecorded ?? SectorsCopy.recorded;
  String get beingChecked =>
      _s?.sectorsBeingChecked ?? SectorsCopy.beingChecked;
  String get returned => _s?.sectorsReturned ?? SectorsCopy.returned;
  String get lapsed => _s?.sectorsLapsed ?? SectorsCopy.lapsed;

  String label(ResidentSector sector) {
    final AppStrings? s = _s;
    if (s == null) return SectorsCopy.label(sector);
    return switch (sector) {
      ResidentSector.seniorCitizen => s.sectorsLabelSenior,
      ResidentSector.pwd => s.sectorsLabelPwd,
      ResidentSector.soloParent => s.sectorsLabelSoloParent,
    };
  }

  String idName(ResidentSector sector) => SectorsCopy.idName(sector);

  String offer(ResidentSector sector) {
    final AppStrings? s = _s;
    if (s == null) return SectorsCopy.offer(sector);
    return switch (sector) {
      ResidentSector.seniorCitizen => s.sectorsOfferSenior,
      ResidentSector.pwd => s.sectorsOfferPwd,
      ResidentSector.soloParent => s.sectorsOfferSoloParent,
    };
  }

  String choiceNote(ResidentSector sector) {
    final AppStrings? s = _s;
    if (s == null) return SectorsCopy.choiceNote(sector);
    return switch (sector) {
      ResidentSector.seniorCitizen => s.sectorsChoiceSenior,
      ResidentSector.pwd => s.sectorsChoicePwd,
      ResidentSector.soloParent => s.sectorsChoiceSoloParent,
    };
  }

  String ownDetail({
    required String? since,
    required String? lastFour,
    required String? validUntil,
  }) {
    final AppStrings? s = _s;
    if (s == null) {
      return SectorsCopy.ownDetail(
        since: since,
        lastFour: lastFour,
        validUntil: validUntil,
      );
    }
    return SectorsCopy.join(<String?>[
      if (since != null) s.sectorsSince(since),
      if (lastFour != null) s.sectorsIdEnding(lastFour),
      if (validUntil != null) s.sectorsValidUntil(validUntil),
    ]);
  }

  String appliedOn(String? date) {
    final AppStrings? s = _s;
    if (s == null) return SectorsCopy.appliedOn(date);
    return date == null ? s.sectorsYouApplied : s.sectorsYouAppliedOn(date);
  }

  /// The reason is the office's own words, passed through as written.
  String returnedDetail(String? reason) {
    final AppStrings? s = _s;
    if (s == null) return SectorsCopy.returnedDetail(reason);
    return reason == null
        ? s.sectorsReturnedNoReason
        : s.sectorsOfficeSaid(reason);
  }

  String get stepOne => _s?.applyStepOf(1, 3) ?? SectorsCopy.stepOne;
  String get stepTwo => _s?.applyStepOf(2, 3) ?? SectorsCopy.stepTwo;
  String get chooseTitle => _s?.sectorsApplyHeading ?? SectorsCopy.chooseTitle;
  String get chooseSubtitle =>
      _s?.sectorsChooseSubtitle ?? SectorsCopy.chooseSubtitle;
  String get choiceGroup => _s?.sectorsSector ?? SectorsCopy.choiceGroup;
  String get next => _s?.gateActionContinue ?? SectorsCopy.next;

  String proofTitle(ResidentSector sector) =>
      _s?.sectorsProofTitle(idName(sector)) ?? SectorsCopy.proofTitle(sector);
  String get proofSubtitle =>
      _s?.sectorsProofSubtitle ?? SectorsCopy.proofSubtitle;
  String get photoLabel => _s?.sectorsPhotoLabel ?? SectorsCopy.photoLabel;
  String get addPhoto => _s?.sectorsAddPhoto ?? SectorsCopy.addPhoto;
  String get change => _s?.applyEdit ?? SectorsCopy.change;
  String photoAdded(String size) =>
      _s?.sectorsPhotoAdded(size) ?? SectorsCopy.photoAdded(size);
  String get photoNote => _s?.sectorsPhotoNote ?? SectorsCopy.photoNote;
  String get confirmLabel =>
      _s?.sectorsConfirmLabel ?? SectorsCopy.confirmLabel;
  String get confirmDescription =>
      _s?.sectorsConfirmDescription ?? SectorsCopy.confirmDescription;
  String get send => _s?.sectorsSend ?? SectorsCopy.send;
  String get sourceTitle => _s?.sectorsSourceTitle ?? SectorsCopy.sourceTitle;
  String get noSource => _s?.sectorsNoSource ?? SectorsCopy.noSource;

  String get sentTitle => _s?.sectorsSentTitle ?? SectorsCopy.sentTitle;
  String sentSubtitle(ResidentSector sector) =>
      _s?.sectorsSentSubtitle(label(sector)) ??
      SectorsCopy.sentSubtitle(sector);
  String get sentSector => _s?.sectorsSector ?? SectorsCopy.sentSector;
  String get sentAt => _s?.sectorsSentAt ?? SectorsCopy.sentAt;
  String get nextHeading => _s?.sectorsNextHeading ?? SectorsCopy.nextHeading;
  String get stepSent => _s?.sectorsStepSent ?? SectorsCopy.stepSent;
  String get stepCheck => _s?.sectorsStepCheck ?? SectorsCopy.stepCheck;
  String get stepCheckDetail =>
      _s?.sectorsStepCheckDetail ?? SectorsCopy.stepCheckDetail;
  String get stepAdded => _s?.sectorsStepAdded ?? SectorsCopy.stepAdded;
  String get stepAddedDetail =>
      _s?.sectorsStepAddedDetail ?? SectorsCopy.stepAddedDetail;
  String get backToSectors =>
      _s?.sectorsBackToSectors ?? SectorsCopy.backToSectors;
  String get home => _s?.sectorsGoHome ?? SectorsCopy.home;

  String get unconfirmedTitle =>
      _s?.unsentTitle ?? SectorsCopy.unconfirmedTitle;
  String get unconfirmed => _s?.sectorsUnconfirmed ?? SectorsCopy.unconfirmed;
  String get offlineTitle => _s?.applyOfflineTitle ?? SectorsCopy.offlineTitle;
  String get offline => _s?.sectorsOffline ?? SectorsCopy.offline;
  String get refusedTitle =>
      _s?.sectorsRefusedTitle ?? SectorsCopy.refusedTitle;
  String get refused => _s?.sectorsRefused ?? SectorsCopy.refused;
  String get waitingTitle =>
      _s?.sectorsWaitingTitle ?? SectorsCopy.waitingTitle;
  String get waiting => _s?.sectorsWaiting ?? SectorsCopy.waiting;
  String get notOpenTitle =>
      _s?.sectorsNotOpenTitle ?? SectorsCopy.notOpenTitle;
  String get notOpen => _s?.sectorsNotOpen ?? SectorsCopy.notOpen;
  String get failedSendTitle =>
      _s?.sectorsFailedSendTitle ?? SectorsCopy.failedSendTitle;
  String get failedSend => _s?.sectorsFailedSend ?? SectorsCopy.failedSend;

  /// A failed send's request id, to quote at the counter.
  String reference(String id) =>
      _s?.applyFailureReference(id) ?? 'Reference: $id';
}
