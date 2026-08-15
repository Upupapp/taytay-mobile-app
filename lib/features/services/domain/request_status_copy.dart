import 'service_request_repository.dart';

/// Resident-facing wording for a request's lifecycle state.
///
/// ---
///
/// **One switch, in one file, for the whole app.** Home and the request list
/// each had their own copy of this, and two exhaustive switches over the same
/// enum will eventually disagree — one gets a new case worded carefully and the
/// other gets whatever the person adding it typed. A resident then reads two
/// different sentences about the same application depending on which screen
/// they are looking at.
///
/// **It lives in `domain/` rather than beside a screen** because more than one
/// feature needs it, and a feature may not import another feature's
/// `presentation/` (Article 2 rule 2). That is the same placement `AppFailure`
/// and `DocumentRejection` already use for their resident copy: the words that
/// explain a state belong with the state.
///
/// **The label never replaces the canonical value.** `ServiceRequest.rawState`
/// is preserved separately and is what a support conversation quotes; this is a
/// rendering of it, which is TAB 17's first acceptance criterion.
///
/// Three wording decisions worth stating:
///
/// * `assigned` reads as "with a Taytay LGU officer" and **never names one**.
///   The Master Command says not to expose staff identity, and a name here would
///   invite a resident to seek out an individual over a case queue.
/// * `waitingRequirements` is phrased as an obligation on the resident, because
///   it is the one state where nothing moves until they act.
/// * An unrecognised state reads as "being processed" — true of every state this
///   build might not know about, and alarming to nobody. A released app meets
///   values added after it shipped, and the safe reading is the neutral one.
String requestStatusLabel(ServiceRequestState? state) => switch (state) {
  ServiceRequestState.draft => 'Not sent yet',
  ServiceRequestState.submitted => 'Sent to Taytay LGU',
  ServiceRequestState.pendingReview => 'Waiting to be reviewed',
  ServiceRequestState.underVerification => 'Being checked',
  ServiceRequestState.assigned => 'With a Taytay LGU officer',
  ServiceRequestState.processing => 'Being processed',
  ServiceRequestState.waitingRequirements => 'Waiting for your documents',
  ServiceRequestState.approved => 'Approved',
  ServiceRequestState.rejected => 'Not approved',
  ServiceRequestState.readyForRelease => 'Ready for you to collect',
  ServiceRequestState.released => 'Released to you',
  ServiceRequestState.completed => 'Completed',
  ServiceRequestState.cancelled => 'Cancelled',
  null => 'Being processed',
};

/// A short sentence saying who the application is waiting on.
///
/// Separate from the label because "where is it?" and "is it my turn?" are
/// different questions, and the second is the one a resident actually opens the
/// app to answer. Answering it plainly is what stops someone queueing at the
/// municipal hall to ask something the app has already told them.
String requestStatusMeaning(ServiceRequestState? state) => switch (state) {
  ServiceRequestState.draft =>
    'You have not sent this yet. Nothing reaches Taytay LGU until you do.',
  ServiceRequestState.waitingRequirements =>
    'Taytay LGU is waiting for you. Send the documents it asked for and this '
        'moves on.',
  ServiceRequestState.readyForRelease =>
    'Taytay LGU is ready for you to collect this. Bring a valid ID.',
  ServiceRequestState.rejected =>
    'Taytay LGU did not approve this application.',
  ServiceRequestState.cancelled => 'This application was cancelled.',
  ServiceRequestState.completed || ServiceRequestState.released =>
    'This application is finished. Nothing further is needed from you.',
  _ => 'Taytay LGU has this. Nothing is needed from you right now.',
};
