/// The words of the "Your card is being prepared" page (`IDStatus.dc.html`,
/// D-207).
///
/// Each sentence says only what the API and the backend's own behaviour make
/// true. The mock-up's "We'll notify you when it's ready", "valid for one
/// year" and "Each code works for 2 minutes" are not here: issuing a card sends
/// the resident no notice, and the card's term and the code's lifetime are
/// the server's to state on the card once it exists (`expires_at`,
/// `qr.expires_at`), not the app's to promise before it does.
abstract final class CardPreparingCopy {
  static const String title = 'Your card is being prepared';
  static const String body =
      "You're verified. The MSWDO issues your card next, and it appears here "
      'with a QR code.';

  static const String stepsTitle = 'Where your card is';
  static const String accountCreated = 'Account created';
  static const String idSent = 'ID and selfie sent';
  static const String verified = 'Verified by Taytay LGU';
  static const String issued = 'Card issued by the MSWDO';

  /// The backend uses the approved verification selfie unless staff choose
  /// another photo the resident sent, hence "usually".
  static const String issuedDetail =
      'Check this page again later. The card photo is usually your '
      'verification selfie.';
  static const String show = 'Show your card';
  static const String showDetail =
      'Staff scan its QR code. Each code works for a short time, and the app '
      'gets a new one.';

  static const String aboutTitle = 'About your card';
  static const String aboutWhat =
      "It is Taytay's own resident card, not a national government ID. The "
      'card shows the date it expires.';
  static const String aboutStops =
      'If it is suspended or expires, the app stops showing its QR code. '
      'Message the MSWDO to find out what to do.';
  static const String message = 'Message the MSWDO';

  /// A step's supporting line from what was sent: the parts joined with a
  /// middle dot, or empty when nothing was.
  static String detail(Iterable<String?> parts) => parts
      .whereType<String>()
      .where((String part) => part.isNotEmpty)
      .join(' · ');
}
