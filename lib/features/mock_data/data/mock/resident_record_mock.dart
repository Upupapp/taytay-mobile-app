import '../../../../core/mock/mock_behavior.dart';
import '../../../../core/result/result.dart';
import '../../../verification/domain/field_correction_note.dart';
import '../../../verification/domain/resident_record.dart';
import '../../../verification/domain/resident_record_repository.dart';

/// Dev-only stand-in for the resident profile wizard.
///
/// Holds the sample record in this object, which is the mock server, not the
/// session. Years at the address, residence type and civil status have no
/// field on Clarence's write schemas, so only this mock remembers them.
class MockResidentRecordRepository implements ResidentRecordRepository {
  MockResidentRecordRepository(this._gate);

  final MockBehaviorController _gate;

  ResidentRecord _record = sampleRecord;

  static const ResidentRecord sampleRecord = ResidentRecord(
    givenName: 'Juana',
    middleName: 'Santos',
    familyName: 'Dela Cruz',
    sex: 'Female',
    birthdate: '1992-03-14',
    civilStatus: 'Single',
    mobile: '0917 123 4567',
    email: 'juana.delacruz@example.com',
    mobileVerified: true,
    barangayId: 'barangay-san-juan',
    barangayName: 'San Juan',
    street: '12 Sampaguita St.',
    purok: '3',
    yearsAtAddress: '6',
    memberCount: '4',
    residenceType: 'Owned',
    verificationTier: 'pending',
    rejectionReason:
        'The ID photo is blurred and the name can\'t be read. '
        'Please upload a clearer photo of the front of your ID.',
    fieldNotes: <FieldCorrectionNote>[
      FieldCorrectionNote(
        label: 'ID photo',
        note: 'The photo is blurry. Retake the front of your ID in good light.',
      ),
      FieldCorrectionNote(
        label: 'Address',
        note: 'Barangay doesn\'t match the ID. Choose the barangay printed on it.',
      ),
    ],
    completeness: 60,
    personalComplete: true,
    householdStarted: true,
  );

  @override
  Future<Result<ResidentRecord>> load() => _gate.respond(_record);

  @override
  Future<Result<ResidentRecord>> savePersonal(PersonalDraft draft) {
    _record = ResidentRecord(
      givenName: draft.givenName,
      middleName: draft.middleName,
      familyName: draft.familyName,
      suffix: draft.suffix,
      sex: draft.sex,
      birthdate: draft.birthdate,
      civilStatus: draft.civilStatus,
      mobile: draft.mobile,
      email: draft.email,
      mobileVerified: _record.mobileVerified,
      barangayId: _record.barangayId,
      barangayName: _record.barangayName,
      street: _record.street,
      purok: _record.purok,
      yearsAtAddress: _record.yearsAtAddress,
      memberCount: _record.memberCount,
      residenceType: _record.residenceType,
      verificationTier: _record.verificationTier,
      rejectionReason: _record.rejectionReason,
      fieldNotes: _record.fieldNotes,
      completeness: _record.completeness,
      personalComplete: draft.givenName.isNotEmpty && draft.familyName.isNotEmpty,
      householdStarted: _record.householdStarted,
    );
    return _gate.respond(_record);
  }

  @override
  Future<Result<ResidentRecord>> saveHousehold(HouseholdDraft draft) {
    _record = ResidentRecord(
      givenName: _record.givenName,
      middleName: _record.middleName,
      familyName: _record.familyName,
      suffix: _record.suffix,
      sex: _record.sex,
      birthdate: _record.birthdate,
      civilStatus: _record.civilStatus,
      mobile: _record.mobile,
      email: _record.email,
      mobileVerified: _record.mobileVerified,
      barangayId: draft.barangayId,
      barangayName: draft.barangayName,
      street: draft.street,
      purok: draft.purok,
      yearsAtAddress: draft.yearsAtAddress,
      memberCount: draft.memberCount,
      residenceType: draft.residenceType,
      verificationTier: _record.verificationTier,
      rejectionReason: _record.rejectionReason,
      fieldNotes: _record.fieldNotes,
      completeness: _record.completeness,
      personalComplete: _record.personalComplete,
      householdStarted: draft.street.isNotEmpty || draft.barangayName.isNotEmpty,
    );
    return _gate.respond(_record);
  }

  @override
  Future<Result<ResidentRecord>> submit({
    required PersonalDraft personal,
    required HouseholdDraft household,
  }) async {
    await savePersonal(personal);
    await saveHousehold(household);
    _record = ResidentRecord(
      givenName: _record.givenName,
      middleName: _record.middleName,
      familyName: _record.familyName,
      suffix: _record.suffix,
      sex: _record.sex,
      birthdate: _record.birthdate,
      civilStatus: _record.civilStatus,
      mobile: _record.mobile,
      email: _record.email,
      mobileVerified: _record.mobileVerified,
      barangayId: _record.barangayId,
      barangayName: _record.barangayName,
      street: _record.street,
      purok: _record.purok,
      yearsAtAddress: _record.yearsAtAddress,
      memberCount: _record.memberCount,
      residenceType: _record.residenceType,
      verificationTier: 'pending',
      rejectionReason: _record.rejectionReason,
      fieldNotes: _record.fieldNotes,
      completeness: 100,
      personalComplete: true,
      householdStarted: true,
    );
    return _gate.respond(_record);
  }
}
