import 'dart:convert';
import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:registro_de_asistencias/database/user_dao.dart';
import 'package:registro_de_asistencias/models/collaborator.dart';
import 'package:registro_de_asistencias/models/user.dart';
import 'package:registro_de_asistencias/service/auth_api.dart';
import 'package:registro_de_asistencias/view/face_registrer_screen_page.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class AdminScreenPage extends StatefulWidget {
  const AdminScreenPage({super.key});

  @override
  State<AdminScreenPage> createState() => _AdminScreenPageState();
}

class _AdminScreenPageState extends State<AdminScreenPage> {
  //Acceder a los datos de la base de datos
  late UserDao dao;
  List<User> users = [];
  List<User> filterUsers = [];
  int? sortColumnIndex;
  bool isAscending = false;
  //Tamaño y tipo del dispositivo
  late Size mediaSize;
  var dT = Device.screenType;
  //Controladore del input de busqueda
  late TextEditingController _searchController;
  //Menu
  SampleItem? selectedItem;
  //API-RESTFUL
  final AuthAPI _authAPI = AuthAPI();
  List<Collaborator> _collaboratorsList = [];

  // Accede a la vace de datos y obtiene todos los usuarios
  _initializeDao() {
    dao = UserDao();
    dao.getAllUsers().then((value) => setState(() {
          users = value;
          filterUsers = users;
        }));
  }

  // Inicializar controlador de texto para realizar una función cada vez
  // que cambie el valor de este
  _initializeController() {
    _searchController = TextEditingController();
    _searchController.addListener(_search);
  }

  // Realiza la busqueda de usuarios donde se cumpla la condición del where
  void _search() {
    setState(() {
      try {
        users = filterUsers
            .where((element) => _getNameFromCollaboratorsList(element)
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()))
            .toList();
      } catch (e) {
        debugPrint('$e');
      }
    });
  }

  //Realiza la petición al APIREST para obtener a los colaboradores
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

  // Llama a la función _getCollaborators e inicializa la variable _collaboratorsList
  _loadCollaborators() async {
    _getCollaborators().then(
      (value) {
        setState(() {
          _collaboratorsList = value;
        });
      },
    );
  }

  // Regresa el nombre del colaborador registrado en la aplicacion movil.
  String _getNameFromCollaboratorsList(User user) {
    String name = '';
    for (var collaborator in _collaboratorsList) {
      if (collaborator.code.compareTo(user.idUser!) == 0) {
        name =
            '${collaborator.first_name} ${collaborator.last_name} ${collaborator.last_name_m}';
        return name;
      }
    }
    return name;
  }

  //Barra superior de la aplicación
  PreferredSizeWidget _appBar() => AppBar(
        title: AutoSizeText(
          'Colaboradores',
          style: TextStyle(
              fontSize: dT == ScreenType.mobile ? 20 : 80,
              fontWeight: FontWeight.bold,
              color: const Color.fromRGBO(32, 53, 140, 1.0)),
          maxLines: 1,
          maxFontSize: 100,
          minFontSize: 20,
        ),
        centerTitle: true,
        leading: PopupMenuButton<SampleItem>(
            offset: const Offset(0, 70),
            initialValue: selectedItem,
            icon: const Icon(Icons.menu,
                size: 33, color: Color.fromRGBO(32, 53, 140, 1.0)),
            onSelected: (SampleItem value) async {
              selectedItem = value;
              FocusScope.of(context).unfocus();
              await Future.delayed(const Duration(milliseconds: 1000));
              Navigator.maybePop(context);
            },
            itemBuilder: (context) => <PopupMenuEntry<SampleItem>>[
                  PopupMenuItem(
                      value: SampleItem.itemOne,
                      child: Text('Cerrar sesión',
                          style: TextStyle(fontSize: 16.sp)))
                ]),
        toolbarHeight: 100,
      );

  // Boton para registrar/actualizar y campo de busqueda
  Widget _optionsTop() => Container(
        margin: const EdgeInsets.fromLTRB(30, 20, 30, 30),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: const Color.fromRGBO(240, 231, 18, 1.0)),
        child: Column(
          children: [
            Container(
                margin: const EdgeInsets.fromLTRB(0, 30, 0, 20),
                child: _buttonUpsert('Registrar/Actualizar', () async {
                  Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const FaceRegistrerScreenPage()))
                      .then((value) => setState(() {
                            _initializeDao();
                          }));
                })),
            Container(
                margin: const EdgeInsets.fromLTRB(0, 0, 0, 30),
                child: _inputTextField(_searchController))
          ],
        ),
      );

  // Diseño de botón principal
  Widget _buttonUpsert(String txt, onPress) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 30),
        width: mediaSize.width - 50,
        height: mediaSize.height * 0.06,
        decoration: BoxDecoration(boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.2),
              offset: const Offset(0, 4),
              blurRadius: 2,
              spreadRadius: 2)
        ], borderRadius: BorderRadius.circular(50), color: Colors.white),
        child: TextButton(
            style: ButtonStyle(
                foregroundColor: MaterialStateProperty.all<Color>(
                    const Color.fromRGBO(32, 53, 140, 1.0))),
            onPressed: onPress,
            child: AutoSizeText(
              txt,
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w700),
              maxLines: 1,
              minFontSize: 18,
              maxFontSize: 70,
            )),
      );

  // Diseño del campo para ingresar datos
  Widget _inputTextField(TextEditingController controller) => Container(
        height: mediaSize.height * 0.06,
        width: mediaSize.width,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20), color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 5),
        margin: const EdgeInsets.symmetric(horizontal: 30),
        child: TextFormField(
          maxLines: null,
          expands: true,
          style: TextStyle(fontSize: 15.sp),
          decoration: InputDecoration(
              prefixIconColor: Colors.grey.shade600,
              prefixIcon: const Icon(Icons.search),
              border: InputBorder.none,
              hintText: 'Buscar...',
              hintStyle: TextStyle(
                  fontSize: 18.sp,
                  color: const Color.fromRGBO(32, 53, 140, 0.5))),
          controller: controller,
        ),
      );

  //Construcción de la tabla
  Widget _buildDataTable() {
    final columns = ['Rostro', 'Nombre', 'Acción'];
    return Container(
      margin: const EdgeInsets.fromLTRB(30, 10, 30, 30),
      height: mediaSize.height * 0.7,
      //decoration: BoxDecoration(border: Border.all(color: Colors.black)),
      child: ClipRRect(
          borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30), topRight: Radius.circular(30)),
          child: ListView(children: [
            DataTable(
                dataTextStyle: TextStyle(
                    fontSize: 16.sp,
                    color: const Color.fromRGBO(32, 53, 140, 1.0)),
                headingRowColor: MaterialStateProperty.all<Color>(
                    const Color.fromRGBO(32, 53, 140, 1)),
                sortAscending: isAscending,
                sortColumnIndex: 1,
                showBottomBorder: true,
                dataRowMaxHeight: mediaSize.height * 0.13,
                columns: _getColums(columns),
                rows: _getRows(users))
          ])),
    );
  }

  // Construcción de las columnas de la tabla
  List<DataColumn> _getColums(List<String> columns) => columns
      .map((e) => DataColumn(
          label: Text(
            e,
            style: TextStyle(color: Colors.white, fontSize: 17.sp),
          ),
          onSort: onSort))
      .toList();

  //Construcción de las filas de la tabla
  List<DataRow> _getRows(List<User> users) => users.map((User e) {
        var faceImage = Container(
          height: mediaSize.width * 0.15,
          width: mediaSize.width * 0.15,
          decoration: BoxDecoration(
            image: DecorationImage(
                fit: BoxFit.fill, image: Image.file(File(e.imagePath)).image),
            shape: BoxShape.circle,
          ),
        );

        String name = _getNameFromCollaboratorsList(e);

        var icon = IconButton(
            onPressed: () => _deleteUserAlert(e),
            icon: const Icon(
              Icons.delete,
              color: Colors.red,
            ));
        final cells = [faceImage, name, icon];
        return DataRow(cells: _getCells(cells));
      }).toList();

  //Construcción de las celdas
  List<DataCell> _getCells(List<dynamic> cells) => cells
      .map((e) => DataCell(e is String
          ? Text(e)
          : ClipRRect(borderRadius: BorderRadius.circular(50), child: e)))
      .toList();

  // Alerta para confirmar la eliminacion de un usuario de la aplicación
  void _deleteUserAlert(User user) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text('Eliminar usuario',
                  style: TextStyle(
                      color: const Color.fromRGBO(32, 53, 140, 1.0),
                      fontSize: 20.sp)),
              content: Text(
                '¿Esta seguro que desea eliminar este usuario?',
                style: TextStyle(
                    color: const Color.fromRGBO(32, 53, 140, 1.0),
                    fontSize: 16.sp),
                textAlign: TextAlign.center,
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                TextButton(
                    style: ButtonStyle(
                        fixedSize: MaterialStateProperty.all<Size>(Size(
                            mediaSize.width * 0.2, mediaSize.height * 0.05)),
                        backgroundColor:
                            MaterialStateProperty.all<Color>(Colors.red)),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'No',
                      style: TextStyle(color: Colors.white, fontSize: 16.sp),
                    )),
                TextButton(
                    style: ButtonStyle(
                        fixedSize: MaterialStateProperty.all<Size>(Size(
                            mediaSize.width * 0.2, mediaSize.height * 0.05)),
                        backgroundColor:
                            MaterialStateProperty.all<Color>(Colors.green)),
                    onPressed: () {
                      _deleteUser(user);
                      Navigator.of(context).pop();
                    },
                    child: Text('Si',
                        style: TextStyle(color: Colors.white, fontSize: 16.sp)))
              ],
              icon: Icon(
                Icons.warning_amber,
                size: dT == ScreenType.mobile ? 40 : 50,
              ),
              iconColor: Colors.red,
            ));
  }

  //Método para eliminar un usuario de la aplicación
  _deleteUser(User user) async {
    debugPrint('Usuario eliminado: ${user.idUser}');
    showDialog(
        context: context,
        builder: (context) {
          return const Center(child: CircularProgressIndicator());
        },
        barrierDismissible: false);
    await dao.deleteOne(user);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        margin: const EdgeInsets.all(15.0),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1500),
        content: Text(
          'Registro facial eliminado',
          style: TextStyle(fontSize: 16.sp),
        )));
    _initializeDao();
  }

  // Método para ordenar la tabla
  void onSort(int columnIndex, bool ascending) {
    /// Ordenar por la columna en el index 1
    if (columnIndex == 1) {
      /// Ordenamiento por nombre
      users.sort((a, b) => compareString(ascending,
          _getNameFromCollaboratorsList(a), _getNameFromCollaboratorsList(b)));
    }

    setState(() {
      sortColumnIndex = columnIndex;
      isAscending = ascending;
    });
  }

  //Comparación de String con opcion de modo ascendente o descendente
  int compareString(bool ascending, String value1, String value2) =>
      ascending ? value1.compareTo(value2) : value2.compareTo(value1);

  // Construcción del cuerpo del widget
  Widget _body() => Scaffold(
        appBar: _appBar(),
        body: SingleChildScrollView(
          child: Column(
            children: [_optionsTop(), _buildDataTable()],
          ),
        ),
      );

  // Tareas a realizar al inicializar el estado/widget
  @override
  void initState() {
    super.initState();
    _initializeController();
    _initializeDao();
    _loadCollaborators();
  }

  // Construcción del widget/interfaz gráfica
  @override
  Widget build(BuildContext context) {
    mediaSize = MediaQuery.of(context).size;
    return _body();
  }
}

// This is the type used by the popup menu below.
enum SampleItem { itemOne }
