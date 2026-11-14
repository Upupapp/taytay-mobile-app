import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/widgets.dart';

import 'live_updates.dart';

/// Lets a screen re-read itself quietly when its data changes (D-218).
///
/// A screen calls [listenLive] once, where it first reads its dependencies,
/// with the topics its endpoints read and the quiet re-read to run. The
/// subscription ends with the screen.
///
/// **Only a screen the resident can see re-reads.** A tab kept alive behind
/// another, or a page under a pushed route, is ticker-disabled; a change that
/// arrives then is remembered, and the re-read runs when the screen is shown
/// again. A hidden screen does not spend the resident's data.
mixin LiveRefresh<T extends StatefulWidget> on State<T> {
  final List<_LiveRead> _liveReads = <_LiveRead>[];
  ValueListenable<TickerModeData>? _shown;

  bool get _isShown => _shown?.value.enabled ?? true;

  /// Runs [reread] when one of [topics] changes, when the change stream
  /// reconnects after a gap, and when the app returns to the foreground.
  ///
  /// [reread] must be quiet: keep what is on screen, show no loading state,
  /// and on failure keep the old data without a message. A null [live] (a
  /// test with no dependencies in scope) registers nothing.
  void listenLive(LiveUpdates? live, Set<String> topics, VoidCallback reread) {
    if (live == null) return;
    final _LiveRead read = _LiveRead(reread);
    read.subscription = live.listen(topics, () {
      if (!mounted) return;
      if (_isShown) {
        read.reread();
      } else {
        read.owed = true;
      }
    });
    _liveReads.add(read);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _watchShown();
  }

  @override
  void activate() {
    super.activate();
    _watchShown();
  }

  void _watchShown() {
    final ValueListenable<TickerModeData> shown = TickerMode.getValuesNotifier(
      context,
    );
    if (identical(shown, _shown)) return;
    _shown?.removeListener(_onShownChanged);
    _shown = shown..addListener(_onShownChanged);
  }

  void _onShownChanged() {
    if (!mounted || !_isShown) return;
    for (final _LiveRead read in List<_LiveRead>.of(_liveReads)) {
      if (!read.owed) continue;
      read.owed = false;
      // The ticker mode changes while the tree above is building. The
      // re-read starts after that frame, never inside it.
      scheduleMicrotask(() {
        if (mounted) read.reread();
      });
    }
  }

  @override
  void dispose() {
    _shown?.removeListener(_onShownChanged);
    _shown = null;
    for (final _LiveRead read in _liveReads) {
      read.subscription?.cancel();
    }
    _liveReads.clear();
    super.dispose();
  }
}

class _LiveRead {
  _LiveRead(this.reread);

  final VoidCallback reread;
  LiveSubscription? subscription;
  bool owed = false;
}
