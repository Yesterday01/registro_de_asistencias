import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:registro_de_asistencias/models/mobile_user.dart';
import 'package:registro_de_asistencias/service/auth_api.dart';
import 'package:registro_de_asistencias/view/edit_users_screen_page.dart';
import 'package:registro_de_asistencias/view/mobile_users_screen_page.dart';
import 'package:registro_de_asistencias/widgets/button.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class SuperAdminScreenPage extends StatefulWidget {
  const SuperAdminScreenPage({super.key});

  @override
  State<SuperAdminScreenPage> createState() => _SuperAdminScreenPageState();
}

class _SuperAdminScreenPageState extends State<SuperAdminScreenPage> {
  //API-RESTFUL
  final AuthAPI _authAPI = AuthAPI();
  List<MobilUser> _mobielUsersList = [];
  List<MobilUser> _filterMobielList = [];
  int? sortColumnIndex;
  bool isAscending = true;
  //Tamaño y tipo del dispositivo
  late Size mediaSize;
  var dT = Device.screenType;
  //Controlador del input de busqueda
  late TextEditingController _searchController;
  //Menu
  SampleItem? selectedItem;

  _initializeController() {
    _searchController = TextEditingController();
    _searchController.addListener(_search);
  }

  void _search() {
    setState(() {
      try {
        if (int.tryParse(_searchController.text) != null) {
          _mobielUsersList = _filterMobielList
              .where((element) => element.collaboratorId
                  .toString()
                  .contains(_searchController.text))
              .toList();
        } else {
          _mobielUsersList = _filterMobielList
              .where((element) =>
                  element.name
                      .toLowerCase()
                      .contains(_searchController.text.toLowerCase()) ||
                  element.rol
                      .toLowerCase()
                      .contains(_searchController.text.toLowerCase()))
              .toList();
          /*if (_mobielUsersList.isEmpty) {
            _mobielUsersList = _filterMobielList
                .where((element) => element.rol
                    .toLowerCase()
                    .contains(_searchController.text.toLowerCase()))
                .toList();
          }*/
        }
      } catch (e) {
        debugPrint('$e');
      }
    });
  }

  Future<List<MobilUser>> _getUsersMobile() async {
    final response = await _authAPI.fetchData();

    List<MobilUser> mobileUsers = [];

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
      // debugPrint('${jsonData[0]}');
      for (var element in jsonData) {
        mobileUsers.add(MobilUser(
            name: element['name'],
            rol: element['rol'],
            collaboratorId: element['collaborator_id'],
            iD: element['id']));
      }
      return mobileUsers;
    } else {
      throw Exception('Fallo la conexion');
    }
  }

  _loadUserMobile() async {
    _getUsersMobile().then(
      (value) {
        setState(() {
          _mobielUsersList = value;
          _filterMobielList = _mobielUsersList;
        });
      },
    );
  }

  PreferredSizeWidget _appBar() => AppBar(
        title: AutoSizeText(
          'Administradores',
          style: TextStyle(
              fontSize: dT == ScreenType.mobile ? 20.sp : 90.sp,
              fontWeight: FontWeight.bold,
              color: const Color.fromRGBO(32, 53, 140, 1.0)),
          maxLines: 1,
          maxFontSize: 50,
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

  Widget _optionsTop() => Container(
        margin: const EdgeInsets.fromLTRB(30, 10, 30, 30),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: const Color.fromRGBO(240, 231, 18, 1.0)),
        child: Column(
          children: [
            Container(
                margin: const EdgeInsets.fromLTRB(0, 30, 0, 20),
                child: Button(text: 'Registrar usuario',onPressed: () {
                      Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const MobileUsersRegistrerScreenPage()))
                          .then((value) => _loadUserMobile());
                    },
                    mediaSize: mediaSize,
                    backgroundColor: Colors.white,
                    textColor: const Color.fromRGBO(32, 53, 140, 1.0)
                )),
            Container(
                margin: const EdgeInsets.fromLTRB(0, 0, 0, 30),
                child: _inputTextField(_searchController))
          ],
        ),
      );

  /* Widget _buttonUpsert(String txt, onPress) => Container(
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
      ); */

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

  Widget _buildDataTable() {
    final columns = ['Id', 'Usuario', 'Rol', 'Accion'];
    return Container(
      margin: const EdgeInsets.fromLTRB(30, 10, 30, 30),
      height: mediaSize.height * 0.8,
      child: ClipRRect(
          borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30), topRight: Radius.circular(30)),
          child: ListView(children: [
            DataTable(
                headingRowColor: MaterialStateProperty.all<Color>(
                    const Color.fromRGBO(32, 53, 140, 1)),
                columnSpacing: 8.sp,
                sortAscending: isAscending,
                sortColumnIndex: sortColumnIndex,
                showBottomBorder: true,
                columns: _getColums(columns),
                rows: _getRows(_mobielUsersList))
          ])),
    );
  }

  List<DataColumn> _getColums(List<String> columns) => columns
      .map((e) => DataColumn(
          label: Text(
            e,
            style: TextStyle(color: Colors.white, fontSize: 16.sp),
          ),
          onSort: onSort))
      .toList();

  List<DataRow> _getRows(List<MobilUser> users) => users.map((MobilUser e) {
        var iconDelete = IconButton(
            onPressed: () => _deleteUserAlert(e),
            icon: const Icon(Icons.delete, color: Colors.red));
        var iconEdit = IconButton(
            onPressed: () => _editUser(e),
            icon: const Icon(Icons.edit, color: Colors.green));
        Row actions = Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [iconDelete, iconEdit],
        );
        final cells = [e.collaboratorId, e.name, e.rol, actions];
        return DataRow(cells: _getCells(cells));
      }).toList();

  List<DataCell> _getCells(List<dynamic> cells) => cells
      .map((e) => DataCell(e is! Row
          ? (dT == ScreenType.mobile
              ? Container(
                  width: 60,
                  child: Text(
                    '$e',
                    style: TextStyle(fontSize: 16.sp),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    softWrap: true,
                  ),
                )
              : Text(
                  '$e',
                  style: TextStyle(fontSize: 16.sp),
                  overflow: TextOverflow.fade,
                  softWrap: false,
                ))
          : e))
      .toList();

  void _deleteUserAlert(MobilUser user) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text('Eliminar usuario',
                  style: TextStyle(
                      color: const Color.fromRGBO(32, 53, 140, 1.0),
                      fontSize: 20.sp)),
              content: Text('¿Esta seguro que desea eliminar este usuario?',
                  style: TextStyle(
                      color: const Color.fromRGBO(32, 53, 140, 1.0),
                      fontSize: 16.sp)),
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
                      _loadUserMobile();
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

  _deleteUser(MobilUser user) async {
    showDialog(
        context: context,
        builder: (context) {
          return const Center(child: CircularProgressIndicator());
        },
        barrierDismissible: false);

    final response = await _authAPI.delete(user.iD);

    Navigator.of(context).pop();

    if (response.statusCode == 200) {
      String body = utf8.decode(response.bodyBytes);
      final jsonData = jsonDecode(body);
      debugPrint('$body  status: ${response.statusCode}');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          margin: const EdgeInsets.all(15.0),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1500),
          content: Text(
            jsonData['mensaje'],
            style: TextStyle(fontSize: 16.sp),
          )));
    }

    debugPrint('Usuario eliminado: ${user.collaboratorId}');
  }

  _editUser(MobilUser userA) async {
    debugPrint('Usuario editado: ${userA.collaboratorId}');
    Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => EditUsersScreenPage(user: userA)))
        .then((value) => _loadUserMobile());
  }

  void onSort(int columnIndex, bool ascending) {
    if (columnIndex == 0) {
      if (_mobielUsersList.isEmpty) return;
      _mobielUsersList.sort(
          (a, b) => compareInt(ascending, a.collaboratorId, b.collaboratorId));
    } else if (columnIndex == 1) {
      _mobielUsersList.sort((a, b) => compareString(ascending, a.name, b.name));
    } else if (columnIndex == 2) {
      _mobielUsersList.sort((a, b) => compareString(ascending, a.rol, b.rol));
    }

    setState(() {
      sortColumnIndex = columnIndex;
      isAscending = ascending;
    });
  }

  int compareInt(bool ascending, int value1, int value2) =>
      ascending ? value1.compareTo(value2) : value2.compareTo(value1);

  int compareString(bool ascending, String value1, String value2) =>
      ascending ? value1.compareTo(value2) : value2.compareTo(value1);

  Widget _body() => Scaffold(
        appBar: _appBar(),
        body: SingleChildScrollView(
          child: Column(
            children: [_optionsTop(), _buildDataTable()],
          ),
        ),
      );

  /*test() async {
    if (!mounted) {
      return;
    } else {
      await Future.delayed(Duration(milliseconds: 5000));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          duration: Duration(days: 1), content: Text('Probando')));
    }
  }*/

  @override
  void initState() {
    super.initState();
    _initializeController();
    _loadUserMobile();
    //test();
  }

  @override
  Widget build(BuildContext context) {
    mediaSize = MediaQuery.of(context).size;
    return _body();
  }
}

// This is the type used by the popup menu below.
enum SampleItem { itemOne }
