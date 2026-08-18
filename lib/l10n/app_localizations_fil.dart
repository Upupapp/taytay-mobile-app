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
  String get failureFileTooLarge =>
      'Masyadong malaki ang file na iyon. Subukan ang mas maliit na larawan, o kunan itong muli sa mas mababang kalidad.';

  @override
  String get failureFileType =>
      'Hindi maipapadala ang ganitong uri ng file. Subukan ang larawan o PDF.';

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

  @override
  String get updateRequiredTitle => 'I-update ang app para makapagpatuloy';

  @override
  String get updateRequiredBody =>
      'Hindi na suportado ang bersyong ito ng Taytay LGU app. Pakiupdate ito mula sa iyong app store, pagkatapos ay buksan itong muli.';

  @override
  String get maintenanceTitle => 'May maintenance ang sistema ng LGU';

  @override
  String get maintenanceBody =>
      'Ligtas ang iyong account at mga hiling. Maaari ka pa ring tumingin ng mga serbisyo at programa habang nangyayari ito. Pakisubukang muli mamaya.';

  @override
  String get blockingNoticeSupport => 'Kung kailangan mo ng tulong ngayon';

  @override
  String get signInCodeSent =>
      'Kung nakarehistro ang numerong iyon sa Taytay LGU, papadalhan ka ng code.';

  @override
  String get signInCodeNotAccepted =>
      'Hindi gumana ang code na iyon. Pakisuri ang code at subukang muli, o humingi ng bago.';

  @override
  String get signInTooManyAttempts =>
      'Masyadong maraming pagsubok. Maghintay muna nang kaunti bago subukang muli.';

  @override
  String get signInOffline =>
      'Mukhang wala kang koneksyon. Pakisuri ang iyong internet at subukang muli.';

  @override
  String get signInTimedOut => 'Masyadong natagalan iyon. Pakisubukang muli.';

  @override
  String get signInServiceUnavailable =>
      'Pansamantalang hindi available ang pag-sign in. Pakisubukang muli mamaya.';

  @override
  String get signInUnexpected =>
      'May hindi inaasahang naganap. Pakisubukang muli, o pumunta sa munisipyo ng Taytay kung magpapatuloy ito.';
}
