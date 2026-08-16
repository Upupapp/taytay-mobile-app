import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';
import '../l10n/app_locales.dart';
import '../result/app_failure.dart';

/// Speaks the outcome of asynchronous work to a screen reader.
///
/// ---
///
/// ## Why a snackbar is not enough
///
/// The Master Command asks for screen-reader announcement of async success and
/// error, and the reason is specific: this app confirms most outcomes with a
/// `SnackBar`, and a `SnackBar` is **not reliably announced**. It is added to an
/// overlay away from the focused node, TalkBack does not move focus to it, and
/// on Android it disappears on a timer a screen-reader user has no way to
/// notice. A sighted resident sees "Your registration has been sent"; a blind
/// resident presses the button and hears nothing at all, then has to explore the
/// screen to work out whether they now hold a place at a medical mission.
///
/// So an outcome is announced **as well as** shown. Never instead — the
/// announcement is additive, and a sighted resident's confirmation is unchanged.
///
/// ## Why the announcement is not the only signal either
///
/// The acceptance criterion runs both ways: no critical action may depend
/// solely on animation or haptics, and equally none may depend solely on an
/// announcement. Every caller here also renders the outcome — a banner, a
/// changed card, a status line — so the spoken text is a second channel over a
/// visible one.
///
/// ## Nothing personal is spoken
///
/// An announcement is read aloud, often on a bus. Callers pass the same fixed
/// app copy they render; no reference number, no name, no address goes through
/// here. The failure door takes an [AppFailure] and derives the sentence from
/// its **kind**, which is why the server's operator-facing `message` cannot
/// reach it even by accident.
abstract final class Announce {
  /// Speaks that something succeeded.
  ///
  /// [what] is the same fixed sentence the screen shows.
  static void success(BuildContext context, String what) {
    _say(context, AppStrings.of(context).a11ySucceeded(what));
  }

  /// Speaks that something failed, in the reader's language, from the failure
  /// kind.
  static void failure(BuildContext context, AppFailure failure) {
    _say(
      context,
      AppStrings.of(
        context,
      ).a11yFailed(localisedResidentMessage(context, failure)),
    );
  }

  /// Speaks that something failed, with copy the caller already chose.
  ///
  /// For outcomes that are not `AppFailure`s — a full event, a closed
  /// registration — which are states to read rather than errors to report.
  static void problem(BuildContext context, String why) {
    _say(context, AppStrings.of(context).a11yFailed(why));
  }

  /// Speaks that work has started.
  ///
  /// Used where the visible signal is a spinner, which a screen reader does not
  /// describe. A silently inert button reads as a broken one.
  static void busy(BuildContext context) {
    _say(context, AppStrings.of(context).a11yBusy);
  }

  /// Speaks arbitrary fixed app copy.
  ///
  /// The escape hatch, deliberately last: prefer the named doors above so the
  /// phrasing stays consistent between screens.
  static void say(BuildContext context, String message) =>
      _say(context, message);

  static void _say(BuildContext context, String message) {
    if (message.trim().isEmpty) return;

    // Addressed to the view this widget is actually in, rather than to the
    // implicit one. On a foldable in two-pane mode, or an Android app in
    // freeform, the implicit view is not necessarily the one the resident is
    // looking at.
    final view = View.maybeOf(context);
    if (view == null) return;

    // `assertive` rather than `polite`: an outcome interrupts, because a
    // resident who has just pressed "Send my application" is waiting for
    // exactly this and nothing else on the screen matters more.
    //
    // Unawaited and swallowed: the platform channel is absent in a widget test
    // and an announcement must never be the thing that breaks a submission.
    SemanticsService.sendAnnouncement(
      view,
      message,
      Directionality.maybeOf(context) ?? TextDirection.ltr,
      assertiveness: Assertiveness.assertive,
    ).catchError((Object _) {});
  }
}
