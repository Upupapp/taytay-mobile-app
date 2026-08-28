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

  @override
  String uploadRefusedTooLarge(int actual, int limit) {
    return 'Ang file na iyon ay $actual MB. Hanggang $limit MB lang ang tinatanggap ng Taytay LGU. Karaniwang sapat na ang laki ng larawang kinunan sa app na ito.';
  }

  @override
  String get uploadRefusedType =>
      'Larawan lamang (JPEG o PNG) o PDF ang tinatanggap ng Taytay LGU. Kunan ng larawan ang dokumento kung nasa papel ito.';

  @override
  String get uploadRefusedEmpty =>
      'Walang laman ang file na iyon. Piliin itong muli, o kunan na lang ng larawan ang dokumento.';

  @override
  String get uploadRefusedUnreadable =>
      'Hindi mabasa ang file na iyon bilang larawan o PDF. Kunan na lang ng larawan ang dokumento.';

  @override
  String get uploadRefusedTitle => 'Hindi maipapadala ang file na iyon';

  @override
  String get onboardingOfficeTitle =>
      'Ginagawa ang account sa tanggapan ng MSWDO';

  @override
  String get onboardingOfficeBody =>
      'Ang Taytay LGU ang gagawa ng iyong account. Pumunta sa Municipal Social Welfare and Development Office dala ang wastong ID, at irerehistro ng staff ang numerong nais mong gamitin. Pagkatapos, mag-sign in dito gamit ang numerong iyon.';

  @override
  String onboardingOfficeContact(String email, String phone) {
    return 'Magtanong sa tanggapan: $email · $phone';
  }

  @override
  String get correctionWhichDetail => 'Aling detalye ang kailangang itama?';

  @override
  String get correctionNotByMessage =>
      'Hindi ito maitatama sa pamamagitan ng mensahe — dalhin ang dokumento sa tanggapan ng MSWDO, o i-upload itong muli kapag hiniling ng tanggapan.';

  @override
  String get fieldFirstName => 'Pangalan';

  @override
  String get fieldMiddleName => 'Gitnang pangalan';

  @override
  String get fieldLastName => 'Apelyido';

  @override
  String get fieldSuffix => 'Suffix (Jr., III)';

  @override
  String get fieldBirthDate => 'Petsa ng kapanganakan';

  @override
  String get fieldSex => 'Kasarian';

  @override
  String get fieldCivilStatus => 'Katayuang sibil';

  @override
  String get fieldBarangay => 'Barangay';

  @override
  String get fieldStreetAddress => 'Numero ng bahay at kalye';

  @override
  String get fieldPurokOrSitio => 'Purok o sitio';

  @override
  String get fieldMobileNumber => 'Numero ng cellphone';

  @override
  String get fieldEmail => 'Email address';

  @override
  String get sessionEndedTitle => 'Natapos ang iyong session';

  @override
  String get sessionEndedBody =>
      'Para sa iyong seguridad, ini-sign out ka ng Taytay LGU IDS sa device na ito. Nangyayari ito pagkatapos ng ilang panahon, o kapag tinapos ng LGU ang isang session.';

  @override
  String get sessionEndedUnsent =>
      'Nasa tanggapan na ang anumang naipadala mo na. Ang anumang naisulat mo ngunit hindi pa naipapadala ay hindi itinatago sa teleponong ito — kakailanganin mong ilagay itong muli.';

  @override
  String get sessionEndedSignInAgain => 'Mag-sign in muli';

  @override
  String get signInNoticeExpired =>
      'Natapos ang iyong session para sa iyong seguridad. Mangyaring mag-sign in muli.';

  @override
  String get signInNoticeSignedOut =>
      'Naka-sign out ka sa device na ito. Maaari ka pa ring mag-browse ng mga serbisyo ng Taytay bilang bisita.';

  @override
  String get signInNoticeReturnTo =>
      'Mag-sign in upang magpatuloy sa pahinang binuksan mo. Dadalhin ka namin doon agad.';

  @override
  String get profileSectionAccountTitle => 'Ang iyong account details';

  @override
  String get profileSectionAccountExplanation =>
      'Maaari mong baguhin ang mga ito nang mag-isa. Ito ang paraan ng pakikipag-ugnayan sa iyo ng Taytay LGU.';

  @override
  String get profileSectionLguTitle => 'Kumpirmado ng Taytay LGU';

  @override
  String get profileSectionLguExplanation =>
      'Sinuri ng Taytay LGU ang mga ito laban sa iyong mga dokumento. Ito ang batayan ng mga benepisyong nararapat sa iyo, kaya ang LGU lamang ang makakapagbago nito.';

  @override
  String get profileFieldMobileNumber => 'Numero ng cellphone';

  @override
  String get profileFieldEmailAddress => 'Email address';

  @override
  String get profileFieldStreetAddress => 'Numero ng bahay at kalye';

  @override
  String get profileFieldPurokOrSitio => 'Purok o sitio';

  @override
  String get profileFieldFullName => 'Buong pangalan';

  @override
  String get profileFieldBirthDate => 'Petsa ng kapanganakan';

  @override
  String get profileFieldSex => 'Kasarian';

  @override
  String get profileFieldCivilStatus => 'Katayuang sibil';

  @override
  String get profileFieldBarangay => 'Barangay';

  @override
  String get profileHintMobileNumber =>
      'Dito ipinapadala ng Taytay LGU ang iyong one-time code at mga update.';

  @override
  String get profileHintEmailAddress =>
      'Opsyonal. Ginagamit para sa kopya ng mga ipinapadala sa iyo ng LGU.';

  @override
  String get profileHintStreetAddress =>
      'Ang numero ng iyong bahay at kalye, ayon sa tala ng Taytay LGU.';

  @override
  String get profileHintPurokOrSitio =>
      'Opsyonal. Ang purok o sitio sa loob ng iyong barangay, kung mayroon.';

  @override
  String get profileHintFullName =>
      'Ayon sa nakasulat sa ID na iyong ipinakita.';

  @override
  String get profileHintBirthDate =>
      'Batayan ng mga serbisyong nakadepende sa edad, tulad ng benepisyo para sa senior citizen.';

  @override
  String get profileHintBarangay =>
      'Batayan kung aling tanggapan ng barangay ang naglilingkod sa iyo.';

  @override
  String profileFieldOptionalSuffix(String label) {
    return '$label (opsyonal)';
  }

  @override
  String get verifyStageNotStartedLabel => 'Hindi pa nasisimulan';

  @override
  String get verifyStageNotStartedBody =>
      'Hindi mo pa sinisimulan ang pagpapatunay ng iyong pagkakakilanlan.';

  @override
  String get verifyStageInProgressLabel => 'Isinasagawa';

  @override
  String get verifyStageInProgressBody =>
      'Sinimulan mo na ang pagpapatunay ngunit hindi mo pa ito naipapadala.';

  @override
  String get verifyStagePendingLabel => 'Naghihintay ng pagsusuri';

  @override
  String get verifyStagePendingBody =>
      'Nasa Taytay LGU na ang iyong mga detalye at sinusuri na ito.';

  @override
  String get verifyStageNeedsInfoLabel => 'May kailangan pang impormasyon';

  @override
  String get verifyStageNeedsInfoBody =>
      'May kailangang itama bago matapos ng Taytay LGU ang pagsusuri.';

  @override
  String get verifyStageVerifiedLabel => 'Napatunayan na';

  @override
  String get verifyStageVerifiedBody =>
      'Kinumpirma na ng Taytay LGU ang iyong pagkakakilanlan.';

  @override
  String get verifyStageUnsuccessfulLabel => 'Hindi napatunayan';

  @override
  String get verifyStageUnsuccessfulBody =>
      'Hindi nakumpirma ng Taytay LGU ang iyong pagkakakilanlan mula sa ipinadala.';

  @override
  String get verifyStageManualReviewLabel => 'Kailangang suriin ng tao';

  @override
  String get verifyStageManualReviewBody =>
      'Kailangan itong personal na suriin ng staff ng Taytay LGU.';

  @override
  String get kycDocIdentityLabel => 'ID na inisyu ng pamahalaan';

  @override
  String get kycDocIdentityBody =>
      'PhilID, pasaporte, lisensya sa pagmamaneho, postal ID o voter\'s ID.';

  @override
  String get kycDocAddressLabel => 'Patunay ng tirahan';

  @override
  String get kycDocAddressBody =>
      'Bill ng kuryente o tubig, o barangay certificate na nagpapakita kung saan ka nakatira.';

  @override
  String get kycDocSent => 'Naipadala na sa Taytay LGU.';

  @override
  String get kycDocSentChecking => 'Naipadala na. Sinusuri pa.';

  @override
  String get validateConfirmDetails =>
      'Kumpirmahin na ito ang iyong mga detalye bago magpatuloy, para maitala ito ng tanggapan sa tamang rekord.';

  @override
  String get validateNarrativeMissing =>
      'Ilarawan sa sarili mong pananalita kung ano ang kailangan mong tulong.';

  @override
  String validateNarrativeTooLong(int limit) {
    return 'Paikliin ito sa $limit karakter o mas maikli. Maaaring humingi ng mas detalyadong paliwanag ang tanggapan mamaya.';
  }

  @override
  String validateConsentRequired(String subject) {
    return 'Kailangan mong tanggapin ang \"$subject\" upang magpatuloy.';
  }

  @override
  String validateAnswerMissingChoice(String subject) {
    return 'Pumili ng sagot para sa \"$subject\".';
  }

  @override
  String validateAnswerMissingYesNo(String subject) {
    return 'Sagutin ng oo o hindi ang \"$subject\".';
  }

  @override
  String validateAnswerMissingDate(String subject) {
    return 'Maglagay ng petsa para sa \"$subject\".';
  }

  @override
  String validateAnswerMissingNumber(String subject) {
    return 'Maglagay ng numero para sa \"$subject\".';
  }

  @override
  String validateAnswerMissingGeneric(String subject) {
    return 'Sagutin ang \"$subject\".';
  }

  @override
  String validateAnswerNotANumber(String subject) {
    return 'Ilagay ang \"$subject\" bilang numero, mga digit lamang.';
  }

  @override
  String validateAnswerTooLong(int limit) {
    return 'Paikliin ito sa $limit karakter o mas maikli.';
  }
}
