import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:registro_de_asistencias/painter/circular_login_painter.dart';
import 'package:registro_de_asistencias/service/auth_api.dart';
import 'package:registro_de_asistencias/service/network_connection.dart';
import 'package:registro_de_asistencias/view/admin_screen_page.dart';
import 'package:registro_de_asistencias/view/face_detector_screen_page.dart';
import 'package:registro_de_asistencias/view/super_admin_screen_page.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreenPage extends StatefulWidget {
  const LoginScreenPage({super.key});

  @override
  State<LoginScreenPage> createState() => _LoginScreenPageState();
}

class _LoginScreenPageState extends State<LoginScreenPage> {
  //Get Size Device
  late Size mediaSize;
  //Get Device Type
  var dT = Device.screenType;
  //Controller for userInput
  late TextEditingController _userController;
  String _validatorUser = '';
  //Controller for passwordInput
  late TextEditingController _passwordController;
  String _validatorPass = '';
  bool obscureText = true;
  //API-RESTFUL
  final AuthAPI _authAPI = AuthAPI();
  String? _userName;
  String? _password;
  //Save preferences
  SharedPreferences? _prefs;
  NetworkController? networkController;

  // Inicializar controlador de texto
  _initializeController() {
    _userController = TextEditingController();
    _userController.addListener(_updateUserName);
    _passwordController = TextEditingController();
    _passwordController.addListener(_updatePassword);
  }

  // Cerrar controladores de forma segura
  _closeControllers() {
    _userController.dispose();
    _passwordController.dispose();
  }

  // Actualiza la variable
  void _updateUserName() {
    setState(() {
      _userName = _userController.text;
    });
  }

  // Actualiza la variable
  void _updatePassword() {
    setState(() {
      _password = _passwordController.text;
    });
  }

  // Limpia los campos para ingresar texto
  cleanTextFields() {
    _userController.clear();
    _passwordController.clear();
  }

  // Carga la instancia de las preferencias
  _chargePreferences() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Hace la petición al APIREST para el inicio de sesión, pasando como parametros
  // el nombre de usuario y la contraseña
  void authLogin(String userName, String password, BuildContext context) async {
    showDialog(
        context: context,
        builder: (context) {
          return const Center(child: CircularProgressIndicator());
        },
        barrierDismissible: false);
    final response = await _authAPI.login(userName, password);

    Navigator.of(context).pop();

    if (response.statusCode != 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          margin: const EdgeInsets.all(15.0),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1000),
          content: Text(
            'Error al intentar conectarse con el servidor',
            style: TextStyle(fontSize: 16.sp),
          )));
    }

    if (response.statusCode == 200) {
      String body = utf8.decode(response.bodyBytes);
      final jsonData = jsonDecode(body);
      if (jsonData['status'] == 0) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            margin: const EdgeInsets.all(15.0),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(milliseconds: 1000),
            content: Text(
              jsonData['msg'],
              style: TextStyle(fontSize: 18.sp),
            )));
      }
      if (jsonData['status'] == 1) {
        switch (jsonData['rol']) {
          case 'Super Administrador':
            cleanTextFields();
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const SuperAdminScreenPage()));
            break;
          case 'Administrador':
            cleanTextFields();
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AdminScreenPage()));
            break;
          case 'Guardia':
            // Guarda las credencias para no volver a iniciar sesión
            _prefs?.setString('user', userName);
            _prefs?.setString('pass', password);
            cleanTextFields();
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const FaceDetectorScreenPage()));
            break;
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeController();
    _chargePreferences();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _closeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    networkController = NetworkController(context);
    networkController?.onInit();
    mediaSize = MediaQuery.of(context).size;
    return Scaffold(
        body: _body(), backgroundColor: const Color.fromRGBO(32, 53, 140, 1.0));
  }

  Widget _body() => SingleChildScrollView(
        child: SizedBox(
          height: mediaSize.height,
          child: CustomPaint(
            painter: CirclePainter(),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Container(
                alignment: Alignment.bottomCenter,
                child: Column(children: [
                  Container(
                      margin:
                          EdgeInsets.fromLTRB(0, mediaSize.height * 0.1, 0, 0),
                      child: _buildTop()),
                  Container(
                      margin:
                          EdgeInsets.fromLTRB(0, mediaSize.height * 0.2, 0, 0),
                      child: _buildBottom())
                ]),
              ),
            ),
          ),
        ),
      );

  Widget _buildTop() => SizedBox(
        width: mediaSize.width,
        //height: mediaSize.width * 0.5,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image.asset(
              'assets/logo.png',
              width: mediaSize.width * 0.3,
            ),
            SizedBox(
              width: mediaSize.width * 0.6,
              child: AutoSizeText(
                '¡Bienvenido!',
                style: TextStyle(
                    fontSize: dT == ScreenType.mobile ? 45 : 90,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromRGBO(32, 53, 140, 1.0)),
                minFontSize: 40,
                maxLines: 1,
              ),
            )
          ],
        ),
      );

  Widget _buildBottom() => SizedBox(
        width: mediaSize.width,
        child: Card(
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30), topRight: Radius.circular(30))),
          color: Colors.transparent,
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _whiteText('Ingrese su usuario:'),
                _inputTextField(_userController),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 35.0),
                  child: Text(_validatorUser,
                      style: TextStyle(
                          color: const Color.fromRGBO(240, 231, 18, 1),
                          fontSize: 16.sp)),
                ),
                const SizedBox(height: 30),
                _whiteText('Contraseña:'),
                _inputTextField(_passwordController, isPassword: true),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 35.0),
                  child: Text(_validatorPass,
                      style: TextStyle(
                          color: const Color.fromRGBO(240, 231, 18, 1),
                          fontSize: 16.sp)),
                ),
                const SizedBox(height: 40),
                _buttonRegistrer('Ingresar', () {
                  setState(() {
                    if (_userName == null || _userController.text.isEmpty) {
                      _validatorUser = '"Favor de ingresar tu usuario"';
                    } else {
                      _validatorUser = '';
                    }
                    if (_password == null || _passwordController.text.isEmpty) {
                      _validatorPass = '"Favor de ingresar tu contraseña"';
                    } else {
                      _validatorPass = '';
                    }
                    if (_userController.text.isNotEmpty &&
                        _passwordController.text.isNotEmpty) {
                      authLogin(_userName!, _password!, context);
                    }
                  });
                }),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      );

  Widget _whiteText(String txt) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 35),
        child: AutoSizeText(
          txt,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.sp,
          ),
        ),
      );

  Widget _inputTextField(TextEditingController controller,
      {isPassword = false}) {
    return Container(
      height: mediaSize.height * 0.07,
      width: mediaSize.width,
      decoration: BoxDecoration(
          border: Border.all(
              width: 2, color: const Color.fromRGBO(32, 53, 140, 1.0)),
          borderRadius: BorderRadius.circular(15),
          color: Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      margin: const EdgeInsets.symmetric(horizontal: 35),
      alignment: Alignment.center,
      child: TextFormField(
        textAlign: TextAlign.start,
        keyboardType:
            isPassword ? TextInputType.visiblePassword : TextInputType.name,
        style: TextStyle(fontSize: 18.sp, letterSpacing: 3),
        obscureText: isPassword ? obscureText : false,
        obscuringCharacter: String.fromCharCode(42),
        decoration: InputDecoration(
            prefixIconColor: Colors.grey.shade600,
            prefixIcon: isPassword
                ? Icon(Icons.lock, size: dT == ScreenType.mobile ? 20 : 40)
                : Icon(Icons.account_circle,
                    size: dT == ScreenType.mobile ? 20 : 40),
            suffixIcon: isPassword
                ? GestureDetector(
                    onTap: () {
                      setState(() {
                        obscureText = !obscureText;
                      });
                    },
                    child: obscureText
                        ? Icon(Icons.visibility_off,
                            size: dT == ScreenType.mobile ? 20 : 40)
                        : Icon(Icons.visibility,
                            size: dT == ScreenType.mobile ? 20 : 40))
                : null,
            border: InputBorder.none,
            hintText: isPassword ? 'Contraseña' : 'Usuario',
            hintStyle: TextStyle(
                fontSize: 18.sp,
                color: const Color.fromRGBO(32, 53, 140, 0.5))),
        controller: controller,
      ),
    );
  }

  Widget _buttonRegistrer(String txt, onPress) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 35),
        width: mediaSize.width - 50,
        height: mediaSize.height * 0.07,
        decoration: BoxDecoration(boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.5),
              offset: const Offset(0, 3),
              blurRadius: 4,
              spreadRadius: 2)
        ], borderRadius: BorderRadius.circular(50), color: Colors.white),
        child: TextButton(
            style: ButtonStyle(
                foregroundColor: MaterialStateProperty.all<Color>(
                    const Color.fromRGBO(32, 53, 140, 1.0))),
            onPressed: onPress,
            child: Text(
              txt,
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w700),
            )),
      );
}
