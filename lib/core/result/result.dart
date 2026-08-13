import 'package:flutter/foundation.dart';

import 'app_failure.dart';

export 'api_error_code.dart';
export 'app_failure.dart';

/// The single return type for every operation that can fail.
///
/// Constitution Article 6: fallible work returns a [Result] instead of throwing.
/// Exceptions cross layers invisibly; a `Result` cannot be ignored because the
/// value is only reachable through a switch that the analyzer checks for
/// exhaustiveness.
///
/// ```dart
/// final result = await repository.loadProfile();
/// switch (result) {
///   case Ok(:final value):
///     showProfile(value);
///   case Err(:final failure):
///     showFailure(failure);
/// }
/// ```
@immutable
sealed class Result<T> {
  const Result();

  /// Wraps a synchronous body, converting an unexpected throw into
  /// [UnexpectedFailure]. Use only at a boundary that must not propagate raw
  /// exceptions (transport adapters, decoders) — never to hide a real bug.
  factory Result.guard(T Function() body, {String? context}) {
    try {
      return Ok<T>(body());
    } on Object catch (error, stackTrace) {
      return Err<T>(
        UnexpectedFailure(
          debugContext: context,
          error: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  bool get isOk => this is Ok<T>;

  bool get isErr => this is Err<T>;

  /// The success value, or `null` when this is an [Err].
  T? get valueOrNull => switch (this) {
    Ok<T>(:final value) => value,
    Err<T>() => null,
  };

  /// The failure, or `null` when this is an [Ok].
  AppFailure? get failureOrNull => switch (this) {
    Ok<T>() => null,
    Err<T>(:final failure) => failure,
  };

  /// Transforms the success value, leaving a failure untouched.
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
    Ok<T>(:final value) => Ok<R>(transform(value)),
    Err<T>(:final failure) => Err<R>(failure),
  };

  /// Chains another fallible step onto a success.
  Result<R> flatMap<R>(Result<R> Function(T value) transform) => switch (this) {
    Ok<T>(:final value) => transform(value),
    Err<T>(:final failure) => Err<R>(failure),
  };

  /// Collapses both branches into a single value.
  R fold<R>({
    required R Function(T value) onOk,
    required R Function(AppFailure failure) onErr,
  }) => switch (this) {
    Ok<T>(:final value) => onOk(value),
    Err<T>(:final failure) => onErr(failure),
  };
}

/// A successful outcome carrying [value].
final class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Ok<T> && other.value == value);

  @override
  int get hashCode => Object.hash(Ok<T>, value);

  @override
  String toString() => 'Ok<$T>($value)';
}

/// A failed outcome carrying an [AppFailure].
final class Err<T> extends Result<T> {
  const Err(this.failure);

  final AppFailure failure;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Err<T> && other.failure == failure);

  @override
  int get hashCode => Object.hash(Err<T>, failure);

  @override
  String toString() => 'Err<$T>($failure)';
}

/// Async ergonomics for `Future<Result<T>>`, so callers do not have to await
/// before mapping.
extension FutureResultX<T> on Future<Result<T>> {
  Future<Result<R>> mapAsync<R>(R Function(T value) transform) async =>
      (await this).map(transform);

  Future<R> foldAsync<R>({
    required R Function(T value) onOk,
    required R Function(AppFailure failure) onErr,
  }) async => (await this).fold(onOk: onOk, onErr: onErr);
}
