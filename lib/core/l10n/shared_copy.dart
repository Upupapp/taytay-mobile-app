import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';
import '../result/app_failure.dart';
import 'app_locales.dart';

/// The app's words for a widget in `lib/shared/`, in the reader's language.
///
/// In the running app this is [AppStrings.of]. A shared widget is also drawn
/// where no [AppStrings] delegate sits above it — the configuration stop
/// screen, which renders before anything else is built, and a widget pumped on
/// its own in a test — and there it speaks the template language rather than
/// throwing. The English is still the ARB's, so there is one copy of it.
AppStrings sharedStrings(BuildContext context) =>
    Localizations.of<AppStrings>(context, AppStrings) ??
    lookupAppStrings(AppLocales.english);

/// [localisedResidentMessage] where the app's delegates are in place, and the
/// failure's own English sentence where they are not (see [sharedStrings]).
String sharedResidentMessage(BuildContext context, AppFailure failure) =>
    Localizations.of<AppStrings>(context, AppStrings) == null
    ? failure.residentMessage
    : localisedResidentMessage(context, failure);
