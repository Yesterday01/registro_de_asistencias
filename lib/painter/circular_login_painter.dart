import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class CirclePainter extends CustomPainter {
  var dT = Device.screenType;
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint1 = Paint()
      ..strokeWidth = 1
      ..style = PaintingStyle.fill
      ..color = Colors.white;
    Offset top = Offset(size.width / 2, dT == ScreenType.mobile ? 0 : -150);
    canvas.drawCircle(top,
        dT == ScreenType.mobile ? size.width * 0.8 : size.width * 0.8, paint1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
