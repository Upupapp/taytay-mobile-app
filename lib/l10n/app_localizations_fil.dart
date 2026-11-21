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
  String get navServices => 'Direktoryo';

  @override
  String get navNews => 'Balita';

  @override
  String get navTulong => 'Tulong';

  @override
  String get navProfile => 'Aking Account';

  @override
  String get actionTryAgain => 'Subukang muli';

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
      'Hindi makakonekta ang app ngayon. Nandito pa ang lahat ng na-type mo.';

  @override
  String get unsentTitle => 'Hindi pa kumpirmado';

  @override
  String unsentMessage(String what) {
    return 'Hindi namin makumpirma kung nasa Taytay LGU na ang $what. Nandito pa sa telepono mo ang lahat ng na-type mo.';
  }

  @override
  String get unsentResendSafe =>
      'Ligtas itong ipadala muli: hindi ito maisusumite nang dalawang beses.';

  @override
  String staleContentMessage(String timestamp) {
    return 'Ipinapakita ang na-save noong $timestamp. Maaaring nagbago na ito.';
  }

  @override
  String get failureNetwork =>
      'Hindi maabot ng app ang Taytay LGU. Pakisuri ang iyong koneksyon at subukang muli.';

  @override
  String get failureTimeout =>
      'Masyadong natagalan bago sumagot ang Taytay LGU. Pakisubukang muli.';

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
      'Masyadong maraming subok. Maghintay saglit at subukang muli.';

  @override
  String get failureServer =>
      'May naganap na problema sa panig ng Taytay LGU. Hindi ito kasalanan mo.';

  @override
  String get failureContract =>
      'Hindi naintindihan ng bersyong ito ng app ang sagot ng Taytay LGU.';

  @override
  String get failureUnexpected => 'May nangyaring mali. Pakisubukang muli.';

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
      'Hindi na suportado ang bersyong ito ng Taytay LGU app. Paki-update ito mula sa iyong app store, pagkatapos ay buksan itong muli.';

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
      'Masyadong maraming subok. Maghintay muna nang kaunti bago subukang muli.';

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
    return 'Ang file na iyon ay $actual MB. Hanggang $limit MB lang ang tinatanggap ng Taytay LGU. Karaniwang sapat na maliit ang larawang kinunan sa app na ito.';
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
      'Nasa tanggapan na ang anumang naipadala mo na. Ang anumang na-type mo ngunit hindi pa naipapadala ay hindi itinatago sa teleponong ito — kakailanganin mong ilagay itong muli.';

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
      'Sinuri ng Taytay LGU ang mga ito gamit ang iyong mga dokumento. Ito ang batayan ng mga benepisyong nararapat sa iyo, kaya ang LGU lamang ang makakapagbago nito.';

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
      'Hindi mo pa sinisimulan ang pag-verify ng iyong pagkakakilanlan.';

  @override
  String get verifyStageInProgressLabel => 'Isinasagawa';

  @override
  String get verifyStageInProgressBody =>
      'Sinimulan mo na ang pag-verify ngunit hindi mo pa ito naipapadala.';

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
  String get verifyStageVerifiedLabel => 'Verified na';

  @override
  String get verifyStageVerifiedBody =>
      'Kinumpirma na ng Taytay LGU ang iyong pagkakakilanlan.';

  @override
  String get verifyStageUnsuccessfulLabel => 'Hindi na-verify';

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

  @override
  String validateConsentRequiredToRegister(String subject) {
    return 'Kailangan mong tanggapin ang \"$subject\" upang makapagparehistro.';
  }

  @override
  String get capabilityBrowseServices => 'Tingnan ang mga serbisyo ng bayan';

  @override
  String get capabilityReadNews => 'Basahin ang mga anunsyo ng Taytay';

  @override
  String get capabilityBrowseEvents => 'Tingnan ang mga kaganapan ng LGU';

  @override
  String get capabilityManageAccount => 'Pamahalaan ang iyong account';

  @override
  String get capabilityManageSecurity => 'Pamahalaan ang sign-in at seguridad';

  @override
  String get capabilityReadNotifications =>
      'Tingnan ang iyong mga notification';

  @override
  String get capabilityBrowsePrograms => 'Tingnan ang mga programang pantulong';

  @override
  String get capabilityCompleteVerification =>
      'I-verify ang iyong pagkakakilanlan';

  @override
  String get capabilityHoldDigitalId => 'Magkaroon ng iyong Taytay digital ID';

  @override
  String get capabilityTrackAssistanceRequests =>
      'Subaybayan ang iyong mga hiling na tulong';

  @override
  String get capabilityApplyForAssistance =>
      'Mag-apply para sa serbisyo ng bayan';

  @override
  String get capabilitySubmitRequirements =>
      'Ipadala ang mga dokumentong hiniling ng Taytay LGU';

  @override
  String get capabilityViewHouseholdSummary =>
      'Tingnan ang buod ng iyong sambahayan';

  @override
  String get gateSignInLikePost =>
      'Kailangan mo ng Taytay LGU account para ma-like ang post na ito.';

  @override
  String get gateSignInCommentOnPost =>
      'Kailangan mo ng Taytay LGU account para makapagkomento.';

  @override
  String get gateSignInRegisterForEvent =>
      'Kailangan mo ng Taytay LGU account para makarehistro sa kaganapang ito.';

  @override
  String get gateSignInSaveService =>
      'Kailangan mo ng Taytay LGU account para ma-save ang serbisyong ito.';

  @override
  String get gateSignInManageNotifications =>
      'Kailangan mo ng Taytay LGU account para pamahalaan ang iyong mga notification.';

  @override
  String get gateSignInApplyForService =>
      'Kailangan mo ng Taytay LGU account para mag-apply sa serbisyong ito.';

  @override
  String get gateSignInViewDigitalId =>
      'Kailangan mo ng Taytay LGU account para buksan ang iyong digital ID.';

  @override
  String get gateSignInMessageOffice =>
      'Kailangan mo ng Taytay LGU account para magmensahe sa mga tanggapan.';

  @override
  String get gateSignInTrailer =>
      'Sa pag-sign in, masusubaybayan mo rin ang anumang inaplayan mo.';

  @override
  String get gateVerifyLikePost =>
      'Kailangang kumpirmahin ng Taytay LGU kung sino ka bago mo ma-like ang post na ito.';

  @override
  String get gateVerifyCommentOnPost =>
      'Kailangang kumpirmahin ng Taytay LGU kung sino ka bago ka makapagkomento.';

  @override
  String get gateVerifyRegisterForEvent =>
      'Kailangang kumpirmahin ng Taytay LGU kung sino ka bago ka makarehistro sa kaganapang ito.';

  @override
  String get gateVerifySaveService =>
      'Kailangang kumpirmahin ng Taytay LGU kung sino ka bago mo ma-save ang serbisyong ito.';

  @override
  String get gateVerifyManageNotifications =>
      'Kailangang kumpirmahin ng Taytay LGU kung sino ka bago mo pamahalaan ang iyong mga notification.';

  @override
  String get gateVerifyApplyForService =>
      'Kailangang kumpirmahin ng Taytay LGU kung sino ka bago ka mag-apply sa serbisyong ito.';

  @override
  String get gateVerifyViewDigitalId =>
      'Kailangang kumpirmahin ng Taytay LGU kung sino ka bago mo buksan ang iyong digital ID.';

  @override
  String get gateVerifyMessageOffice =>
      'Kailangang kumpirmahin ng Taytay LGU kung sino ka bago ka magmensahe sa mga tanggapan.';

  @override
  String get gateVerifyTrailer => 'Isang beses lang ang verification.';

  @override
  String get documentSourceCamera => 'Kumuha ng larawan';

  @override
  String get documentSourceGallery => 'Pumili ng larawan';

  @override
  String get documentSourceFile => 'Pumili ng file';

  @override
  String get capabilityExplainPending => 'Sinusuri ang iyong account…';

  @override
  String get capabilityExplainNeedsSignIn =>
      'Mag-sign in gamit ang iyong numero ng cellphone para magamit ito. Bukas pa rin sa lahat ang pagtingin.';

  @override
  String get capabilityExplainNeedsVerification =>
      'Kailangang kumpirmahin ng Taytay LGU ang iyong pagkakakilanlan bago mo ito magamit.';

  @override
  String get capabilityExplainNotYetAvailable =>
      'Hindi pa ito binubuksan ng Taytay LGU. Walang problema sa iyong account, at magagamit mo pa rin ang lahat ng iba pa sa app.';

  @override
  String get capabilityRequirementSignIn => 'Kailangang mag-sign in';

  @override
  String get capabilityRequirementVerification => 'Kailangan ng verification';

  @override
  String get capabilityRequirementNotAvailable => 'Hindi pa available';

  @override
  String get gateActionSignIn => 'Mag-sign in';

  @override
  String get gateActionVerify => 'I-verify ang aking pagkakakilanlan';

  @override
  String get gateActionSeeAvailable => 'Tingnan kung ano ang available';

  @override
  String get gateActionContinue => 'Magpatuloy';

  @override
  String get gateBackToHome => 'Bumalik sa Home';

  @override
  String get gateSheetNotAvailableTitle => 'Hindi pa available';

  @override
  String get gateSheetNotAvailablePrivacy =>
      'Walang naipadala, at walang problema sa iyong account.';

  @override
  String get gateSheetClose => 'Isara';

  @override
  String get gateSheetSignInTitle => 'Mag-sign in para magpatuloy';

  @override
  String get gateSheetSignInPrivacy =>
      'Bukas sa lahat ang pagtingin — maaari kang magbasa nang walang account.';

  @override
  String get gateSheetSignInAction => 'Mag-sign in';

  @override
  String get gateSheetCreateAccount => 'Gumawa ng account';

  @override
  String get gateSheetKeepBrowsing => 'Magpatuloy sa pagtingin';

  @override
  String get gateSheetVerifyTitle => 'I-verify ang iyong pagkakakilanlan';

  @override
  String get gateSheetVerifyPrivacy =>
      'Ang hinihingi lang ng LGU ay ang kailangan para kumpirmahin ang iyong pagkakakilanlan at paninirahan, at sinasabi nila kung bakit.';

  @override
  String get gateSheetStartVerification => 'Simulan ang verification';

  @override
  String get gateSheetNotNow => 'Hindi muna';

  @override
  String get verifyActionStart => 'Simulan ang verification';

  @override
  String get verifyActionContinue => 'Ipagpatuloy ang verification';

  @override
  String get verifyActionFixResend => 'Ayusin at ipadala muli';

  @override
  String get verifyActionTryAgain => 'Subukang muli';

  @override
  String get homeVerifiedTitle => 'Verified ka na';

  @override
  String get homeVerifiedBody =>
      'Bukas na sa iyo ang iyong Taytay digital ID at mga aplikasyon sa serbisyo.';

  @override
  String get homeOneStepTitle => 'Isang hakbang na lang';

  @override
  String get homeOneStepBody =>
      'I-verify ang iyong pagkakakilanlan sa Taytay LGU para mabuksan ang iyong digital ID at mga aplikasyon sa serbisyo.';

  @override
  String get homeOpenDigitalId => 'Buksan ang aking digital ID';

  @override
  String get homeCheckStatus => 'Tingnan ang aking status';

  @override
  String get householdFixAddressLabel => 'Mali ang address';

  @override
  String get householdFixAddressBody =>
      'Hindi tama ang street address o barangay na nakatala sa Taytay LGU para sa sambahayang ito.';

  @override
  String get householdFixRoleLabel => 'Mali ang papel ko sa sambahayan';

  @override
  String get householdFixRoleBody =>
      'Iba ang nakatala sa Taytay LGU kaysa sa totoong takbo ng sambahayan.';

  @override
  String get householdFixSizeLabel => 'Mali ang bilang ng tao';

  @override
  String get householdFixSizeBody =>
      'May kulang sa talaan ng sambahayan, o may nakatala na hindi na dito nakatira.';

  @override
  String get householdFixNotMineLabel => 'Hindi ito ang aking sambahayan';

  @override
  String get householdFixNotMineBody =>
      'Naitala ka sa sambahayang hindi mo kinabibilangan.';

  @override
  String get householdFixOtherLabel => 'May iba pang mali';

  @override
  String get householdFixOtherBody =>
      'Tatanungin ka tungkol dito sa munisipyo.';

  @override
  String get householdRoleHead => 'Puno ng sambahayan';

  @override
  String get householdRoleMember => 'Miyembro ng sambahayan';

  @override
  String get reportAbusiveLabel => 'Mapang-abuso o nananakot';

  @override
  String get reportAbusiveBody =>
      'Panlalait, pagbabanta, o mapoot na pananalita.';

  @override
  String get reportHarassmentLabel => 'Pinupuntirya ang isang tao';

  @override
  String get reportHarassmentBody => 'Nakatuon sa isang partikular na tao.';

  @override
  String get reportFalseInfoLabel => 'Maling impormasyon tungkol sa serbisyo';

  @override
  String get reportFalseInfoBody =>
      'Maling pahayag tungkol sa mga serbisyo o iskedyul ng Taytay LGU.';

  @override
  String get reportSpamLabel => 'Spam o patalastas';

  @override
  String get reportSpamBody =>
      'Nagbebenta ng kung ano, o paulit-ulit na na-post.';

  @override
  String get reportPersonalInfoLabel => 'Personal na impormasyon ng iba';

  @override
  String get reportPersonalInfoBody =>
      'Numero ng telepono, address, o iba pang pribadong detalyeng na-post nang walang pahintulot.';

  @override
  String get notifCatVerification => 'Pag-verify ng pagkakakilanlan';

  @override
  String get notifCatAssistance => 'Mga update sa tulong';

  @override
  String get notifCatMissingRequirement => 'Kailangang dokumento';

  @override
  String get notifCatRelease => 'Pagkuha ng tulong';

  @override
  String get notifCatReferral => 'Mga referral';

  @override
  String get notifCatEventRegistration => 'Mga rehistro sa kaganapan';

  @override
  String get notifCatEventReminder => 'Mga paalala sa kaganapan';

  @override
  String get notifCatPublicAdvisory => 'Mga pampublikong abiso';

  @override
  String get notifCatAccountSecurity => 'Account at seguridad';

  @override
  String get notifSwitchDocumentRequests => 'Mga hiling na dokumento';

  @override
  String get notifSwitchSectorApplications => 'Mga aplikasyon sa sektor';

  @override
  String get notifSwitchOfficeReplies => 'Mga sagot ng tanggapan';

  @override
  String get inboxGroupToday => 'Ngayong araw';

  @override
  String get inboxGroupThisWeek => 'Mas maaga ngayong linggo';

  @override
  String get inboxGroupThisMonth => 'Mas maaga ngayong buwan';

  @override
  String get inboxGroupOlder => 'Mas luma';

  @override
  String get inboxGroupUndated => 'Walang petsa';

  @override
  String get serviceCategoryDokumento => 'Mga Dokumento';

  @override
  String get serviceCategoryBuwis => 'Buwis at bayarin';

  @override
  String get serviceCategoryKalusugan => 'Kalusugan';

  @override
  String get serviceCategoryTrabaho => 'Trabaho';

  @override
  String get serviceCategoryIds => 'Pagkakakilanlan';

  @override
  String get serviceCategoryNational => 'Mga serbisyong pambansa';

  @override
  String uploadRefusedTooLargeUnknown(int limit) {
    return 'Masyadong malaki ang file na iyon. Hanggang $limit MB lang ang tinatanggap ng Taytay LGU. Karaniwang sapat na maliit ang larawang kinunan sa app na ito.';
  }

  @override
  String get intentResumedLikePost => 'Maaari mo nang i-like ang post na ito.';

  @override
  String get intentResumedCommentOnPost => 'Maaari ka nang magkomento.';

  @override
  String get intentResumedRegisterForEvent =>
      'Maaari ka nang magrehistro sa kaganapang ito.';

  @override
  String get intentResumedSaveService =>
      'Maaari mo nang i-save ang serbisyong ito.';

  @override
  String get intentResumedManageNotifications =>
      'Maaari mo nang pamahalaan ang iyong mga notification.';

  @override
  String get intentResumedApplyForService =>
      'Maaari ka nang mag-apply sa serbisyong ito.';

  @override
  String get intentResumedViewDigitalId =>
      'Maaari mo nang buksan ang iyong digital ID.';

  @override
  String get intentResumedMessageOffice =>
      'Maaari ka nang magmensahe sa mga tanggapan.';

  @override
  String get welcomeSkip => 'Laktawan';

  @override
  String get welcomeNext => 'Susunod';

  @override
  String get welcomeGetStarted => 'Magsimula';

  @override
  String get welcomeContinueAsGuest => 'Magpatuloy bilang bisita';

  @override
  String get welcomeGuestNote =>
      'Maaari mong tingnan ang mga serbisyo ng munisipyo nang walang account.';

  @override
  String welcomeStep(int current, int total) {
    return 'Hakbang $current ng $total';
  }

  @override
  String get welcomeServicesEyebrow =>
      'Mga serbisyo ng munisipyo sa iisang lugar';

  @override
  String get welcomeServicesTitle => 'Serbisyong bayan,\nnasa isang app.';

  @override
  String get welcomeServicesBody =>
      'Mga dokumento, buwis sa lupa, mga programa sa kalusugan, at serbisyo sa trabaho — tingnan ang inaalok ng Taytay LGU at subaybayan ang anumang inaplayan mo.';

  @override
  String get welcomeServicesChipDocuments => 'Mga dokumento';

  @override
  String get welcomeServicesChipTax => 'Buwis sa lupa';

  @override
  String get welcomeServicesChipHealth => 'Kalusugan';

  @override
  String get welcomeServicesChipJobs => 'Trabaho';

  @override
  String get welcomeServicesTag => 'Munisipyo ng Taytay';

  @override
  String get welcomeServicesCredit =>
      'Larawan: Ramon FVelasquez · CC BY-SA 3.0';

  @override
  String get welcomeIdEyebrow => 'Ang iyong Taytay ID, nasa telepono mo';

  @override
  String get welcomeIdTitle => 'Ang Taytay ID mo,\nnasa phone mo na.';

  @override
  String get welcomeIdBody =>
      'Mag-apply at dalhin ang digital ID ng Munisipalidad ng Taytay nang hindi pumipila sa munisipyo.';

  @override
  String get welcomeIdChipDigital => 'Digital na ID';

  @override
  String get welcomeIdChipQueue => 'Walang pila';

  @override
  String get welcomeIdTag =>
      'Taytay Tiangge · Kabisera ng kasuotan at woodcraft';

  @override
  String get welcomeIdCredit => 'Larawan: Ralff Nestor Nacor · CC BY-SA 4.0';

  @override
  String get welcomePrivacyEyebrow => 'Ikaw ang pipili ng ibabahagi mo';

  @override
  String get welcomePrivacyTitle => 'Ikaw ang pipili\nng ibabahagi.';

  @override
  String get welcomePrivacyBody =>
      'Humihingi ang Taytay LGU ng kailangan lang ng isang serbisyo, at sinasabi kung bakit. Protektado ang iyong impormasyon sa ilalim ng Data Privacy Act of 2012.';

  @override
  String get welcomePrivacyTag => 'Parokya ni San Juan Bautista';

  @override
  String get welcomePrivacyCredit => 'Larawan: Urbanroamer · CC BY-SA 3.0';

  @override
  String verificationReviewRange(int min, int max) {
    return '$min–$max araw ng trabaho';
  }

  @override
  String verificationReviewDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days araw ng trabaho',
    );
    return '$_temp0';
  }

  @override
  String verificationReviewSentence(String duration) {
    return 'Karaniwang inaabot ito ng $duration.';
  }

  @override
  String verificationReviewTimelineDetail(String duration) {
    return 'Karaniwang $duration';
  }

  @override
  String get myRequestsTitle => 'Aking mga hiling';

  @override
  String get myRequestsSubtitle => 'Mga hiling na tulong na naisampa sa MSWDO';

  @override
  String get myRequestsInPerson =>
      'May mga hiling na pinag-uusapan lamang nang personal sa tanggapan ng MSWDO.';

  @override
  String get myRequestsEmptyTitle => 'Walang hiling na maipapakita';

  @override
  String get myRequestsEmptyMessage =>
      'Walang hiling na naisampa sa tanggapan ang ipinapakita rito.';

  @override
  String get myRequestsLoading => 'Kinukuha ang iyong mga hiling';

  @override
  String get myRequestsShowOlder => 'Ipakita ang mas lumang mga hiling';

  @override
  String get myRequestsLoadingMore => 'Kinukuha…';

  @override
  String get myRequestsMoreFailed => 'Hindi nakuha ang iba pa. Subukang muli';

  @override
  String myRequestsFiled(String date) {
    return 'Naisampa noong $date';
  }

  @override
  String get myRequestsUnnamedProgramme => 'Hiling na tulong';

  @override
  String get assistanceStageReceived => 'Natanggap';

  @override
  String get assistanceStageBeingAssessed => 'Sinusuri';

  @override
  String get assistanceStageApproved => 'Aprubado';

  @override
  String get assistanceStagePayoutScheduled => 'Nakaiskedyul na ang pagkuha';

  @override
  String get assistanceStageReleased => 'Naibigay na';

  @override
  String get assistanceStageNeedsMore =>
      'May kailangan pa sa iyo ang tanggapan — pakibisita o kontakin ang MSWDO';

  @override
  String get assistanceStageDocumentsSent =>
      'Naipadala na — hinihintay ang pagsusuri ng tanggapan';

  @override
  String get assistanceStageNotApproved =>
      'Hindi naaprubahan — masasabi sa iyo ng MSWDO kung bakit';

  @override
  String get assistanceStageCancelled => 'Kinansela';

  @override
  String get assistanceStageExpired => 'Nag-expire';

  @override
  String get assistanceStageUpdated => 'Katayuan: may update';

  @override
  String get myRequestDetailTitle => 'Hiling na tulong';

  @override
  String get myRequestReference => 'Numero ng reperensiya';

  @override
  String get myRequestFiledOn => 'Petsa ng pagsampa';

  @override
  String get myRequestStatusChangedOn => 'Huling nagbago ang katayuan';

  @override
  String get myRequestApprovedAmount => 'Halagang inaprubahan';

  @override
  String get myRequestPayoutDate => 'Petsa ng pagkuha';

  @override
  String get myRequestPayoutVenue => 'Saan kukunin';

  @override
  String get myRequestReleasedOn => 'Naibigay noong';

  @override
  String get myRequestLoading => 'Kinukuha ang hiling';

  @override
  String get myRequestNotShownTitle =>
      'Hindi ipinapakita rito ang hiling na ito';

  @override
  String get myRequestNotShownMessage =>
      'Wala ito sa mga hiling na ipinapakita para sa iyong account.';

  @override
  String get myRequestsSeeAll => 'Tingnan ang lahat ng aking hiling';

  @override
  String get applyCardTitle => 'Mag-apply sa app';

  @override
  String get applyCardBody =>
      'Ipadala mula sa iyong telepono ang iyong aplikasyon at mga dokumento sa tanggapan ng MSWDO. Susuriin ito ng tanggapan gaya ng sa counter.';

  @override
  String get applyCardButton => 'Mag-apply';

  @override
  String get applyTitle => 'Mag-apply ng tulong';

  @override
  String applyStepOf(int step, int total) {
    return 'Hakbang $step sa $total';
  }

  @override
  String get applyLoading => 'Binubuksan ang aplikasyon';

  @override
  String get applyNotOfferedTitle =>
      'Hindi tumatanggap ng aplikasyon sa app ang programang ito';

  @override
  String get applyNotOfferedMessage =>
      'Pumunta o makipag-ugnayan sa tanggapan ng MSWDO para mag-apply. Nakasulat sa pahina ng programa kung paano.';

  @override
  String get applyBackToProgramme => 'Bumalik sa programa';

  @override
  String get applyBack => 'Bumalik';

  @override
  String get applyNext => 'Susunod';

  @override
  String get applyAboutHeading => 'Ano ito';

  @override
  String get applyAboutBody =>
      'Nag-a-apply ka sa tanggapan ng MSWDO para sa tulong sa ilalim ng programang ito. Babasahin ng tanggapan ang iyong aplikasyon at mga dokumento, gaya ng sa counter, at ito ang magpapasya. Ang pagpapadala ay hindi nangangahulugang aprubado na ito.';

  @override
  String get applyWhoHeading => 'Sino ang puwedeng mag-apply sa app';

  @override
  String get applyWhoBody =>
      'Residenteng beripikado na ng Taytay LGU ang account, at naiugnay na ng MSWDO sa kanyang rekord sa tanggapan. Iniuugnay ng MSWDO ang iyong account kapag sinuri nito ang iyong ID, o sa counter.';

  @override
  String get applyNeedsHeading => 'Ano ang hinihingi ng tanggapan';

  @override
  String get applyNeedsNone =>
      'Walang hinihinging dokumento sa app ang tanggapan para sa programang ito.';

  @override
  String get applyInPersonAlso =>
      'Puwede ka ring mag-apply nang personal sa tanggapan ng MSWDO.';

  @override
  String get applyStart => 'Magsimula';

  @override
  String get applyNotVerifiedTitle =>
      'Tapusin muna ang beripikasyon ng iyong account';

  @override
  String get applyNotVerifiedBody =>
      'Ang residenteng beripikado na ng Taytay LGU ang pagkakakilanlan lamang ang puwedeng mag-apply sa app. Ipadala ang iyong valid ID at selfie sa app, o magpa-beripika nang personal sa Munisipyo.';

  @override
  String get applyGoToVerification => 'Pumunta sa beripikasyon';

  @override
  String get applyNotLinkedTitle =>
      'Kailangang iugnay ng MSWDO ang iyong account';

  @override
  String get applyNotLinkedBody =>
      'Walang naipadala. Beripikado ang iyong account, pero hindi pa ito naiuugnay ng MSWDO sa iyong rekord sa tanggapan. Ginagawa nila ito kapag sinuri ang iyong ID, o sa counter: magdala ng valid ID sa tanggapan ng MSWDO at hilinging iugnay ang iyong account sa app. Mananatili rito ang iyong mga sagot hanggang umalis ka sa pahinang ito.';

  @override
  String get applyTryAgain => 'Subukang ipadala muli';

  @override
  String get applyMessageOffice => 'Magmensahe sa tanggapan';

  @override
  String get applyUnlinkedBody =>
      'Beripikado ang iyong account, pero hindi pa ito naiuugnay ng MSWDO sa iyong rekord sa tanggapan, kaya hindi pa maipapadala ang aplikasyon mula sa app. Ginagawa nila ito kapag sinuri ang iyong ID, o sa counter: magdala ng valid ID sa tanggapan ng MSWDO at hilinging iugnay ang iyong account sa app. Kapag naiugnay na, bumalik sa pahinang ito para mag-apply.';

  @override
  String get accountLinkedNote =>
      'Naiugnay na ang iyong account sa iyong rekord sa MSWDO.';

  @override
  String get accountNotLinkedNote =>
      'Hindi pa naiuugnay ang iyong account sa iyong rekord sa MSWDO. Iniuugnay ito ng MSWDO kapag sinuri ang iyong ID, o sa counter.';

  @override
  String get applyDetailsHeading => 'Ang iyong aplikasyon';

  @override
  String get applyPurposeLabel => 'Saan mo kailangan ng tulong?';

  @override
  String get applyPurposeHint =>
      'Halimbawa: gamot ng aking ina pagkatapos ng operasyon';

  @override
  String get applyPurposeHelp =>
      'Sa sarili mong salita. Babasahin ito ng tanggapan.';

  @override
  String get applyPurposeEmpty => 'Sabihin kung para saan ang tulong.';

  @override
  String applyPurposeTooShort(int min) {
    return 'Dagdagan pa nang kaunti: hindi bababa sa $min titik.';
  }

  @override
  String applyPurposeTooLong(int max) {
    return 'Hanggang $max titik lamang.';
  }

  @override
  String get applyAmountLabel => 'Halagang hinihingi (hindi kailangan)';

  @override
  String get applyAmountHint => 'Halimbawa: 5,000';

  @override
  String get applyAmountHelp =>
      'Sa piso. Iwanang blangko kung hindi sigurado. Ang tanggapan ang magpapasya ng halaga.';

  @override
  String get applyAmountUnreadable =>
      'Isulat ang halaga sa piso, gaya ng 5000 o 5,000.50.';

  @override
  String get applyAmountZero =>
      'Isulat ang halagang higit sa zero, o iwanang blangko.';

  @override
  String get applyAmountTooLarge =>
      'Masyadong malaki ang halagang iyan. Iwanang blangko kung hindi sigurado.';

  @override
  String get applyServerFlagged =>
      'Hindi ito matanggap ng tanggapan. Tingnan ang isinulat mo.';

  @override
  String get applyDocumentsHeading => 'Mga dokumento';

  @override
  String applyDocumentsIntro(int limit) {
    return 'Isang file bawat isa: litrato (JPEG o PNG) o PDF, hanggang $limit MB bawat isa. Ilatag nang patag ang papel, punuin ang frame, at tiyaking nababasa ang bawat salita.';
  }

  @override
  String get applyObligationRequired => 'Kailangan';

  @override
  String get applyObligationOptional => 'Hindi kailangan';

  @override
  String get applyObligationConditional => 'Kung ito ay para sa iyo lamang';

  @override
  String get applyConditionUnstated =>
      'Sasabihin ng tanggapan kung kailangan mo ito.';

  @override
  String get applyAddFile => 'Magdagdag ng file';

  @override
  String get applyRemoveFile => 'Alisin';

  @override
  String get applyFilePhoto => 'Litrato';

  @override
  String get applyFilePdf => 'file na PDF';

  @override
  String applyFileAdded(String kind, String size) {
    return 'Naidagdag ang $kind · $size';
  }

  @override
  String get applyMissingFile => 'Idagdag ang file na ito para magpatuloy.';

  @override
  String get applyFileFlagged =>
      'Hindi matanggap ng tanggapan ang file na ito. Piliin itong muli, o pumili ng iba.';

  @override
  String get applyRequiredMissing =>
      'Idagdag ang mga dokumentong may markang Kailangan. Kung wala ka nito, puwede ka pa ring mag-apply nang personal sa tanggapan ng MSWDO.';

  @override
  String applyChooseSource(String name) {
    return 'Idagdag: $name';
  }

  @override
  String get applyNoPicker =>
      'Hindi makapili ng file ang teleponong ito. Puwede kang mag-apply nang personal sa tanggapan ng MSWDO.';

  @override
  String get applyReviewHeading => 'Suriin ang iyong aplikasyon';

  @override
  String get applyReviewProgramme => 'Programa';

  @override
  String get applyReviewPurpose => 'Para saan ito';

  @override
  String get applyReviewAmount => 'Halagang hinihingi';

  @override
  String get applyReviewNoAmount => 'Walang ibinigay';

  @override
  String get applyReviewDocuments => 'Mga dokumentong ipapadala mo';

  @override
  String applyReviewFile(String name, String kind, String size) {
    return '$name: $kind na $size';
  }

  @override
  String applyReviewNotSent(String name) {
    return '$name: hindi ipapadala';
  }

  @override
  String get applyEdit => 'Baguhin';

  @override
  String get applyReviewNote =>
      'Babasahin ito ng tanggapan at maaaring tawagan o padalhan ka ng mensahe. Hindi mo na ito mababago pagkatapos ipadala. Kung may kailangan pa ang tanggapan, ibabalik nito ang hiling at sasabihin kung ano.';

  @override
  String get applySend => 'Ipadala ang aplikasyon';

  @override
  String get applySending => 'Ipinapadala…';

  @override
  String get applyUnconfirmedTitle => 'Hindi pa kumpirmado';

  @override
  String get applyUnconfirmedBody =>
      'Hindi namin makumpirma kung natanggap ang iyong aplikasyon. Ligtas itong ipadala muli: hindi ito maihahain nang dalawang beses. Puwede mo ring tingnan ang Aking mga hiling.';

  @override
  String get applyOfflineTitle => 'Wala kang koneksyon';

  @override
  String get applyOfflineBody =>
      'Walang naipadala. Nandito pa sa telepono ang iyong mga sagot. Kumonekta sa internet at subukang muli.';

  @override
  String get applyCheckTitle => 'May kailangang tingnang muli';

  @override
  String get applyCheckBody =>
      'Walang naipadala. May bahaging hindi matanggap ng tanggapan. Tingnan ang mga may marka.';

  @override
  String get applyFileTitle => 'May file na hindi matanggap';

  @override
  String get applyFileBody =>
      'Walang naipadala. May file na masyadong malaki o hindi mabasa. Pumili ng mas maliit na litrato o ibang file, at subukang muli.';

  @override
  String get applyRateTitle => 'Masyadong maraming subok';

  @override
  String get applyRateBody =>
      'Walang naipadala. Maghintay ng ilang minuto, saka subukang muli.';

  @override
  String get applyClosedBody =>
      'Walang naipadala. Huminto na ang tanggapan sa pagtanggap ng aplikasyon sa app para sa programang ito. Pumunta o makipag-ugnayan sa tanggapan ng MSWDO para mag-apply.';

  @override
  String get applySessionTitle => 'Mag-sign in muli';

  @override
  String get applySessionBody =>
      'Walang naipadala. Natapos ang iyong session. Mag-sign in, saka subukang muli.';

  @override
  String get applyNotAllowedTitle => 'Hindi available para sa account na ito';

  @override
  String get applyNotAllowedBody =>
      'Walang naipadala. Hindi bukas sa account na ito ang pag-a-apply sa app. Masasabi pa ng tanggapan ng MSWDO.';

  @override
  String get applyServerTitle => 'Hindi ito natuloy';

  @override
  String get applyServerBody =>
      'Walang naipadala. May nagkaproblema sa aming panig. Subukang muli maya-maya.';

  @override
  String applyFailureReference(String reference) {
    return 'Reperensiya: $reference';
  }

  @override
  String get applyDoneTitle => 'Natanggap na ng MSWDO ang iyong aplikasyon';

  @override
  String get applyDoneMessage =>
      'Itago ang control number na ito. Ginagamit ito ng tanggapan kapag nagtanong ka tungkol sa iyong aplikasyon.';

  @override
  String get applyDoneControlNumber => 'Numero ng kontrol';

  @override
  String get applyDoneNote =>
      'Susuriin ito ng tanggapan sa intake. Makikita sa Aking mga hiling kung nasaan na ang iyong mga hiling. May mga hiling na pinag-uusapan lamang nang personal sa tanggapan ng MSWDO.';

  @override
  String get applyOpenMyRequests => 'Buksan ang Aking mga hiling';

  @override
  String get applyBackToTulong => 'Bumalik sa Tulong';

  @override
  String get addDocsTitle => 'Magdagdag ng dokumento';

  @override
  String addDocsIntro(int limit) {
    return 'Ibinalik ng tanggapan ang hiling na ito at kailangan nito ang mga dokumento sa ibaba. Magpadala ng litrato (JPEG o PNG) o PDF ng bawat isa, hanggang $limit MB bawat isa.';
  }

  @override
  String get addDocsStateNotSent => 'Hindi pa naipapadala';

  @override
  String get addDocsStateSendAgain => 'Ipadala itong muli';

  @override
  String get addDocsStateOther => 'Kailangan';

  @override
  String get addDocsSend => 'Ipadala ang mga dokumento';

  @override
  String get addDocsNothingChosen =>
      'Magdagdag ng kahit isang dokumento para maipadala.';

  @override
  String get addDocsDoneTitle => 'Naipadala ang mga dokumento';

  @override
  String get addDocsDoneMessage =>
      'Natanggap na ito ng tanggapan. Ito na ang magpapatuloy sa iyong hiling.';

  @override
  String get addDocsBackToRequest => 'Bumalik sa hiling';

  @override
  String get addDocsMovedTitle => 'Umusad na ang hiling';

  @override
  String get addDocsMovedBody =>
      'Walang naipadala. Hindi na naghihintay ng dokumento ang tanggapan para sa hiling na ito. Buksan itong muli para makita kung nasaan na ito.';

  @override
  String get addDocsUnconfirmedBody =>
      'Hindi namin makumpirma kung natanggap ang iyong mga dokumento. Ligtas itong ipadala muli: hindi ito maidadagdag nang dalawang beses. Puwede mo ring buksan ang hiling para tingnan.';

  @override
  String get addDocsNoneNeeded =>
      'Hindi naghihintay ng dokumento ang tanggapan para sa hiling na ito.';

  @override
  String get myRequestsChannelOnline => 'In-apply sa app';

  @override
  String get myRequestsChannelOffice => 'Inihain sa tanggapan';

  @override
  String get myRequestsChannelImported => 'Mula sa mga talaan ng tanggapan';

  @override
  String myRequestControlNumber(String number) {
    return 'Control no. $number';
  }

  @override
  String get myRequestSystemReference => 'Reperensiya ng sistema';

  @override
  String get myRequestChannel => 'Paano ito inihain';

  @override
  String get myRequestMissingHeading =>
      'Mga dokumentong kailangan ng tanggapan';

  @override
  String get myRequestAddDocuments => 'Magdagdag ng dokumento';

  @override
  String get verifiedLinkNote =>
      'May isa pang hakbang sa tanggapan: iniuugnay ng MSWDO ang iyong account sa iyong rekord doon, kadalasan kapag sinuri ang iyong ID, o sa counter. Kapag naiugnay na, makikita sa Aking mga hiling ang iyong mga hiling na tulong at puwede ka nang mag-apply ng Tulong sa app.';

  @override
  String get verifiedLinkedNote =>
      'Naiugnay na ang iyong account sa iyong rekord sa MSWDO. Makikita sa Aking mga hiling ang iyong mga hiling na tulong, at puwede ka nang mag-apply ng Tulong sa app.';

  @override
  String get verifiedApplyStep => 'Mag-apply ng Tulong';

  @override
  String get verifiedApplyStepDetail =>
      'Mula sa pahina ng programang may Mag-apply';

  @override
  String get verifiedRequestsStep =>
      'Subaybayan ang iyong mga hiling na tulong';

  @override
  String get verifiedRequestsStepDetail =>
      'Sa Aking mga hiling, kapag naiugnay na ng MSWDO ang iyong account';
}
