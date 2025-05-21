import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class Button extends StatelessWidget {

  final String text;
  final VoidCallback onPressed;
  final Size mediaSize;

  // Parámetros para mayor personalización
  final Color backgroundColor;
  final Color textColor;
  final double borderRadius;
  final List<BoxShadow>? boxShadow;
  final double? width;
  final double? height;

  const Button({
    super.key, 
    required this.text, 
    required this.onPressed, 
    required this.mediaSize,
    this.backgroundColor = const Color.fromRGBO(32, 53, 140, 1.0),
    this.textColor = Colors.white,
    this.borderRadius = 15.0,
    this.boxShadow,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 30),
      width: width ?? mediaSize.width,
      height: height ?? mediaSize.height * 0.06,
      decoration: BoxDecoration(
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(0, 3),
                blurRadius: 4,
                spreadRadius: 2,
              )
            ],
        borderRadius: BorderRadius.circular(borderRadius),
        color: backgroundColor,
      ),
      child: TextButton(
        style: ButtonStyle(
          foregroundColor: MaterialStateProperty.all<Color>(textColor),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}