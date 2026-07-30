import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A Wise-style 3D perspective card that responds to touch with tilt and glow.
class PerspectiveCard extends StatefulWidget {
  final Widget child;
  final double maxTilt;
  final BorderRadius borderRadius;
  final Color glowColor;
  final double elevation;

  const PerspectiveCard({
    super.key,
    required this.child,
    this.maxTilt = 0.06,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.glowColor = HyphenColors.primary,
    this.elevation = 12,
  });

  @override
  State<PerspectiveCard> createState() => _PerspectiveCardState();
}

class _PerspectiveCardState extends State<PerspectiveCard>
    with SingleTickerProviderStateMixin {
  double _rotX = 0;
  double _rotY = 0;
  bool _touching = false;
  late AnimationController _resetController;
  double _startX = 0;
  double _startY = 0;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _resetController.addListener(() {
      final t = Curves.easeOutBack.transform(_resetController.value);
      setState(() {
        _rotX = _startX * (1 - t);
        _rotY = _startY * (1 - t);
      });
    });
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final box = context.findRenderObject() as RenderBox;
    final size = box.size;
    final local = box.globalToLocal(details.globalPosition);
    setState(() {
      _touching = true;
      _rotY = ((local.dx / size.width) - 0.5) * 2 * widget.maxTilt;
      _rotX = -((local.dy / size.height) - 0.5) * 2 * widget.maxTilt;
    });
  }

  void _onPanEnd(_) {
    _touching = false;
    _startX = _rotX;
    _startY = _rotY;
    _resetController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onPanCancel: () => _onPanEnd(DragEndDetails()),
      child: AnimatedContainer(
        duration: _touching ? Duration.zero : const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        transformAlignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX(_rotX)
          ..rotateY(_rotY),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withValues(
                  alpha: _touching ? 0.25 : 0.1,
                ),
                blurRadius: widget.elevation + (_touching ? 12 : 0),
                spreadRadius: _touching ? 2 : 0,
                offset: Offset(_rotY * 30, -_rotX * 30 + 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: widget.borderRadius,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// A floating orb with animated gradient shimmer — used as a decorative
/// background element on welcome/node-mode screens.
class FloatingOrb extends StatefulWidget {
  final double size;
  final Color color1;
  final Color color2;
  final Duration period;
  final Offset offset;

  const FloatingOrb({
    super.key,
    this.size = 120,
    this.color1 = HyphenColors.primary,
    this.color2 = HyphenColors.accent,
    this.period = const Duration(seconds: 4),
    this.offset = Offset.zero,
  });

  @override
  State<FloatingOrb> createState() => _FloatingOrbState();
}

class _FloatingOrbState extends State<FloatingOrb>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.period)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        final t = Curves.easeInOut.transform(_ctrl.value);
        final dy = math.sin(t * math.pi) * 12;
        return Transform.translate(
          offset: widget.offset + Offset(0, dy),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Color.lerp(
                    widget.color1,
                    widget.color2,
                    t,
                  )!.withValues(alpha: 0.25),
                  Color.lerp(
                    widget.color2,
                    widget.color1,
                    t,
                  )!.withValues(alpha: 0.05),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
