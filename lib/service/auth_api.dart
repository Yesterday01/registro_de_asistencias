import 'dart:convert';

import 'package:http/http.dart' as http;

class BaseAPI {
  //static String base = "http://10.0.2.2:8000";
  //static String base = "http://200.1.2.110:80";
  //static String base = "http://127.0.0.1:80";
  static String base = "https://rh.unillantas.com.mx";
  static var api = "$base/api";
  var usersMobilePath = "$api/mobileusers";
  var loginPath = "$api/loginmobileuser";
  var storeMobileUser = "$api/mobileusers";
  var updateMobileUser = "$api/mobileusers/";
  var deleteMobileUser = "$api/mobileusers/";
  var collaboratorsPath = "$api/collaborators";
  var attendance = "$api/attendance";

  Map<String, String> headers = {
    "Content-Type": "application/json; charset=UTF-8",
    "Accept": "application/json"
  };
}

class AuthAPI extends BaseAPI {
  //Peticion para los registros de usuarios de la aplicación móvil
  Future<http.Response> fetchData() async {
    http.Response response = await http
        .get(Uri.parse(super.usersMobilePath), headers: super.headers)
        .timeout(const Duration(seconds: 10));

    return response;
  }

  //Peticion para los registros de los colaboradores
  Future<http.Response> fetchCollaborators() async {
    http.Response response = await http
        .get(Uri.parse(super.collaboratorsPath), headers: super.headers)
        .timeout(const Duration(seconds: 10));

    return response;
  }

  //Petición para almacenar un nuevo usuario para la aplicación móvil
  Future<http.Response> store(
      String name, String password, String rol, int collaboratorId) async {
    var body = jsonEncode({
      'name': name,
      'password': password,
      'rol': rol,
      'collaborator_id': collaboratorId
    });

    http.Response response = await http
        .post(Uri.parse(super.storeMobileUser),
            headers: super.headers, body: body)
        .timeout(const Duration(seconds: 10));

    return response;
  }

  //Petición para actualizar los datos de un usuario para la aplicación móvil
  Future<http.Response> update(
      String name, String rol, int collaboratorId, int id,
      {String password = ''}) async {
    var body = jsonEncode({
      'name': name,
      'password': password,
      'rol': rol,
      'collaborator_id': collaboratorId
    });
    if (password.isEmpty) {
      body = jsonEncode(
          {'name': name, 'rol': rol, 'collaborator_id': collaboratorId});
    }

    http.Response response = await http
        .put(Uri.parse('${super.updateMobileUser}$id'),
            headers: super.headers, body: body)
        .timeout(const Duration(seconds: 10));

    return response;
  }

  //Petición para iniciar sesion en la aplicación móvil
  Future<http.Response> login(String name, String password) async {
    var body = jsonEncode({'name': name, 'password': password});

    http.Response response = await http.post(Uri.parse(super.loginPath),
        headers: super.headers, body: body);

    return response;
  }

  //Petición para eliminar un usuario de la aplicación móvil
  Future<http.Response> delete(int id) async {
    http.Response response = await http.delete(
        Uri.parse('${super.deleteMobileUser}$id'),
        headers: super.headers);

    return response;
  }

  //Petición para registrar las asistencias
  Future<http.Response> storeAttendance(int collaborator, String date) async {
    var body = jsonEncode({
      'collaborator_id': collaborator,
      'date': date,
    });

    http.Response response = await http
        .post(Uri.parse(super.attendance), headers: super.headers, body: body)
        .timeout(const Duration(seconds: 10));
    return response;
  }
}
