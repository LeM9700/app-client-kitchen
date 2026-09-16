import 'package:flutter/material.dart';

import 'package:app_client/core/theme/kitchen_motion.dart';
import 'package:app_client/core/theme/kitchen_tokens.dart';

class KitchenPhotoBackground extends StatefulWidget {
  const KitchenPhotoBackground({
    super.key,
    required this.assetPath,
    required this.child,
    this.overlayColor = KitchenColors.photoScrim,
    this.alignment = Alignment.center,
    this.enableSlowScale = false,
  });

  final String assetPath;
  final Widget child;
  final Color overlayColor;
  final Alignment alignment;
  final bool enableSlowScale;

  @override
  State<KitchenPhotoBackground> createState() => _KitchenPhotoBackgroundState();
}

class _KitchenPhotoBackgroundState extends State<KitchenPhotoBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: KitchenMotion.background,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || MediaQuery.disableAnimationsOf(context)) return;
      if (widget.enableSlowScale) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(AssetImage(widget.assetPath), context);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      widget.assetPath,
      fit: BoxFit.cover,
      alignment: widget.alignment,
      filterQuality: FilterQuality.medium,
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedBuilder(
          animation: _controller,
          child: image,
          builder: (context, child) {
            final scale =
                widget.enableSlowScale ? 1 + (_controller.value * 0.035) : 1.0;
            return Transform.scale(scale: scale, child: child);
          },
        ),
        DecoratedBox(decoration: BoxDecoration(color: widget.overlayColor)),
        widget.child,
      ],
    );
  }
}
