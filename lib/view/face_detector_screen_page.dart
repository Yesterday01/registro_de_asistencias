import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:registro_de_asistencias/ML/recognition.dart';
import 'package:registro_de_asistencias/ML/recognizer.dart';
import 'package:registro_de_asistencias/database/user_dao.dart';
import 'package:registro_de_asistencias/models/collaborator.dart';
import 'package:registro_de_asistencias/models/user.dart';
import 'package:registro_de_asistencias/painter/face_detector_painter.dart';
import 'package:registro_de_asistencias/service/auth_api.dart';
import 'package:registro_de_asistencias/service/network_connection.dart';
import 'package:registro_de_asistencias/view/camera_screen_page.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class FaceDetectorScreenPage extends StatefulWidget {
  const FaceDetectorScreenPage({super.key});

  @override
  State<FaceDetectorScreenPage> createState() => _FaceDetectorScreenPageState();
}

class _FaceDetectorScreenPageState extends State<FaceDetectorScreenPage> {
  /*------------------------------------------------------------------------/
  /                                                                         /
  /                 VARIABLES PARA FACE DETECTOR                            /
  /                                                                         /
  /------------------------------------------------------------------------*/

  //Declaración de instancias
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
    ),
  );

  //Variables para el procesamiento de la imagen
  bool _isWorking = false;
  bool _canProcess = true;
  bool _blinkOrSmile = false;
  CustomPaint? _customPaint;
  String _status = '';

  //InternetConexion
  NetworkController? networkController;

  /*------------------------------------------------------------------------/
  /                                                                         /
  /                      VARIABLES PARA FACE MATCH                          /
  /                                                                         /
  /------------------------------------------------------------------------*/

  //API-RESTFUL
  final AuthAPI _authAPI = AuthAPI();
  List<Collaborator> _collaboratorsList = [];
  Collaborator? _collaborator;

  //DB NoSQL para obtener los rostros
  final dao = UserDao();
  List<User> users = [];

  //Variables
  Uint8List? _faceSaved;
  late Size mediaSize;
  var dT = Device.screenType;

  //TestVariables
  late Recognizer _recognizer;
  Recognition? _recognition;

  // Tareas a realizar al inicializar el estado/widget
  @override
  void initState() {
    super.initState();
    _recognizer = Recognizer();
    _loadCollaborators();
  }

  // Tareas a realizar al disponer el estado/widget
  @override
  void dispose() {
    _canProcess = false;
    _faceDetector.close();
    _recognizer.close();
    super.dispose();
  }

  // Construcción del widget/interfaz gráfica
  @override
  Widget build(BuildContext context) {
    networkController = NetworkController(context);
    networkController?.onInit();
    mediaSize = MediaQuery.of(context).size;
    return CameraView(
        customPaint: _customPaint,
        onImage: _processFrame,
        onAttendance: processInputImage,
        title: _status,
        enable: _blinkOrSmile,
        collaborator: _collaborator,
        faceSaved: _faceSaved);
  }

  // Procesa el objeto de tipo InputImage para permitir la captura de la imagen
  // para la toma de asistencia
  Future<void> _processFrame(InputImage inputImage) async {
    if (!_canProcess) return;
    if (_isWorking) return;
    _isWorking = true;
    setState(() {});
    final faces = await _faceDetector.processImage(inputImage);
    if (inputImage.metadata?.size != null &&
        inputImage.metadata?.rotation != null) {
      final painter = FaceDetectorPainter(faces, inputImage.metadata!.size,
          inputImage.metadata!.rotation, CameraLensDirection.front);
      _customPaint = CustomPaint(painter: painter);
      if (faces.isNotEmpty) {
        /// Aplicación de la tecnología Liveness Detection para verificar que
        /// el rostro sea en tiempo real y no una fotografía.
        var smileOrBlink = _smilingAndBlinkingProbability(faces);

        if (smileOrBlink[0] < 0.20 || smileOrBlink[1] > 0.90) {
          _blinkOrSmile = true;
          _status = 'Puede registrar su asistencia';
        } else {
          if (_status.compareTo('Puede registrar su asistencia') != 0) {
            _status = 'Sonría o pestañee';
          }
        }
      } else {
        _blinkOrSmile = false;
        _status = 'Ningún rostro detectado...';
      }
    }
    _isWorking = false;
    if (mounted) {
      setState(() {});
    }
  }

  //Liveness Detection
  List<double> _smilingAndBlinkingProbability(List<Face> faces) {
    double blink = 0.0;
    double smile = 0.0;
    Face face = faces.first;

    // Calcular la probabilidad de que ambos ojos esten abiertos
    if (face.leftEyeOpenProbability != null &&
        face.rightEyeOpenProbability != null) {
      blink =
          (face.leftEyeOpenProbability! + face.rightEyeOpenProbability!) / 2;
    }

    // Calcula la probabilidad de que este sonriendo
    if (face.smilingProbability != null) {
      smile = face.smilingProbability!;
    }

    return [blink, smile];
  }

  /*------------------------------------------------------------------------/
  /                                                                         /
  /                            FACE MATCH                                   /
  /                                                                         /
  /------------------------------------------------------------------------*/

  Future<List<Collaborator>> _getCollaborators() async {
    final response = await _authAPI.fetchCollaborators();

    List<Collaborator> collaborators = [];

    if (response.statusCode != 200) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          margin: EdgeInsets.all(15.0),
          behavior: SnackBarBehavior.floating,
          duration: Duration(milliseconds: 2000),
          content: Text('Error al intentar conectarse con el servidor')));
    }

    if (response.statusCode == 200) {
      String body = utf8.decode(response.bodyBytes);
      final jsonData = jsonDecode(body);
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
      throw Exception('Error de conexión');
    }
  }

  _loadCollaborators() async {
    _getCollaborators().then(
      (value) {
        setState(() {
          _collaboratorsList = value;
        });
      },
    );
  }

  Future<List<User>> _loadUsers() {
    return dao.getAllUsers();
  }

  ///Procesa la fotografía capturada para la asistencia, detectando y
  ///reconociendo el rostro que se encuentre en la fotografía.
  processInputImage(File imge, DateTime date) async {
    _collaborator = null;
    InputImage inputImage = InputImage.fromFile(imge);
    final faces = await _faceDetector.processImage(inputImage);
    var image = await decodeImageFromList(imge.readAsBytesSync());

    /// Si no se encontro un rostro lanza una alerta
    if (faces.isEmpty) {
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: Text('Sin rostro detectado',
                    style: TextStyle(
                        color: const Color.fromRGBO(32, 53, 140, 1.0),
                        fontSize: 20.sp)),
                content: Text(
                  'No se detecto ningún rostro , favor '
                  'de volver a tomar la fotografía',
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
                              MaterialStateProperty.all<Color>(Colors.green)),
                      onPressed: () {
                        setState(() {});
                        Navigator.of(context).pop();
                      },
                      child: Text('OK',
                          style:
                              TextStyle(color: Colors.white, fontSize: 16.sp)))
                ],
                icon: Icon(
                  Icons.info_outline,
                  size: dT == ScreenType.mobile ? 40 : 50,
                  color: const Color.fromRGBO(32, 53, 140, 1.0),
                ),
              ),
          barrierDismissible: false);
    } else {
      /// Si se encuentra un rostro, se toma el primero para realizar el
      /// reconocimiento facial
      Face firstFace = faces.first;
      final Rect boundingBox = firstFace.boundingBox;

      num left = boundingBox.left < 0 ? 0 : boundingBox.left;
      num top = boundingBox.top < 0 ? 0 : boundingBox.top;
      num right =
          boundingBox.right > image.width ? image.width - 1 : boundingBox.right;
      num bottom = boundingBox.bottom > image.height
          ? image.height - 1
          : boundingBox.bottom;
      num width = right - left;
      num height = bottom - top;

      final bytes = imge.readAsBytesSync();
      img.Image? faceImg = img.decodeImage(bytes);
      img.Image croppedFace = img.copyCrop(faceImg!,
          x: left.toInt(),
          y: top.toInt(),
          width: width.toInt(),
          height: height.toInt());

      _recognition = _recognizer.recognize(croppedFace, boundingBox);

      /// Si no se logro reconocer el rostro, muestra la siguiente alerta
      if (_recognition!.code == 0 || _recognition!.distance > 0.8) {
        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: Text('Asistencia del colaborador',
                      style: TextStyle(
                          color: const Color.fromRGBO(32, 53, 140, 1.0),
                          fontSize: 20.sp)),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.image_not_supported_rounded),
                      Text(
                        'Colaborador no encontrado',
                        style: TextStyle(
                            color: const Color.fromRGBO(32, 53, 140, 1.0),
                            fontSize: 16.sp),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  icon: Icon(
                    Icons.date_range,
                    size: dT == ScreenType.mobile ? 40 : 50,
                  ),
                  iconColor: Colors.orange,
                ));
      } else {
        /// Si se encontró, llama el siguiente método para mostrar la alerta
        /// correspondiente
        _findUserInServer(_recognition!.code, _recognition!.facePath, date);
      }
    }
  }

  /// Se busca el colaborador en la lista de todos los colaboradores y se
  /// registra su asistencia.
  _findUserInServer(int findedUser, String faceSaved, DateTime date) async {
    for (var col in _collaboratorsList) {
      if (findedUser == col.code) {
        int h = date.hour > 12 ? date.hour - 12 : date.hour;
        String pmOrAm = date.hour > 11 ? 'PM' : 'AM';
        var fs = File(faceSaved);
        String fechaEntrada = '';
        String horaEntrada = '';
        String horaEntradaFormatted = '';
        String pmOrAmEntrada = '';

        /// Petición para registrar una asistencia
        final response =
            await _authAPI.storeAttendance(col.id, date.toString());
        String body = utf8.decode(response.bodyBytes);
        final jsonData = jsonDecode(body);

        /// Si la respuesta de la petición para almacenar asistencias es de
        /// estatus "1" eso quiere decir que es registro de salida
        if (jsonData['status'] == 1) {
          fechaEntrada = jsonData['fechaE'];
          horaEntrada = jsonData['horaE'];
          var fechaEntradaArray = fechaEntrada.split('/');
          String fechaEntradaFormatted = fechaEntradaArray[2] +
              fechaEntradaArray[1] +
              fechaEntradaArray[0];
          var dateTime = DateTime.parse('$fechaEntradaFormatted $horaEntrada');
          pmOrAmEntrada = dateTime.hour > 11 ? 'PM' : 'AM';
          var hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
          horaEntradaFormatted = '${(hour < 10 ? '0$hour' : hour)}:'
              '${dateTime.minute < 10 ? '0${dateTime.minute}' : dateTime.minute}'
              ':${dateTime.second}';
        }

        setState(() {
          _collaborator = col;
          showDialog(
              context: context,
              builder: (context) => AlertDialog(
                    title: Text('Asistencia del colaborador',
                        style: TextStyle(
                            color: const Color.fromRGBO(32, 53, 140, 1.0),
                            fontSize: 20.sp)),
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image(
                          image: Image.file(fs).image,
                          height: mediaSize.width * 0.2,
                          width: mediaSize.width * 0.2,
                        ),
                        jsonData['status'] == 2
                            ? Text(
                                '\n\n ${jsonData['msj']}',
                                style: TextStyle(
                                    color: Colors.red, fontSize: 16.sp),
                                textAlign: TextAlign.center,
                              )
                            : Text(
                                '\n\n${_collaborator!.first_name} '
                                '${_collaborator!.last_name} ${_collaborator!.last_name_m}'
                                '\n\n ${_collaborator!.occupation}'
                                '\n\n Sucursal: ${_collaborator!.branch}'
                                '${(jsonData['status'] == 1 ? '\n\nFecha de entrada : $fechaEntrada'
                                    '\n\nHora de entrada : $horaEntradaFormatted $pmOrAmEntrada' : '')}'
                                '\n\n Fecha de ${(jsonData['status'] == 0 ? 'entrada' : 'salida')} : '
                                '${(date.day < 10 ? '0${date.day}' : date.day)}/'
                                '${(date.month < 10 ? '0${date.month}' : date.month)}/'
                                '${date.year}'
                                '\n\n Hora de ${(jsonData['status'] == 0 ? 'entrada' : 'salida')} : '
                                '${(h < 10 ? '0$h' : h)}'
                                ':${(date.minute < 10 ? '0${date.minute}' : date.minute)}'
                                ':${(date.second < 10 ? '0${date.second}' : date.second)} $pmOrAm\n',
                                style: TextStyle(
                                    color:
                                        const Color.fromRGBO(32, 53, 140, 1.0),
                                    fontSize: 16.sp),
                                textAlign: TextAlign.center,
                              ),
                      ],
                    ),
                    icon: Icon(
                      Icons.date_range,
                      size: dT == ScreenType.mobile ? 40 : 50,
                    ),
                    iconColor: Colors.orange,
                  ));
        });
      }
    }
  }
}
