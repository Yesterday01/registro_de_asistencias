import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class InputTextField extends StatefulWidget {

  final TextEditingController controller;
  final bool isPassword;
  final Size mediaSize;
  final ScreenType dT;

  // Parámetros para mayor personalización
  final IconData? prefixIcon;
  final String? hintText;

  const InputTextField({
    super.key, 
    required this.controller, 
    this.isPassword = false, 
    required this.mediaSize,
    required this.dT,
    this.prefixIcon,
    this.hintText
  });

  @override
  State<InputTextField> createState() => _InputTextFieldState();
}

class _InputTextFieldState extends State<InputTextField> {
  
  bool obscureText = true;

  

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.mediaSize.height * 0.07,
      width: widget.mediaSize.width,
      decoration: BoxDecoration(
        border: Border.all(
            width: 2, color: const Color.fromRGBO(32, 53, 140, 1.0)),
        borderRadius: BorderRadius.circular(15),
        color: Colors.white,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      margin: const EdgeInsets.symmetric(horizontal: 30),
      alignment: Alignment.center,
      child: TextFormField(
        textAlign: TextAlign.start,
        keyboardType: widget.isPassword
            ? TextInputType.visiblePassword
            : TextInputType.name,
        style: TextStyle(fontSize: 18.sp, letterSpacing: 2),
        obscureText: widget.isPassword ? obscureText : false,
        obscuringCharacter: '*',
        controller: widget.controller,
        decoration: InputDecoration(
          prefixIconColor: Colors.grey.shade600,
          prefixIcon: widget.isPassword
              ? Icon(Icons.lock,
                  size: widget.dT == ScreenType.mobile ? 20 : 40)
              : widget.prefixIcon != null ? Icon( widget.prefixIcon,
                  size: widget.dT == ScreenType.mobile ? 20 : 40) : null,
          suffixIcon: widget.isPassword
              ? GestureDetector(
                  onTap: () {
                    setState(() {
                      obscureText = !obscureText;
                    });
                  },
                  child: Icon(
                    obscureText ? Icons.visibility_off : Icons.visibility,
                    size: widget.dT == ScreenType.mobile ? 20 : 40,
                  ),
                )
              : null,
          border: InputBorder.none,
          hintText: widget.isPassword ? 'Contraseña' : widget.hintText,
          hintStyle: TextStyle(
            fontSize: 18.sp,
            color: const Color.fromRGBO(32, 53, 140, 0.5),
          ),
        ),
      ),
    );
  }
}