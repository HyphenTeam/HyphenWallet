import 'package:material_ui/material_ui.dart';

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
    _resetController.stop();
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
    final reduced = MediaQuery.disableAnimationsOf(context);
    return GestureDetector(
      onPanUpdate: reduced ? null : _onPanUpdate,
      onPanEnd: reduced ? null : _onPanEnd,
      onPanCancel: reduced ? null : () => _onPanEnd(DragEndDetails()),
      child: Transform(
        alignment: Alignment.center,
        transform: reduced
            ? Matrix4.identity()
            : (Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateX(_rotX)
                ..rotateY(_rotY)),
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

class FloatingOrb extends StatelessWidget {
  final double size;
  final Color color1;
  final Color color2;

  const FloatingOrb({
    super.key,
    this.size = 120,
    this.color1 = HyphenColors.primary,
    this.color2 = HyphenColors.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color1.withValues(alpha: 0.25),
            color2.withValues(alpha: 0.05),
          ],
        ),
      ),
    );
  }
}
