import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/result/result.dart';
import 'remote_image.dart';

/// Loads one public picture by an identifier the screen already holds.
typedef MediaBytesLoader = Future<Result<Uint8List?>> Function(String id);

/// Asks [load] once and hands the bytes, or null, to [builder].
///
/// A null [load], a failed read, a 404, or a throw all call [builder] with
/// null. The widget does not throw and does not paint an error of its own:
/// the caller decides what the missing picture looks like.
class MediaBytesHost extends StatefulWidget {
  const MediaBytesHost({
    required this.id,
    required this.builder,
    this.load,
    this.enabled = true,
    super.key,
  });

  final String id;
  final MediaBytesLoader? load;
  final bool enabled;
  final Widget Function(Uint8List? bytes) builder;

  @override
  State<MediaBytesHost> createState() => _MediaBytesHostState();
}

class _MediaBytesHostState extends State<MediaBytesHost> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(MediaBytesHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id ||
        oldWidget.enabled != widget.enabled ||
        oldWidget.load != widget.load) {
      _bytes = null;
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    final MediaBytesLoader? load = widget.load;
    if (!widget.enabled || load == null) return;
    final String id = widget.id;
    try {
      final Result<Uint8List?> result = await load(id);
      if (!mounted || widget.id != id) return;
      final Uint8List? bytes = result.valueOrNull;
      if (bytes == null || bytes.isEmpty) return;
      setState(() => _bytes = bytes);
    } on Object {
      // The placeholder stays. A picture is never the reason a page fails.
    }
  }

  @override
  Widget build(BuildContext context) => widget.builder(_bytes);
}

/// A decoded photograph sized to the box it is drawn in.
///
/// [placeholder] is what the resident sees when the bytes will not decode.
class DecodedMemoryImage extends StatelessWidget {
  const DecodedMemoryImage({
    required this.bytes,
    required this.placeholder,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.semanticLabel,
    this.height,
    this.maxDecodeWidth = RemoteImage.feedDecodeCeiling,
    this.keepInImageCache = true,
    super.key,
  });

  final Uint8List bytes;
  final Widget placeholder;
  final BoxFit fit;
  final Alignment alignment;
  final String? semanticLabel;
  final double? height;
  final int maxDecodeWidth;

  /// Public photographs may stay in Flutter's shared image cache.
  /// A personal portrait must not.
  final bool keepInImageCache;

  @override
  Widget build(BuildContext context) {
    if (!keepInImageCache) {
      return _PrivateMemoryImage(
        bytes: bytes,
        placeholder: placeholder,
        fit: fit,
        alignment: alignment,
        semanticLabel: semanticLabel,
        height: height,
        maxDecodeWidth: maxDecodeWidth,
      );
    }
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double ratio = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1;
        final double logicalWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        return Image.memory(
          bytes,
          height: height,
          width: height == null ? null : double.infinity,
          fit: fit,
          alignment: alignment,
          semanticLabel: semanticLabel,
          excludeFromSemantics: semanticLabel == null,
          cacheWidth: RemoteImage.decodedPixelWidth(
            logicalWidth: logicalWidth,
            devicePixelRatio: ratio,
            ceiling: maxDecodeWidth,
          ),
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
          errorBuilder:
              (BuildContext context, Object error, StackTrace? stack) =>
                  placeholder,
        );
      },
    );
  }
}

/// Paints a personal picture and removes it from the shared image cache
/// when the widget goes away. [Image.memory] would otherwise leave the
/// decoded frame behind.
class _PrivateMemoryImage extends StatefulWidget {
  const _PrivateMemoryImage({
    required this.bytes,
    required this.placeholder,
    required this.fit,
    required this.alignment,
    required this.maxDecodeWidth,
    this.semanticLabel,
    this.height,
  });

  final Uint8List bytes;
  final Widget placeholder;
  final BoxFit fit;
  final Alignment alignment;
  final String? semanticLabel;
  final double? height;
  final int maxDecodeWidth;

  @override
  State<_PrivateMemoryImage> createState() => _PrivateMemoryImageState();
}

class _PrivateMemoryImageState extends State<_PrivateMemoryImage> {
  ImageProvider<Object>? _provider;

  @override
  void dispose() {
    final ImageProvider<Object>? provider = _provider;
    _provider = null;
    if (provider != null) {
      // The cache key is the provider's obtained key, not the provider.
      unawaited(provider.evict());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double ratio = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1;
        final double logicalWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : (widget.height ?? 84);
        final ImageProvider<Object> provider = ResizeImage(
          MemoryImage(widget.bytes),
          width: RemoteImage.decodedPixelWidth(
            logicalWidth: logicalWidth,
            devicePixelRatio: ratio,
            ceiling: widget.maxDecodeWidth,
          ),
        );
        _provider = provider;
        return Image(
          image: provider,
          height: widget.height,
          width: widget.height == null ? null : double.infinity,
          fit: widget.fit,
          alignment: widget.alignment,
          semanticLabel: widget.semanticLabel,
          excludeFromSemantics: widget.semanticLabel == null,
          gaplessPlayback: false,
          filterQuality: FilterQuality.medium,
          errorBuilder:
              (BuildContext context, Object error, StackTrace? stack) =>
                  widget.placeholder,
        );
      },
    );
  }
}
