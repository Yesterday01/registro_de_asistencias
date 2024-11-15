import 'package:registro_de_asistencias/database/user_dao.dart';
import 'package:registro_de_asistencias/models/user.dart';

Future<String> saveUser(int id, String path, List<double> embedding) async {
  final dao = UserDao();
  List<User> users = await dao.getAllUsers();
  bool isRegistrer = false;
  String msj = '';

  for (var element in users) {
    if (element.idUser == id) {
      isRegistrer = true;
      User user = User()
        ..id = element.id
        ..idUser = id
        ..imagePath = path
        ..embedding = embedding.join(",");
      dao.upsert(user);
      msj = '¡Datos del colaborador actualizados con exito!';
    }
  }

  if (!isRegistrer) {
    User user = User()
      ..idUser = id
      ..imagePath = path
      ..embedding = embedding.join(",");
    dao.upsert(user);
    msj = '¡Datos del colaborador guardados con exito!';
  }

  return msj;
}
