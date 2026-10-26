import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/sign_in_field.dart';
import '../../core/motion/motion_tokens.dart';
import '../../core/router/app_routes.dart';
import 'taytay_thread.dart';
import 'welcome_backdrop.dart';

/// The gold thread and the field it is stitched into.
///
/// Welcome, sign-in, and sign-up share this layer. It sits under the page
/// content and above nothing that should cover the stitch, and the 7s clock
/// is created once. A route change morphs the cubic. It does not build a
/// new clock, so the glowing tip does not jump back to the start.
class GoldThreadModel extends ChangeNotifier {
  GoldThreadModel(TickerProvider vsync)
    : clock = AnimationController(
        vsync: vsync,
        duration: MotionTokens.welcomeLight,
      ),
      morph = AnimationController(
        vsync: vsync,
        duration: MotionTokens.standard,
        value: 1,
      );

  /// Raw 0–1 position of the 7s loop, before the speck curve.
  final AnimationController clock;

  /// 0 at the previous cubic, 1 at the cubic for the current route.
  final AnimationController morph;

  String path = '';
  bool welcome = true;
  double welcomePage = 0;
  SignInAtmosphere atmosphere = SignInAtmosphere.signIn;
  double sheetTop = 844;

  ThreadCurve _from = ThreadCurve.pages.first;
  ThreadCurve _to = ThreadCurve.pages.first;

  /// 0–1 position of the loop. Tests read this to prove a route change
  /// did not start the loop again.
  double get cycle => clock.value;

  ThreadCurve get curve {
    final double t = MotionTokens.standardEase.transform(morph.value);
    return _from.lerp(_to, t);
  }

  void applyPath(String next) {
    if (next == path) return;
    final bool first = path.isEmpty;
    path = next;
    final _Scene scene = _sceneFor(next);
    welcome = scene.welcome;
    atmosphere = scene.atmosphere;
    sheetTop = scene.sheetTop;
    if (scene.welcome) welcomePage = 0;
    _retarget(scene.curve, animate: !first && !scene.welcome);
  }

  /// Welcome reports the live page. The cubic follows the finger immediately.
  void setWelcomePage(double page) {
    if (!welcome || path != AppRoute.onboarding.path) return;
    if ((welcomePage - page).abs() < 0.0001) return;
    welcomePage = page;
    _retarget(ThreadCurve.welcomeAt(page), animate: false);
  }

  /// A screen reports the cubic and field the design draws for this step.
  ///
  /// Ignored when [path] is not the route currently showing, so the page
  /// that is leaving cannot pull the stitch back.
  void report({
    required String? path,
    required ThreadCurve curve,
    required SignInAtmosphere atmosphere,
    required double sheetTop,
  }) {
    if (path == null || path != this.path || welcome) return;
    final bool same =
        curve == _to &&
        atmosphere.fadeHold == this.atmosphere.fadeHold &&
        atmosphere.angle == this.atmosphere.angle &&
        sheetTop == this.sheetTop &&
        morph.value == 1;
    if (same) return;
    this.atmosphere = atmosphere;
    this.sheetTop = sheetTop;
    _retarget(curve, animate: curve != _to);
  }

  void _retarget(ThreadCurve next, {required bool animate}) {
    if (next == _to && morph.value == 1) {
      notifyListeners();
      return;
    }
    _from = curve;
    _to = next;
    if (!animate) {
      morph.value = 1;
    } else {
      morph.forward(from: 0);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    clock.dispose();
    morph.dispose();
    super.dispose();
  }
}

class _Scene {
  const _Scene({
    required this.curve,
    required this.atmosphere,
    required this.sheetTop,
    required this.welcome,
  });

  final ThreadCurve curve;
  final SignInAtmosphere atmosphere;
  final double sheetTop;
  final bool welcome;
}

_Scene _sceneFor(String path) {
  if (path == AppRoute.onboarding.path) {
    return const _Scene(
      curve: ThreadCurve(200, 300),
      atmosphere: SignInAtmosphere.signIn,
      sheetTop: 844,
      welcome: true,
    );
  }
  if (path == AppRoute.passwordUpdated.path) {
    return const _Scene(
      curve: ThreadCurve.submitted,
      atmosphere: SignInAtmosphere.passwordUpdated,
      sheetTop: 500,
      welcome: false,
    );
  }
  if (path == AppRoute.setPassword.path || path == AppRoute.resetCode.path) {
    return const _Scene(
      curve: ThreadCurve.reset,
      atmosphere: SignInAtmosphere.resetCode,
      sheetTop: 252,
      welcome: false,
    );
  }
  if (path == AppRoute.tooMany.path) {
    return const _Scene(
      curve: ThreadCurve.reset,
      atmosphere: SignInAtmosphere.tooMany,
      sheetTop: 252,
      welcome: false,
    );
  }
  if (path == AppRoute.forgotPassword.path) {
    return const _Scene(
      curve: ThreadCurve.reset,
      atmosphere: SignInAtmosphere.reset,
      sheetTop: 300,
      welcome: false,
    );
  }
  if (path == AppRoute.register.path) {
    return const _Scene(
      curve: ThreadCurve.wizard,
      atmosphere: SignInAtmosphere.personal,
      sheetTop: 150,
      welcome: false,
    );
  }
  return const _Scene(
    curve: ThreadCurve.signIn,
    atmosphere: SignInAtmosphere.signIn,
    sheetTop: 332,
    welcome: false,
  );
}

class GoldThreadScope extends InheritedWidget {
  const GoldThreadScope({required this.model, required super.child, super.key});

  final GoldThreadModel model;

  static GoldThreadModel? maybeOf(BuildContext context) {
    return context.getInheritedWidgetOfExactType<GoldThreadScope>()?.model;
  }

  @override
  bool updateShouldNotify(GoldThreadScope oldWidget) =>
      oldWidget.model != model;
}

/// Paints the shared field and thread, then the route.
class GoldThreadShell extends StatefulWidget {
  const GoldThreadShell({required this.child, super.key});

  final Widget child;

  @override
  State<GoldThreadShell> createState() => _GoldThreadShellState();
}

class _GoldThreadShellState extends State<GoldThreadShell>
    with TickerProviderStateMixin {
  late final GoldThreadModel _model = GoldThreadModel(this);
  bool _built = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final String path = GoRouterState.of(context).uri.path;
    _model.applyPath(path);
    if (Motion.decorativeLoop(context)) {
      if (!_model.clock.isAnimating) _model.clock.repeat();
    } else {
      _model.clock.stop();
    }
    if (_built) setState(() {});
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _built = true;
    return GoldThreadScope(
      model: _model,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          ListenableBuilder(
            listenable: _model,
            builder: (context, _) => _Field(model: _model),
          ),
          widget.child,
          ListenableBuilder(
            listenable: Listenable.merge(<Listenable>[
              _model,
              _model.clock,
              _model.morph,
            ]),
            builder: (context, _) => _Stitch(model: _model),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.model});

  final GoldThreadModel model;

  @override
  Widget build(BuildContext context) {
    if (!model.welcome) {
      return SignInBackdrop(atmosphere: model.atmosphere);
    }
    final double page = model.welcomePage.clamp(0, 2).toDouble();
    final int index = page.floor();
    final double frac = page - index;
    final int next = math.min(index + 1, 2);
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        GradientBackdrop(page: index),
        if (next != index)
          Opacity(
            opacity: frac,
            child: GradientBackdrop(page: next),
          ),
      ],
    );
  }
}

class _Stitch extends StatelessWidget {
  const _Stitch({required this.model});

  final GoldThreadModel model;

  @override
  Widget build(BuildContext context) {
    final ThreadCurve curve = model.curve;
    final double low = math.min(curve.entryY, curve.exitY) - 28;
    final double high = math.max(curve.entryY, curve.exitY) + 28;
    final double top = math.max(low, model.welcome ? 130 : 124);
    final double bottom = math.min(high, model.sheetTop - 1);
    return IgnorePointer(
      child: ClipPath(
        clipper: _BandClipper(top: top, bottom: bottom),
        child: SignInThreadOverlay(clock: model.clock, curve: curve),
      ),
    );
  }
}

class _BandClipper extends CustomClipper<Path> {
  const _BandClipper({required this.top, required this.bottom});

  final double top;
  final double bottom;

  @override
  Path getClip(Size size) {
    final double scale = size.width / 390;
    final double y0 = top * scale;
    final double y1 = math.max(y0, bottom * scale);
    return Path()..addRect(Rect.fromLTRB(0, y0, size.width, y1));
  }

  @override
  bool shouldReclip(covariant _BandClipper oldClipper) =>
      oldClipper.top != top || oldClipper.bottom != bottom;
}

/// Tells the shared layer which cubic this screen is showing.
///
/// Outside the shell this is a no-op, so a golden can still paint its own
/// thread.
class GoldThreadBinding extends StatefulWidget {
  const GoldThreadBinding({
    required this.curve,
    required this.atmosphere,
    required this.sheetTop,
    required this.child,
    super.key,
  });

  final ThreadCurve curve;
  final SignInAtmosphere atmosphere;
  final double sheetTop;
  final Widget child;

  @override
  State<GoldThreadBinding> createState() => _GoldThreadBindingState();
}

class _GoldThreadBindingState extends State<GoldThreadBinding> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _report();
  }

  @override
  void didUpdateWidget(GoldThreadBinding oldWidget) {
    super.didUpdateWidget(oldWidget);
    _report();
  }

  void _report() {
    final GoldThreadModel? model = GoldThreadScope.maybeOf(context);
    if (model == null) return;
    final String? path = GoRouter.maybeOf(context)?.state.uri.path;
    final ThreadCurve curve = widget.curve;
    final SignInAtmosphere atmosphere = widget.atmosphere;
    final double sheetTop = widget.sheetTop;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      model.report(
        path: path,
        curve: curve,
        atmosphere: atmosphere,
        sheetTop: sheetTop,
      );
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
