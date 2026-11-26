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
  String get failureNotFound => 'Hindi namin makita ang hinahanap mo.';

  @override
  String get failureFileType =>
      'Hindi maipapadala ang ganitong uri ng file. Subukan ang larawan o PDF.';

  @override
  String get failureRateLimited =>
      'Masyadong maraming subok. Maghintay saglit at subukang muli.';

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
  String get notifSwitchRegistryRecord =>
      'Mga pagbabago sa iyong rekord sa tanggapan';

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
      'Susuriin ng MSWDO ang iyong ipinadala. Hanggang doon, makikita sa iyong hiling na hinihintay pa ang tanggapan.';

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
  String get myRequestApplicantNoteFrom => 'Mula sa MSWDO:';

  @override
  String get myRequestDocumentsSentOn => 'Naipadala ang mga dokumento noong';

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

  @override
  String addDocsDoneStillNeeded(String documents) {
    return 'Kailangan pa ng tanggapan: $documents. Ipadala ang mga ito mula sa hiling kapag hawak mo na.';
  }

  @override
  String addDocsDoneFile(String kind, String size) {
    return '$kind na $size';
  }

  @override
  String get addDocsDoneSentOn => 'Naipadala noong';

  @override
  String get addDocsDoneNote =>
      'Buksan ang hiling anumang oras para makita kung nasaan na ito. Kung may kailangan pa ang tanggapan, makikita ito sa hiling.';

  @override
  String get accountSectorsSubtitle =>
      'Sino ang matutulungan: mga senior citizen, PWD at solo parent';

  @override
  String get authHelpTitle => 'Nakalimutan mo ang password mo?';

  @override
  String get authHelpSubtitle => 'Tulong sa pag-sign in';

  @override
  String get authHelpIntro =>
      'I-reset ito mula sa sign-in screen. Magpapadala kami ng code sa email o numero ng cellphone ng account, at hindi namin kailanman sinasabi kung may account nga.';

  @override
  String get authHelpNoCodeTitle => 'Hindi dumating ang code';

  @override
  String get authHelpNoCodeBody =>
      'Tiyaking tama ang na-type mong numero, at may signal ang telepono mo. Maaaring abutin nang ilang minuto ang mensahe. Maaari kang humingi ng bagong code mula sa sign-in screen.';

  @override
  String get authHelpCodeFailedTitle => 'Hindi gumana ang code';

  @override
  String get authHelpCodeFailedBody =>
      'Maikli lang ang bisa ng code at isang beses lang magagamit. Humingi ng bago at ilagay ito agad pagdating.';

  @override
  String get authHelpTooManyTitle => 'Sinasabing masyadong maraming subok';

  @override
  String get authHelpTooManyBody =>
      'Nililimitahan ng Taytay LGU ang mga subok na mag-sign in para protektahan ang iyong account. Maghintay muna nang kaunti, saka subukang muli. Walang problema sa iyong account.';

  @override
  String get authHelpLostNumberTitle => 'Wala na sa iyo ang numerong iyon';

  @override
  String get authHelpLostNumberBody =>
      'Ang pagpapalit ng numero sa isang account ay desisyon tungkol sa pagkakakilanlan, kaya personal itong ginagawa ng Taytay LGU. Pumunta sa munisipyo dala ang valid ID at hilinging i-update ang nakarehistro mong numero ng cellphone. Hindi mo kailangan ang app na ito o ang luma mong telepono para dito.';

  @override
  String get authHelpMisuseTitle =>
      'Maaaring may ibang gumamit ng iyong account';

  @override
  String get authHelpMisuseBody =>
      'Mag-sign in at mag-sign out sa device na ito mula sa Sign-in at seguridad. Kung hindi ka makapag-sign in, iulat ito sa munisipyo — direktang maaasikaso ng staff doon ang iyong account.';

  @override
  String get authHelpNeverAskHeading =>
      'Ang hindi namin kailanman hihingin sa iyo';

  @override
  String get authHelpNeverAskBody =>
      'Hindi kailanman hihingin ng staff ng Taytay LGU ang iyong one-time code, sa tawag, text o mensahe. Kung may humingi nito sa iyo, hindi siya taga-LGU. Huwag itong ibahagi.';

  @override
  String get authBackToSignIn => 'Bumalik sa sign in';

  @override
  String get authLockTitle => 'Naka-lock ang Taytay LGU IDS';

  @override
  String get authLockUnlock => 'I-unlock';

  @override
  String get authLockSignOutInstead => 'Mag-sign out na lang';

  @override
  String get authLockExplainIdle =>
      'Binuksan mo ang app lock, kaya hinihingi ng Taytay LGU IDS ang iyong fingerprint, mukha o screen lock bago muling ipakita ang iyong mga detalye.';

  @override
  String get authLockExplainUnlocking => 'Ina-unlock…';

  @override
  String get authLockExplainCancelled =>
      'I-unlock para makita muli ang iyong mga detalye.';

  @override
  String get authLockExplainFailed =>
      'Hindi iyon tumugma. Subukang muli, o mag-sign out at mag-sign in muli.';

  @override
  String get authLockExplainUnavailable =>
      'Hindi maipakita ng iyong device ang unlock prompt. Maaari kang mag-sign out at mag-sign in muli — walang problema sa iyong account.';

  @override
  String get authSignInTitle => 'Maligayang pagbabalik!';

  @override
  String get authSignInSubtitle =>
      'Mag-sign in sa iyong Taytay resident account.';

  @override
  String get authSignInNewHere => 'Bago rito?';

  @override
  String get authSignInIncorrectTitle => 'Mali ang email o password. ';

  @override
  String authSignInAttemptsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count subok na lang bago ang 15 minutong paghinto.',
    );
    return '$_temp0';
  }

  @override
  String get authIdentifierLabel => 'Email o numero ng cellphone';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authSignInIncorrectPassword => 'Mali ang password';

  @override
  String get authPasswordShow => 'Ipakita';

  @override
  String get authPasswordHide => 'Itago';

  @override
  String get authForgotPasswordLink => 'Nakalimutan ang password?';

  @override
  String get authEnterPassword => 'Ilagay ang iyong password.';

  @override
  String get authIdentifierEmpty =>
      'Ilagay ang iyong email o numero ng cellphone.';

  @override
  String get authIdentifierShape =>
      'Maglagay ng email address o 11-digit na numero ng cellphone.';

  @override
  String get authResetTitle => 'I-reset ang iyong password';

  @override
  String get authResetSubtitle =>
      'Ilagay ang email o numero ng cellphone ng iyong account. Magpapadala kami ng 6-digit na code para ma-reset ang iyong password.';

  @override
  String get authResetSendCode => 'Ipadala ang reset code';

  @override
  String get authResetNoEnumeration =>
      'Para sa iyong seguridad, hindi namin sinasabi kung may account para sa address na ito.';

  @override
  String get authResetSent => 'Kung may tugmang account, papunta na ang code.';

  @override
  String get authYourEmail => 'iyong email';

  @override
  String get authResetCodeTitle => 'Ilagay ang 6-digit na code';

  @override
  String authResetCodeSubtitle(String email) {
    return 'Nagpadala kami ng code sa $email.';
  }

  @override
  String get authResetSendNewCode => 'Magpadala ng bagong code';

  @override
  String get authResetVerifyCode => 'I-verify ang code';

  @override
  String get authResetCodeRules =>
      'Valid ang code nang 10 minuto. May 5 subok ka bawat code.';

  @override
  String get authResetBackToSignIn => 'Bumalik sa sign in';

  @override
  String get authResetWrongTitle => 'Mali ang code. ';

  @override
  String authResetAttemptsLeft(int remaining, int total) {
    return '$remaining sa $total subok na lang ang natitira.';
  }

  @override
  String authResetAttemptsPerCode(int total) {
    return 'May $total subok ka bawat code.';
  }

  @override
  String get authResetExpiredTitle => 'Nag-expire na ang code. ';

  @override
  String authResetExpiredBody(int count) {
    return 'Magpadala ng bago. May $count subok ka ulit.';
  }

  @override
  String get authResetUnavailableTitle => 'Subukang muli. ';

  @override
  String get authCodeServiceUnavailable =>
      'Hindi available ang serbisyo ngayon. Subukang muli.';

  @override
  String authResetExpiresIn(String time) {
    return 'Mag-e-expire sa $time';
  }

  @override
  String get authResetResend => 'Ipadala muli';

  @override
  String authResetResendIn(String time) {
    return 'Ipadala muli sa $time';
  }

  @override
  String get authResetMismatch => 'Hindi tugma ang password. Pakiulit.';

  @override
  String get authResetNewPasswordTitle => 'Gumawa ng bagong password';

  @override
  String authResetNewPasswordSubtitle(String email) {
    return 'Para sa $email. Gamitin ito sa susunod mong pag-sign in.';
  }

  @override
  String get authRequestNewCode => 'Humingi ng bagong code';

  @override
  String get authResetSavePassword => 'I-save ang password';

  @override
  String get authResetNotChangedTitle => 'Hindi pa napalitan ang password. ';

  @override
  String get authResetLinkExpiredTitle => 'Nag-expire na ang reset link mo. ';

  @override
  String get authResetLinkExpiredBody =>
      'Valid lang ito nang 15 minuto. Humingi ng bagong code para makapagpatuloy.';

  @override
  String get authResetNewPasswordLabel => 'Bagong password *';

  @override
  String get authResetConfirmLabel => 'Ulitin ang bagong password *';

  @override
  String get authResetMatched => 'Tugma ang password';

  @override
  String get authResetShowPassword => 'Ipakita';

  @override
  String get authResetHidePassword => 'Itago';

  @override
  String get authResetRuleLength => 'Hindi bababa sa 8 character';

  @override
  String get authResetRuleDigit => 'May numero';

  @override
  String get authResetRuleLetter => 'May letra';

  @override
  String authPasswordRuleMet(String rule) {
    return '$rule, natupad';
  }

  @override
  String authPasswordRuleNotMet(String rule) {
    return '$rule, hindi pa natupad';
  }

  @override
  String get authResetFailOffline =>
      'Walang koneksyon. Ikonekta ang telepono at subukang muli.';

  @override
  String get authResetFailRateLimited =>
      'Masyadong maraming subok. Maghintay nang ilang minuto bago subukang muli.';

  @override
  String get authResetFailLinkUsed =>
      'Hindi na magagamit ang reset link na ito. Humingi ng bagong code.';

  @override
  String get authResetFailWeak =>
      'Kailangan ng password na may 8 o higit pang titik, may letra at numero.';

  @override
  String get authResetFailOther =>
      'Hindi ito natapos ngayon. Subukang muli mamaya.';

  @override
  String get authResetDoneTitle => 'Na-update na ang password mo';

  @override
  String get authResetDoneBody =>
      'Gamitin ang bagong password sa susunod mong pag-sign in sa Taytay LGUIDS.';

  @override
  String get authResetDoneSecurityTitle => 'Para sa iyong seguridad. ';

  @override
  String get authResetDoneSecurityBody =>
      'Kung hindi ikaw ang nagpalit ng password, tumawag sa Municipal Hall o pumunta sa MSWDO.';

  @override
  String get authResetDoneSignIn => 'Mag-sign in';

  @override
  String get authHoldLeadReady =>
      'Puwede ka nang humingi ng bagong code. Ipapadala namin ito sa ';

  @override
  String get authHoldLeadLocked =>
      'Para protektahan ang account mo, pansamantala naming itinigil ang pagpapadala at pag-verify ng code para sa ';

  @override
  String get authHoldTitleReady => 'Subukan ulit ngayon';

  @override
  String get authHoldTitleLocked => 'Masyadong maraming subok';

  @override
  String get authHoldSubtitleReady => 'Puwede na ulit';

  @override
  String get authHoldSubtitleLocked => 'Pansamantalang naka-lock';

  @override
  String get authHoldWhyHeading => 'Bakit ito nangyari?';

  @override
  String get authHoldWhyBody =>
      'Masyadong maraming maling code o hiling ng bagong code sa maikling oras. Hindi mo kailangang gumawa ng bagong account.';

  @override
  String get authHoldSpokenReady => 'Tapos na ang paghihintay. 00:00';

  @override
  String authHoldSpokenWaiting(String time) {
    return 'Subukang muli sa $time';
  }

  @override
  String get authHoldClockReady => 'Tapos na ang paghihintay';

  @override
  String get authHoldClockWaiting => 'Subukang muli sa';

  @override
  String get authMobileShape =>
      'Maglagay ng 11-digit na numero ng cellphone na nagsisimula sa 09.';

  @override
  String get authWizardFinishForNow => 'Tapusin muna';

  @override
  String get authWizardInPersonOfferHeading =>
      'Mas gusto mong magpa-verify nang personal?';

  @override
  String get authWizardInPersonOffer =>
      'Hindi mo kailangang mag-upload ng kahit ano. Magdala ng valid ID sa tanggapan ng MSWDO at doon ive-verify ng staff ang iyong account. Walang kukuning selfie.';

  @override
  String get authWizardInPersonOfferAction =>
      'Magpa-verify na lang nang personal';

  @override
  String get authWizardInPersonChosenHeading =>
      'Pinili mong magpa-verify nang personal';

  @override
  String get authWizardInPersonChosen =>
      'Walang ipapadalang anuman tungkol sa iyong ID mula sa app. Mananatili ang iyong account at gagana ito kahit wala ang ID hanggang i-verify ka ng staff sa tanggapan.';

  @override
  String get authWizardInPersonUndo => 'Ipadala na lang ang aking ID sa app';

  @override
  String get authWizardInPersonStepTitle => 'Magpa-verify nang personal';

  @override
  String get authWizardInPersonStepSubtitle =>
      'Handa na ang iyong account. Ive-verify ito ng staff sa counter ng MSWDO.';

  @override
  String get authWizardChooseBarangay => 'Piliin ang iyong barangay.';

  @override
  String get authWizardEmailInvalid =>
      'Maglagay ng wastong email, hal. name@example.com';

  @override
  String get authWizardPasswordShort =>
      'Gumamit ng hindi bababa sa 8 character.';

  @override
  String get authWizardPasswordWeak =>
      'Gumamit ng hindi bababa sa 8 character, may letra at numero.';

  @override
  String get authWizardEnterCode => 'Ilagay ang 6-digit na code.';

  @override
  String get authWizardServiceUnavailable =>
      'Hindi available ang serbisyo ngayon. Subukang muli.';

  @override
  String authWizardWrongCode(int remaining, int total) {
    return 'Mali ang code. $remaining sa $total subok na lang ang natitira.';
  }

  @override
  String get authWizardTermsBoth =>
      'Sumang-ayon sa Terms of Use at kilalanin ang Privacy Notice: lagyan ng tsek ang bawat isa.';

  @override
  String get authWizardTermsOnly =>
      'Sumang-ayon sa Terms of Use para makapagpatuloy.';

  @override
  String get authWizardPrivacyOnly =>
      'Kilalanin ang Privacy Notice para makapagpatuloy.';

  @override
  String get authWizardConsentUnknown =>
      'Hindi namin makumpirma kung naitala ang iyong pahintulot. Ligtas na sumang-ayon muli: isang beses lang ito itatala.';

  @override
  String authWizardConsentNotRecorded(String reason) {
    return 'Hindi naitala ang iyong pahintulot. $reason';
  }

  @override
  String get authWizardAddIdFront =>
      'Magdagdag ng litrato ng harap ng iyong ID.';

  @override
  String get authWizardTakeSelfieFirst =>
      'Kumuha ng selfie para makapagpatuloy.';

  @override
  String get authWizardEmailTaken => 'May Taytay account na ang email na ito.';

  @override
  String get authWizardEmailExists =>
      'May account na gamit ang email na ito. Mag-sign in na lang, o gumamit ng ibang email.';

  @override
  String authWizardCodeNotSent(String email, String next) {
    return 'Na-save ang iyong account, pero hindi namin maipadala ang code sa $email. $next';
  }

  @override
  String get authWizardCodeNotSentOffline =>
      'Suriin ang iyong koneksyon, saka pindutin ang Magpatuloy para subukang muli.';

  @override
  String get authWizardCodeNotSentLater =>
      'Pindutin ang Magpatuloy para subukang muli maya-maya.';

  @override
  String get authWizardDetailsUnknown =>
      'Hindi namin makumpirma kung na-save ang iyong mga detalye. Pindutin ang Magpatuloy para ipadala itong muli: ligtas itong ulitin.';

  @override
  String get authWizardDetailsNotSaved =>
      'Hindi na-save ang iyong mga detalye.';

  @override
  String get authWizardDetailsCheckHighlighted =>
      'Pakisuri ang mga naka-highlight na detalye.';

  @override
  String get authWizardDetailsEmailConflict =>
      'Nasa ibang Taytay account na ang email na ito. Humingi ng tulong sa munisipyo.';

  @override
  String get authWizardSummaryIsDraft => 'Draft ang buod sa hakbang na ito.';

  @override
  String get authWizardProgressLabel => 'Progreso ng paggawa ng account';

  @override
  String get authWizardPersonalTitle => 'Tungkol sa iyo';

  @override
  String get authWizardPersonalSubtitle =>
      'Mga pangunahing detalye lang. Makukumpleto mo ang iyong Resident Profile kapag na-verify na ang iyong account.';

  @override
  String get authWizardAccountCreatedTitle => 'Nagawa na ang account';

  @override
  String get authWizardAccountCreatedSubtitle =>
      'Ito ang email na gagamitin mo sa pag-sign in. Susunod, magpapadala kami ng 6-digit na code dito.';

  @override
  String get authWizardAccountTitle => 'Gawin ang iyong account';

  @override
  String get authWizardAccountSubtitle =>
      'Ito ang email at password na gagamitin mo sa pag-sign in. Susunod, magpapadala kami ng 6-digit na code sa email.';

  @override
  String get authWizardCodeExpiredTitle => 'Nag-expire na ang code';

  @override
  String authWizardCodeExpiredSubtitle(String address) {
    return 'Valid lang ang code nang 10 minuto. Magpadala ng bago sa $address.';
  }

  @override
  String get authWizardCodeTitle => 'Ilagay ang 6-digit na code';

  @override
  String authWizardCodeSubtitle(String address) {
    return 'Nagpadala kami ng code sa $address. Mag-e-expire ito sa loob ng 10 minuto.';
  }

  @override
  String get authWizardTermsTitle => 'Protektado ang iyong data';

  @override
  String get authWizardTermsSubtitle => 'Terms at Privacy';

  @override
  String get authWizardIdTitle =>
      'Mag-upload ng valid na ID mula sa pamahalaan';

  @override
  String get authWizardIdSubtitle =>
      'Ginagamit ito ng LGU para kumpirmahin kung sino ka. Siguraduhing malinaw ang apat na sulok at ang iyong pangalan.';

  @override
  String get authWizardSelfieTitle => 'Kumuha ng mabilis na selfie';

  @override
  String get authWizardSelfieSubtitle =>
      'Ikukumpara ito ng staff ng LGU sa iyong ID. Hindi ito gagamiting profile photo mo.';

  @override
  String get authWizardReviewTitle => 'Suriin ang iyong mga detalye';

  @override
  String get authWizardSendNewCode => 'Magpadala ng bagong code';

  @override
  String get authWizardChangeEmail => 'Palitan ang email address';

  @override
  String get authWizardConfirmEmail => 'Kumpirmahin ang email';

  @override
  String get authWizardSubmit => 'Ipadala para sa verification';

  @override
  String get authWizardCreateAccount => 'Gawin ang aking account';

  @override
  String authWizardFixFields(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pakiayos ang $count field para makapagpatuloy.',
    );
    return '$_temp0';
  }

  @override
  String get authWizardChoose => 'Pumili';

  @override
  String get authWizardStreetLabel => 'Kalye / Purok';

  @override
  String authWizardAddressHint(String street, String barangay) {
    return 'Tirahan: $street, Brgy. $barangay, Taytay, Rizal';
  }

  @override
  String get authWizardRuleLength => '8+ character';

  @override
  String get authWizardResendCode => 'Ipadala muli ang code';

  @override
  String authWizardResendIn(String time) {
    return 'Ipadala muli sa $time';
  }

  @override
  String get authWizardDidntGetIt => 'Hindi mo natanggap?';

  @override
  String get authWizardCheckSpam => 'Tingnan din ang iyong spam folder.';

  @override
  String get authWizardOldCodeTitle => 'Hindi na magagamit ang lumang code. ';

  @override
  String get authWizardNewCodeTries => 'Sa bagong code, may 5 subok ka ulit.';

  @override
  String get authWizardCanResendNow =>
      'Puwede nang magpadala muli · Tingnan din ang spam folder';

  @override
  String get authWizardCheckingConsent =>
      'Sinusuri ang pahintulot para sa selfie';

  @override
  String get authWizardIdFront => 'Harap ng ID';

  @override
  String get authWizardIdBack => 'Likod ng ID (opsyonal)';

  @override
  String get authWizardAddPhoto => 'Magdagdag ng litrato · JPG o PNG';

  @override
  String get authWizardAttached => 'Naka-attach';

  @override
  String get authWizardSelfieTipLight => 'Maliwanag, nakaharap sa camera';

  @override
  String get authWizardSelfieTipFace =>
      'Kita ang buong mukha: walang sunglasses, mask o sumbrero';

  @override
  String get authWizardSelfieTipAlone => 'Ikaw lang ang nasa litrato';

  @override
  String get authWizardTakeSelfie => 'Kumuha ng selfie';

  @override
  String get authWizardIdSidesBoth => 'harap at likod';

  @override
  String get authWizardIdSidesFront => 'harap';

  @override
  String authWizardIdCaptured(String sides) {
    return 'Nakuha: $sides';
  }

  @override
  String get authWizardNotAdded => 'Hindi pa naidagdag';

  @override
  String get authWizardRowName => 'Pangalan';

  @override
  String get authWizardRowEmail => 'Email';

  @override
  String get authWizardRowMobile => 'Cellphone';

  @override
  String get authWizardRowAddress => 'Tirahan';

  @override
  String get authWizardRowTerms => 'Terms at Privacy Notice';

  @override
  String get authWizardTermsAgreed => 'Sumang-ayon · naibigay ang pahintulot';

  @override
  String get authWizardTermsNotAgreed => 'Hindi pa sumasang-ayon';

  @override
  String get authWizardRowId => 'Valid ID';

  @override
  String get authWizardRowSelfie => 'Selfie';

  @override
  String get authWizardSelfieTaken => 'Nakuha na';

  @override
  String get authWizardSelfieNotTaken => 'Hindi pa nakukuha';

  @override
  String get authWizardEdit => 'I-edit';

  @override
  String get authWizardDoneTitle => 'Handa na ang lahat!';

  @override
  String authWizardDoneTitleNamed(String name) {
    return 'Handa na ang lahat, $name!';
  }

  @override
  String get authWizardDoneMessage =>
      'Nagawa na ang iyong account at naipadala na sa Taytay LGU ang iyong mga detalye para sa verification.';

  @override
  String get authWizardDoneVerification => 'Verification ng account';

  @override
  String get authWizardPendingReview => 'Naghihintay ng pagsusuri';

  @override
  String get authWizardDoneBody =>
      'Sinusuri ng staff ng Taytay LGU ang iyong ID at selfie sa munisipyo, sa sariling sistema ng tanggapan. Makakatanggap ka ng notification sa app na ito kapag nakapagpasya na sila. Habang naghihintay, maaari kang tumingin ng mga serbisyo at balita.';

  @override
  String get authWizardContinueToApp => 'Magpatuloy sa app';

  @override
  String authWizardPickerRequired(String label) {
    return '$label, kailangan';
  }

  @override
  String get authWizardNotChosen => 'Hindi pa napili';

  @override
  String get authWizardNameOnAccount => 'Pangalan sa iyong account';

  @override
  String get authWizardNoticeDraftPill =>
      'DRAFT · Hindi pa inilalathala ng Taytay LGU';

  @override
  String get authWizardNoticeLoading => 'Nilo-load ang Privacy Notice';

  @override
  String get authWizardNoticeFailedHeading =>
      'Hindi ma-load ang Privacy Notice';

  @override
  String get authWizardNoticeFailedBody =>
      'Suriin ang iyong koneksyon at subukang muli. Basahin ito bago mo ito kilalanin sa ibaba.';

  @override
  String authWizardNoticeVersion(String version) {
    return 'Bersyon $version';
  }

  @override
  String authWizardNoticeUpdated(String version, String date) {
    return '$version · Na-update noong $date';
  }

  @override
  String get authWizardDraftIntro =>
      'Kinokolekta ng Bayan ng Taytay ang iyong pangalan, contact details, address, valid ID at selfie para gawin at i-verify ang iyong resident account at para maibigay ang mga serbisyo ng bayan na hinihiling mo.';

  @override
  String get authWizardDraftUseTitle => 'Paano namin ito ginagamit';

  @override
  String get authWizardDraftUseBody =>
      'Pag-verify ng pagkakakilanlan at paninirahan, mga hiling sa serbisyo, at mga abiso mula sa LGU.';

  @override
  String get authWizardDraftWhoTitle => 'Sino ang makakakita nito';

  @override
  String get authWizardDraftWhoBody =>
      'Ang awtorisadong tauhan lamang ng Taytay LGU.';

  @override
  String get authWizardDraftRightsTitle => 'Ang iyong mga karapatan';

  @override
  String get authWizardDraftRightsBody =>
      'Ang malaman, ma-access, maitama, tumutol at mabura, at magsampa ng reklamo sa National Privacy Commission. Makipag-ugnayan sa Data Protection Officer ng LGU para sa mga hiling.';

  @override
  String get authWizardFullDocuments => 'Buong mga dokumento';

  @override
  String get authWizardReadTerms => 'Basahin ang buong Terms';

  @override
  String get authWizardReadPrivacy => 'Basahin ang buong Privacy Notice';

  @override
  String get authWizardSelfieGuideTaken =>
      'Gabay sa selfie, nakuha na ang selfie. Larawang guhit, walang totoong tao.';

  @override
  String get authWizardSelfieGuide =>
      'Gabay sa selfie. Larawang guhit, walang totoong tao.';

  @override
  String get authWizardIllustration => 'Larawang guhit · walang totoong tao';

  @override
  String get acctSignOutTitle => 'Mag-sign out sa device na ito?';

  @override
  String get acctSignOutBody =>
      'Kakailanganin mo ng bagong one-time code para makapag-sign in muli. Maaari ka pa ring tumingin ng mga serbisyo, tanggapan at anunsyo ng Taytay bilang bisita.';

  @override
  String acctRevokeOneTitle(String device) {
    return 'I-sign out ang $device?';
  }

  @override
  String get acctRevokeOneBody =>
      'Mai-sign out ang device na iyon sa iyong Taytay LGU IDS account. Ang sinumang gumagamit nito ay kakailanganin ng bagong one-time code na ipapadala sa iyong numero ng cellphone para makapag-sign in muli. Mananatiling naka-sign in ang device na ito.';

  @override
  String get acctRevokeOneAction => 'I-sign out ang device na iyon';

  @override
  String get acctRevokeOthersTitle => 'I-sign out ang lahat ng ibang device?';

  @override
  String get acctRevokeOthersBody =>
      'Mai-sign out ang lahat ng ibang telepono, tablet o computer na naka-sign in sa iyong Taytay LGU IDS account. Mananatiling naka-sign in ang device na ito. Ang sinumang gumagamit ng iba ay kakailanganin ng bagong one-time code na ipapadala sa iyong numero ng cellphone.';

  @override
  String get acctRevokeOthersAction => 'I-sign out ang iba';

  @override
  String get acctCloseConversationTitle => 'Isara ang usapang ito?';

  @override
  String get acctCloseConversationBody =>
      'Makikita ng tanggapan na sarado na ito. Maaari kang magsimula ng bagong mensahe pagkatapos.';

  @override
  String get acctCloseConversationAction => 'Isara ang usapan';

  @override
  String get acctNothingChangedTitle => 'Walang nabago';

  @override
  String get acctNothingChangedBody =>
      'Hindi na-update ang iyong profile. Maaari mong subukang muli.';

  @override
  String get acctNotConfirmedTitle => 'Hindi pa kumpirmado';

  @override
  String get acctNotConfirmedBody =>
      'Hindi namin makumpirma kung na-update ang iyong profile. Ligtas na i-save itong muli: ang parehong pagbabago ang ipapadala.';

  @override
  String get acctNameNotChangedTitle => 'Hindi napalitan ang iyong pangalan';

  @override
  String acctRefusedNothingSaved(String reason) {
    return '$reason Walang na-save.';
  }

  @override
  String acctRefusedNothingSavedKeepOthers(String reason) {
    return '$reason Walang na-save. I-save itong muli para mapanatili ang iba mong pagbabago.';
  }

  @override
  String get acctLanguageTitle => 'Wika';

  @override
  String get acctLanguageBody => 'Sinusunod ng app ang wika ng teleponong ito.';

  @override
  String get acctPasswordUpdatedTitle => 'Na-update ang password';

  @override
  String get acctPasswordUpdatedBody =>
      'Gamitin ang bagong password sa susunod mong pag-sign in.';

  @override
  String get acctNotifications => 'Mga notification';

  @override
  String get acctLoadingAccount => 'Kinukuha ang iyong account';

  @override
  String get acctMyTaytayId => 'Aking Taytay ID';

  @override
  String get acctMore => 'Iba pa';

  @override
  String acctUnreadCount(int count) {
    return '$count bago';
  }

  @override
  String get acctSampleMessages => 'mga halimbawang mensahe lamang';

  @override
  String get acctSampleConversation => 'halimbawang usapan lamang';

  @override
  String get acctRetry => 'Subukang muli';

  @override
  String get acctInboxEmptyTitle => 'Wala pang mensahe';

  @override
  String get acctInboxEmptyBody =>
      'Lalabas dito ang mga tanong na ipinadala mo sa mga tanggapan ng munisipyo at ang kanilang mga sagot.';

  @override
  String get acctMessageAnOffice => 'Magmensahe sa isang tanggapan';

  @override
  String get acctMessagingVerifiedOnly =>
      'Para lamang sa mga residenteng verified na ang pagmemensahe.';

  @override
  String get acctInboxErrorTitle => 'Hindi na-load ang mga mensahe';

  @override
  String get acctInboxErrorBody =>
      'Hindi maabot ang Taytay LGU. Maaari mong subukang muli.';

  @override
  String get acctSaveChanges => 'I-save ang mga pagbabago';

  @override
  String get acctLoadingProfile => 'Kinukuha ang iyong profile';

  @override
  String get acctProfilePhoto => 'Litrato sa profile';

  @override
  String get acctProfilePhotoNote =>
      'Litrato sa profile · susuriin ng LGU bago ito lumabas sa iyong ID';

  @override
  String get acctCannotChangeHere => 'Hindi ito mababago rito';

  @override
  String get acctLegalNameNote =>
      'Ang pagpapalit ng legal na pangalan ay dadaan sa Profile ng residente at sa muling verification.';

  @override
  String get acctNotificationSettings => 'Mga setting ng notification';

  @override
  String get acctNotificationSettingsDetail =>
      'Ang mga ipinapaalam sa iyo ng Taytay LGU';

  @override
  String get acctSectionApp => 'App';

  @override
  String get acctLanguageOptions => 'Ingles · Filipino';

  @override
  String get acctChangePassword => 'Palitan ang password';

  @override
  String get acctSectionPrivacy => 'Privacy';

  @override
  String get acctPrivacyNotice => 'Privacy Notice';

  @override
  String get acctPrivacyNoticeDetail =>
      'Data Privacy Act of 2012 · Hinihintay pa ang tekstong aprubado ng LGU';

  @override
  String get acctYourConsents => 'Ang iyong mga pahintulot';

  @override
  String get acctYourConsentsDetail => 'Suriin o bawiin ang mga pinayagan mo';

  @override
  String get acctRequestDataCopy => 'Humingi ng kopya ng aking data';

  @override
  String get acctRightToAccess => 'Karapatang ma-access ang iyong data';

  @override
  String get acctSealLabel => 'Selyo ng Taytay, Rizal';

  @override
  String acctAboutVersion(String version) {
    return 'Bayan ng Taytay, Rizal · bersyon $version';
  }

  @override
  String get acctPhotoCredits => 'Mga kredito ng litrato';

  @override
  String get acctOfficeBannerPhotos => 'Mga litrato sa banner ng tanggapan';

  @override
  String acctBannerSummary(int count) {
    return '$count litrato · Wikimedia Commons';
  }

  @override
  String get acctSectionAbout => 'Tungkol sa app';

  @override
  String get acctMunicipalSeal => 'Selyo ng munisipyo';

  @override
  String get acctMunicipalSealDetail =>
      'Inilalarawan sa taytayrizal.gov.ph/seal · Wikimedia';

  @override
  String get acctLoadingPrivacyNotice => 'Kinukuha ang privacy notice';

  @override
  String get acctDraftPill =>
      'DRAFT · Ilalagay pa ang tekstong aprubado ng LGU';

  @override
  String get acctNoticeCollectTitle => 'Ano ang kinukuha namin';

  @override
  String get acctNoticeCollectBody =>
      'Pangalan, contact details, address, valid ID at selfie, at mga mensaheng ipinapadala mo sa mga tanggapan.';

  @override
  String get acctNoticeWhyTitle => 'Bakit';

  @override
  String get acctNoticeWhyBody =>
      'Para kumpirmahing residente ka ng Taytay at maibigay ang mga serbisyong hinihiling mo.';

  @override
  String get acctNoticeWhoTitle => 'Sino ang makakakita nito';

  @override
  String get acctNoticeWhoBody =>
      'Ang awtorisadong staff ng LGU sa tanggapang kausap mo. Hindi ito ibinebenta o ibinabahagi para sa marketing.';

  @override
  String get acctNoticeRightsTitle => 'Ang iyong mga karapatan';

  @override
  String get acctNoticeRightsBody =>
      'Pag-access, pagtatama, pagtutol at pagbura. Makipag-ugnayan sa Data Protection Officer ng LGU';

  @override
  String get acctNoticePending =>
      'Lalabas dito ang privacy notice kapag nailathala na ito ng Taytay LGU.';

  @override
  String get acctBannersIntroBefore =>
      'Lahat ay mula sa Wikimedia Commons. Ang mga litratong may markang ';

  @override
  String get acctBannersIntroAfter =>
      ' ay nagpapakita ng mga tao at pansamantala lamang hanggang magbigay ang Taytay LGU ng sarili nitong mga litratong may pahintulot.';

  @override
  String get acctReplaceMark => 'Papalitan';

  @override
  String get acctConversation => 'Usapan';

  @override
  String get acctConversationClosed => 'Sarado na ang usapang ito.';

  @override
  String get acctAttachment => 'Attachment';

  @override
  String get acctPhotoReliefDistribution =>
      'Pamamahagi ng relief ng DSWD (lindol noong 2026)';

  @override
  String get acctPhotoMunicipalHall => 'Munisipyo ng Taytay';

  @override
  String get acctPhotoParishChurch => 'Parokya ni San Juan Bautista';

  @override
  String get acctPhotoPesoNotes => 'Mga perang papel at barya ng Pilipinas';

  @override
  String get acctPhotoMuzonStreet => 'Kalye sa Muzon, Taytay';

  @override
  String get acctPhotoSariSari => 'Tindahang sari-sari, Maynila';

  @override
  String get acctPhotoRescuers => 'Mga rescuer ng BFP, Angeles City';

  @override
  String get acctPhotoRescueVehicle => 'Sasakyang pang-rescue, Bula';

  @override
  String get acctPhotoSkillsTraining => 'Pagsasanay sa kasanayan ng TESDA';

  @override
  String get acctPhotoSkCouncil => 'Konseho ng Sangguniang Kabataan';

  @override
  String get acctPhotoSkCourt => 'Basketball court ng SK';

  @override
  String get acctPhotoHealthCentre => 'Health center ng barangay, Bula';

  @override
  String get acctPhotoVaccination => 'Pagbabakuna, Camarines Sur';

  @override
  String get acctMessagesNoneUnread => 'Walang bagong sagot';

  @override
  String acctMessagesUnread(int count, String office) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bagong sagot mula sa $office',
    );
    return '$_temp0';
  }

  @override
  String get acctVerifiedResident => 'Verified na residente';

  @override
  String get acctMenuProfile => 'Profile ng residente';

  @override
  String get acctMenuProfileDetail => 'Pangalan, contact, barangay';

  @override
  String acctMenuProfileComplete(int percent) {
    return '$percent% kumpleto';
  }

  @override
  String get acctMenuSectors => 'Mga sektor at benepisyo';

  @override
  String get acctMessages => 'Mga mensahe';

  @override
  String get acctMenuVerification => 'Katayuan ng verification';

  @override
  String acctVerifiedOn(String date) {
    return 'Na-verify · $date';
  }

  @override
  String get acctMenuRequestDocuments => 'Humiling ng dokumento';

  @override
  String get acctMenuRequestDocumentsDetail =>
      'Mga sertipiko at kopya mula sa mga tanggapan';

  @override
  String get acctMenuHousehold => 'Sambahayan';

  @override
  String get acctMenuHouseholdDetail => 'Ang address at ang iyong papel dito';

  @override
  String get acctMenuSettings => 'Mga setting';

  @override
  String get acctMenuSettingsDetail => 'Mga notification, wika';

  @override
  String get acctMenuPrivacy => 'Privacy at data';

  @override
  String get acctMenuPrivacyDetail =>
      'Privacy Notice, ang iyong mga karapatan sa data';

  @override
  String get acctMenuCredits => 'Mga kredito ng litrato at tungkol sa app';

  @override
  String get acctMenuCreditsDetail => 'Mga lisensya, bersyon ng app';

  @override
  String get acctVerifiedByLgu => 'Verified ng Taytay LGU';

  @override
  String get acctCannotAttach =>
      'Hindi makapag-attach ng file ang teleponong ito.';

  @override
  String get acctWriteBeforeSending =>
      'Sumulat muna ng mensahe bago magpadala.';

  @override
  String get acctEditProfile => 'I-edit ang profile';

  @override
  String get acctFieldEmail => 'Email';

  @override
  String get acctSettingsTitle => 'Mga setting at privacy';

  @override
  String get acctSecurityTitle => 'Sign-in at seguridad';

  @override
  String get acctAppLock => 'App lock';

  @override
  String get acctAppLockLede =>
      'Hingin ang iyong fingerprint, mukha o screen lock bago ipakitang muli ang iyong mga detalye pagkatapos mong umalis sa app.';

  @override
  String get acctLockThisApp => 'I-lock ang app na ito';

  @override
  String get acctAppLockNote =>
      'Ang lock na ito ay para lamang sa teleponong ito. Hindi ito ang paraan ng Taytay LGU para malaman kung sino ka, at walang nababago sa magagawa ng iyong account kapag binuksan ito.';

  @override
  String get acctWhereSignedIn => 'Kung saan ka naka-sign in';

  @override
  String get acctThisDevice => 'Ang device na ito';

  @override
  String get acctSignOutLede =>
      'Inaalis ng pag-sign out ang iyong session sa teleponong ito. Magagamit mo pa rin ang mga pampublikong serbisyo ng Taytay bilang bisita.';

  @override
  String get acctSignOutThisDevice => 'Mag-sign out sa device na ito';

  @override
  String get acctLockOn =>
      'Naka-on. Hihilingin sa iyong mag-unlock pagbalik mo sa app.';

  @override
  String get acctLockOff => 'Naka-off.';

  @override
  String get acctLockNotEnrolled =>
      'Mag-set up ng fingerprint, face unlock o screen lock sa settings ng iyong telepono para magamit ito.';

  @override
  String get acctLockUnsupported =>
      'Hindi makapagpakita ng unlock prompt ang teleponong ito, kaya hindi available dito ang app lock.';

  @override
  String get acctLockCancelled =>
      'Hindi nabuksan ang app lock. Maaari mong subukang muli anumang oras.';

  @override
  String get acctLockFailed =>
      'Hindi iyon tumugma, kaya nananatiling naka-off ang app lock.';

  @override
  String get acctLockUnavailable =>
      'Hindi naipakita ng iyong telepono ang unlock prompt.';

  @override
  String get acctCheckingSignIns => 'Sinusuri kung saan ka naka-sign in';

  @override
  String get acctSignInsErrorTitle => 'Hindi masuri ang iyong mga sign-in';

  @override
  String get acctSignInsErrorBody =>
      'Hindi namin maabot ang Taytay LGU IDS para ilista kung saan naka-sign in ang iyong account. Subukang muli maya-maya. Laging tinatapos ng pag-sign out dito ang session ng device na ito.';

  @override
  String get acctCheckDevicesLede =>
      'Tingnan ang mga device kung saan kasalukuyang naka-sign in ang iyong Taytay LGU IDS account.';

  @override
  String get acctCheckMyDevices => 'Tingnan ang aking mga device';

  @override
  String acctSignOutOtherDevices(int count) {
    return 'I-sign out ang lahat ng $count pang ibang device';
  }

  @override
  String get acctSignedIn => 'Naka-sign in';

  @override
  String acctLastUsed(String date) {
    return 'Huling ginamit noong $date';
  }

  @override
  String get acctAccountTitle => 'Account';

  @override
  String get acctResident => 'Residente';

  @override
  String get acctNotSignedIn => 'Hindi naka-sign in';

  @override
  String get acctNotYetVerified => 'Hindi pa verified ang account';

  @override
  String get acctPreferences => 'Mga kagustuhan';

  @override
  String get acctVibration => 'Pag-vibrate';

  @override
  String get acctVibrationDetail =>
      'Maikling pag-vibrate kapag nagtagumpay o pumalya ang isang aksyon.';

  @override
  String get acctSectionSecurity => 'Seguridad';

  @override
  String get acctSecurityDetail =>
      'App lock, pag-sign out, at kung saan ka naka-sign in.';

  @override
  String get acctServiceStatus => 'Katayuan ng serbisyo';

  @override
  String get acctServiceStatusLede =>
      'Tingnan kung naaabot ang mga serbisyo ng Taytay LGU. Makakatulong ito para malaman kung sira ang serbisyo o ang iyong koneksyon.';

  @override
  String get acctChecking => 'Sinusuri…';

  @override
  String get acctCheckServiceStatus => 'Tingnan ang katayuan ng serbisyo';

  @override
  String get acctCurrentPassword => 'Kasalukuyang password';

  @override
  String get acctNewPassword => 'Bagong password';

  @override
  String get acctRepeatNewPassword => 'Ulitin ang bagong password';

  @override
  String get acctEnterCurrentPassword =>
      'Ilagay ang iyong kasalukuyang password.';

  @override
  String get acctEnterNewPassword => 'Maglagay ng bagong password.';

  @override
  String get acctPasswordsDoNotMatch =>
      'Hindi magkatugma ang mga password na iyon.';

  @override
  String get acctPasswordWrong => 'Hindi tugma ang password na iyon.';

  @override
  String get acctPasswordWeak =>
      'Gumamit ng hindi bababa sa 8 karakter, na may titik at numero.';

  @override
  String get acctSaving => 'Sine-save';

  @override
  String get acctSavePassword => 'I-save ang password';

  @override
  String get settingsTitle => 'Mga setting';

  @override
  String get settingsSectionYourAccount => 'Ang iyong account';

  @override
  String get settingsRowAccountTitle => 'Account';

  @override
  String get settingsRowAccountDetail =>
      'Ang iyong mga detalye at kung paano ka nagsa-sign in';

  @override
  String get settingsRowSecurityTitle => 'Sign-in at seguridad';

  @override
  String get settingsRowSecurityDetail => 'App lock at mga device';

  @override
  String get settingsRowNotificationsTitle => 'Mga notification';

  @override
  String get settingsRowNotificationsDetail =>
      'Mga ipinapaalam sa iyo ng Taytay LGU';

  @override
  String get settingsSectionPrivacy => 'Privacy';

  @override
  String get settingsRowPrivacyNoticeTitle => 'Privacy notice';

  @override
  String get settingsRowPrivacyNoticeDetail =>
      'Ano ang hawak ng Taytay LGU, at ang iyong mga karapatan';

  @override
  String get settingsRowConsentsTitle =>
      'Ang iyong mga pahintulot at hiling tungkol sa account';

  @override
  String get settingsRowConsentsDetail =>
      'Ang mga sinang-ayunan mo, at paghiling ng mga pagbabago';

  @override
  String get settingsSectionAccessibility => 'Accessibility';

  @override
  String get settingsHelp => 'Tulong sa app';

  @override
  String get settingsRowHelpTitle =>
      'Tulong at pakikipag-ugnayan sa Taytay LGU';

  @override
  String get settingsRowHelpDetail =>
      'Mga tanong, at saan pupunta nang personal';

  @override
  String get settingsSectionAbout => 'Tungkol sa app';

  @override
  String get settingsReduceMotionTitle => 'Bawasan ang galaw';

  @override
  String get settingsReduceMotionOsOn =>
      'Naka-on na, dahil nakatakda ang iyong telepono na bawasan ang galaw.';

  @override
  String get settingsReduceMotionDetail =>
      'Pinapaikli o inaalis ang mga animation.';

  @override
  String get settingsVibrationTitle => 'Pag-vibrate';

  @override
  String get settingsVibrationDetail =>
      'Maikling pag-vibrate kapag may nakumpirma.';

  @override
  String get settingsTextSizeNote =>
      'Sinusunod ng laki ng teksto ang setting ng iyong telepono. Ginawa ang app na ito para manatiling nababasa kahit sa pinakamalaking setting.';

  @override
  String get settingsTelemetryNone =>
      'Walang ipinapadala ang app na ito kaninuman na impormasyon tungkol sa kung paano mo ito ginagamit. Kumokonekta lang ito sa Taytay LGU para ipakita sa iyo ang hiningi mo.';

  @override
  String get settingsTelemetryTitle => 'Tumulong na pahusayin ang app na ito';

  @override
  String get settingsTelemetryDetail =>
      'Ipinapadala kung aling mga screen ang binuksan at kung gumana ang mga ito. Hindi kailanman ang iyong pangalan, ang iyong mga dokumento, ang inaplayan mo, o anumang na-type mo.';

  @override
  String get settingsAboutBody =>
      'Ang Taytay LGU IDS ang app para sa mga residente ng Bayan ng Taytay, Rizal. Inilalabas ito ng pamahalaang bayan.';

  @override
  String get settingsAboutReach =>
      'Isa lang ang app na ito sa mga paraan para maabot ang Taytay LGU. Ginagawa rin ng munisipyo at ng iyong barangay hall ang lahat ng ginagawa nito, at higit pa.';

  @override
  String settingsVersion(String version) {
    return 'Bersyon $version';
  }

  @override
  String get settingsTestBuildTitle => 'Pansubok na build. ';

  @override
  String settingsTestBuildBody(String environment) {
    return 'Isa itong $environment build, hindi ang app na inilabas para sa mga residente.';
  }

  @override
  String get settingsSignOutTitle => 'Mag-sign out sa device na ito?';

  @override
  String get settingsSignOutConsequence =>
      'Kakailanganin mo ang iyong numero ng cellphone at isang code para makapag-sign in muli. Walang maaalis sa anumang naipadala mo sa Taytay LGU.';

  @override
  String get settingsStaySignedIn => 'Manatiling naka-sign in';

  @override
  String get settingsConsentsTitle =>
      'Mga pahintulot at hiling tungkol sa account';

  @override
  String get settingsLoadingConsents => 'Nilo-load ang iyong mga pahintulot';

  @override
  String get settingsSelfieConsent => 'Pahintulot sa selfie';

  @override
  String get settingsSectionAgreed => 'Ang mga sinang-ayunan mo';

  @override
  String get settingsNoConsents =>
      'Walang nakatalang pahintulot mo sa Taytay LGU.';

  @override
  String get settingsSectionAskingChanges =>
      'Paghiling ng mga pagbabago sa Taytay LGU';

  @override
  String get settingsRequestsNotOn =>
      'Hindi pa bukas sa app na ito ang mga hiling na ito. Matatanggap ang mga ito nang personal sa munisipyo, at masasabi sa iyo ng iyong barangay hall kung saan pupunta.';

  @override
  String get settingsAskCorrection => 'Humiling ng pagwawasto';

  @override
  String get settingsCorrectionNotice =>
      'Ang Taytay LGU ang nagwawasto sa iyong rekord bilang residente. Gamitin ang paraan ng pagwawasto sa screen ng iyong sambahayan o profile para malaman ng tanggapan kung aling rekord ang tinutukoy mo.';

  @override
  String get settingsReauthTitle =>
      'Maaaring hilingin sa iyong mag-sign in muli. ';

  @override
  String get settingsReauthBody =>
      'Hinihiling ng Taytay LGU sa mga residente na kumpirmahin kung sino sila bago ang mga pagbabagong tulad nito.';

  @override
  String get settingsCheckingSelfieConsent =>
      'Sinusuri ang pahintulot sa selfie';

  @override
  String get settingsSelfieConsentUnreadable =>
      'Hindi mabasa ang katayuan ng iyong pahintulot sa selfie. Pakisuri ang iyong koneksyon at subukang muli.';

  @override
  String get settingsSelfieConsentUnpublished =>
      'Wala pang inilalabas na pahintulot sa selfie ang Taytay LGU, kaya walang kinukuhang selfie ang app at wala itong hawak na pahintulot para rito.';

  @override
  String get settingsSelfieConsentOwed =>
      'Hindi ka pa pumapayag sa pahintulot sa selfie. Nagtatanong muna ang app bago ito kumuha ng anumang selfie, at maaari kang magpa-verify nang personal sa halip.';

  @override
  String settingsSelfieConsentGiven(String version) {
    return 'Pumayag ka na maaaring kunin at gamitin ng Taytay LGU ang iyong selfie (bersyon $version).';
  }

  @override
  String settingsSelfieConsentGivenOn(String date, String version) {
    return 'Pumayag ka noong $date na maaaring kunin at gamitin ng Taytay LGU ang iyong selfie (bersyon $version).';
  }

  @override
  String get settingsWhatWithdrawingDoes => 'Ano ang nangyayari kapag binawi';

  @override
  String get settingsBiometricWithdrawn =>
      'Naitala na ng Taytay LGU ang pagbawi mo, at nabura na ang iyong mga selfie.';

  @override
  String get settingsWithdrawalUnconfirmed =>
      'Hindi namin makumpirma kung naitala ang pagbawi mo. Ligtas na subukang muli: isang beses lang ito itatala.';

  @override
  String get settingsWithdrawalNotRecorded =>
      'Hindi naitala ang pagbawing iyon. Walang nagbago, at maaari mong subukang muli.';

  @override
  String get settingsWithdrawalRecorded =>
      'Naitala na ng Taytay LGU ang pagbawi mo.';

  @override
  String get settingsConsentRecordedAgain =>
      'Muling naitala ng Taytay LGU ang pahintulot na ito.';

  @override
  String get settingsConsentUnconfirmed =>
      'Hindi namin makumpirma kung naitala ang iyong pahintulot. Ligtas na subukang muli: isang beses lang ito itatala.';

  @override
  String get settingsConsentNotRecorded =>
      'Hindi naitala ang pahintulot na iyon. Walang nagbago, at maaari mong subukang muli.';

  @override
  String get settingsWithdrawConsentTitle => 'Bawiin ang pahintulot na ito?';

  @override
  String get settingsWithdrawConsentConsequence =>
      'Titigil ang Taytay LGU sa pagsandal sa pahintulot na ito mula sa sandaling maitala ang pagbawi. Mananatili kung ano ito ang anumang nagawa na sa ilalim nito — hindi umaabot pabalik sa nakaraan ang pagbawi.';

  @override
  String get settingsWithdrawIt => 'Bawiin ito';

  @override
  String get settingsLeaveInPlace => 'Panatilihin ito';

  @override
  String settingsConsentAgreedOn(String date) {
    return 'Sumang-ayon noong $date';
  }

  @override
  String settingsConsentWithdrawnOn(String date) {
    return 'Binawi noong $date';
  }

  @override
  String get settingsConsentInForce => 'May bisa';

  @override
  String get settingsConsentWithdrawn => 'Binawi';

  @override
  String get settingsWithdrawConsent => 'Bawiin ang pahintulot na ito';

  @override
  String get settingsAcceptAgain => 'Tanggapin muli';

  @override
  String get settingsConsentKindTerms => 'Terms of Use';

  @override
  String get settingsConsentKindPrivacy => 'Privacy Notice';

  @override
  String get settingsConsentKindUnspecified =>
      'Terms at Privacy Notice (naunang pagsang-ayon)';

  @override
  String get settingsConsentVersionAtTheTime => 'na umiiral noon';

  @override
  String settingsConsentStatementTerms(String version) {
    return 'Sumang-ayon sa Terms of Use, bersyon $version';
  }

  @override
  String settingsConsentStatementPrivacy(String version) {
    return 'Kinilala ang Privacy Notice, bersyon $version';
  }

  @override
  String settingsConsentStatementBiometric(String version) {
    return 'Pumayag na maaaring gamitin ng Taytay LGU ang iyong selfie, bersyon $version';
  }

  @override
  String settingsConsentStatementUnspecified(String version) {
    return 'Sumang-ayon sa Terms at sa Privacy Notice nang sabay, bersyon $version';
  }

  @override
  String get settingsCloseAction => 'Isara ang aking account';

  @override
  String get settingsCloseEffects =>
      'Agad na magkakabisa ang pagsasara ng iyong account, at hindi ka na makakapag-sign in dito muli. Aalisin dito ang iyong pangalan, petsa ng kapanganakan, contact details, address at profile photo, kakanselahin ang iyong digital ID, at buburahin ang mga litrato ng ID at selfie na ipinadala mo. Hindi na makakatanggap ng abiso mula sa app na ito ang iyong mga telepono. Kung ikaw ang puno ng isang sambahayan sa app, aalisin ang sambahayang iyon. Mananatili sa mga tanggapan ng Taytay LGU ang mga rekord na hawak nila tungkol sa iyo, gaya ng iyong rekord sa tanggapan ng MSWDO at ng mga hiling na isinampa mo. Hindi na ito maaaring bawiin sa app.';

  @override
  String get settingsCloseConfirmTitle => 'Isara ang iyong account?';

  @override
  String get settingsCloseConfirm =>
      'Isasara na ngayon ang iyong account at hindi ka na makakapag-sign in dito muli. Kakanselahin ang iyong digital ID, at aalisin sa account ang iyong mga detalye, litrato at larawan ng ID. Mananatili sa mga tanggapan ng Taytay LGU ang mga rekord na hawak nila tungkol sa iyo. Hindi na ito maaaring bawiin sa app.';

  @override
  String get settingsClosed =>
      'Sarado na ang iyong account. Hindi ka na makakapag-sign in dito muli, at kanselado na ang iyong digital ID. Mananatili sa mga tanggapan ng Taytay LGU ang mga rekord na hawak nila tungkol sa iyo.';

  @override
  String get settingsCloseAlreadyClosed =>
      'Sarado na ang iyong account. Hindi ka na makakapag-sign in dito muli.';

  @override
  String get settingsCloseNotConfirmed =>
      'Hindi namin makumpirma kung naisara ang iyong account. Ligtas na subukang muli: isang beses lang naisasara ang isang account.';

  @override
  String get settingsCloseNotClosed =>
      'Hindi naisara ang iyong account. Walang nagbago, at maaari mong subukang muli.';

  @override
  String get settingsHelpGettingHelp => 'Paghingi ng tulong';

  @override
  String get settingsHelpIntro =>
      'Ang lahat ng nasa app na ito ay inaasikaso rin sa munisipyo ng Taytay at sa iyong barangay hall. Kung may hindi gumagana rito, hindi kailanman mali ang pumunta nang personal.';

  @override
  String get settingsFaqAccountQuestion =>
      'Kailangan ko ba ng account para magamit ang app na ito?';

  @override
  String get settingsFaqAccountAnswer =>
      'Hindi. Bukas sa lahat ang mga anunsyo, kaganapan at listahan ng mga serbisyo ng munisipyo. Kailangan mo lang ng account para sa mga bagay tungkol sa iyo — ang iyong mga aplikasyon, mga dokumento, at ID.';

  @override
  String get settingsFaqVerifyQuestion =>
      'Bakit nito ipinapakumpirma ang aking pagkakakilanlan?';

  @override
  String get settingsFaqVerifyAnswer =>
      'May mga serbisyong gumagamit ng iyong rekord bilang residente sa Taytay LGU, kaya kailangang matiyak ng tanggapan na ikaw talaga iyon. Isang beses lang ginagawa ang verification at binubuksan nito ang mga serbisyong iyon.';

  @override
  String get settingsFaqDurationQuestion =>
      'Gaano katagal ang aking aplikasyon?';

  @override
  String get settingsFaqDurationAnswer =>
      'Ang Taytay LGU ang nagpapasya niyan, at depende ito sa serbisyo at sa mga dokumento. Ipinapakita ng app na ito kung nasaan na ang iyong aplikasyon at kung ano ang susunod na kailangan, pero hindi ito makakapangako ng petsa.';

  @override
  String get settingsFaqRecordQuestion => 'May mali sa aking rekord.';

  @override
  String get settingsFaqRecordAnswer =>
      'Maaari mo itong i-report mula sa screen ng iyong profile o sambahayan. Ang tanggapan ang sumusuri at nagwawasto nito — hindi kailanman direktang binabago ng app ang iyong rekord.';

  @override
  String get settingsFaqLostPhoneQuestion => 'Nawala ang aking telepono.';

  @override
  String get settingsFaqLostPhoneAnswer =>
      'Mag-sign in sa bago mong telepono. Kung sa tingin mo ay may ibang gumagamit ng iyong account, sabihan ang munisipyo, at i-sign out ang ibang mga device mula sa screen ng sign-in at seguridad.';

  @override
  String get settingsHelpContactTitle => 'Pakikipag-ugnayan sa Taytay LGU. ';

  @override
  String get settingsHelpContactBody =>
      'Gamitin ang contact details na nakalathala sa serbisyo, programa o kaganapang itinatanong mo — galing ang mga iyon sa tanggapang namamahala rito. Laging maituturo sa iyo ng iyong barangay hall ang tamang mesa.';

  @override
  String get platformConsentBothChanged =>
      'Nagbago ang Terms of Use at ang Privacy Notice';

  @override
  String get platformConsentTermsChanged => 'Nagbago ang Terms of Use';

  @override
  String get platformConsentPrivacyChanged => 'Nagbago ang Privacy Notice';

  @override
  String get platformTermsUpdated => 'Na-update ang Terms of Use.';

  @override
  String platformTermsUpdatedOn(String date) {
    return 'Na-update ang Terms of Use noong $date.';
  }

  @override
  String get platformPrivacyUpdated => 'Na-update ang Privacy Notice.';

  @override
  String platformPrivacyUpdatedOn(String date) {
    return 'Na-update ang Privacy Notice noong $date.';
  }

  @override
  String get platformConsentRecording => 'Itinatala ang iyong pagsang-ayon…';

  @override
  String get platformConsentAgree => 'Sumasang-ayon ako';

  @override
  String get platformConsentContinueForNow => 'Magpatuloy muna';

  @override
  String get platformConsentReadChanges =>
      'Pakibasa kung ano ang nagbago. Para patuloy mong magamit ang iyong account, lagyan ng tsek ang bawat teksto sa ibaba para sumang-ayon dito. Kung hindi ka sumasang-ayon, maaari kang mag-sign out at patuloy na gamitin ang app bilang bisita.';

  @override
  String get platformReadTerms => 'Basahin ang Terms of Use';

  @override
  String get platformReadPrivacy => 'Basahin ang Privacy Notice';

  @override
  String get platformAgreementUnconfirmed =>
      'Hindi namin makumpirma kung naitala ang iyong pagsang-ayon. Ligtas na sumang-ayon muli: isang beses lang ito itatala.';

  @override
  String platformAgreementNotRecorded(String reason) {
    return 'Hindi naitala ang iyong pagsang-ayon. $reason';
  }

  @override
  String get platformConsentContinueNote =>
      'Maaari ka ring magpatuloy muna nang wala ito. Magtatanong muli ang app sa susunod na bumalik ka rito.';

  @override
  String get messagingStartUnconfirmed =>
      'Hindi namin makumpirma kung natanggap ang iyong mensahe. Ligtas itong ipadala muli: hindi ito maipo-post nang dalawang beses. Puwede mo ring tingnan ang Messages.';

  @override
  String get messagingReplyUnconfirmed =>
      'Hindi namin makumpirma kung natanggap ang iyong mensahe. Ligtas itong ipadala muli: hindi ito maipo-post nang dalawang beses.';

  @override
  String get messagingNotSent => 'Walang naipadala.';

  @override
  String get messagingStartConflict =>
      'Walang naipadala. May nagkaproblema sa panig namin. Buksan ang Mga mensahe para makita kung ano ang natanggap ng tanggapan bago subukang muli.';

  @override
  String verifDate(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String get verifUploadNewPhoto => 'Mag-upload ng bagong litrato';

  @override
  String get verifAddPhoto => 'Idagdag';

  @override
  String get verifPreviousSelfieKept => 'Nakatago pa ang dating selfie';

  @override
  String get verifTakeSelfie => 'Kumuha ng selfie';

  @override
  String get verifCheckingStatus =>
      'Sinusuri ang katayuan ng iyong verification';

  @override
  String get verifCouldNotCheckStatus => 'Hindi masuri ang iyong katayuan';

  @override
  String get verifNewPhotoSent => 'Naipadala na ang bagong litrato';

  @override
  String get verifPhotoAdded => 'Naidagdag na ang litrato';

  @override
  String get verifIdType => 'Uri ng ID';

  @override
  String get verifIdTypeDriversLicense => 'Lisensya sa pagmamaneho';

  @override
  String get verifIdTypePassport => 'Pasaporte';

  @override
  String get verifIdTypeOther => 'Ibang ID mula sa pamahalaan';

  @override
  String get verifSelfieConsentChecking =>
      'Sinusuri ang pahintulot para sa selfie';

  @override
  String get verifSelfieErasedHeading => 'Binura na ang iyong selfie';

  @override
  String get verifSelfieErasedSlot => 'Binura ang selfie: kumuha ng bago';

  @override
  String get verifSelfieRetake => 'Kumuha ng bagong selfie';

  @override
  String verifSelfieErasedPendingOn(String date) {
    return 'Binawi mo ang iyong pahintulot para sa selfie noong $date, kaya binura ang selfie na ipinadala mo. Hindi maaaprubahan ng staff ang hiling na ito hangga\'t hindi ka nagpapadala ng bagong selfie, o maaari kang magpa-verify nang personal sa halip.';
  }

  @override
  String get verifSelfieErasedPending =>
      'Binawi mo ang iyong pahintulot para sa selfie, kaya binura ang selfie na ipinadala mo. Hindi maaaprubahan ng staff ang hiling na ito hangga\'t hindi ka nagpapadala ng bagong selfie, o maaari kang magpa-verify nang personal sa halip.';

  @override
  String verifSelfieErasedRejectedOn(String date) {
    return 'Binawi mo ang iyong pahintulot para sa selfie noong $date, kaya binura ang selfie na ipinadala mo. Magpadala ng bago kasama ang iyong ID, o magpa-verify nang personal sa halip.';
  }

  @override
  String get verifSelfieErasedRejected =>
      'Binawi mo ang iyong pahintulot para sa selfie, kaya binura ang selfie na ipinadala mo. Magpadala ng bago kasama ang iyong ID, o magpa-verify nang personal sa halip.';

  @override
  String get verifSendValidId => 'Ipadala ang iyong valid ID';

  @override
  String get verifIdFront => 'Harap ng ID';

  @override
  String get verifIdBackOptional => 'Likod ng ID (opsyonal)';

  @override
  String get verifSelfie => 'Selfie';

  @override
  String get verifMethodInPerson =>
      'Na-verify nang personal sa tanggapan ng Taytay LGU.';

  @override
  String get verifMethodSelfie =>
      'Na-verify gamit ang iyong valid ID at selfie.';

  @override
  String get verifReplacedErased =>
      'Napalitan: na-verify ka nang personal sa tanggapan, kaya isinara ang iyong hiling na may selfie at binura ang selfie na ipinadala mo.';

  @override
  String get verifReplaced =>
      'Napalitan: na-verify ka nang personal sa tanggapan, kaya isinara ang iyong hiling na may selfie.';

  @override
  String get verifStatusTitle => 'Katayuan ng verification';

  @override
  String get verifResubmitDialogTitle => 'Mensahe sa Taytay LGU';

  @override
  String get verifResubmit => 'Ipadala muli para sa verification';

  @override
  String get verifCategoryPersonalDetails => 'Ang iyong mga detalye';

  @override
  String get verifAddress => 'Tirahan';

  @override
  String get verifCategoryContact => 'Mga detalye sa pakikipag-ugnayan';

  @override
  String get verifCategoryIdPhoto => 'Litrato ng ID';

  @override
  String get verifCategoryPhoto => 'Litrato mo';

  @override
  String get verifCategoryOther => 'Mga detalye';

  @override
  String get verifPendingTitle => 'Sinusuri namin ang iyong account';

  @override
  String get verifPendingChip => 'Naghihintay ng pagsusuri';

  @override
  String get verifPendingBody =>
      'Sinusuri ng staff ng Taytay LGU ang iyong valid ID at selfie.';

  @override
  String get verifNoActionNeeded => 'Wala kang kailangang gawin.';

  @override
  String get verifProgress => 'Progreso';

  @override
  String get verifStepAccountCreated => 'Nagawa ang account';

  @override
  String get verifStepEmailConfirmed => 'Nakumpirma ang email';

  @override
  String get verifStepIdReceived => 'Natanggap ang valid ID at selfie';

  @override
  String get verifStepLguReview => 'Pagsusuri ng LGU';

  @override
  String get verifStepInQueue => 'Nakapila';

  @override
  String get verifStepVerifiedDetail =>
      'Mabubuksan ang paghiling ng dokumento, pagmemensahe sa mga tanggapan at pag-apply ng Tulong';

  @override
  String verifSubmittedOn(String date) {
    return 'Isinumite noong $date';
  }

  @override
  String get verifPendingBrowseNote =>
      'Habang naghihintay, maaari kang tumingin ng mga serbisyo, balita at kaganapan, at gumamit ng mga emergency hotline.';

  @override
  String get verifVerifiedBody =>
      'Bukas na sa iyo ang lahat ng serbisyo para sa residente.';

  @override
  String verifVerifiedBodyOn(String date) {
    return 'Na-verify ng Taytay LGU noong $date. Bukas na sa iyo ang lahat ng serbisyo para sa residente.';
  }

  @override
  String get verifGoHome => 'Pumunta sa Home';

  @override
  String get verifVerifiedTitle => 'Verified na ang iyong account';

  @override
  String get verifYouCanNow => 'Maaari mo na ngayong';

  @override
  String get verifCanRequestDocuments => 'Humiling ng mga dokumento';

  @override
  String get verifCanRequestDocumentsDetail =>
      'Mga sertipiko, clearance at permit';

  @override
  String get verifCanMessage => 'Magmensahe sa mga tanggapan ng munisipyo';

  @override
  String get verifCanMessageDetail =>
      'Magtanong at mag-follow up ng mga hiling';

  @override
  String get verifCanUseId => 'Gamitin ang iyong Taytay digital ID';

  @override
  String get verifCanUseIdDetail => 'Ipakita ito sa munisipyo';

  @override
  String get verifCompleteProfile =>
      'Kumpletuhin ang iyong Profile ng Residente';

  @override
  String verifPercentComplete(int percent) {
    return '$percent% kumpleto';
  }

  @override
  String get verifCorrectionFallbackReason =>
      'May kailangang itama bago matapos ng Taytay LGU ang pagsusuri.';

  @override
  String get verifNeedsCorrection => 'Kailangang itama';

  @override
  String get verifYourMessage => 'Ang iyong mensahe';

  @override
  String get verifSendNewValidId => 'Magpadala ng bagong valid ID';

  @override
  String get verifRetake => 'Kunan muli';

  @override
  String get verifNotVerified => 'Hindi pa verified';

  @override
  String get verifNotVerifiedBody =>
      'Hindi pa kinukumpirma ng Taytay LGU ang account na ito. Maaari kang tumingin ng mga serbisyo habang ipinapadala mo ang iyong valid ID at selfie, o magpa-verify nang personal.';

  @override
  String get verifHeldFromYou => 'Ang hawak ng Taytay LGU mula sa iyo';

  @override
  String get verifReasonHeading => 'DAHILAN MULA SA TAYTAY LGU';

  @override
  String verifReviewedOn(String date) {
    return 'Sinuri noong $date';
  }

  @override
  String get verifGateNotVerifiedYet => 'Hindi pa verified ang iyong account.';

  @override
  String get verifGateTitleDigitalId =>
      'I-verify ang iyong account para mabuksan ang iyong digital ID';

  @override
  String get verifGateTitleMessage =>
      'I-verify ang iyong account para makapagmensahe sa mga tanggapan';

  @override
  String get verifGateTitleOther =>
      'I-verify ang iyong account para makapagpatuloy';

  @override
  String get verifGateLeadMessage =>
      'Para sa mga verified na residente ng Taytay ang pagmemensahe sa mga tanggapan ng munisipyo.';

  @override
  String get verifGateLeadDigitalId =>
      'Para sa mga verified na residente ng Taytay ang iyong Taytay digital ID.';

  @override
  String get verifGateLeadOther =>
      'Para sa mga verified na residente ng Taytay ang aksyong ito.';

  @override
  String get verifKycLoadingBarangays => 'Kinukuha ang mga barangay…';

  @override
  String get verifKycIntro =>
      'Sinusuri ng Taytay LGU ang mga detalyeng ito laban sa talaan ng mga residente ng munisipyo. Ilagay ang mga ito ayon sa nakasulat sa iyong birth certificate o valid ID.';

  @override
  String get verifKycBarangaysFailed => 'Hindi makuha ang listahan ng barangay';

  @override
  String get verifKycStartFailed => 'Hindi masimulan ang iyong verification';

  @override
  String get verifKycAsOnId => 'Ayon sa nakasulat sa iyong ID.';

  @override
  String get verifSuffix => 'Suffix';

  @override
  String get verifKycChooseBirthDate =>
      'Piliin ang iyong petsa ng kapanganakan';

  @override
  String get verifKycSexHint => 'Ayon sa nakatala sa iyong birth certificate.';

  @override
  String get verifSexFemale => 'Babae';

  @override
  String get verifSexMale => 'Lalaki';

  @override
  String get verifSexUnspecified => 'Hindi tinukoy';

  @override
  String get verifKycWhyTitle => 'Bakit kailangan ito ng Taytay LGU?';

  @override
  String get verifKycWhyPurpose =>
      'Itinutugma ng Taytay LGU ang mga detalyeng ito sa talaan ng mga residente ng munisipyo para kumpirmahin na ikaw nga ang sinasabi mong ikaw.';

  @override
  String get verifKycWhyWho =>
      'Ang staff na sumusuri ng verification para sa iyong barangay. Hindi ipinapakita sa ibang residente ang iyong mga detalye at hindi ginagamit sa anumang iba pang layunin.';

  @override
  String get verifKycWhyDecline =>
      'Maaari mo pa ring gamitin ang app na ito para tumingin ng mga serbisyo at anunsyo ng munisipyo. Hindi ka magkakaroon ng digital ID hangga\'t hindi kinukumpirma ng Taytay LGU kung sino ka. Impormasyon lamang ang laman ng mga pahina ng programa.';

  @override
  String get verifKycSaveContinue => 'I-save at magpatuloy';

  @override
  String get verifKycNothingSentYet =>
      'Wala pang naipapadala sa Taytay LGU. Maaari mong suriin ang iyong mga detalye bago ipadala ang mga ito para sa pagsusuri.';

  @override
  String get verifProfileUnavailable => 'Hindi available ang profile ngayon.';

  @override
  String get verifProfileHeader => 'Profile ng residente';

  @override
  String get verifProfileLoading => 'Kinukuha ang iyong profile';

  @override
  String get verifProfileTitle => 'Profile ng Residente';

  @override
  String get verifProfileSubmittedTitle => 'Naisumite ang profile';

  @override
  String get verifProfileSubmittedMessage =>
      'Naipadala na sa Taytay LGU ang iyong profile ng residente. Aabisuhan ka namin kapag nasuri na ito.';

  @override
  String get verifBackToProfile => 'Bumalik sa profile';

  @override
  String get verifPersonalInfo => 'Personal na impormasyon';

  @override
  String get verifSaveAndContinue => 'I-save at magpatuloy';

  @override
  String get verifHouseholdAddress => 'Sambahayan at address';

  @override
  String get verifReviewSubmit => 'Suriin at isumite';

  @override
  String get verifSubmitToLgu => 'Isumite sa Taytay LGU';

  @override
  String get verifYourName => 'Ang iyong pangalan';

  @override
  String get verifProfileCompleteness => 'Pagkakumpleto ng profile';

  @override
  String get verifCompleteAllSections =>
      'Kumpletuhin ang lahat ng bahagi para maisumite ang iyong profile sa Taytay LGU.';

  @override
  String get verifSectionComplete => 'Kumpleto';

  @override
  String get verifSupportingDocuments => 'Mga sumusuportang dokumento';

  @override
  String get verifBirthdate => 'Petsa ng kapanganakan';

  @override
  String get verifAge => 'Edad';

  @override
  String get verifContact => 'Contact';

  @override
  String get verifEmail => 'Email';

  @override
  String get verifHouseNoStreet => 'Blg. ng bahay / Kalye';

  @override
  String get verifPurokSitio => 'Purok / Sitio';

  @override
  String get verifMunicipalityProvince => 'Bayan / Lalawigan';

  @override
  String get verifHousehold => 'Sambahayan';

  @override
  String get verifYearsAtThisAddress => 'Taon sa address na ito';

  @override
  String get verifHouseholdMembers => 'Mga miyembro ng sambahayan';

  @override
  String get verifResidenceType => 'Uri ng tirahan';

  @override
  String get verifName => 'Pangalan';

  @override
  String get verifSexBirthdate => 'Kasarian · Petsa ng kapanganakan';

  @override
  String get verifMobile => 'Cellphone';

  @override
  String get verifYearsAtAddress => 'Taon sa address';

  @override
  String get verifCertify =>
      'Pinatutunayan ko na totoo at tama ang impormasyon, at pumapayag ako sa pagproseso nito sa ilalim ng Data Privacy Act of 2012 ayon sa Privacy Notice ng Taytay LGU.';

  @override
  String get verifSubmitted => 'Naisumite';

  @override
  String get verifProfileVerified => 'Na-verify ang profile';

  @override
  String get verifEdit => 'I-edit';

  @override
  String get issuanceStatusSubmitted => 'Naipadala na sa tanggapan';

  @override
  String get issuanceStatusUnderReview => 'Sinusuri na';

  @override
  String get issuanceStatusNeedsInfo => 'May kailangan pa sa iyo';

  @override
  String get issuanceStatusApproved => 'Aprubado, inihahanda na';

  @override
  String get issuanceStatusReadyForPickup => 'Handa nang kunin';

  @override
  String get issuanceStatusReleased => 'Nakuha na';

  @override
  String get issuanceStatusRejected => 'Hindi inisyu';

  @override
  String get issuanceStatusUpdated => 'May update';

  @override
  String get issuanceExplainSubmitted =>
      'Nasa tanggapan na ang iyong hiling. Wala pang nagsisimulang gumawa nito.';

  @override
  String get issuanceExplainUnderReview =>
      'Sinusuri ng tanggapan ang iyong hiling at ang iyong mga file. Wala kang kailangang gawin ngayon.';

  @override
  String get issuanceExplainNeedsInfo =>
      'May kailangan pa ang tanggapan bago ito makapagpatuloy. Basahin ang hiningi nila, saka ipadala ito rito.';

  @override
  String get issuanceExplainApproved =>
      'Inaprubahan ng tanggapan ang iyong hiling at inihahanda na ang dokumento. Sasabihan ka rito kapag handa na ito.';

  @override
  String get issuanceExplainReadyForPickup =>
      'Handa na ang iyong dokumento. Basahin sa ibaba kung kailan at saan ito kukunin.';

  @override
  String get issuanceExplainReleased =>
      'Ibinigay na sa iyo ng tanggapan ang dokumento.';

  @override
  String get issuanceExplainRejected =>
      'Hindi mai-isyu ng tanggapan ang dokumentong ito. Nasa ibaba ang kanilang dahilan.';

  @override
  String get issuanceExplainCancelled => 'Kinansela ang hiling na ito.';

  @override
  String get issuanceExplainUpdated =>
      'May binago ang tanggapan sa hiling na ito. Magtanong sa tanggapan kung may hindi malinaw.';

  @override
  String get issuanceHistorySent => 'Ipinadala mo ang hiling';

  @override
  String get issuanceHistoryCancelled => 'Kinansela mo ang hiling';

  @override
  String get issuanceHistoryAnswered => 'Ipinadala mo ang hiningi ng tanggapan';

  @override
  String get issuanceHistoryReviewStarted =>
      'Sinimulan itong suriin ng tanggapan';

  @override
  String get issuanceHistoryAskedForMore => 'May hiningi pa ang tanggapan';

  @override
  String get issuanceHistoryApproved => 'Inaprubahan ito ng tanggapan';

  @override
  String get issuanceHistoryRefused => 'Hindi ito mai-isyu ng tanggapan';

  @override
  String get issuanceHistoryReleased =>
      'Ibinigay na ng tanggapan ang dokumento';

  @override
  String get issuanceHistoryUpdated => 'Na-update ang hiling';

  @override
  String get issuanceHistoryClaimedNext => 'Makukuha sa tanggapan';

  @override
  String get issuanceHistoryUpcoming => 'Makikita mo ito rito';

  @override
  String issuanceHistoryByYou(String date) {
    return '$date · Ikaw';
  }

  @override
  String issuanceHistoryByOffice(String date) {
    return '$date · Tanggapan';
  }

  @override
  String get issuanceYourNote => 'Ang iyong tala';

  @override
  String get issuanceFromOffice => 'Mula sa tanggapan';

  @override
  String get issuanceAccessSignInTitle =>
      'Mag-sign in para humiling ng dokumento';

  @override
  String get issuanceAccessSignInBody =>
      'Mababasa mo na ngayon kung ano ang kailangan ng bawat dokumento. Para magpadala ng hiling, mag-sign in gamit ang verified na Taytay account.';

  @override
  String get issuanceAccessVerifyTitle => 'I-verify muna ang iyong account';

  @override
  String get issuanceAccessVerifyBody =>
      'Ang mga verified na residente lamang ng Taytay ang makakapagpadala ng hiling na dokumento, dahil sa iyong pangalan ito iniisyu ng tanggapan. Mababasa mo na ngayon kung ano ang kailangan ng bawat dokumento.';

  @override
  String get issuanceLoadNotFoundTitle => 'Hindi makita';

  @override
  String get issuanceLoadNotFoundBody =>
      'Hindi ito available. Maaaring inalis na ito, o pag-aari ito ng ibang account.';

  @override
  String get issuanceLoadOfflineBody =>
      'Hindi maabot ang Taytay LGU. Pakisuri ang iyong koneksyon at subukang muli.';

  @override
  String get issuanceLoadFailedThis => 'Hindi ito nakuha';

  @override
  String get issuanceLoadFailedDocuments => 'Hindi nakuha ang mga dokumento';

  @override
  String get issuanceLoadFailedDocument => 'Hindi nakuha ang dokumentong ito';

  @override
  String get issuanceLoadFailedRequest => 'Hindi nakuha ang hiling na ito';

  @override
  String get issuanceLoadFailedRequests => 'Hindi nakuha ang iyong mga hiling';

  @override
  String get issuanceCancelTitle => 'Kanselahin ang hiling na ito?';

  @override
  String issuanceCancelMessage(String reference) {
    return 'Ititigil ng tanggapan ang paggawa sa $reference. Hindi na mabubuksang muli ang kinanselang hiling; kailangan mong magpadala ng bago.';
  }

  @override
  String get issuanceCancelConfirm => 'Kanselahin ang hiling';

  @override
  String get issuanceCancelKeep => 'Panatilihin ito';

  @override
  String get issuanceCancelDone => 'Kinansela ang hiling.';

  @override
  String get issuanceCancelButton => 'Kanselahin ang hiling na ito';

  @override
  String get issuanceDetailTitle => 'Hiling na dokumento';

  @override
  String get issuanceDetailLoading => 'Binubuksan ang iyong hiling';

  @override
  String get issuanceAskedLabel => 'Hiningi ng tanggapan';

  @override
  String get issuanceHowToClaim => 'Paano ito kukunin';

  @override
  String get issuanceBringId =>
      'Magdala ng valid ID at ng iyong numero ng reperensiya.';

  @override
  String get issuanceRefusalLabel => 'Dahilan ng tanggapan';

  @override
  String get issuanceProgress => 'Pag-usad';

  @override
  String get issuanceYourRequest => 'Ang iyong hiling';

  @override
  String get issuancePurpose => 'Layunin';

  @override
  String get issuanceFilesSent => 'Mga file na ipinadala mo';

  @override
  String get issuanceFile => 'File';

  @override
  String issuanceAttachmentVersion(int version) {
    return 'bersyon $version';
  }

  @override
  String get issuanceAttachmentReplaced => 'pinalitan pagkatapos';

  @override
  String get issuanceView => 'Tingnan';

  @override
  String issuancePhotoLoading(String label) {
    return 'Kinukuha ang litratong ipinadala mo para sa $label';
  }

  @override
  String issuancePhotoSemantic(String label) {
    return 'Ang litratong ipinadala mo para sa $label';
  }

  @override
  String get issuancePhotoOffline =>
      'Wala kang koneksyon. Kumonekta at subukang muli.';

  @override
  String get issuancePhotoUnavailable =>
      'Hindi maipakita rito ang file na ito. Nasa tanggapan pa rin ito.';

  @override
  String get issuanceResubmitTitle => 'Ipadala ang hiningi ng tanggapan';

  @override
  String get issuanceResubmitIntro =>
      'Magdagdag ng tala, bagong file, o pareho. Itatabi ang bagong file kasama ng ipinadala mo dati; walang papalitan sa mga naipadala mo.';

  @override
  String get issuanceResubmitNoteLabel => 'Tala para sa tanggapan (opsyonal)';

  @override
  String get issuanceResubmitOptional => 'Bagong file, kung hiningi';

  @override
  String get issuanceResubmitEmpty => 'Magdagdag muna ng tala o file.';

  @override
  String get issuanceSendToOffice => 'Ipadala sa tanggapan';

  @override
  String get issuanceResubmitDone =>
      'Naipadala na. Susuriin itong muli ng tanggapan.';

  @override
  String get issuanceRequestTitle => 'Humiling ng dokumento';

  @override
  String get issuanceFormLoading => 'Binubuksan ang form';

  @override
  String get issuanceReviewButton => 'Suriin ang hiling';

  @override
  String get issuancePurposeLabel => 'Para saan ang dokumento?';

  @override
  String get issuancePurposeHint =>
      'Halimbawa: para sa requirement sa pag-enroll sa paaralan';

  @override
  String get issuancePurposeHelp =>
      'Babasahin ito ng tanggapan. Gawin itong maikli.';

  @override
  String get issuancePurposeEmpty =>
      'Sabihin kung para saan ang dokumento, halimbawa \"para sa pag-enroll sa paaralan\".';

  @override
  String get issuanceFilesNeeded => 'Mga file na kailangan ng tanggapan';

  @override
  String issuanceFilesIntro(String accepted) {
    return 'Isang file bawat isa: $accepted. Ilatag nang patag ang papel, punuin ang frame, at tiyaking nababasa ang bawat salita.';
  }

  @override
  String get issuanceMissingAnswers =>
      'May kulang na sagot. May marka ang mga ito sa itaas.';

  @override
  String get issuanceReviewTitle => 'Suriin ang iyong hiling';

  @override
  String get issuanceSendRequest => 'Ipadala ang hiling';

  @override
  String get issuanceChangeSomething => 'May babaguhin';

  @override
  String get issuanceAskingFor => 'Hinihiling mo ito';

  @override
  String get issuanceFilesSending => 'Mga file na ipapadala mo';

  @override
  String get issuanceKindPhoto => 'litrato';

  @override
  String issuanceReviewNotSent(String name) {
    return '$name: hindi ipapadala (opsyonal)';
  }

  @override
  String get issuanceReviewNote =>
      'Suriin ito bago ipadala. Maaari mong kanselahin ang hiling hangga\'t hindi pa ito sinisimulan ng tanggapan. Pagkatapos noon, magmensahe sa tanggapan.';

  @override
  String get issuanceDoneTitle => 'Nasa tanggapan na ang iyong hiling';

  @override
  String get issuanceDoneMessage =>
      'Itago ang numerong ito. Ginagamit ito ng tanggapan kapag nagtanong ka tungkol sa iyong hiling.';

  @override
  String get issuanceDocument => 'Dokumento';

  @override
  String get issuanceOffice => 'Tanggapan';

  @override
  String get issuanceDoneNote =>
      'Susuriin ito ng tanggapan. Makikita rito at sa iyong mga notification ang bawat hakbang, pati kung kailan ito handa nang kunin.';

  @override
  String get issuanceFollowRequest => 'Subaybayan ang hiling na ito';

  @override
  String get issuanceBackToDocuments => 'Bumalik sa mga dokumento';

  @override
  String get issuanceNothingSent => 'Walang naipadala.';

  @override
  String get issuanceNothingCancelled => 'Walang nakansela.';

  @override
  String get issuanceUnconfirmedSubmit =>
      'Hindi namin makumpirma kung natanggap ang iyong hiling. Ligtas na ipadala muli ang parehong hiling: hindi ito maihahain nang dalawang beses. Puwede mo ring tingnan ang Aking mga hiling na dokumento.';

  @override
  String get issuanceUnconfirmedResubmit =>
      'Hindi namin makumpirma kung natanggap ang iyong mga ipinadala. Ligtas itong ipadala muli: hindi ito maihahain nang dalawang beses. Puwede ka ring bumalik at buksan ang hiling para tingnan.';

  @override
  String get issuanceUnconfirmedCancel =>
      'Hindi namin makumpirma kung natanggap ang iyong pagkansela. Ligtas na subukang muli: isang beses lang makakansela ang hiling. Puwede ka ring bumalik at buksan ang hiling para tingnan.';

  @override
  String get issuanceFailVerifyTitle =>
      'Ang mga verified na residente lamang ang makakagawa nito';

  @override
  String get issuanceFailVerifyBody =>
      'Hindi pa verified ang iyong account sa Taytay LGU. Tapusin muna ang verification, saka bumalik sa pahinang ito.';

  @override
  String get issuanceFailForbiddenBody =>
      'Hindi bukas sa account na ito ang paghiling ng dokumento. Masasabi pa sa iyo ng munisipyo.';

  @override
  String get issuanceFailOfflineBody =>
      'Nandito pa sa telepono ang iyong mga sagot. Kumonekta sa internet at subukang muli.';

  @override
  String get issuanceFailCheckBody =>
      'May bahaging hindi matanggap ng tanggapan. Tingnan ang mga may marka sa ibaba.';

  @override
  String get issuanceFailFileBody =>
      'May file na masyadong malaki o hindi mabasa. Pumili ng mas maliit na litrato o ibang file, at subukang muli.';

  @override
  String get issuanceFailRateBody =>
      'Maghintay ng ilang minuto, saka subukang muli.';

  @override
  String get issuanceFailKeyConflictBody =>
      'May nagkaproblema sa aming panig. Buksan ang Aking mga hiling na dokumento para tingnan kung ano ang nasa tanggapan bago subukang muli.';

  @override
  String get issuanceFailMovedBody =>
      'May ginawa na rito ang tanggapan. Bumalik at buksan itong muli para makita kung nasaan na ito.';

  @override
  String get issuanceFailGoneTitle => 'Hindi na available';

  @override
  String get issuanceFailGoneBody =>
      'Hindi na ito nakalista sa tanggapan. Bumalik sa listahan para makita kung ano ang available.';

  @override
  String get issuanceFailSessionBody =>
      'Natapos ang iyong session. Mag-sign in, saka subukang muli.';

  @override
  String get issuanceFailServerBody =>
      'May nagkaproblema sa aming panig. Subukang muli maya-maya.';

  @override
  String get issuanceFeeNotStated => 'Walang nakasaad na bayad';

  @override
  String get issuanceFeeNone => 'Walang bayad';

  @override
  String issuanceFee(String amount) {
    return 'Bayad: $amount, babayaran sa tanggapan';
  }

  @override
  String get issuanceProcessingNotStated =>
      'Walang nakasaad na tagal ng pagproseso';

  @override
  String get issuanceProcessingSameDay =>
      'Karaniwang sa parehong araw ng trabaho';

  @override
  String issuanceProcessingDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Mga $days araw ng trabaho',
    );
    return '$_temp0';
  }

  @override
  String get issuanceAcceptedAnyFile => 'isang file';

  @override
  String issuanceAcceptedOr(String first, String last) {
    return '$first o $last';
  }

  @override
  String issuanceAcceptedLine(String kinds, int limit) {
    return '$kinds, hanggang $limit MB bawat isa';
  }

  @override
  String get issuanceCatalogueTitle => 'Humiling ng mga dokumento';

  @override
  String get issuanceSearchHint => 'Maghanap ng dokumento';

  @override
  String get issuanceMyRequests => 'Aking mga hiling na dokumento';

  @override
  String get issuanceMyRequestsDetail => 'Subaybayan ang mga ipinadala mo';

  @override
  String get issuanceCatalogueIntro =>
      'Mga sertipiko at certified na kopya na iniisyu ng mga tanggapan ng munisipyo. Pumili ng isa para makita kung ano ang kailangan nito. Anumang bayad ay sa tanggapan binabayaran, hindi kailanman sa app.';

  @override
  String get issuanceCatalogueLoading => 'Kinukuha ang mga dokumento';

  @override
  String get issuanceCatalogueEmptyTitle => 'Wala pang nakalistang dokumento';

  @override
  String get issuanceCatalogueEmptyMessage =>
      'Wala pang inilistang dokumento sa app ang mga tanggapan ng munisipyo. Maaari ka pa ring magtanong sa Munisipyo.';

  @override
  String get issuanceNoMatchTitle => 'Walang tugmang dokumento';

  @override
  String get issuanceNoMatchMessage =>
      'Sumubok ng ibang salita, o burahin ang hinahanap para makita ang lahat.';

  @override
  String get issuanceTypeTitle => 'Detalye ng dokumento';

  @override
  String get issuanceRequestThis => 'Hilingin ang dokumentong ito';

  @override
  String get issuanceTypeLoading => 'Binubuksan ang dokumentong ito';

  @override
  String get issuanceFeeLabel => 'Bayad';

  @override
  String get issuanceProcessingLabel => 'Tagal ng pagproseso';

  @override
  String get issuanceWhatToSend => 'Ang kailangan mong ipadala';

  @override
  String get issuanceNoFilesNeeded =>
      'Walang file. Sapat na ang layunin ng iyong hiling.';

  @override
  String issuanceSendEachAs(String accepted) {
    return 'Ipadala ang bawat isa bilang litrato o file: $accepted.';
  }

  @override
  String get issuanceClaimFallback =>
      'Sasabihin dito ng tanggapan kung kailan at saan ito kukunin, kapag handa na ito.';

  @override
  String get issuanceNoPicker =>
      'Hindi makapili ng file ang teleponong ito. Maaaring tanggapin ng tanggapan ang dokumento nang personal sa Munisipyo.';

  @override
  String get issuanceMyRequestsEmptyTitle => 'Wala ka pang hiling na dokumento';

  @override
  String get issuanceMyRequestsEmptyMessage =>
      'Kapag humiling ka ng sertipiko o kopya mula sa isang tanggapan ng munisipyo, masusubaybayan mo ito rito.';

  @override
  String issuanceSentOn(String date) {
    return 'Naipadala noong $date';
  }

  @override
  String get digitalIdTitle => 'Aking Taytay ID';

  @override
  String get digitalIdLoading => 'Kinukuha ang iyong digital ID';

  @override
  String get digitalIdUnknownStatus =>
      'Lalabas dito ang iyong digital ID kapag inisyu na ito ng Taytay LGU.';

  @override
  String get digitalIdGenuineNote =>
      'Ang Taytay LGU ang nag-isyu ng card na ito. Scanner ang sumusuri sa code. Hindi ang teleponong ito ang nagpapasya kung tunay ang card.';

  @override
  String get digitalIdNotYetIssued => 'Hindi pa naiisyu';

  @override
  String get digitalIdPhotoSemantic => 'Litrato sa ID';

  @override
  String get digitalIdPhotoPlaceholder => 'Walang litrato';

  @override
  String get digitalIdStatusActive => 'Aktibo';

  @override
  String get digitalIdStatusSuspended => 'Suspendido';

  @override
  String get digitalIdStatusRevoked => 'Binawi';

  @override
  String digitalIdStatusSemantic(String status) {
    return 'Katayuan: $status';
  }

  @override
  String get digitalIdCodeRefreshes => 'Nagre-refresh ang code';

  @override
  String digitalIdCodeValidUntil(String time, String zone) {
    return 'Nagre-refresh ang code · may bisa hanggang $time $zone';
  }

  @override
  String get digitalIdShowCode => 'Ipakita ang code na ito para ma-scan';

  @override
  String get digitalIdRefreshingCode => 'Nire-refresh ang code…';

  @override
  String get digitalIdNoCodeWhileInactive =>
      'Walang ipinapakitang code habang hindi aktibo ang card.';

  @override
  String get digitalIdSuspendedTitle => 'Suspendido ang iyong ID';

  @override
  String get digitalIdSuspendedBody =>
      'Pansamantalang itinigil ng Taytay LGU ang card na ito. Pumunta sa Munisipyo o magmensahe sa LGU para malaman kung bakit.';

  @override
  String get digitalIdRevokedTitle => 'Wala nang bisa ang ID na ito';

  @override
  String get digitalIdRevokedBody =>
      'Binawi ng Taytay LGU ang card na ito. Pumunta sa Munisipyo kung kailangan mo ng bago.';

  @override
  String get digitalIdExpiredTitle => 'Nag-expire na ang iyong ID';

  @override
  String get digitalIdExpiredBody =>
      'Lumampas na ang card na ito sa petsa ng pag-expire nito. Pumunta sa Munisipyo para i-renew ito.';

  @override
  String get digitalIdPreparingTitle => 'Inihahanda na ang iyong card';

  @override
  String get digitalIdPreparingBody =>
      'Verified ka na. Ang MSWDO ang susunod na mag-iisyu ng iyong card, at lalabas ito rito kasama ang QR code.';

  @override
  String get digitalIdStepsTitle => 'Nasaan na ang iyong card';

  @override
  String get digitalIdStepAccountCreated => 'Nagawa ang account';

  @override
  String get digitalIdStepIdSent => 'Naipadala ang ID at selfie';

  @override
  String get digitalIdStepVerified => 'Na-verify ng Taytay LGU';

  @override
  String get digitalIdStepIssued => 'Pag-isyu ng card ng MSWDO';

  @override
  String get digitalIdStepIssuedDetail =>
      'Balikan ang pahinang ito mamaya. Karaniwang ang iyong verification selfie ang litrato sa card.';

  @override
  String get digitalIdStepShow => 'Ipakita ang iyong card';

  @override
  String get digitalIdStepShowDetail =>
      'Ini-scan ng staff ang QR code nito. Maikling panahon lang gumagana ang bawat code, at kumukuha ang app ng bago.';

  @override
  String get digitalIdAboutTitle => 'Tungkol sa iyong card';

  @override
  String get digitalIdAboutWhat =>
      'Ito ang sariling resident card ng Taytay, hindi pambansang ID ng pamahalaan. Nakasaad sa card ang petsa ng pag-expire nito.';

  @override
  String get digitalIdAboutStops =>
      'Kapag na-suspend o nag-expire ito, hihinto ang app sa pagpapakita ng QR code nito. Magmensahe sa MSWDO para malaman kung ano ang gagawin.';

  @override
  String get digitalIdMessageMswdo => 'Magmensahe sa MSWDO';

  @override
  String get hhTitle => 'Sambahayan at pamilya';

  @override
  String get hhLoading => 'Nilo-load ang talaan ng iyong sambahayan';

  @override
  String get hhSectionHousehold => 'Ang iyong sambahayan';

  @override
  String get hhRowHousehold => 'Sambahayan';

  @override
  String get hhRowPeople => 'Mga taong nakatala rito';

  @override
  String get hhSectionFamily => 'Ang talaan ng iyong pamilya';

  @override
  String get hhRoleHeadBody =>
      'Nakatala ka sa Taytay LGU bilang taong nananagot para sa sambahayang ito. Ang tanggapan ang nag-iingat ng talaang iyon. Hindi tumatanggap ng aplikasyon ang app na ito.';

  @override
  String get hhRoleMemberBody =>
      'Nakatala ka sa Taytay LGU bilang bahagi ng sambahayang ito. Hindi tumatanggap ng aplikasyon ang app na ito.';

  @override
  String get hhHiddenTitle => 'Bakit hindi mo makita ang ibang tao rito';

  @override
  String get hhHiddenBody =>
      'Sa kanila ang mga detalye ng iba pang kasama sa iyong sambahayan, hindi sa iyong account — kaya hindi ipinapakita ng app na ito ang kanilang pangalan, kalagayan, o anumang inaplayan nila. Maaaring suriin ng staff ng Taytay LGU ang talaan ng sambahayan kasama mo nang personal.';

  @override
  String get hhNoneTitle => 'Wala pang sambahayan sa iyong account';

  @override
  String get hhNoneBody =>
      'Hindi bahagi ng anumang sambahayan ang iyong account sa app na ito, at hindi ito kayang i-set up ng bersyong ito ng app. May sariling talaan ng sambahayan ang munisipyo, at maaari itong suriin ng staff kasama mo.';

  @override
  String get hhCorrectionHeading => 'May mali ba?';

  @override
  String get hhCorrectionLead =>
      'Sabihin sa Taytay LGU kung ano ang mukhang mali at susuriin nila ang talaan. Walang magbabago hangga\'t hindi ito nasusuri ng staff.';

  @override
  String get hhReportError => 'Mag-ulat ng mali';

  @override
  String get hhNotOnFile => 'Wala sa talaan';

  @override
  String get hhFixQuestion => 'Ano ang mukhang mali?';

  @override
  String get hhFixLead =>
      'Piliin ang pinakamalapit. Susuriin ng staff ng Taytay LGU ang talaan — walang magbabago hangga\'t hindi pa nila ito nagagawa.';

  @override
  String get hhFixNoDetailsTitle =>
      'Pakiusap, huwag mag-type ng personal na detalye rito';

  @override
  String get hhFixNoDetailsBody =>
      'Ang tinatanong lang ng app na ito ay kung anong uri ng bagay ang mali. Ang mga pangalan, impormasyon tungkol sa kalusugan at mga dahilan ay para sa pakikipag-usap sa staff, na maaaring magtala nito nang maayos at kumilos dito.';

  @override
  String get hhFixHallTitle => 'Dalhin ito sa munisipyo';

  @override
  String get hhFixHallBody =>
      'Ang staff ng Taytay LGU ang nagbabago ng talaan ng sambahayan matapos nilang tingnan ang iyong mga dokumento. Pumunta sa munisipyo dala ang wastong ID — hindi mo kailangan ang app na ito o ang iyong telepono para mapagsilbihan doon.';

  @override
  String get hhFixSentTitle => 'Natanggap na ng Taytay LGU ang iyong ulat';

  @override
  String get hhFixSentBody =>
      'Susuriin ng staff ang talaan. Wala pang nababago, at sasabihin sa iyo kung ano ang kanilang makikita.';

  @override
  String get hhFixFailedTitle => 'Hindi naipadala ang iyong ulat';

  @override
  String get hhFixFailedBody =>
      'Hindi pa binubuksan ng Taytay LGU ang pag-uulat tungkol sa sambahayan sa app na ito. Walang naipadala, at walang nagbago. Maaari itong iulat nang personal sa munisipyo.';

  @override
  String get hhFixSend => 'Ipadala ang ulat';

  @override
  String get hhFixNoChange =>
      'Hindi nababago ng pagpapadala nito ang talaan ng iyong sambahayan.';

  @override
  String get profTitle => 'Profile';

  @override
  String get profGuestTitle => 'Nagba-browse ka bilang bisita';

  @override
  String get profGuestBody =>
      'Mag-sign in gamit ang iyong numero ng cellphone para magkaroon ng iyong digital ID. Bukas pa rin ang pag-browse kahit hindi ka mag-sign in. Impormasyon lamang ang mga pahina ng programa.';

  @override
  String get profYourAccount => 'Ang iyong account';

  @override
  String get profUnverifiedBody =>
      'Hindi pa kinukumpirma ng Taytay LGU ang iyong pagkakakilanlan. Kapag na-verify ka, mabubuksan ang iyong digital ID at ang pag-apply para sa Tulong sa app.';

  @override
  String get profVerifiedResident => 'Verified na residente';

  @override
  String get profSectionPrivacyHelp => 'Privacy at tulong';

  @override
  String get profPrivacyRow => 'Privacy at ang iyong datos';

  @override
  String get profPrivacyRowDetail =>
      'Ano ang hawak ng Taytay LGU, bakit, at ang iyong mga karapatan dito.';

  @override
  String get profHelpRow => 'Tulong at suporta';

  @override
  String get profHelpRowDetail =>
      'Problema sa pag-sign in, at kung saan hihingi ng tulong.';

  @override
  String get profRequestDocuments => 'Humiling ng mga dokumento';

  @override
  String get profRequestDocumentsNeedsVerified =>
      'Kailangan ng verified na account para makapagpadala ng hiling';

  @override
  String get profMessageOffice => 'Magmensahe sa isang tanggapan';

  @override
  String get profLoadingRecord => 'Nilo-load ang iyong rekord';

  @override
  String get profAccountDetailsUnavailable =>
      'Hindi pa binubuksan ng Taytay LGU ang account details sa app na ito. Gumagana pa rin ang iyong account.';

  @override
  String get profRecordUnavailable =>
      'Hindi pa binubuksan ng Taytay LGU ang iyong rekord sa app na ito. Masasabi sa iyo ng munisipyo kung ano ang nakatala.';

  @override
  String get profNotAvailableYet => 'Hindi pa available sa app na ito';

  @override
  String get profCanonicalTitle =>
      'Ang Taytay LGU ang nagpapanatiling tama nito';

  @override
  String get profCanonicalExplanation =>
      'Sinuri ang detalyeng ito gamit ang iyong mga dokumento, at umaasa rito ang iba pang serbisyo ng Taytay. Ang Taytay LGU ang nagpapasya kung babaguhin ito, kaya hindi ito mae-edit sa app na ito.';

  @override
  String get profCanonicalNextStep =>
      'Kung mali ito, pumunta sa munisipyo ng Taytay dala ang wastong ID at ang dokumentong nagpapakita ng tamang detalye. Maaaring direktang i-update ng staff ang iyong rekord. Hindi mo kailangan ang app na ito o ang iyong telepono para gawin ito.';

  @override
  String get profCanonicalDuringVerification =>
      'Nasa kalagitnaan ka ng verification ng iyong pagkakakilanlan. Kung humingi roon ang Taytay LGU ng pagwawasto, ang pagsagot dito ang pinakamabilis na paraan para maayos ito.';

  @override
  String get profCheckMyVerification => 'Tingnan ang aking verification';

  @override
  String get profBadgeNotSignedIn => 'Hindi naka-sign in';

  @override
  String get profBadgeNotVerified => 'Hindi pa verified';

  @override
  String get profBadgeVerified => 'Verified ng Taytay LGU';

  @override
  String get profSaveChanges => 'I-save ang mga pagbabago';

  @override
  String get profLoadingDetails => 'Nilo-load ang iyong mga detalye';

  @override
  String get profContactWhyTitle => 'Bakit ito itinatago ng Taytay LGU';

  @override
  String get profContactWhyPurpose =>
      'Ang numero ng iyong cellphone ang ginagamit ng Taytay LGU para ma-sign in ka at para sabihan ka tungkol sa iyong mga hiling. Opsyonal ang iyong email at ginagamit lang para padalhan ka ng mga kopya.';

  @override
  String get profContactWhoSees =>
      'Ang staff na humahawak sa anumang inaplayan mo. Hindi ito kailanman ibinabahagi para sa advertising.';

  @override
  String get profContactIfDecline =>
      'Kung walang numero ng cellphone, hindi ka makakapag-sign in. Maaaring iwanang blangko ang email.';

  @override
  String get profContactSaved => 'Na-update na ang iyong contact details.';

  @override
  String get profContactMaybeNotSavedTitle =>
      'Maaaring hindi na-save ang iyong mga pagbabago.';

  @override
  String get profContactMaybeNotSavedBody =>
      'Hindi namin ito makumpirma. Ligtas na i-save muli: ang parehong mga detalye ang ipapadala ulit.';

  @override
  String get profContactNotSavedTitle =>
      'Hindi na-save ang iyong mga pagbabago.';

  @override
  String profContactNotSavedBody(String reason) {
    return '$reason Walang nabago, at maaaring i-update ito ng munisipyo para sa iyo.';
  }

  @override
  String get profContactMobileHelper =>
      'Ito rin ang ginagamit mo sa pag-sign in.';

  @override
  String get profMobileEmpty => 'Ilagay ang iyong numero ng cellphone.';

  @override
  String get profMobileShape =>
      'Maglagay ng 11-digit na numero ng cellphone na nagsisimula sa 09.';

  @override
  String get profContactEmailInvalid =>
      'Maglagay ng email address, o iwanan itong blangko.';

  @override
  String get profPrivacyResponsibleTitle =>
      'Ang Taytay LGU ang may pananagutan sa iyong impormasyon';

  @override
  String get profPrivacyResponsibleIntro =>
      'Isa ang app na ito sa mga paraan para maabot ang Bayan ng Taytay, Rizal. Bahagi ng iyong rekord sa munisipyo ang iyong impormasyon, hindi ng app sa iyong telepono.';

  @override
  String get profPrivacyKeptTitle =>
      'Ang itinatago ng app na ito sa iyong telepono';

  @override
  String get profPrivacyKeptBody =>
      'Ang kailangan lang para manatili kang naka-sign in: isang sign-in token sa secure keystore ng iyong telepono, ang iyong unang pangalan para sa pagbati, at kung na-verify ka na ng Taytay LGU. Kapag nag-sign out ka, mabubura ang lahat ng ito sa device na ito.';

  @override
  String get profPrivacyNeverKeptTitle =>
      'Ang hindi kailanman itinatago ng app na ito';

  @override
  String get profPrivacyNeverKeptBody =>
      'Hindi itinatago sa iyong telepono ang iyong address, petsa ng kapanganakan, mga larawan ng ID at mga detalye ng sambahayan. Kinukuha lang ng mga screen ang mga ito kapag ipinapakita, at walang isinusulat sa file o cache.';

  @override
  String get profPrivacyLguHoldsTitle => 'Ang hawak ng Taytay LGU';

  @override
  String get profPrivacyLguHoldsBody =>
      'Ang iyong rekord bilang residente ng munisipyo: ang iyong pangalan, petsa ng kapanganakan, address at barangay, kasama ang anumang inaplayan mo. Ang nakikita lang ng staff ay ang kailangan sa kanilang trabaho.';

  @override
  String get profPrivacyWhoElseTitle => 'Sino pa ang makakakita nito';

  @override
  String get profPrivacyWhoElseBody =>
      'Walang sinuman sa labas ng Taytay LGU, at walang advertiser. Hindi ibinebenta o ibinabahagi ang iyong impormasyon para sa marketing. Ibinabahagi lamang ito sa ibang tanggapan ng pamahalaan kung iniuutos ito ng batas.';

  @override
  String get profPrivacyRightsTitle => 'Ang iyong mga karapatan';

  @override
  String get profPrivacyRightsBody =>
      'Sa ilalim ng Data Privacy Act of 2012, maaari mong itanong sa Taytay LGU kung ano ang hawak nito tungkol sa iyo, humingi ng kopya, hilingin na itama ang isang mali, tumutol sa paraan ng paggamit nito, at magreklamo sa National Privacy Commission.';

  @override
  String get profPrivacyRightsHow =>
      'Magtanong sa munisipyo ng Taytay dala ang wastong ID. Maaaring direktang asikasuhin ng staff doon ang iyong rekord. Hindi mo kailangan ang app na ito o ang iyong telepono para gawin ito.';

  @override
  String get profPrivacyConsentTitle => 'Pagbabago sa iyong pinahintulutan.';

  @override
  String get profPrivacyConsentBody =>
      'Ang mga pahintulot na ibinigay mo noong nagparehistro ka ay nakatala kasama ng iyong rekord sa Taytay LGU, hindi sa app na ito. Para baguhin o bawiin ang isa, magtanong sa munisipyo — sa ganoong paraan, maitatala ang pagbabago kung saan ito mahalaga.';

  @override
  String get profPrivacyDeleteTitle => 'Pagbura ng iyong rekord.';

  @override
  String get profPrivacyDeleteBody =>
      'Itinatago ang rekord ng residente ng munisipyo hangga\'t iniuutos ng batas, kaya hindi ito binubura kapag hiniling. Maaaring i-deactivate ng Taytay LGU ang isang account at itama ang mali.';

  @override
  String get profNameAsPrinted =>
      'Isulat ang iyong pangalan nang eksakto kung paano ito nakalimbag sa iyong ID mula sa pamahalaan. Sinusuri ito ng Taytay LGU laban sa iyong ID.';

  @override
  String get profNameUnderReview =>
      'Sinusuri ng Taytay LGU ang pangalang ito laban sa iyong ID, kaya hindi ito mababago habang hindi pa tapos ang pagsusuri.';

  @override
  String get profNameChecked =>
      'Nasuri na ng Taytay LGU ang pangalang ito laban sa iyong ID, kaya hindi ito mababago rito. Para baguhin ito, magtanong sa Taytay LGU.';

  @override
  String get profNameUnknown =>
      'Hindi namin masuri kung maaaring baguhin ang iyong pangalan. Subukang muli mamaya.';

  @override
  String get profNameBeforeSendingTitle => 'Ang iyong pangalan at ang iyong ID';

  @override
  String get profNameBeforeSending =>
      'Susuriin ng Taytay LGU kung ang pangalan sa iyong account ang nakasulat sa iyong ID. Tiyaking magkatugma ang dalawa bago ipadala. Hindi na mababago ang iyong pangalan habang sinusuri pa ito o kapag naaprubahan na.';

  @override
  String get profNameCheckName => 'Suriin ang pangalan sa iyong account';

  @override
  String get profNameEmpty =>
      'Ilagay ang iyong pangalan nang eksakto kung paano ito nakalimbag sa iyong ID mula sa pamahalaan.';

  @override
  String profNameTooLong(int max) {
    return 'Hanggang $max karakter lang ang maaaring haba ng iyong pangalan.';
  }

  @override
  String get profBarangayHeldNote =>
      'Para baguhin ang iyong barangay, pumunta sa tanggapan ng MSWDO dala ang patunay ng iyong bagong tirahan.';

  @override
  String get profBarangayRefusedTitle => 'Hindi nabago ang iyong barangay';

  @override
  String get profBarangayRefused =>
      'Verified na ang iyong account, kaya sa tanggapan ng MSWDO binabago ang iyong barangay. Para baguhin ang iyong barangay, pumunta sa tanggapan ng MSWDO dala ang patunay ng iyong bagong tirahan.';

  @override
  String get profOfficeRecordTitle => 'Ang iyong rekord sa tanggapan ng MSWDO';

  @override
  String get profOfficeRecordKeptByOffice =>
      'Ang tanggapan ang nag-iingat ng rekord na ito. Kung may mali rito, pumunta sa tanggapan ng MSWDO dala ang iyong ID.';

  @override
  String get profOfficeRecordName => 'Pangalan';

  @override
  String get profOfficeRecordBirthDate => 'Petsa ng kapanganakan';

  @override
  String get profOfficeRecordNotShown => 'Magtanong sa tanggapan ng MSWDO';

  @override
  String get profSexFemale => 'Babae';

  @override
  String get profSexMale => 'Lalaki';

  @override
  String get sectorsTitle => 'Mga sektor at benepisyo';

  @override
  String get sectorsIntro =>
      'Bahagi ng iyong rekord sa Taytay LGU ang iyong mga sektor. Ginagamit ito ng mga tanggapan para makita kung aling mga programa ang maaaring angkop sa iyo.';

  @override
  String get sectorsYoursHeading => 'Ang iyong mga sektor';

  @override
  String get sectorsNone =>
      'Wala pang sektor sa iyong rekord sa app. Lalabas ang mga ito rito kapag naiugnay na ng MSWDO ang iyong account sa mga rekord nito, na ginagawa nito kapag inaprubahan nito ang iyong unang aplikasyon.';

  @override
  String get sectorsApplyHeading => 'Mag-apply para sa isang sektor';

  @override
  String get sectorsNothingToApply =>
      'Ang senior citizen, taong may kapansanan at solo parent ay nasa iyong rekord na o sinusuri pa. Masasabi sa iyo ng MSWDO kung paano mag-renew ng ID.';

  @override
  String get sectorsInPerson =>
      'Ipinapakita ng pahinang ito ang senior citizen, taong may kapansanan at solo parent. Ang ibang sektor ay personal na itinatala ng MSWDO at hindi ipinapakita rito.';

  @override
  String get sectorsLoading => 'Nilo-load ang iyong mga sektor';

  @override
  String get sectorsRecorded => 'Nakatala';

  @override
  String get sectorsBeingChecked => 'Sinusuri';

  @override
  String get sectorsReturned => 'Ibinalik';

  @override
  String get sectorsLapsed => 'Expired na ang ID';

  @override
  String get sectorsLabelSenior => 'Senior citizen';

  @override
  String get sectorsLabelPwd => 'Taong may kapansanan';

  @override
  String get sectorsLabelSoloParent => 'Solo parent';

  @override
  String get sectorsOfferSenior =>
      '60 pataas · ang iyong Senior Citizen ID o birth certificate';

  @override
  String get sectorsOfferPwd => 'Ang iyong PWD ID mula sa PDAO';

  @override
  String get sectorsOfferSoloParent => 'Ang iyong Solo Parent ID';

  @override
  String get sectorsChoiceSenior =>
      'Para sa mga residenteng 60 taong gulang pataas. Ihanda ang iyong Senior Citizen ID o birth certificate.';

  @override
  String get sectorsChoicePwd => 'Ihanda ang iyong PWD ID mula sa PDAO.';

  @override
  String get sectorsChoiceSoloParent => 'Ihanda ang iyong Solo Parent ID.';

  @override
  String sectorsSince(String date) {
    return 'Mula $date';
  }

  @override
  String sectorsIdEnding(String lastFour) {
    return 'ID na nagtatapos sa $lastFour';
  }

  @override
  String sectorsValidUntil(String date) {
    return 'Valid hanggang $date';
  }

  @override
  String get sectorsYouApplied => 'Nag-apply ka';

  @override
  String sectorsYouAppliedOn(String date) {
    return 'Nag-apply ka noong $date';
  }

  @override
  String get sectorsReturnedNoReason =>
      'Ibinalik ito ng tanggapan. Maaari kang mag-apply muli.';

  @override
  String sectorsOfficeSaid(String reason) {
    return 'Sabi ng tanggapan: $reason';
  }

  @override
  String get sectorsChooseSubtitle =>
      'Piliin ang sektor na angkop sa iyo. Susunod, magdaragdag ka ng litrato ng iyong ID.';

  @override
  String get sectorsSector => 'Sektor';

  @override
  String sectorsProofTitle(String idName) {
    return 'Idagdag ang iyong $idName';
  }

  @override
  String get sectorsProofSubtitle =>
      'Sinusuri ito ng staff ng MSWDO laban sa kanilang mga rekord bago idagdag ang sektor.';

  @override
  String get sectorsPhotoLabel => 'Litrato ng ID';

  @override
  String get sectorsAddPhoto => 'Magdagdag ng litrato';

  @override
  String sectorsPhotoAdded(String size) {
    return 'Naidagdag ang litrato · $size';
  }

  @override
  String get sectorsPhotoNote =>
      'Tinitingnan ng staff ng Taytay LGU ang litratong ito para maitala ang iyong sektor. Kunan ito sa maliwanag na lugar, at kita ang buong ID sa frame.';

  @override
  String get sectorsConfirmLabel => 'Akin ang ID na ito';

  @override
  String get sectorsConfirmDescription =>
      'Ipinapadala ko ito para maitala ng Taytay LGU ang sektor na ito sa aking profile.';

  @override
  String get sectorsSend => 'Ipadala para masuri';

  @override
  String get sectorsSourceTitle => 'Idagdag ang litrato';

  @override
  String get sectorsNoSource =>
      'Hindi makapagdagdag ng litrato rito ang teleponong ito. Maitatala ng MSWDO ang sektor sa munisipyo.';

  @override
  String get sectorsSentTitle => 'Naipadala ang aplikasyon';

  @override
  String sectorsSentSubtitle(String sector) {
    return '$sector · Bayan ng Taytay';
  }

  @override
  String get sectorsSentAt => 'Naipadala';

  @override
  String get sectorsNextHeading => 'Ano ang susunod';

  @override
  String get sectorsStepSent => 'Naipadala sa MSWDO';

  @override
  String get sectorsStepCheck => 'Sinusuri ng staff ang iyong ID';

  @override
  String get sectorsStepCheckDetail =>
      'Maaari silang humingi ng mas malinaw na litrato. Makakatanggap ka ng abiso sa app na ito kapag nakapagpasya na sila.';

  @override
  String get sectorsStepAdded => 'Naidagdag sa iyong profile';

  @override
  String get sectorsStepAddedDetail =>
      'Pagkatapos, lalabas itong nakatala sa Mga sektor at benepisyo.';

  @override
  String get sectorsBackToSectors => 'Bumalik sa Mga sektor at benepisyo';

  @override
  String get sectorsGoHome => 'Pumunta sa Home';

  @override
  String get sectorsUnconfirmed =>
      'Hindi namin makumpirma kung dumating ang iyong aplikasyon. Bago ito ipadala muli, buksan ang Mga sektor at benepisyo: kung nakalagay itong sinusuri, dumating na ito.';

  @override
  String get sectorsOffline =>
      'Walang naipadala. Nandito pa sa telepono ang iyong napili at ang litrato. Kumonekta sa internet at ipadala muli.';

  @override
  String get sectorsRefusedTitle => 'Hindi tinanggap ang litrato';

  @override
  String get sectorsRefused =>
      'Walang naipadala. Pumili ng mas malinaw na JPEG o PNG na litrato ng ID, hanggang 5 MB, at ipadala muli.';

  @override
  String get sectorsWaitingTitle => 'Nasa rekord mo na o sinusuri pa';

  @override
  String get sectorsWaiting =>
      'Walang bagong naipadala. Nasa iyong rekord na ang sektor na ito, o nasa MSWDO na ang isang aplikasyon para dito. Makikita sa Mga sektor at benepisyo kung alin.';

  @override
  String get sectorsNotOpenTitle => 'Hindi available para sa account na ito';

  @override
  String get sectorsNotOpen =>
      'Walang naipadala. Bukas ang pag-apply para sa sektor sa mga verified na residente. Masasabi sa iyo ng munisipyo ang higit pa.';

  @override
  String get sectorsFailedSendTitle => 'Hindi naipadala';

  @override
  String get sectorsFailedSend =>
      'Walang naipadala. May nangyaring mali sa aming panig. Subukang muli maya-maya.';

  @override
  String get eventsTitle => 'Mga Kaganapan';

  @override
  String get eventsScopeSemantics => 'Ipakita ang mga kaganapan';

  @override
  String get eventsScopeUpcoming => 'Paparating';

  @override
  String get eventsScopeRegistered => 'Nakarehistro';

  @override
  String get eventsScopePast => 'Nakaraan';

  @override
  String get eventsUnavailableTitle =>
      'Hindi available ang mga kaganapan ngayon';

  @override
  String get eventsUnavailableBody =>
      'Hindi namin maabot ang Taytay LGU. Pakisuri ang iyong koneksyon at subukang muli. Nakapaskil din ang mga abiso ng kaganapan sa munisipyo at sa mga barangay hall.';

  @override
  String get eventsEmptyUpcomingTitle => 'Walang nakatakda sa ngayon';

  @override
  String get eventsEmptyRegisteredTitle =>
      'Hindi ka pa nakarehistro sa anumang kaganapan';

  @override
  String get eventsEmptyPastTitle => 'Walang nakaraang kaganapang maipapakita';

  @override
  String get eventsEmptyUpcomingBody =>
      'Lalabas dito ang mga bagong kaganapan ng Taytay LGU kapag inanunsyo na ang mga ito.';

  @override
  String get eventsEmptyRegisteredBody =>
      'Lalabas dito ang mga kaganapang pinarehistruhan mo.';

  @override
  String get eventsEmptyPastBody =>
      'Lalabas dito ang mga kaganapang natapos na.';

  @override
  String get eventsLoadMoreFailed => 'Hindi nakuha ang iba pa. ';

  @override
  String get eventsSeenStillHere => 'Nandito pa rin ang mga nakita mo na.';

  @override
  String get eventsLoadingMore => 'Naglo-load ng iba pang kaganapan';

  @override
  String get eventsLoadMore => 'Mag-load pa';

  @override
  String get eventsListEnd =>
      'Iyan na ang lahat ng nakalista rito ng Taytay LGU.';

  @override
  String eventsPlacesLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count puwesto na lang ang natitira',
      one: '1 puwesto na lang ang natitira',
    );
    return '$_temp0';
  }

  @override
  String get eventsLoading => 'Naglo-load ng mga kaganapan';

  @override
  String get eventsCalledOff => 'Kinansela ng Taytay LGU';

  @override
  String get eventsStateNotRequired => 'Hindi kailangang magparehistro';

  @override
  String get eventsStateNotOpen => 'Hindi pa bukas ang pagpaparehistro';

  @override
  String get eventsStateOpen => 'Bukas ang pagpaparehistro';

  @override
  String get eventsStateRegistered => 'Nakarehistro ka';

  @override
  String get eventsStateWaitlisted => 'Nasa waitlist ka';

  @override
  String get eventsStateCancelled => 'Kinansela mo ang iyong puwesto';

  @override
  String get eventsStateFull => 'Puno na';

  @override
  String get eventsStateClosed => 'Sarado na ang pagpaparehistro';

  @override
  String get eventsStateUnknown =>
      'Magtanong sa tanggapan tungkol sa pagpaparehistro';

  @override
  String get eventsGiveUpTitle => 'Bitawan ang iyong puwesto?';

  @override
  String get eventsGiveUpConsequence =>
      'Iaalok ng Taytay LGU ang iyong puwesto sa susunod na naghihintay. Kung magbago ang isip mo, kailangan mong magparehistro muli, at maaaring puno na ang kaganapan pagsapit noon.';

  @override
  String get eventsGiveUpConfirm => 'Bitawan ang aking puwesto';

  @override
  String get eventsGiveUpKeep => 'Panatilihin ang aking puwesto';

  @override
  String get eventsGiveUpDone =>
      'Nabitawan na ang iyong puwesto. Naabisuhan na ang Taytay LGU.';

  @override
  String get eventsGiveUpUnconfirmed =>
      'Hindi namin makumpirma kung nabitawan na ang iyong puwesto. Ligtas itong subukang muli: hindi ito magagawa nang dalawang beses.';

  @override
  String get eventsGiveUpTooLate =>
      'Hindi na maaaring bitawan ang iyong puwesto sa app. Makipag-ugnayan sa Taytay LGU kung hindi ka makakapunta.';

  @override
  String eventsGiveUpFailedStillHeld(String message) {
    return '$message Nasa iyo pa rin ang iyong puwesto.';
  }

  @override
  String get eventsMapRefused => 'Hindi mabuksan nang ligtas ang link ng mapa.';

  @override
  String get eventsMapNoApp =>
      'Walang app sa device na ito na makapagbubukas ng mapa.';

  @override
  String get eventsEventTitle => 'Kaganapan';

  @override
  String get eventsOpening => 'Binubuksan ang kaganapan…';

  @override
  String get eventsCalledOffBody =>
      'Kinansela ng Taytay LGU ang kaganapang ito. Hindi ito matutuloy gaya ng nakalista. Magtanong sa tanggapan kung may tanong ka.';

  @override
  String get eventsOpenDirections => 'Buksan ang direksyon';

  @override
  String get eventsShareEvent => 'Ibahagi ang kaganapang ito';

  @override
  String get eventsRegisteredNotice =>
      'Nasa Taytay LGU na ang iyong rehistro para sa kaganapang ito. Magdala ng valid ID.';

  @override
  String get eventsFactWhen => 'Kailan';

  @override
  String get eventsFactWhere => 'Saan';

  @override
  String get eventsFactOrganiser => 'Inorganisa ng';

  @override
  String get eventsFactQuestions => 'Mga tanong';

  @override
  String get eventsWhoCanJoin => 'Sino ang maaaring sumali';

  @override
  String get eventsWhoCanRegister => 'Sino ang maaaring magparehistro';

  @override
  String get eventsWhatToBring => 'Ano ang dadalhin';

  @override
  String get eventsRegisterForEvent => 'Magparehistro sa kaganapang ito';

  @override
  String get eventsLguDecides =>
      'Ang Taytay LGU ang magpapasya kung may bakanteng puwesto.';

  @override
  String get eventsReference => 'Reperensiya';

  @override
  String get eventsWaitlistPosition => 'Puwesto sa waitlist';

  @override
  String get eventsAttended => 'Itinala ng Taytay LGU na dumalo ka.';

  @override
  String get eventsAbsent =>
      'Hindi ka naitala ng Taytay LGU bilang dumalo. Kung mali iyon, makipag-ugnayan sa tanggapan.';

  @override
  String get eventsAttendanceNotRecorded =>
      'Hindi pa naitatala ang pagdalo para sa kaganapang ito.';

  @override
  String eventsCapacityOfTotal(int remaining, int total) {
    return '$remaining sa $total puwesto na lang ang natitira';
  }

  @override
  String eventsCapacityLeft(int remaining) {
    return '$remaining puwesto na lang ang natitira';
  }

  @override
  String get eventsCapacityNone => 'Wala nang natitirang puwesto';

  @override
  String eventsCapacityRoomFor(int total) {
    return 'May puwesto para sa $total katao';
  }

  @override
  String get eventsCapacityTitle => 'Mga puwesto';

  @override
  String eventsCapacityFull(String line) {
    return '$line. Masasabi sa iyo ng tanggapan kung may bukas na waitlist.';
  }

  @override
  String get eventsOpenToVerified =>
      'Mga residenteng na-verify na ng Taytay LGU ang ID. Ilang hakbang lang ang pag-verify, at isang beses lang itong gagawin.';

  @override
  String get eventsOpenToAccounts =>
      'Sinumang naka-sign in sa app. Hindi mo kailangan ng na-verify na ID para magparehistro sa kaganapang ito.';

  @override
  String get eventsNotAvailableTitle => 'Hindi available ang kaganapang ito';

  @override
  String get eventsSeeAll => 'Tingnan ang lahat ng kaganapan';

  @override
  String get eventsOpeningForm => 'Binubuksan ang form ng pagpaparehistro…';

  @override
  String get eventsRegistrationNotSwitchedOn =>
      'Hindi pa binubuksan ang pagpaparehistro sa app na ito. Masasabi sa iyo ng tanggapan ng Taytay na nangangasiwa sa kaganapang ito kung paano sumali.';

  @override
  String get eventsRegisteringYou => 'Inirerehistro ka…';

  @override
  String get eventsRegister => 'Magparehistro';

  @override
  String get eventsBlockedAlreadyTitle => 'Nakarehistro ka na';

  @override
  String get eventsBlockedAlreadyBody =>
      'Nasa Taytay LGU na ang iyong puwesto para sa kaganapang ito. Nasa pahina ng kaganapan ang iyong reperensiya.';

  @override
  String get eventsBackToEvent => 'Bumalik sa kaganapan';

  @override
  String get eventsBlockedVerifyTitle =>
      'Kailangan ng na-verify na account para sa kaganapang ito';

  @override
  String get eventsBlockedVerifyBody =>
      'Hinihingi ng Taytay LGU na kumpirmado ang iyong pagkakakilanlan bago magparehistro rito. Ilang hakbang lang ang pag-verify, at isang beses lang itong gagawin.';

  @override
  String get eventsBlockedUnsupportedTitle =>
      'Kailangan ang tanggapan para sa pagpaparehistrong ito';

  @override
  String get eventsBlockedUnsupportedBody =>
      'May idinagdag ang Taytay LGU sa form na ito na hindi maipakita ng bersyong ito ng app. Maaaring makatulong ang pag-update ng app. Hanggang doon, maaari kang irehistro nang personal ng tanggapang nangangasiwa sa kaganapan.';

  @override
  String get eventsBlockedNotOpenTitle => 'Hindi bukas ang pagpaparehistro';

  @override
  String get eventsBlockedNotOpenBody =>
      'Hindi tumatanggap ang Taytay LGU ng rehistro para sa kaganapang ito sa ngayon.';

  @override
  String get eventsRegistrationSubtitle => 'Pagpaparehistro sa kaganapan';

  @override
  String get eventsStepConfirm => 'Kumpirmahin ang iyong rehistro';

  @override
  String get eventsStepQuestions => 'Mga tanong mula sa tanggapan';

  @override
  String get eventsStepConsent => 'Bago ka magparehistro';

  @override
  String get eventsStepSubmitting => 'Nagpaparehistro';

  @override
  String get eventsStepOutcome => 'Ang iyong rehistro';

  @override
  String get eventsRegisteringFor => 'Nagpaparehistro ka para sa';

  @override
  String get eventsFiledAgainstAccount =>
      'Itatala ang rehistrong ito sa account na naka-sign in ka ngayon.';

  @override
  String get eventsFromTheOffice => 'Mula sa tanggapan';

  @override
  String get eventsLguDecidesNextScreen =>
      'Ang Taytay LGU ang magpapasya kung may bakanteng puwesto. Makikita mo ang sagot sa susunod na screen.';

  @override
  String get eventsAnswerYes => 'Oo';

  @override
  String get eventsAnswerNo => 'Hindi';

  @override
  String eventsConsentOptional(String label) {
    return '$label (opsyonal)';
  }

  @override
  String get eventsOutcomeFullTitle => 'Puno na ang kaganapang ito';

  @override
  String get eventsOutcomeClosedTitle => 'Nagsara na ang pagpaparehistro';

  @override
  String get eventsOutcomeRefusedTitle => 'Hindi ka mairehistro ng Taytay LGU';

  @override
  String get eventsOutcomeUnconfirmedTitle =>
      'Hindi pa kumpirmado ang pagpaparehistro';

  @override
  String get eventsOutcomeNotRegisteredTitle => 'Hindi nakarehistro';

  @override
  String eventsWaitlistNumber(int position) {
    return 'Pang-$position ka sa waitlist.';
  }

  @override
  String eventsQuoteRequestId(String requestId) {
    return 'Kung makikipag-ugnayan ka sa tanggapan, banggitin ang $requestId.';
  }

  @override
  String get eventsCannotRegisterHere => 'Hindi ka pa makakapagparehistro dito';

  @override
  String get eventsOutcomeRegisteredBody =>
      'Nasa Taytay LGU na ang iyong puwesto. Banggitin ang iyong reperensiya sa pasukan.';

  @override
  String get eventsOutcomeWaitlistedBody =>
      'Nasa waitlist ka ng Taytay LGU. Inaakyat ng tanggapan ang mga nasa waitlist kapag may nabakanteng puwesto, at makakakita ka ng abiso sa app kapag nangyari iyon.';

  @override
  String get eventsOutcomeFullBody =>
      'Naubos na ang lahat ng puwesto bago dumating ang iyong rehistro, at walang waitlist ang kaganapang ito. Walang nairehistro.';

  @override
  String get eventsOutcomeClosedBody =>
      'Nagsara ang pagpaparehistro para sa kaganapang ito bago dumating ang iyong rehistro. Walang nairehistro.';

  @override
  String get eventsRefusedNeedsVerification =>
      'Tumatanggap ang kaganapang ito ng rehistro mula sa mga na-verify na account lamang. I-verify muna ang iyong account, saka magparehistro.';

  @override
  String get eventsRefusedNotAllowed =>
      'Hindi available sa app ang pagpaparehistro sa kaganapan para sa account na ito.';

  @override
  String get eventsRefusedNotListed =>
      'Hindi na nakalista ang kaganapang ito, kaya hindi makatanggap ang Taytay LGU ng rehistro para rito.';

  @override
  String get eventsRefusedNotTaking =>
      'Hindi tumatanggap ang Taytay LGU ng rehistro para sa kaganapang ito sa ngayon. Nakasaad sa pahina ng kaganapan kung magbubukas ang pagpaparehistro sa ibang pagkakataon.';

  @override
  String get eventsRefusedNotAccepted =>
      'Hindi matanggap ng Taytay LGU ang rehistrong ito gaya ng pagkakapadala. Kung maulit ito, banggitin sa tanggapan ang reperensiya sa ibaba.';

  @override
  String get eventsRegistrationUnconfirmed =>
      'Hindi namin makumpirma kung natanggap ang iyong rehistro. Ligtas itong subukang muli: hindi ka mairerehistro nang dalawang beses.';

  @override
  String eventsRegistrationNotSent(String message) {
    return 'Hindi namin naipadala ang iyong rehistro, kaya walang nairehistro. $message';
  }

  @override
  String get balitaAdvisoriesTitle => 'Mga Advisory';

  @override
  String get balitaFilteredSubtitle => 'Balita · naka-filter';

  @override
  String get balitaLoading => 'Naglo-load ng Balita';

  @override
  String get balitaUnavailableTitle => 'Hindi available ang mga anunsyo ngayon';

  @override
  String get balitaUnavailableBody =>
      'Hindi namin maabot ang Taytay LGU. Pakisuri ang iyong koneksyon at subukang muli. Nakapaskil din ang mga abiso ng bayan sa munisipyo at sa mga barangay hall.';

  @override
  String get balitaEmptyTitle => 'Walang bago sa ngayon';

  @override
  String get balitaEmptyBody =>
      'Lalabas dito ang mga bagong anunsyo ng Taytay LGU.';

  @override
  String get balitaFilterSemantics => 'I-filter ang Balita';

  @override
  String get balitaLatest => 'Pinakabagong Balita';

  @override
  String balitaShareArticle(String title) {
    return 'Ibahagi ang $title';
  }

  @override
  String get balitaShare => 'Ibahagi';

  @override
  String get balitaEmergencyAdvisory => 'Abiso sa emergency';

  @override
  String get balitaPinnedAdvisory => 'Naka-pin na abiso';

  @override
  String get balitaEmptyEventsBody =>
      'Wala pang nai-post na paparating na kaganapan ng bayan. Aabisuhan ka namin kapag may inanunsyo ang LGU.';

  @override
  String balitaEmptyCategoryBody(String category) {
    return 'Wala pang nailalathalang post sa $category.';
  }

  @override
  String get balitaSeeAll => 'Tingnan ang lahat ng Balita';

  @override
  String get balitaShareFooter => 'Mula sa Taytay LGU';

  @override
  String get balitaShareCopied =>
      'Nakopya na. Maaari mo itong i-paste sa kahit anong app.';

  @override
  String get balitaShareUnavailable =>
      'Hindi available ang pagbabahagi sa device na ito.';

  @override
  String get balitaLoadingArticle => 'Kinukuha ang anunsyo';

  @override
  String get balitaArticleNotAvailable => 'Hindi available ang anunsyong ito';

  @override
  String get balitaSeeAllAnnouncements => 'Tingnan ang lahat ng anunsyo';

  @override
  String get inboxTitle => 'Mga Notification';

  @override
  String get inboxLoading => 'Naglo-load ng mga notification';

  @override
  String get inboxEmptyTitle => 'Wala pa';

  @override
  String get inboxEmptyBody =>
      'Lalabas dito ang mga update tungkol sa iyong mga hiling, dokumento, at kaganapan.';

  @override
  String get inboxEarlier => 'Mas maaga';

  @override
  String get inboxEyebrowUpdate => 'Update';

  @override
  String get inboxLoadMoreFailed => 'Hindi nakuha ang iba pa';

  @override
  String get inboxLoadingOlder => 'Kinukuha ang mas luma';

  @override
  String get inboxLoadOlder => 'Ipakita ang mas luma';

  @override
  String get inboxFilterAll => 'Lahat';

  @override
  String inboxFilterUnread(int count) {
    return 'Hindi pa nababasa · $count';
  }

  @override
  String get inboxMarkAllRead => 'Markahang nabasa lahat';

  @override
  String get inboxUnread => 'Hindi pa nababasa';

  @override
  String get inboxSettingsTitle => 'Mga setting ng notification';

  @override
  String get inboxSettingsLoading =>
      'Naglo-load ng mga setting ng notification';

  @override
  String get inboxSaveUnconfirmedTitle =>
      'Maaaring hindi na-save ang iyong pagbabago';

  @override
  String get inboxSaveUnconfirmedBody =>
      'Hindi namin ito makumpirma. Ipinapakita ng switch ang iyong setting bago ang pagbabago. Ligtas itong i-set muli.';

  @override
  String get inboxSaveFailedTitle => 'Hindi na-save ang pagbabagong iyon';

  @override
  String get inboxSaveFailedBody =>
      'Walang nagbago sa iyong setting. Pakisuri ang iyong koneksyon at subukang muli.';

  @override
  String get inboxSettingsIntro =>
      'Piliin kung tungkol saan ka aabisuhan ng Taytay LGU.';

  @override
  String get inboxAlwaysSentTitle => 'Laging ipinapadala';

  @override
  String get inboxAlwaysSentBody =>
      'Laging ipinapadala ang mga pampublikong abiso at ang mga mensahe tungkol sa iyong account at seguridad. Sa pamamagitan ng mga ito ka naaabot ng Taytay LGU sa oras ng emergency, o nasasabihan kung may ibang nag-sign in bilang ikaw.';

  @override
  String get dirOfficeDetails => 'Detalye ng tanggapan';

  @override
  String get dirOfficeNotShownTitle => 'Hindi maipakita ang tanggapang ito';

  @override
  String get dirOfficeNotShownBody =>
      'Hindi maabot ang Taytay LGU, o wala na sa listahan ang tanggapan. Maaari mong subukang muli.';

  @override
  String get dirLoadingOffice => 'Kinukuha ang tanggapan';

  @override
  String get dirSearchTitle => 'Maghanap';

  @override
  String get dirMunicipalOffices => 'Mga tanggapan ng munisipyo';

  @override
  String get dirNotifications => 'Mga notification';

  @override
  String get dirSearchHint => 'Maghanap ng tanggapan o serbisyo';

  @override
  String get dirCategory => 'Kategorya';

  @override
  String get dirChipAll => 'Lahat';

  @override
  String get dirNoOfficesInCategory => 'Walang tanggapan sa kategoryang ito';

  @override
  String dirNoOfficesFound(String query) {
    return 'Walang nahanap na tanggapan para sa “$query”';
  }

  @override
  String get dirTryAnotherWord =>
      'Sumubok ng ibang salita, o tumingin ayon sa kategorya.';

  @override
  String get dirBrowseAll => 'Tingnan ang lahat ng tanggapan';

  @override
  String dirOfficeCountNoun(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'tanggapan',
    );
    return '$_temp0';
  }

  @override
  String get dirLoadingDirectory => 'Kinukuha ang direktoryo';

  @override
  String get dirCantLoadTitle => 'Hindi ma-load ang direktoryo';

  @override
  String get dirCantLoadBody =>
      'Pakisuri ang iyong mobile data o Wi-Fi, saka subukang muli. Nakalista sa ibaba ang mga naka-save na numero ng tanggapan.';

  @override
  String get dirSavedOnPhone => 'Naka-save sa teleponong ito';

  @override
  String get dirOfflineTitle => 'Wala kang koneksyon';

  @override
  String get dirOfflineShowingSaved =>
      'Ipinapakita ang na-save sa teleponong ito';

  @override
  String dirCallName(String name) {
    return 'Tawagan ang $name';
  }

  @override
  String get dirRepresentativePhoto => 'Halimbawang larawan';

  @override
  String dirRepresentativePhotoCredit(String credit) {
    return 'Halimbawang larawan · $credit';
  }

  @override
  String get dirActionCall => 'Tumawag';

  @override
  String get dirActionDirections => 'Direksyon';

  @override
  String get dirActionMessage => 'Magmensahe';

  @override
  String get dirActionApp => 'App';

  @override
  String get dirFactLocation => 'Lokasyon';

  @override
  String get dirFactHours => 'Oras ng tanggapan';

  @override
  String get dirFactPhone => 'Telepono';

  @override
  String get dirFactEmail => 'Email';

  @override
  String get dirFactHead => 'Pinuno';

  @override
  String get dirServices => 'Mga serbisyo';

  @override
  String get dirNewMessage => 'Bagong mensahe';

  @override
  String get dirOfficeDidNotLoadTitle => 'Hindi na-load ang tanggapang ito';

  @override
  String get dirOfficeDidNotLoadBody =>
      'Subukang muli, o bumalik sa direktoryo.';

  @override
  String get dirTopic => 'Paksa';

  @override
  String dirTopicValue(String topic) {
    return 'Paksa, $topic';
  }

  @override
  String get dirGeneralTopic => 'Pangkalahatang tanong';

  @override
  String get dirFieldMessage => 'Mensahe';

  @override
  String get dirMessageHint => 'Isulat ang iyong mensahe';

  @override
  String get dirSendMessage => 'Ipadala ang mensahe';

  @override
  String get dirPrivacyWarning =>
      'Huwag ibahagi ang password o one-time code sa mensahe.';

  @override
  String get dirTo => 'Para sa';

  @override
  String get dirAttach => 'Mag-attach ng litrato o PDF (opsyonal)';

  @override
  String get dirEmergencyHeading =>
      'Kapag emergency, huwag nang hintayin ang sagot';

  @override
  String get dirEmergencyBody => 'Tumawag sa emergency hotline.';

  @override
  String dirEmergencyCallLine(String name, String number) {
    return 'Tawagan ang $name: $number.';
  }

  @override
  String get dirSeeHotlines => 'Tingnan ang mga emergency hotline';

  @override
  String get dirLoadingHotline => 'Kinukuha ang emergency hotline';

  @override
  String get dirMessageSentTitle => 'Naipadala ang mensahe';

  @override
  String get dirMessageSentBody =>
      'Aabisuhan ka namin, at naka-save ang usapan sa Aking Account › Mga mensahe.';

  @override
  String get dirGoToMessages => 'Pumunta sa Mga mensahe';

  @override
  String get dirBackToDirectory => 'Bumalik sa Direktoryo';

  @override
  String get dirConversation => 'Usapan';

  @override
  String get dirCannotAttach =>
      'Hindi makapag-attach ng file ang teleponong ito.';

  @override
  String get dirWriteBeforeSending => 'Sumulat ng mensahe bago ipadala.';

  @override
  String get dirNoDialer => 'Walang app sa teleponong ito na kayang tumawag.';

  @override
  String get tulongSubtitle => 'Mga serbisyong panlipunan at programa';

  @override
  String get tulongSubtitleMswdo => 'Mga serbisyong panlipunan · MSWDO';

  @override
  String get tulongNoteInformationOnly =>
      'Impormasyon tungkol sa mga programa ng munisipyo. Mga pahina ito ng impormasyon, hindi aplikasyon.';

  @override
  String get tulongNoteSomeApply =>
      'Impormasyon tungkol sa mga programa ng munisipyo. May ilang pahina na tumatanggap din ng aplikasyon sa app: buksan ang pahina para makita kung tumatanggap ito.';

  @override
  String get tulongStaleHeading => 'Hindi ma-refresh ang listahan';

  @override
  String tulongStaleMessage(String timestamp) {
    return 'Ipinapakita ang listahan noong $timestamp. Maaaring nagbago na ito.';
  }

  @override
  String tulongIncomplete(int shown) {
    return 'Mas marami ang programang nakalista ng Taytay LGU kaysa sa kinukuha ng app na ito. Ang unang $shown lamang ang sakop ng listahang ito at ng paghahanap.';
  }

  @override
  String get tulongSearchHint => 'Maghanap ng programa';

  @override
  String get tulongLoading => 'Kinukuha ang mga programa';

  @override
  String get tulongTryingAgain => 'Sinusubukang muli…';

  @override
  String get tulongNoMatchTitle => 'Walang programang tugma sa hinanap mo.';

  @override
  String get tulongNoMatchBody =>
      'Sumubok ng ibang salita, o burahin ang hinahanap para makita ang bawat programa.';

  @override
  String get tulongEmptyTitle => 'Wala pang nakalistang programa';

  @override
  String get tulongEmptyBody =>
      'Lalabas dito ang impormasyon tungkol sa mga programa mula sa Taytay LGU.';

  @override
  String get tulongOfflineTitle =>
      'Kailangan ng koneksyon para sa mga pahina ng programa';

  @override
  String get tulongOfflineBody =>
      'Hindi namin ma-load ang pinakabagong impormasyon tungkol sa mga programa.';

  @override
  String get tulongOfflineBodySaved =>
      'Hindi namin ma-load ang pinakabagong impormasyon tungkol sa mga programa. Naka-save sa ibaba ang mga pahinang binuksan mo dati.';

  @override
  String get tulongSavedPages => 'Mga naka-save na pahina';

  @override
  String get tulongWhoCanAvail => 'Sino ang puwedeng mag-avail';

  @override
  String get tulongRequirements => 'Mga requirement';

  @override
  String get tulongInformationOnly => '(impormasyon lamang)';

  @override
  String get tulongHowToClaim => 'Paano kunin';

  @override
  String get tulongSchedule => 'Iskedyul';

  @override
  String get tulongQuestions => 'Mga tanong';

  @override
  String get tulongShare => 'Ibahagi sa kapamilya';

  @override
  String get tulongFactOffice => 'Tanggapan';

  @override
  String get tulongFactHours => 'Oras';

  @override
  String get tulongContactLandline => 'Landline';

  @override
  String get tulongContactHotline => 'Hotline';

  @override
  String get tulongContactEmail => 'Email';

  @override
  String get tulongContactMobile => 'Cellphone';

  @override
  String get tulongContactOther => 'Kontak';

  @override
  String get tulongNoPhone =>
      'Wala pang inilalathalang numero ng telepono ang tanggapang ito.';

  @override
  String get tulongNoCalling => 'Hindi puwedeng tumawag sa device na ito.';

  @override
  String get tulongNoAddress =>
      'Wala pang inilalathalang address ang tanggapang ito.';

  @override
  String get tulongNoMaps => 'Hindi mabuksan ang mapa sa device na ito.';

  @override
  String get tulongNoOffice =>
      'Hindi nakaugnay sa isang tanggapan ang programang ito.';

  @override
  String get tulongShareSignature => 'Mula sa Taytay LGU';

  @override
  String get tulongCopied =>
      'Nakopya na. Puwede mo itong i-paste sa kahit anong app.';

  @override
  String get tulongNoSharing => 'Hindi puwedeng magbahagi sa device na ito.';

  @override
  String get tulongNotAvailableTitle => 'Hindi available ang programang ito';

  @override
  String get tulongNotAvailableBody =>
      'Bumalik sa Tulong para makita ang mga programang nakalista ngayon.';

  @override
  String get tulongCheckConnection =>
      'Pakisuri ang iyong koneksyon at subukang muli.';

  @override
  String get tulongLoadingOne => 'Kinukuha ang programa';

  @override
  String get homeGuestTitle => 'Tumitingin bilang bisita';

  @override
  String get homeGuestBody =>
      'Mag-sign up para makapagmensahe sa mga tanggapan.';

  @override
  String get homeNotVerifiedTitle => 'Hindi pa verified';

  @override
  String get homeNotSentBody =>
      'Wala pang naipapadalang ID. Magpadala sa app, o magpa-verify nang personal sa MSWDO. Mabubuksan ang pagmemensahe sa mga tanggapan kapag verified ka na.';

  @override
  String get homePendingTitle => 'Hinihintay ang verification';

  @override
  String get homePendingBody =>
      'Sinusuri ng Taytay LGU ang iyong ID. Mabubuksan ang pagmemensahe sa mga tanggapan kapag verified ka na.';

  @override
  String get homeRejectedTitle => 'Hindi tinanggap ang iyong ID';

  @override
  String get homeRejectedBody =>
      'Tingnan kung ano ang aayusin at ipadala itong muli, o magpa-verify nang personal sa MSWDO. Mabubuksan ang pagmemensahe sa mga tanggapan kapag verified ka na.';

  @override
  String get homeUnlocksOnceVerified =>
      'Mabubuksan ang pagmemensahe sa mga tanggapan kapag verified ka na.';

  @override
  String get homeFixAction => 'Tingnan ang aayusin';

  @override
  String get homeStatusAction => 'Katayuan ng verification';

  @override
  String get homeCreateAccount => 'Gumawa ng account';

  @override
  String get homeLoadingStories => 'Kinukuha ang mga itinatampok';

  @override
  String get homeLatestBalita => 'Pinakabagong Balita';

  @override
  String get homeSeeAll => 'Tingnan lahat';

  @override
  String get homeLoadingBalita => 'Kinukuha ang Balita';

  @override
  String get homeEmergency => 'Emergency';

  @override
  String get homeAllHotlines => 'Lahat ng hotline';

  @override
  String homeNotificationsUnread(int count) {
    return 'Mga notification, $count ang hindi pa nababasa';
  }

  @override
  String get homeUpdating => 'Ina-update ang Balita at mga abiso…';

  @override
  String get homeHotlines => 'Mga hotline';

  @override
  String get homeEvents => 'Mga Kaganapan';

  @override
  String get homeReadBalita => 'Basahin ang Balita';

  @override
  String get homeExploreTulong => 'Tingnan ang Tulong';

  @override
  String get homeOpenDirectory => 'Buksan ang Direktoryo';

  @override
  String get homeSeeHotlines => 'Tingnan ang mga hotline';

  @override
  String get homeSeeEvents => 'Tingnan ang mga event';

  @override
  String get homeOpen => 'Buksan';

  @override
  String get homeHotlinesTitle => 'Mga emergency hotline';

  @override
  String get homeLoadingHotlines => 'Kinukuha ang mga hotline';

  @override
  String get homeNoHotlinesTitle => 'Walang hotline na maipapakita';

  @override
  String get homeNoHotlinesBody =>
      'Wala pang inilalathalang hotline dito ang Taytay LGU.';

  @override
  String get homeHotlinesMunicipal => 'Munisipyo';

  @override
  String get homeHotlinesSource =>
      'Pinagmulan: Taytay LGU / Taytay Public Information Office.';

  @override
  String get coreFailureTimeout =>
      'Mas natatagalan ito kaysa sa inaasahan. Pakisubukang muli.';

  @override
  String get coreFailureUnauthenticated =>
      'Natapos na ang iyong session. Mag-sign in muli para magpatuloy.';

  @override
  String get coreFailureForbidden =>
      'Hindi available ang serbisyong ito para sa iyong account sa ngayon.';

  @override
  String get coreFailureVerificationRequired =>
      'I-verify muna ang iyong account para magamit ang serbisyong ito.';

  @override
  String get coreFailureBiometricConsent =>
      'Walang naipadala. Kailangan ng selfie ang iyong pahintulot sa tekstong tungkol sa selfie na inilalathala ngayon ng Taytay LGU. Sumang-ayon dito, o magpa-beripika nang personal.';

  @override
  String get coreFailureValidation =>
      'Pakisuri ang mga naka-highlight na detalye at subukang muli.';

  @override
  String get coreFailureConflict =>
      'Naipadala na ito. I-refresh para makita ang pinakabagong katayuan.';

  @override
  String get coreFailureInvalidStateTransition =>
      'Umusad na ang hiling na ito. I-refresh para makita ang kasalukuyang katayuan nito.';

  @override
  String get coreFailureBarangayHeldByOffice =>
      'Beripikado ang iyong account, kaya sa tanggapan ng MSWDO pinapalitan ang iyong barangay. Para palitan ang iyong barangay, pumunta sa tanggapan ng MSWDO dala ang patunay ng iyong bagong address.';

  @override
  String coreFailureRateLimitedFor(int seconds) {
    return 'Masyadong maraming subok. Subukang muli pagkalipas ng $seconds segundo.';
  }

  @override
  String get coreFailureServiceUnavailable =>
      'Pansamantalang hindi available ang serbisyo. Pakisubukang muli mamaya.';

  @override
  String get coreFailureServer =>
      'May nagkaproblema sa aming panig. Pakisubukang muli.';

  @override
  String get coreFailureContract =>
      'Hindi namin mabasa ang sagot mula sa server. Pakisubukang muli.';

  @override
  String get coreFailureUnexpected =>
      'May nangyaring mali. Pakisubukang muli, o makipag-ugnayan sa LGU kung paulit-ulit itong mangyari.';

  @override
  String get coreFailureFileTooLarge =>
      'Masyadong malaki ang file na iyon para ipadala. Subukan ang mas maliit na litrato o mas mababang setting ng kalidad.';

  @override
  String get coreFailureCodeInvalid => 'Hindi tinanggap ang code na iyon.';

  @override
  String get coreFailureCodeExpired =>
      'Nag-expire na ang code na iyon. Humingi ng bago.';

  @override
  String get coreFailureCodeLocked =>
      'Masyadong maraming subok. Maghintay muna bago humingi ng panibagong code.';

  @override
  String get coreSignInCredentialsRejected =>
      'Mali ang email o password. 2 subok na lang ang natitira bago ka pahintayin nang 15 minuto.';

  @override
  String get coreSignInPasswordNeedsEmail =>
      'Gamitin ang iyong email para mag-sign in gamit ang password, o humingi ng code na ipapadala sa iyong cellphone.';

  @override
  String get coreDeepLinkUnavailable =>
      'Hindi mabuksan ang link na iyon. Maaaring para ito sa mas bagong bersyon ng app, o maaaring wala na ang item na iyon.';

  @override
  String get coreDeepLinkActionRefused =>
      'Sinubukan ng link na iyon na gumawa ng isang bagay para sa iyo. Hindi kailanman kumikilos ang Taytay LGU IDS mula sa isang link — buksan ang item at ikaw mismo ang pumili.';

  @override
  String get coreRouteNotFoundTitle => 'Hindi makita ang pahina';

  @override
  String get coreRouteNotFoundBody =>
      'Walang pinatutunguhan ang link na iyon sa app na ito.';

  @override
  String get coreRouteGoHome => 'Pumunta sa Home';

  @override
  String get coreAppLockEnableReason =>
      'Kumpirmahin na ikaw ito bago i-on ang app lock';

  @override
  String get coreAppLockUnlockReason => 'Buksan ang Taytay LGU IDS';

  @override
  String get coreSealSemanticLabel => 'Selyo ng Bayan ng Taytay, Rizal';

  @override
  String get corePhotoMunicipalHall => 'Litrato: Munisipyo ng Taytay';

  @override
  String get corePhotoTiangge => 'Litrato: Tiangge ng Taytay';

  @override
  String get corePhotoParishChurch =>
      'Litrato: Simbahan ng Parokya ni San Juan Bautista';

  @override
  String get sharedBiometricDialogTitle =>
      'Ang iyong pahintulot bago ang selfie';

  @override
  String get sharedBiometricWhatHeading => 'Ano ang kinukuha ng app, at bakit';

  @override
  String get sharedBiometricWhat =>
      'Isang selfie: litrato ng iyong mukha. Ikinukumpara ito ng staff ng Taytay LGU sa litrato sa iyong ID para kumpirmahin na sa iyo ang account na ito, at ito ang litrato sa iyong Taytay digital ID kapag na-verify ka na. Ang litrato ng mukha na ginagamit para kumpirmahin kung sino ang isang tao ay itinuturing na biometric data, kaya hinihingi ng app ang iyong pahintulot bago bumukas ang camera.';

  @override
  String get sharedBiometricTextHeading =>
      'Ang pahintulot na inilathala ng Taytay LGU';

  @override
  String sharedBiometricVersion(String version) {
    return 'Bersyon $version';
  }

  @override
  String get sharedBiometricChoice =>
      'Ikaw ang magpapasya kung papayag ka. Kung hindi ka papayag, maaari ka pa ring ma-verify nang personal, nang walang selfie. Maaari mong bawiin ang pahintulot na ito anumang oras sa Account, Mga pahintulot at hiling tungkol sa account; kapag binawi mo ito, mabubura ang iyong mga selfie.';

  @override
  String get sharedBiometricTick =>
      'Pumapayag ako na kunin at gamitin ng Taytay LGU ang aking selfie ayon sa inilarawan sa itaas.';

  @override
  String get sharedBiometricAgree => 'Pumayag at magpatuloy';

  @override
  String get sharedBiometricRecording => 'Itinatala ang iyong pahintulot…';

  @override
  String get sharedBiometricDecline =>
      'Hindi, magpapa-verify ako nang personal';

  @override
  String get sharedBiometricUnavailableHeading =>
      'Hindi pa available ang selfie verification';

  @override
  String get sharedBiometricUnavailable =>
      'Hindi pa inilalathala ng Taytay LGU ang pahintulot na kailangan ng app bago ito makakuha ng selfie, kaya walang selfie na maipapadala sa ngayon. Gumagana ang iyong account kahit wala nito.';

  @override
  String get sharedBiometricInPersonHeading => 'Magpa-verify nang personal';

  @override
  String get sharedBiometricInPerson =>
      'Magdala ng valid ID sa MSWDO. Susuriin ito ng staff at ive-verify ang iyong account. Walang kukuning selfie.';

  @override
  String sharedBiometricInPersonHours(String hours) {
    return 'Oras: $hours';
  }

  @override
  String sharedBiometricInPersonPhone(String phone) {
    return 'Telepono: $phone';
  }

  @override
  String get sharedBiometricDeclinedHeading => 'Walang kinuhang selfie';

  @override
  String get sharedBiometricDeclined =>
      'Hindi ka pumayag sa pahintulot para sa selfie, at ayos lang iyon. Walang naitala o naipadala.';

  @override
  String get sharedBiometricFailedHeading =>
      'Hindi masuri ang pahintulot para sa selfie';

  @override
  String get sharedBiometricFailed =>
      'Walang selfie na makukuha hangga\'t hindi alam ng app ang katayuan ng iyong pahintulot. Pakisuri ang iyong koneksyon at subukang muli.';

  @override
  String get sharedBiometricNotRecorded =>
      'Hindi naitala ang iyong pahintulot, kaya walang kinuhang selfie. Maaari mong subukang muli.';

  @override
  String get sharedBiometricNotConfirmed =>
      'Hindi namin makumpirma kung naitala ang iyong pahintulot, kaya wala pang kinuhang selfie. Ligtas na subukang muli: isang beses lang ito itatala.';

  @override
  String get sharedBiometricWithdrawEffects =>
      'Kapag binawi mo ito, mabubura sa mismong sandaling iyon ang bawat selfie na ipinadala mo. Ang hiling na ma-verify na naghihintay pa ng pagsusuri ay mangangailangan ng bagong selfie bago ito maaprubahan ng staff, at mawawalan ng litrato ang Taytay digital ID. Mananatili ang mga nagawa na: hindi umaatras ang bisa ng pagbawi.';

  @override
  String get sharedBiometricWithdrawButton =>
      'Bawiin ang pahintulot para sa selfie';

  @override
  String get sharedBiometricWithdrawTitle =>
      'Bawiin ang pahintulot para sa selfie?';

  @override
  String get sharedBiometricWithdrawConfirm =>
      'Bawiin at burahin ang aking mga selfie';

  @override
  String get sharedBiometricWithdrawCancel =>
      'Panatilihin ang aking pahintulot';

  @override
  String get sharedTermsNotPublishedYet =>
      'Malapit nang makita ang buong Terms of Use. Hindi pa ito inilalathala ng Taytay LGU sa app.';

  @override
  String get sharedPrivacyNoticeNotPublishedYet =>
      'Malapit nang makita ang buong Privacy Notice. Hindi pa ito inilalathala ng Taytay LGU sa app.';

  @override
  String get sharedTermsConsentLabel =>
      'Nabasa ko at sumasang-ayon ako sa Terms of Use.';

  @override
  String get sharedPrivacyConsentLabel =>
      'Nabasa ko ang Privacy Notice at nauunawaan ko kung paano ginagamit ng Taytay LGU ang aking personal na datos.';

  @override
  String sharedLegalTextLoading(String title) {
    return 'Naglo-load ang $title';
  }

  @override
  String get sharedBarangayPickerTitle => 'Piliin ang iyong barangay';

  @override
  String get sharedBarangayPickerLoading => 'Naglo-load ang mga barangay';

  @override
  String get sharedBarangayPickerEmpty =>
      'Wala pang nakalistang barangay. Pakisubukang muli mamaya.';

  @override
  String get sharedBarangayPickerFailed =>
      'Hindi namin ma-load ang listahan ng mga barangay. Pakisuri ang iyong koneksyon at subukang muli.';

  @override
  String get sharedHoursOpen => 'Bukas';

  @override
  String get sharedHoursClosed => 'Sarado';

  @override
  String sharedHoursCloses(String time) {
    return 'Magsasara nang $time';
  }

  @override
  String sharedHoursOpensToday(String time) {
    return 'Magbubukas nang $time ngayong araw';
  }

  @override
  String sharedHoursOpensTomorrow(String time) {
    return 'Magbubukas nang $time bukas';
  }

  @override
  String sharedHoursOpensOn(String time, String weekday) {
    return 'Magbubukas nang $time sa $weekday';
  }

  @override
  String get sharedWeekdayMonday => 'Lunes';

  @override
  String get sharedWeekdayTuesday => 'Martes';

  @override
  String get sharedWeekdayWednesday => 'Miyerkoles';

  @override
  String get sharedWeekdayThursday => 'Huwebes';

  @override
  String get sharedWeekdayFriday => 'Biyernes';

  @override
  String get sharedWeekdaySaturday => 'Sabado';

  @override
  String get sharedWeekdaySunday => 'Linggo';

  @override
  String sharedFormErrorSummaryHeading(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'May $count na problema',
      one: 'May isang problema',
    );
    return '$_temp0';
  }

  @override
  String get sharedWhyWeAskTitle => 'Bakit namin ito hinihingi';

  @override
  String get sharedWhyWeAskWhy => 'Bakit';

  @override
  String get sharedWhyWeAskWhoSeesIt => 'Sino ang nakakakita nito';

  @override
  String get sharedWhyWeAskIfYouDecline => 'Kung mas gusto mong huwag ibigay';

  @override
  String get sharedNoteToneInfo => 'Impormasyon';

  @override
  String get sharedNoteToneWarning => 'Paalala';

  @override
  String get sharedNoteToneError => 'Mali';

  @override
  String get sharedNoteToneSuccess => 'Tapos na';

  @override
  String get sharedNoteToneEmergency => 'Emergency';

  @override
  String get sharedComposerHint => 'Sumulat ng mensahe…';

  @override
  String get sharedComposerRemoveAttachment => 'Alisin ang attachment';

  @override
  String get sharedComposerAttach => 'Maglakip ng litrato o PDF';

  @override
  String get sharedComposerSend => 'Ipadala';

  @override
  String get sharedDialogConfirm => 'Kumpirmahin';

  @override
  String get sharedConfirmKeepAsItIs => 'Panatilihin ito gaya ng dati';

  @override
  String get sharedConfirmWhatHappens => 'Ano ang mangyayari';

  @override
  String get sharedBannerDismiss => 'Isara';

  @override
  String get sharedMessageFieldLabel => 'Mensahe';

  @override
  String sharedBadgeNew(int count) {
    return '$count bago';
  }

  @override
  String get sharedOfflineMessage =>
      'Hindi maabot ang Taytay LGU. Pakisuri ang iyong koneksyon at subukang muli.';

  @override
  String get sharedSampleTag => 'HALIMBAWA';

  @override
  String get sharedIllustrationLabelPrefix => 'Ilustrasyon:';

  @override
  String get sharedIllustrationEmpty =>
      'Ilustrasyon: isang walang lamang tray, ibig sabihin ay wala pang laman dito.';

  @override
  String get sharedIllustrationError =>
      'Ilustrasyon: isang putol na kawing, ibig sabihin ay may hindi ma-load.';

  @override
  String get sharedIllustrationSuccess =>
      'Ilustrasyon: isang tsek, ibig sabihin ay natapos ang hiling.';

  @override
  String get sharedConfigStopTitle =>
      'Hindi tama ang pagkaka-configure ng build na ito at hindi ito makapagsisimula.';

  @override
  String get sharedConfigStopIconLabel => 'Configuration';
}
