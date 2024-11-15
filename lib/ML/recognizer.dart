import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:registro_de_asistencias/ML/recognition.dart';
import 'package:registro_de_asistencias/database/user_dao.dart';
import 'package:registro_de_asistencias/models/user.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class Recognizer {
  late Interpreter interpreter;
  late InterpreterOptions _interpreterOptions;
  static const int WIDTH = 160;
  static const int HEIGHT = 160;
  late UserDao dao;
  List<User> users = [];
  Map<int, Recognition> registered = {};
  String get modelName => 'assets/ml_models/facenet.tflite';

  Recognizer({int? numThreads}) {
    _interpreterOptions = InterpreterOptions();

    if (numThreads != null) {
      _interpreterOptions.threads = numThreads;
    }
    loadModel();
    initDB();
  }

  initDB() async {
    dao = UserDao();
    loadRegisteredFaces();
  }

  void loadRegisteredFaces() async {
    final allRows = await dao.getAllUsers();

    for (final row in allRows) {
      int code = row.idUser!;
      List<double> embd = row.embedding
          .split(',')
          .map((e) => double.parse(e))
          .toList()
          .cast<double>();
      Recognition recognition =
          Recognition(row.idUser!, Rect.zero, embd, 0, row.imagePath);
      registered.putIfAbsent(code, () => recognition);
    }
  }

  Future<void> loadModel() async {
    try {
      interpreter = await Interpreter.fromAsset(modelName);
    } catch (e) {}
  }

  List<dynamic> imageToArray(img.Image inputImage) {
    img.Image resizedImage =
        img.copyResize(inputImage, width: WIDTH, height: HEIGHT);
    List<double> flattenedList = resizedImage.data!
        .expand((channel) => [channel.r, channel.g, channel.b])
        .map((value) => value.toDouble())
        .toList();
    Float32List float32Array = Float32List.fromList(flattenedList);
    int channels = 3;
    int height = HEIGHT;
    int width = WIDTH;
    Float32List reshapedArray = Float32List(1 * height * width * channels);
    for (int c = 0; c < channels; c++) {
      for (int h = 0; h < height; h++) {
        for (int w = 0; w < width; w++) {
          int index = c * height * width + h * width + w;
          reshapedArray[index] =
              (float32Array[c * height * width + h * width + w] - 127.5) /
                  127.5;
        }
      }
    }
    return reshapedArray.reshape([1, 160, 160, 3]);
  }

  Recognition recognize(img.Image image, Rect location) {
    //TODO recortar la cara de la imagen, cambiar su tamaño y convertirla en una matriz flotante
    var input = imageToArray(image);

    //TODO array de salida
    List output = List.filled(1 * 512, 0).reshape([1, 512]);

    //TODO realizar inferencia
    //final runs = DateTime.now().millisecondsSinceEpoch;
    interpreter.run(input, output);
    //final run = DateTime.now().millisecondsSinceEpoch - runs;

    //TODO convertir lista dinámica a lista doble
    List<double> outputArray = output.first.cast<double>();

    //TODO busca la incorporación más cercana en la base de datos y devuelve el par
    Pair pair = findNearest(outputArray);

    //debugPrint('${pair.distance} codde: ${pair.code}');

    return Recognition(
        pair.code, location, outputArray, pair.distance, pair.path);
  }

  findNearest(List<double> emb) {
    Pair pair = Pair(0, -5, 'Unknow');
    for (MapEntry<int, Recognition> item in registered.entries) {
      final int code = item.key;
      List<double> knownEmb = item.value.embeddings;
      String path = item.value.facePath;
      double distance = 0;
      for (int i = 0; i < emb.length; i++) {
        double diff = emb[i] - knownEmb[i];
        distance += diff * diff;
      }
      distance = sqrt(distance);
      if (pair.distance == -5 || distance < pair.distance) {
        pair.distance = distance;
        pair.code = code;
        pair.path = path;
      }
    }
    return pair;
  }

  void close() {
    interpreter.close();
  }
}

class Pair {
  int code;
  double distance;
  String path;
  Pair(this.code, this.distance, this.path);
}
