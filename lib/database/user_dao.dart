import 'package:isar/isar.dart';
import 'package:registro_de_asistencias/database/isar_helper.dart';
import 'package:registro_de_asistencias/models/user.dart';

class UserDao {
  final isar = IsarHelper.instance.isar;

  //Obtener todos los colaboradores registrados
  Future<List<User>> getAllUsers() async {
    return isar.users.where().findAll();
  }

  //Eliminar una colección
  Future<bool> deleteOne(User user) async {
    return isar.writeTxn(() => isar.users.delete(user.id));
  }

  //Actualizar una colección en especifico
  Future<int> upsert(User user) async {
    return isar.writeTxn(() => isar.users.put(user));
  }

  //Mirar todos los cambios a la base de datos en tiempo real
  Stream<List<User>> watchUsers() async* {
    yield* isar.users.where().watch(fireImmediately: true);
  }
}
