import 'package:material_ui/material_ui.dart';

class WalletLogo extends StatelessWidget {
  const WalletLogo({super.key, required this.size, required this.errorBuilder});

  final double size;
  final ImageErrorWidgetBuilder errorBuilder;

  @override
  Widget build(BuildContext context) {
    // Share one decoded image across routes at the largest displayed size.
    final pixels = (120 * MediaQuery.devicePixelRatioOf(context)).ceil();
    return Image.asset(
      pixels <= 480
          ? 'assets/images/Hyphen-480.png'
          : 'assets/images/Hyphen.png',
      width: size,
      height: size,
      cacheWidth: pixels.clamp(1, 1704),
      errorBuilder: errorBuilder,
    );
  }
}
