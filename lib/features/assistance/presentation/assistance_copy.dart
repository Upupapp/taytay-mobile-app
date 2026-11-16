import 'package:flutter/widgets.dart';

import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/time/manila_time.dart';
import '../../../l10n/app_localizations.dart';
import '../../issuance/domain/issuance_terms.dart';
import '../domain/own_assistance_request.dart';

/// How a request's stage is said and drawn on My requests (D-223).
///
/// One switch for the words and one for the look, so the list and the
/// request never word the same status two ways. The words carry the meaning;
/// the icon and the ink repeat it, so colour is never the only signal.
abstract final class AssistanceCopy {
  static String stage(AppStrings s, AssistanceStage stage) => switch (stage) {
    AssistanceStage.received => s.assistanceStageReceived,
    AssistanceStage.beingAssessed => s.assistanceStageBeingAssessed,
    AssistanceStage.approved => s.assistanceStageApproved,
    AssistanceStage.payoutScheduled => s.assistanceStagePayoutScheduled,
    AssistanceStage.released => s.assistanceStageReleased,
    AssistanceStage.needsMore => s.assistanceStageNeedsMore,
    AssistanceStage.notApproved => s.assistanceStageNotApproved,
    AssistanceStage.cancelled => s.assistanceStageCancelled,
    AssistanceStage.expired => s.assistanceStageExpired,
    AssistanceStage.updated => s.assistanceStageUpdated,
  };

  static IconData icon(AssistanceStage stage) => switch (stage) {
    AssistanceStage.received => TaytayIcons.inbox,
    AssistanceStage.beingAssessed => TaytayIcons.hourglass,
    AssistanceStage.approved => TaytayIcons.circleCheck,
    AssistanceStage.payoutScheduled => TaytayIcons.calendar,
    AssistanceStage.released => TaytayIcons.handCoins,
    AssistanceStage.needsMore => TaytayIcons.triangleAlert,
    AssistanceStage.notApproved => TaytayIcons.circleX,
    AssistanceStage.cancelled => TaytayIcons.circleSlash,
    AssistanceStage.expired => TaytayIcons.clock,
    AssistanceStage.updated => TaytayIcons.info,
  };

  static Color ink(AssistanceStage stage) => switch (stage) {
    AssistanceStage.received ||
    AssistanceStage.beingAssessed ||
    AssistanceStage.updated => BrandColors.blue,
    AssistanceStage.approved ||
    AssistanceStage.payoutScheduled ||
    AssistanceStage.released => BrandColors.green,
    AssistanceStage.needsMore => BrandColors.goldInk,
    AssistanceStage.notApproved => BrandColors.redInk,
    AssistanceStage.cancelled || AssistanceStage.expired => BrandColors.muted,
  };

  /// The programme's name, or a neutral one when the API names none.
  static String programme(AppStrings s, OwnAssistanceRequest request) =>
      request.programName ?? s.myRequestsUnnamedProgramme;

  /// `05 Aug 2026` in Manila, or null.
  static String? date(DateTime? instant) =>
      instant == null ? null : ManilaTime.formatDate(instant);

  /// `₱5,000.00` from integer centavos, or null.
  static String? amount(int? centavos) =>
      centavos == null ? null : formatPesos(centavos);

  /// Parts read as one label, skipping the empty ones.
  static String join(Iterable<String?> parts) => <String>[
    for (final String? part in parts)
      if (part != null && part.isNotEmpty) part,
  ].join(', ');
}
