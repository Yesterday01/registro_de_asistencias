import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:registro_de_asistencias/models/user.dart';

class IsarHelper {
  //Patrón Singleton
  static IsarHelper? isarHelper;
  IsarHelper._();

  static IsarHelper get instance => isarHelper ?? IsarHelper._();

  static Isar? _isarDb;

  Isar get isar => _isarDb!;

  Future<void> init() async {
    if (_isarDb != null) {
      return;
    }
    final path = (await getApplicationDocumentsDirectory()).path;
    debugPrint('Ruta de la base de datos: $path');
    _isarDb = await Isar.open([UserSchema], directory: path);
  }
}
