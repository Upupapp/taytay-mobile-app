import '../../../core/api/send_key.dart';

/// The idempotency key for a submit, a resubmit or a cancel.
///
/// [SendKey], which office messages share. The owner calls `reset` on every
/// edit, because the server compares the fields and files with what the key
/// first carried (backend `0d1cb14`).
typedef IssuanceSendKey = SendKey;
