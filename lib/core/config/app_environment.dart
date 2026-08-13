/// Which deployment of the Taytay LGU IDS backend this build talks to.
///
/// The environment is a **compile-time** constant supplied with
/// `--dart-define=TAYTAY_ENV=...`. It is deliberately not a runtime setting:
/// a build that can be re-pointed at another environment after shipping is a
/// build whose API target is not auditable, and an in-app environment switcher
/// is a well-known way for a test/staging dataset to leak into a public release.
enum AppEnvironment {
  dev('dev', 'DEV'),
  staging('staging', 'STAGING'),
  prod('prod', '');

  const AppEnvironment(this.wireValue, this.badgeLabel);

  /// Value expected in `--dart-define=TAYTAY_ENV=<wireValue>`.
  final String wireValue;

  /// Short label shown in the non-production build badge. Empty for production.
  final String badgeLabel;

  bool get isProduction => this == AppEnvironment.prod;

  /// Non-production builds may show diagnostics (request ids, env badge) that
  /// must never appear on a resident's production device.
  bool get allowsDiagnosticsUi => !isProduction;

  static AppEnvironment? tryParse(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final environment in AppEnvironment.values) {
      if (environment.wireValue == value) return environment;
    }
    return null;
  }
}
