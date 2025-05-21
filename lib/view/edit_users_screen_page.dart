import 'dart:convert';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:registro_de_asistencias/models/collaborator.dart';
import 'package:registro_de_asistencias/models/mobile_user.dart';
import 'package:registro_de_asistencias/service/auth_api.dart';
import 'package:registro_de_asistencias/tools/arrow_icons.dart';
import 'package:registro_de_asistencias/widgets/button.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class EditUsersScreenPage extends StatefulWidget {
  final MobilUser user;
  const EditUsersScreenPage({super.key, required this.user});

  @override
  State<EditUsersScreenPage> createState() => _EditUsersScreenPageState();
}

class _EditUsersScreenPageState extends State<EditUsersScreenPage> {
  //Tamaño y tipo del dispositivo
  late Size mediaSize;
  var dT = Device.screenType;
  //Controladores del inputText
  late TextEditingController _nombreFieldController;
  late TextEditingController _codeFieldController;
  late TextEditingController _sucursalFieldController;
  late TextEditingController _passwordFieldController;
  late String passPattern;
  late RegExp passRegExp;
  late String userPattern;
  late RegExp userRegExp;
  //late String codePattern;
  //late RegExp codeRegExp;
  bool validatePassword = true;
  bool validateUserName = true;
  //bool validateCode = true;
  //String _emptyUserName = '';
  String _emptyPassword = '';
  //String _emptyCode = '';
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
          _updateTextFieldsListener();
        });
      },
    );
  }

  // Inicializar controlador de texto y regex
  _initializeController() {
    _passwordFieldController = TextEditingController();
    _passwordFieldController.addListener(_validatePasswordListener);
    _codeFieldController = TextEditingController();
    _nombreFieldController = TextEditingController();
    _sucursalFieldController = TextEditingController();
    passPattern = r'^(?=.*\d)(?=.*[a-z])(?=.*[A-Z])(?=.*[a-zA-Z]).{8,}$';
    passRegExp = RegExp(passPattern);
    userPattern = r'^(?!.*\.\.)(?!.*\.$)[^\W][\w.]{0,29}$';
    userRegExp = RegExp(userPattern);
  }

  // Cerrar controladores de forma segura
  _closeControllers() {
    _passwordFieldController.dispose();
    _codeFieldController.dispose();
    _nombreFieldController.dispose();
    _sucursalFieldController.dispose();
  }

  //Validar la contraseña ingresada
  void _validatePasswordListener() {
    setState(() {
      if (_passwordFieldController.text.isNotEmpty) {
        validatePassword = passRegExp.hasMatch(_passwordFieldController.text);
      } else {
        validatePassword = true;
      }
    });
  }

  // Actualizar los campos si el codigo del colaborador es encontrado
  void _updateTextFieldsListener() {
    if (!mounted) {
      return;
    }

    for (var element in _collaboratorsList) {
      if (widget.user.collaboratorId.compareTo(element.id) == 0) {
        _codeFieldController.text = element.code.toString();
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

  // Hacer la petición para actualizar un usuario de la aplicación
  _actualizarUsuario(String username, String password, String rol, int id,
      int collaboratorId, BuildContext context) async {
    showDialog(
        context: context,
        builder: (context) {
          return const Center(child: CircularProgressIndicator());
        },
        barrierDismissible: false);

    /// Petición
    final response = await _authAPI.update(username, rol, collaboratorId, id,
        password: password);

    Navigator.of(context).pop();

    /// Alerta si hubó un error
    if (response.statusCode == 404) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          margin: const EdgeInsets.all(15.0),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 2000),
          content: Text(
            'El usuario no se pudo actualizar',
            style: TextStyle(fontSize: 15.sp),
            textAlign: TextAlign.center,
          )));
    }

    // Alerta si hubó un error en la conexión
    if (response.statusCode == 500) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          margin: const EdgeInsets.all(15.0),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 2000),
          content: Text(
            'Error en la conexion',
            style: TextStyle(fontSize: 16.sp),
            textAlign: TextAlign.center,
          )));
    }

    /// Alerta si la pertición fue exitosa
    if (response.statusCode == 200) {
      String body = utf8.decode(response.bodyBytes);
      final jsonData = jsonDecode(body);
      if (jsonData['res'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            margin: const EdgeInsets.all(15.0),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(milliseconds: 2000),
            content: Text(
              '¡Usuario actualizado con exito!',
              style: TextStyle(fontSize: 15.sp),
              textAlign: TextAlign.center,
            )));
        _passwordFieldController.clear();
        _codeFieldController.clear();
        _nombreFieldController.clear();
        _sucursalFieldController.clear();
        _selectedValue = null;
      }
    }
  }

  // Tareas a realizar al inicializar el estado/widget
  @override
  void initState() {
    super.initState();
    _initializeController();
    _loadCollaborators();
    _updateTextFieldsListener();
  }

  // Tareas a realizar al disponer el estado/widget
  @override
  void dispose() {
    _closeControllers();
    super.dispose();
  }

  // Construcción del widget/interfaz gráfica
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

  // Diseño del campo para ingresar datos
  Widget _inputTextField(
    String hintText,
    TextEditingController controller,
    TextInputType textInputType, {
    isEnable = false,
    isPassword = false,
  }) =>
      Container(
        height: mediaSize.height * 0.05,
        decoration: BoxDecoration(
            border: Border.all(
                width: 2,
                color: isPassword
                    ? validatePassword
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

  // Campo que muestra diversas opciones.
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

  // Construcción del cuerpo del widget
  Widget _body() => Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                alignment: Alignment.centerLeft,
                margin: const EdgeInsets.fromLTRB(30, 50, 0, 0),
                child: Text(
                  'Editar usuario',
                  style: TextStyle(
                      color: const Color.fromRGBO(32, 53, 140, 1.0),
                      fontSize: 25.sp,
                      fontWeight: FontWeight.bold),
                ),
              ),
              Container(margin: const EdgeInsets.fromLTRB(0, 0, 0, 30)),
              _inputTextField("Codigo del colaborador (Solo numeros)",
                  _codeFieldController, TextInputType.number),
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
                margin: const EdgeInsets.fromLTRB(0, 15, 0, 0),
              ),
              _inputTextField(
                  "Contraseña (min 8 digitos, 1 letra minuscula, mayuscula, numero)",
                  _passwordFieldController,
                  TextInputType.visiblePassword,
                  isEnable: true,
                  isPassword: true),
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
                  if (_passwordFieldController.text.isEmpty) {
                    _emptyPassword = '"Favor de ingresar una contraseña"';
                  } else {
                    _emptyPassword = '';
                  }

                  if (_selectedValue == null) {
                    _emptyRole = '"Favor de seleccionar un rol"';
                  } else {
                    _emptyRole = '';
                  }

                  if (_passwordFieldController.text.isNotEmpty &&
                      _selectedValue != null) {
                    if (!validateUserName || !validatePassword) {
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
                      _actualizarUsuario(
                          widget.user.name,
                          _passwordFieldController.text,
                          _selectedValue!,
                          widget.user.iD,
                          widget.user.collaboratorId,
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

  //Barra superior de la aplicación
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
