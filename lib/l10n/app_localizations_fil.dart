// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Filipino Pilipino (`fil`).
class AppStringsFil extends AppStrings {
  AppStringsFil([String locale = 'fil']) : super(locale);

  @override
  String get appTitle => 'Taytay LGU IDS';

  @override
  String get navHome => 'Home';

  @override
  String get navServices => 'Mga Serbisyo';

  @override
  String get navNews => 'Balita';

  @override
  String get navEvents => 'Mga Kaganapan';

  @override
  String get navProfile => 'Profile';

  @override
  String get actionTryAgain => 'Subukan muli';

  @override
  String get actionRefresh => 'I-refresh';

  @override
  String get actionCancel => 'Kanselahin';

  @override
  String get actionClose => 'Isara';

  @override
  String get actionSignIn => 'Mag-sign in';

  @override
  String get actionSignOut => 'Mag-sign out';

  @override
  String get actionTrySendingAgain => 'Subukang ipadala muli';

  @override
  String get networkUnreachableTitle => 'Hindi maabot ang Taytay LGU';

  @override
  String get networkUnreachableMessage =>
      'Hindi makakonekta ang app ngayon. Nandiyan pa ang lahat ng na-type mo, at wala pang naipadala.';

  @override
  String get unsentTitle => 'Hindi pa naipapadala';

  @override
  String unsentMessage(String what) {
    return 'Wala pa sa Taytay LGU ang $what. Nandito pa sa telepono mo ang lahat ng na-type mo. Walang naisumite, kaya hindi magiging dalawa kapag ipinadala mong muli.';
  }

  @override
  String staleContentMessage(String timestamp) {
    return 'Ipinapakita ang naitago noong $timestamp. Maaaring nagbago na ito.';
  }

  @override
  String get failureNetwork =>
      'Hindi maabot ng app ang Taytay LGU. Pakisuri ang iyong koneksyon at subukan muli.';

  @override
  String get failureTimeout =>
      'Matagal bago sumagot ang Taytay LGU. Pakisubukan muli.';

  @override
  String get failureUnauthenticated =>
      'Na-sign out ka na. Mag-sign in muli para magpatuloy.';

  @override
  String get failureForbidden => 'Hindi ito available para sa iyong account.';

  @override
  String get failureNotFound => 'Hindi namin makita ang hinahanap mo.';

  @override
  String get failureValidation => 'May kailangang baguhin sa iyong isinulat.';

  @override
  String get failureConflict =>
      'Nagawa na ito, o may nagbago habang ginagawa mo.';

  @override
  String get failureRateLimited =>
      'Masyadong maraming pagsubok. Maghintay saglit at subukan muli.';

  @override
  String get failureServer =>
      'May naganap na problema sa panig ng Taytay LGU. Hindi ito kasalanan mo.';

  @override
  String get failureContract =>
      'Hindi naintindihan ng bersyong ito ng app ang sagot ng Taytay LGU.';

  @override
  String get failureUnexpected => 'May nangyaring mali. Pakisubukan muli.';

  @override
  String get a11yLoading => 'Naglo-load';

  @override
  String get a11yBusy => 'Ginagawa na. Pakihintay.';

  @override
  String a11ySucceeded(String what) {
    return 'Tapos na. $what';
  }

  @override
  String a11yFailed(String why) {
    return 'Hindi ito naisagawa. $why';
  }

  @override
  String get a11yRequired => 'Kailangan';

  @override
  String a11yFieldError(String message) {
    return 'Mali: $message';
  }
}
