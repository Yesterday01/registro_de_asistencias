import 'dart:convert';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:registro_de_asistencias/models/collaborator.dart';
import 'package:registro_de_asistencias/service/auth_api.dart';
import 'package:registro_de_asistencias/tools/arrow_icons.dart';
import 'package:registro_de_asistencias/widgets/button.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class MobileUsersRegistrerScreenPage extends StatefulWidget {
  const MobileUsersRegistrerScreenPage({super.key});

  @override
  State<MobileUsersRegistrerScreenPage> createState() =>
      _MobileUsersRegistrerScreenPageState();
}

class _MobileUsersRegistrerScreenPageState
    extends State<MobileUsersRegistrerScreenPage> {
  //Tamaño y tipo del dispositivo
  late Size mediaSize;
  var dT = Device.screenType;
  //Controladores del inputText
  late TextEditingController _codeFieldController;
  late TextEditingController _nombreFieldController;
  late TextEditingController _sucursalFieldController;
  late TextEditingController _usernameFieldController;
  late TextEditingController _passwordFieldController;
  late String passPattern;
  late RegExp passRegExp;
  late String userPattern;
  late RegExp userRegExp;
  late String codePattern;
  late RegExp codeRegExp;
  bool validatePassword = true;
  bool validateUserName = true;
  bool validateCode = true;
  String _emptyUserName = '';
  String _emptyPassword = '';
  String _emptyCode = '';
  String _emptyRole = '';
  bool obscureText = true;

  //Lista para las opciones del dropdown
  final List<String> _listRol = [
    'Super Administrador',
    'Administrador',
    'Guardia'
  ];
  String? _selectedValue;

  //API-RESTFUL
  final AuthAPI _authAPI = AuthAPI();
  List<Collaborator> _collaboratorsList = [];
  Collaborator? _collaborator;

  Future<List<Collaborator>> _getCollaborators() async {
    final response = await _authAPI.fetchCollaborators();

    List<Collaborator> collaborators = [];

    if (response.statusCode != 200) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          margin: EdgeInsets.all(15.0),
          behavior: SnackBarBehavior.floating,
          duration: Duration(milliseconds: 1000),
          content: Text('Error al intentar conectarse con el servidor')));
    }

    if (response.statusCode == 200) {
      String body = utf8.decode(response.bodyBytes);
      final jsonData = jsonDecode(body);
      debugPrint('${jsonData[1]}');
      for (var element in jsonData) {
        collaborators.add(Collaborator(
            first_name: element['first_name'],
            last_name: element['last_name'],
            last_name_m: element['last_name_m'],
            occupation: element['occupation'],
            branch: element['branch'],
            id: element['id'],
            code: element['code']));
      }
      return collaborators;
    } else {
      throw Exception('Fallo la conexion');
    }
  }

  _loadCollaborators() async {
    _getCollaborators().then(
      (value) {
        setState(() {
          _collaboratorsList = value;
          for (var element in _collaboratorsList) {
            debugPrint(element.toString());
          }
        });
      },
    );
  }

  _initializeController() {
    _usernameFieldController = TextEditingController();
    _usernameFieldController.addListener(_validateUserNameListener);
    _passwordFieldController = TextEditingController();
    _passwordFieldController.addListener(_validatePasswordListener);
    _codeFieldController = TextEditingController();
    _codeFieldController.addListener(_updateTextFieldsListener);
    _nombreFieldController = TextEditingController();
    _sucursalFieldController = TextEditingController();
    passPattern = r'^(?=.*\d)(?=.*[a-z])(?=.*[A-Z])(?=.*[a-zA-Z]).{8,}$';
    passRegExp = RegExp(passPattern);
    userPattern = r'^(?!.*\.\.)(?!.*\.$)[^\W][\w.]{0,29}$';
    userRegExp = RegExp(userPattern);
    codePattern = r'^[0-9]+$';
    codeRegExp = RegExp(codePattern);
  }

  _closeControllers() {
    _usernameFieldController.dispose();
    _passwordFieldController.dispose();
    _codeFieldController.dispose();
    _nombreFieldController.dispose();
    _sucursalFieldController.dispose();
  }

  void _validateUserNameListener() {
    setState(() {
      if (_usernameFieldController.text.isNotEmpty) {
        validateUserName = userRegExp.hasMatch(_usernameFieldController.text);
      } else {
        validateUserName = true;
      }
    });
  }

  void _validatePasswordListener() {
    setState(() {
      if (_passwordFieldController.text.isNotEmpty) {
        validatePassword = passRegExp.hasMatch(_passwordFieldController.text);
      } else {
        validatePassword = true;
      }
    });
  }

  void _updateTextFieldsListener() {
    setState(() {
      if (_codeFieldController.text.isNotEmpty) {
        validateCode = codeRegExp.hasMatch(_codeFieldController.text);
      } else {
        validateCode = true;
      }
    });

    for (var element in _collaboratorsList) {
      if (_codeFieldController.text.compareTo(element.code.toString()) == 0) {
        _nombreFieldController.text = element.first_name;
        _sucursalFieldController.text = element.branch;
        _collaborator = element;
        return;
      } else {
        _nombreFieldController.clear();
        _sucursalFieldController.clear();
        _collaborator = null;
      }
    }
  }

  _registrarUsuario(String username, String password, String rol, int id,
      BuildContext context) async {
    showDialog(
        context: context,
        builder: (context) {
          return const Center(child: CircularProgressIndicator());
        },
        barrierDismissible: false);

    final response = await _authAPI.store(username, password, rol, id);

    Navigator.of(context).pop();

    if (response.statusCode == 422) {
      String body = utf8.decode(response.bodyBytes);
      final jsonData = jsonDecode(body);
      debugPrint(jsonData['message']);
      debugPrint('$body  status: ${response.statusCode}');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          margin: const EdgeInsets.all(15.0),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 2000),
          content: Text(
            jsonData['message'],
            style: TextStyle(fontSize: 15.sp),
            textAlign: TextAlign.center,
          )));
    }

    if (response.statusCode == 500) {
      String body = utf8.decode(response.bodyBytes);
      //final jsonData = jsonDecode(body);
      debugPrint('$body  status: ${response.statusCode}');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          margin: const EdgeInsets.all(15.0),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 2000),
          content: Text(
            'El colaborador ya cuenta con un usuario',
            style: TextStyle(fontSize: 16.sp),
            textAlign: TextAlign.center,
          )));
    }

    if (response.statusCode == 200) {
      String body = utf8.decode(response.bodyBytes);
      final jsonData = jsonDecode(body);
      debugPrint(body);
      if (jsonData['status'] == 1) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            margin: const EdgeInsets.all(15.0),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(milliseconds: 2000),
            content: Text(
              jsonData['msg'],
              style: TextStyle(fontSize: 15.sp),
              textAlign: TextAlign.center,
            )));
        _usernameFieldController.clear();
        _passwordFieldController.clear();
        _codeFieldController.clear();
        _nombreFieldController.clear();
        _sucursalFieldController.clear();
        _selectedValue = null;
      }
      if (jsonData['status'] == 0) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            margin: const EdgeInsets.all(15.0),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(milliseconds: 2000),
            content: Text(
              jsonData['msg'],
              style: TextStyle(fontSize: 15.sp),
              textAlign: TextAlign.center,
            )));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeController();
    _loadCollaborators();
  }

  @override
  void dispose() {
    _closeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    mediaSize = MediaQuery.of(context).size;
    return Scaffold(
      appBar: _appBar(),
      body: _body(),
    );
  }

  /* Widget _buttonRegistrer(String txt, onPress) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 35),
        width: mediaSize.width - 60,
        height: mediaSize.height * 0.05,
        decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  offset: const Offset(0, 3),
                  blurRadius: 4,
                  spreadRadius: 2)
            ],
            borderRadius: BorderRadius.circular(15),
            color: const Color.fromRGBO(32, 53, 140, 1.0)),
        child: TextButton(
            style: ButtonStyle(
                foregroundColor:
                    MaterialStateProperty.all<Color>(Colors.white)),
            onPressed: onPress,
            child: Text(
              txt,
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
            )),
      ); */

  Widget _inputTextField(String hintText, TextEditingController controller,
          TextInputType textInputType,
          {isEnable = false,
          isPassword = false,
          isUserName = false,
          isCode = false}) =>
      Container(
        height: mediaSize.height * 0.05,
        decoration: BoxDecoration(
            border: Border.all(
                width: 2,
                color: isPassword
                    ? validatePassword
                        ? const Color.fromRGBO(32, 53, 140, 1)
                        : Colors.red
                    : isUserName
                        ? validateUserName
                            ? const Color.fromRGBO(32, 53, 140, 1)
                            : Colors.red
                        : isCode
                            ? validateCode
                                ? const Color.fromRGBO(32, 53, 140, 1)
                                : Colors.red
                            : const Color.fromRGBO(32, 53, 140, 1)),
            borderRadius: BorderRadius.circular(15),
            color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        margin: const EdgeInsets.symmetric(horizontal: 35),
        alignment: Alignment.center,
        child: TextFormField(
          enabled: isEnable ? true : false,
          keyboardType: textInputType,
          obscureText: isPassword ? obscureText : false,
          style: TextStyle(
              fontSize: 15.sp, color: const Color.fromRGBO(32, 53, 140, 1)),
          decoration: InputDecoration(
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
              hintText: hintText,
              hintStyle:
                  const TextStyle(color: Color.fromRGBO(32, 53, 140, 0.5))),
          controller: controller,
        ),
      );

  DropdownButtonHideUnderline _dropdown() => DropdownButtonHideUnderline(
        child: DropdownButton2<String>(
          isExpanded: true,
          hint: Text(
            'Seleccionar rol',
            style: TextStyle(
              fontSize: 15.sp,
              color: const Color.fromRGBO(32, 53, 140, 0.5),
            ),
          ),
          items: _listRol
              .map((String item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      item,
                      style: TextStyle(
                          fontSize: 15.sp,
                          color: const Color.fromRGBO(32, 53, 140, 1)),
                    ),
                  ))
              .toList(),
          value: _selectedValue,
          onChanged: (String? value) {
            setState(() {
              _selectedValue = value;
              debugPrint(_selectedValue);
            });
          },
          buttonStyleData: ButtonStyleData(
            height: mediaSize.height * 0.05,
            width: mediaSize.width - 70,
            padding: const EdgeInsets.only(left: 14, right: 14),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  width: 2,
                  color: const Color.fromRGBO(32, 53, 140, 1),
                ),
                color: Colors.white),
            elevation: 1,
          ),
          iconStyleData: IconStyleData(
            icon: const Icon(
              Icons.arrow_drop_down,
            ),
            iconSize: dT == ScreenType.mobile ? 20 : 40,
            iconEnabledColor: Colors.yellow,
            iconDisabledColor: Colors.grey,
          ),
          menuItemStyleData: const MenuItemStyleData(
            padding: EdgeInsets.only(left: 14, right: 14),
          ),
        ),
      );

  Widget _body() => Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              /*Icon(
                Icons.supervisor_account,
                size: dT == ScreenType.mobile ? 80 : 150,
                color: const Color.fromRGBO(32, 53, 140, 1.0),
              ),*/
              Container(
                alignment: Alignment.centerLeft,
                margin: const EdgeInsets.fromLTRB(30, 50, 0, 0),
                child: Text(
                  'Registro',
                  style: TextStyle(
                      color: const Color.fromRGBO(32, 53, 140, 1.0),
                      fontSize: 25.sp,
                      fontWeight: FontWeight.bold),
                ),
              ),
              Container(margin: const EdgeInsets.fromLTRB(0, 0, 0, 30)),
              Container(
                margin: const EdgeInsets.fromLTRB(0, 15, 0, 0),
              ),
              _inputTextField("Nombre de usuario", _usernameFieldController,
                  TextInputType.name,
                  isEnable: true, isUserName: true),
              _emptyUserName.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 35.0),
                      child: Text(_emptyUserName,
                          style: TextStyle(color: Colors.red, fontSize: 13.sp)),
                    )
                  : const SizedBox(),
              Container(
                margin: const EdgeInsets.fromLTRB(0, 15, 0, 0),
              ),
              _inputTextField("Contraseña", _passwordFieldController,
                  TextInputType.visiblePassword,
                  isEnable: true, isPassword: true),
              _emptyPassword.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 35.0),
                      child: Text(_emptyPassword,
                          style: TextStyle(color: Colors.red, fontSize: 13.sp)),
                    )
                  : const SizedBox(),
              Container(
                margin: const EdgeInsets.fromLTRB(0, 15, 0, 0),
              ),
              _inputTextField("Codigo del colaborador (Solo numeros)",
                  _codeFieldController, TextInputType.number,
                  isEnable: true, isCode: true),
              _emptyUserName.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 35.0),
                      child: Text(_emptyCode,
                          style: TextStyle(color: Colors.red, fontSize: 13.sp)),
                    )
                  : const SizedBox(),
              Container(
                alignment: Alignment.centerLeft,
                margin: const EdgeInsets.fromLTRB(35, 15, 0, 0),
              ),
              Row(children: [
                Expanded(
                  child: _inputTextField(
                      "Nombre", _nombreFieldController, TextInputType.text),
                ),
                Expanded(
                  child: _inputTextField(
                      "Sucursal", _sucursalFieldController, TextInputType.text),
                ),
              ]),
              Container(
                alignment: Alignment.centerLeft,
                margin: const EdgeInsets.fromLTRB(35, 15, 0, 0),
              ),

              Container(
                alignment: Alignment.centerLeft,
                margin: const EdgeInsets.fromLTRB(35, 15, 0, 0),
              ),
              _dropdown(),
              _emptyRole.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 35.0),
                      child: Text(_emptyRole,
                          style: TextStyle(color: Colors.red, fontSize: 13.sp)),
                    )
                  : const SizedBox(),
              Container(
                  margin:
                      EdgeInsets.fromLTRB(0, 0, 0, mediaSize.height * 0.08)),
              Button( text: 'Registrar', onPressed: () {
                setState(() {
                  if (_usernameFieldController.text.isEmpty) {
                    _emptyUserName = '"Favor de ingresar un nombre de usuario"';
                  } else {
                    _emptyUserName = '';
                  }

                  if (_passwordFieldController.text.isEmpty) {
                    _emptyPassword = '"Favor de ingresar una contraseña"';
                  } else {
                    _emptyPassword = '';
                  }

                  if (_codeFieldController.text.isEmpty) {
                    _emptyCode = '"Favor de ingresar el codigo del usuario"';
                  } else {
                    _emptyCode = '';
                  }

                  if (_selectedValue == null) {
                    _emptyRole = '"Favor de seleccionar un rol"';
                  } else {
                    _emptyRole = '';
                  }

                  if (_usernameFieldController.text.isNotEmpty &&
                      _passwordFieldController.text.isNotEmpty &&
                      _codeFieldController.text.isNotEmpty &&
                      _selectedValue != null) {
                    if (!validateUserName ||
                        !validatePassword ||
                        !validateCode) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          margin: const EdgeInsets.all(30.0),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(milliseconds: 2000),
                          content: Text(
                            'Campos invalidos',
                            style: TextStyle(fontSize: 15.sp),
                            textAlign: TextAlign.center,
                          )));
                    } else if (_collaborator == null) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          margin: const EdgeInsets.all(30.0),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(milliseconds: 2000),
                          content: Text(
                            'El codigo del colaborador no existe',
                            style: TextStyle(fontSize: 15.sp),
                            textAlign: TextAlign.center,
                          )));
                    } else {
                      _registrarUsuario(
                          _usernameFieldController.text,
                          _passwordFieldController.text,
                          _selectedValue!,
                          _collaborator!.id,
                          context);
                    }
                  }
                });
              },
              mediaSize: mediaSize),
              SizedBox(height: mediaSize.height * 0.05),
              Image.asset(
                'assets/logo.png',
                width: mediaSize.width * 0.3,
              ),
              //Container(margin: const EdgeInsets.fromLTRB(0, 50, 0, 50)),
            ],
          ),
        ),
      );

  PreferredSizeWidget _appBar() => AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Arrow.arrow_circle_left,
            size: 40,
            color: Color.fromRGBO(240, 231, 18, 1.0),
          ),
        ),
      );
}
