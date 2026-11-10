import 'package:flutter/material.dart';

import '../../core/design/design_tokens.dart';
import '../../core/motion/motion_tokens.dart';
import 'remote_image.dart';

/// One picture in a [PhotoCarousel]: a URL the LGU published (drawn through
/// [RemoteImage], decoded at the size it is shown) or an [ImageProvider] the
/// caller already holds.
@immutable
class CarouselPhoto {
  const CarouselPhoto.url(String this.url, {this.semanticLabel}) : image = null;

  const CarouselPhoto.provider(ImageProvider this.image, {this.semanticLabel})
    : url = null;

  final String? url;
  final ImageProvider? image;

  /// What the picture shows. Null marks it decorative.
  final String? semanticLabel;
}

/// Swipeable photos with dots (CSS `.car` / `.slide` / `.dots` on Balita):
/// rounded 24, navy behind the image while it loads, and dots that stretch
/// for the current photo. A single photo shows no dots.
///
/// [viewportFraction] below 1 peeks the next photo (Balita's 86%).
/// [overlayBuilder] draws over a photo, e.g. a featured story's category and
/// title; [onTap] opens it.
class PhotoCarousel extends StatefulWidget {
  const PhotoCarousel({
    required this.photos,
    this.height = 250,
    this.viewportFraction = 1,
    this.radius = 24,
    this.onTap,
    this.onPageChanged,
    this.overlayBuilder,
    super.key,
  }) : assert(viewportFraction > 0 && viewportFraction <= 1);

  final List<CarouselPhoto> photos;
  final double height;
  final double viewportFraction;
  final double radius;
  final ValueChanged<int>? onTap;
  final ValueChanged<int>? onPageChanged;
  final Widget Function(BuildContext context, int index)? overlayBuilder;

  @override
  State<PhotoCarousel> createState() => _PhotoCarouselState();
}

class _PhotoCarouselState extends State<PhotoCarousel> {
  late PageController _controller = PageController(
    viewportFraction: widget.viewportFraction,
  );
  int _index = 0;

  @override
  void didUpdateWidget(covariant PhotoCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewportFraction != widget.viewportFraction) {
      _controller.dispose();
      _controller = PageController(
        viewportFraction: widget.viewportFraction,
        initialPage: _index,
      );
    }
    if (_index >= widget.photos.length) {
      _index = widget.photos.isEmpty ? 0 : widget.photos.length - 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<CarouselPhoto> photos = widget.photos;
    if (photos.isEmpty) return const SizedBox.shrink();
    final double gap = widget.viewportFraction < 1 ? 6 : 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _controller,
            itemCount: photos.length,
            onPageChanged: (index) {
              setState(() => _index = index);
              widget.onPageChanged?.call(index);
            },
            itemBuilder: (context, index) => Padding(
              padding: EdgeInsets.symmetric(horizontal: gap),
              child: _slide(context, index),
            ),
          ),
        ),
        if (photos.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: Spacing.sm),
            child: ExcludeSemantics(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  for (var i = 0; i < photos.length; i++)
                    _Dot(active: i == _index),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _slide(BuildContext context, int index) {
    final CarouselPhoto photo = widget.photos[index];
    final String? url = photo.url;
    final ImageProvider? provider = photo.image;
    final Widget picture = url != null
        ? RemoteImage(url: url)
        : provider != null
        ? Image(
            image: provider,
            fit: BoxFit.cover,
            excludeFromSemantics: true,
            errorBuilder: (context, error, stack) => const SizedBox.shrink(),
          )
        : const SizedBox.shrink();
    final String? label = photo.semanticLabel;
    final Widget Function(BuildContext, int)? overlay = widget.overlayBuilder;
    final ValueChanged<int>? onTap = widget.onTap;

    Widget slide = ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: ColoredBox(
        color: BrandColors.navy,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            if (label == null || label.isEmpty)
              ExcludeSemantics(child: picture)
            else
              Semantics(
                container: true,
                image: true,
                label: label,
                child: ExcludeSemantics(child: picture),
              ),
            if (overlay != null) overlay(context, index),
          ],
        ),
      ),
    );
    if (onTap != null) {
      slide = Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(widget.radius),
          onTap: () => onTap(index),
          child: slide,
        ),
      );
    }
    return slide;
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Motion.reduced(context)
          ? MotionTokens.instant
          : MotionTokens.fast,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: active ? 22 : 7,
      height: 7,
      decoration: BoxDecoration(
        color: active
            ? BrandColors.blue
            : BrandColors.ink.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
    );
  }
}
