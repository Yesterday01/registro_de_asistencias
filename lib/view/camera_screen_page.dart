import 'dart:async';
import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:registro_de_asistencias/models/collaborator.dart';
import 'package:registro_de_asistencias/view/login_screen_page.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CameraView extends StatefulWidget {
  //Declaracion de instancias
  final CustomPaint? customPaint;
  final Function(InputImage) onImage;
  final Function(File, DateTime) onAttendance;
  final String title;
  final bool enable;
  final Collaborator? collaborator;
  final Uint8List? faceSaved;

  const CameraView(
      {super.key,
      required this.customPaint,
      required this.onImage,
      required this.onAttendance,
      required this.title,
      required this.enable,
      required this.collaborator,
      required this.faceSaved});

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  //Declarando instancias
  static List<CameraDescription> _cameras = [];
  CameraController? _cameraController;
  int _cameraIndex = -1;
  //Tamaño y tipo del dispositivo
  late Size mediaSize;
  var dT = Device.screenType;
  //Menu
  SampleItem? selectedItem;
  //Controlador del input de llave
  late TextEditingController _keyController;
  //Eliminar preferencias
  SharedPreferences? _prefs;
  bool loginReturn = false;

  //Get time
  int H = DateTime.now().hour;
  int h =
      DateTime.now().hour > 12 ? DateTime.now().hour - 12 : DateTime.now().hour;
  int m = DateTime.now().minute;
  int s = DateTime.now().second;

  //Get Date
  int year = DateTime.now().year;
  //int month = DateTime.now().month;
  int day = DateTime.now().day;
  var d = DateTime.now();
  String? nameDay;
  String? nameMonth;

  Timer? timer;

  // Inicializa un Timer que realizará una función cada un segundo
  _startTimer() {
    if (!mounted) return;
    nameDay = _obtenerNombreDia(d);
    nameMonth = _obtenerNombreMes(d);
    timer = Timer.periodic(const Duration(seconds: 1), (Timer t) => _getTime());
  }

  //Asigna la hora, minuto, segundo actual, dia de la semana y mes.
  _getTime() {
    setState(() {
      H = DateTime.now().hour;
      h = DateTime.now().hour > 12
          ? DateTime.now().hour - 12
          : DateTime.now().hour;
      m = DateTime.now().minute;
      s = DateTime.now().second;
      year = DateTime.now().year;
      day = DateTime.now().day;
      nameDay = _obtenerNombreDia(d);
      nameMonth = _obtenerNombreMes(d);
    });
  }

  // Cancela el timer de forma segura
  _cancelTimer() {
    timer?.cancel();
    timer = null;
  }

  // Regresa el día de la semana
  String _obtenerNombreDia(DateTime date) {
    final diasSemana = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo'
    ];
    return diasSemana[date.weekday - 1];
  }

  // Regresa el nombre del mes
  String _obtenerNombreMes(DateTime date) {
    final diasSemana = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];
    return diasSemana[date.month - 1];
  }

  // Inicializar controlador de texto
  _initializeController() {
    _keyController = TextEditingController();
  }

  // Carga las preferencias almacenadas en la aplicación móvil
  _chargePreferences() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Obtenemos la cámara frontal disponible
  void _initCamera() async {
    if (_cameras.isEmpty) {
      _cameras = await availableCameras();
    }
    for (var i = 0; i < _cameras.length; i++) {
      if (_cameras[i].lensDirection == CameraLensDirection.front) {
        _cameraIndex = i;
        break;
      }
    }
    if (_cameraIndex != -1) {
      _startCamera();
    }
  }

  //Inicialización del controlador de la camara y configuración de este
  Future _startCamera() async {
    final camera = _cameras[_cameraIndex];

    _cameraController = CameraController(camera, ResolutionPreset.high,
        enableAudio: false, imageFormatGroup: ImageFormatGroup.nv21);

    _cameraController?.initialize().then((_) {
      if (!mounted) {
        return;
      }
      _cameraController?.startImageStream(_processCameraImage);

      setState(() {});
    });
  }

  // Detención del controlador de cámara
  Future _stopCamera() async {
    await _cameraController?.stopImageStream();
    await _cameraController?.dispose();
    _cameraController = null;
  }

  // Pausar el controlador de cámara
  Future _pauseCamera() async {
    await _cameraController?.stopImageStream();
  }

  // Tomar una fotografía
  _takePhoto() async {
    if (!mounted) {
      return;
    }

    var date = DateTime.now();

    showDialog(
        context: context,
        builder: (context) => const Center(
              child: CircularProgressIndicator(),
            ),
        barrierDismissible: false);
    XFile? pictureTaked;
    pictureTaked = await _cameraController?.takePicture();
    debugPrint('Fotografia tomada');
    widget.onAttendance(File(pictureTaked!.path), date);
    Navigator.of(context).pop();
  }

  // Tareas a realizar al inicializar el estado/widget
  @override
  void initState() {
    super.initState();
    _initCamera();
    _startTimer();
    _initializeController();
    _chargePreferences();
  }

  // Tareas a realizar al disponer el estado/widget
  @override
  void dispose() {
    _stopCamera();
    _cancelTimer();
    _keyController.dispose();
    super.dispose();
  }

  // Construcción del widget/interfaz gráfica
  @override
  Widget build(BuildContext context) {
    mediaSize = MediaQuery.of(context).size;
    return Scaffold(
      body: _body(context),
    );
  }

  //Barra superior de la aplicación
  PreferredSizeWidget _appBar(BuildContext context) => AppBar(
        title: AutoSizeText(
          '${(h < 10 ? '0$h' : h)} : ${(m < 10 ? '0$m' : m)} : ${(s < 10 ? '0$s' : s)} ${(H < 12 ? 'AM' : 'PM')}',
          style: TextStyle(
              fontSize: dT == ScreenType.mobile ? 20 : 90,
              color: const Color.fromRGBO(32, 53, 140, 1.0),
              fontWeight: FontWeight.bold),
          minFontSize: 40,
          maxFontSize: 100,
          maxLines: 1,
        ),
        centerTitle: true,
        leading: PopupMenuButton<SampleItem>(
            offset: const Offset(0, 76),
            initialValue: selectedItem,
            icon: const Icon(Icons.menu,
                size: 33, color: Color.fromRGBO(32, 53, 140, 1.0)),
            onSelected: (SampleItem value) async {
              switch (value) {
                case SampleItem.itemOne:
                  selectedItem = value;

                  //SystemNavigator.pop();
                  SystemChannels.platform.invokeMethod('SystemNavigator.pop');
                  //await Future.delayed(const Duration(seconds: 1));
                  _stopCamera();
                  _cancelTimer();
                  break;
                case SampleItem.itemTwo:
                  selectedItem = value;
                  await _closeSession(context);
                  break;
              }
            },
            itemBuilder: (context) => <PopupMenuEntry<SampleItem>>[
                  PopupMenuItem(
                      value: SampleItem.itemOne,
                      child: Text('Salir',
                          style: TextStyle(
                              fontSize: 16.sp,
                              color: const Color.fromRGBO(32, 53, 140, 1.0)))),
                  PopupMenuItem(
                      value: SampleItem.itemTwo,
                      child: Text('Cerrar sesión',
                          style: TextStyle(
                              fontSize: 16.sp,
                              color: const Color.fromRGBO(32, 53, 140, 1.0))))
                ]),
        toolbarHeight: 120,
      );

  // Alerta para cerrar sesión
  _closeSession(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text('Cerrar sesión',
                  style: TextStyle(
                      color: const Color.fromRGBO(32, 53, 140, 1.0),
                      fontSize: 20.sp)),
              content: Text(
                  'Para poder cerrar la sesión es necesario que ingrese el código de salida.',
                  style: TextStyle(
                      color: const Color.fromRGBO(32, 53, 140, 1.0),
                      fontSize: 16.sp)),
              actions: [_inputTextField(_keyController), _enter(context)],
              icon: Icon(
                Icons.security,
                size: dT == ScreenType.mobile ? 40 : 50,
              ),
              iconColor: Colors.green,
            ));
  }

  // Diseño del campo para ingresar datos
  Widget _inputTextField(TextEditingController controller) => Container(
        height: mediaSize.height * 0.06,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20), color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 5),
        margin: const EdgeInsets.symmetric(horizontal: 10),
        child: TextFormField(
          obscureText: true,
          style: TextStyle(fontSize: 15.sp),
          decoration: InputDecoration(
              prefixIconColor: Colors.grey.shade600,
              prefixIcon: const Icon(Icons.logout),
              border: InputBorder.none,
              hintText: 'Ingrese el código',
              hintStyle: TextStyle(
                  fontSize: 18.sp,
                  color: const Color.fromRGBO(32, 53, 140, 0.5))),
          controller: controller,
        ),
      );

  // Método para validar el codigo ingresado para cerrar sesión, y borrar las
  // preferencias almacenadas
  Widget _enter(BuildContext context) => TextButton(
      child: Text('Ingresar código',
          style: TextStyle(
              color: const Color.fromRGBO(32, 53, 140, 1.0), fontSize: 16.sp)),
      onPressed: () async {
        // Validación de la clave/codigo
        if (_keyController.text.compareTo('Un1ll4nt45') == 0) {
          // Preferencias
          _prefs?.setString('user', '');
          _prefs?.setString('pass', '');
          _keyController.clear();
          Navigator.pop(context);
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => const LoginScreenPage()));
          loginReturn = true;
        }
      });

  // Construcción del cuerpo del widget
  Widget _body(BuildContext context) {
    if (_cameras.isEmpty) return Container();
    if (_cameraController == null) return Container();
    if (_cameraController?.value.isInitialized == false) return Container();
    return Scaffold(
      appBar: _appBar(context),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            SizedBox(
              height: mediaSize.height * 0.02,
            ),
            AutoSizeText(
              ' $nameDay, ${(day < 10 ? '0$day' : day)} de $nameMonth , $year',
              style: TextStyle(
                  fontSize: dT == ScreenType.mobile ? 25 : 45,
                  color: const Color.fromRGBO(32, 53, 140, 1.0)),
              minFontSize: 25,
              maxFontSize: 60,
              maxLines: 2,
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: mediaSize.height * 0.05,
            ),
            _cameraController != null
                ? Container(
                    margin: EdgeInsets.symmetric(horizontal: 20.sp),
                    height: mediaSize.width * 0.9,
                    width: mediaSize.width * 0.9,
                    decoration: BoxDecoration(
                        border: Border.all(
                            color: const Color.fromRGBO(32, 53, 140, 1.0),
                            width: 15),
                        borderRadius: BorderRadius.circular(1000)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(1000),
                      child: _cameraController != null
                          ? CameraPreview(_cameraController!,
                              child: widget.customPaint)
                          : const Center(child: CircularProgressIndicator()),
                    ),
                  )
                : const Center(child: CircularProgressIndicator()),
            SizedBox(
              height: mediaSize.height * 0.05,
            ),
            Text(widget.title.isEmpty ? 'Procesando...' : widget.title,
                style: TextStyle(
                    fontSize: dT == ScreenType.mobile ? 25 : 40,
                    color: const Color.fromRGBO(32, 53, 140, 1.0)))
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        color: const Color.fromRGBO(32, 53, 140, 1.0),
        child: Container(
          height: 50.0,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        enableFeedback: true,
        onPressed: /*_takePhoto*/ widget.enable ? _takePhoto : null,
        tooltip: 'Capturar rostro',
        shape: const CircleBorder(),
        backgroundColor: widget.enable
            ? const Color.fromRGBO(32, 53, 140, 1.0)
            : Colors.grey,
        splashColor: widget.enable
            ? const Color.fromRGBO(240, 231, 18, 1.0)
            : Colors.grey,
        heroTag: Object(),
        child: const Icon(
          Icons.circle_outlined,
          color: Colors.white,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  // Procesa la imagen de la cámara
  void _processCameraImage(CameraImage image) {
    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) return;
    widget.onImage(inputImage);
  }

  // Definir orientaciones
  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  // Como parámetro se le pasa la imagen obtenida de la camara y nos regresa
  // un objeto de tipo InputImage, clase proporcionada por google_mlkit_commons
  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_cameraController == null) return null;

    // get image rotation
    // it is used in android to convert the InputImage from Dart to Java: https://github.com/flutter-ml/google_ml_kit_flutter/blob/master/packages/google_mlkit_commons/android/src/main/java/com/google_mlkit_commons/InputImageConverter.java
    // `rotation` is not used in iOS to convert the InputImage from Dart to Obj-C: https://github.com/flutter-ml/google_ml_kit_flutter/blob/master/packages/google_mlkit_commons/ios/Classes/MLKVisionImage%2BFlutterPlugin.m
    // in both platforms `rotation` and `camera.lensDirection` can be used to compensate `x` and `y` coordinates on a canvas: https://github.com/flutter-ml/google_ml_kit_flutter/blob/master/packages/example/lib/vision_detector_views/painters/coordinates_translator.dart
    final camera = _cameras[_cameraIndex];
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;

    var rotationCompensation =
        _orientations[_cameraController!.value.deviceOrientation];
    if (rotationCompensation == null) return null;
    if (camera.lensDirection == CameraLensDirection.front) {
      // front-facing
      rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
    } else {
      // back-facing
      rotationCompensation =
          (sensorOrientation - rotationCompensation + 360) % 360;
    }
    rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    //debugPrint('rotationCompensation: $rotationCompensation');

    if (rotation == null) return null;
    //debugPrint('final rotation: $rotation');
    final format = InputImageFormatValue.fromRawValue(image.format.raw);

    if (format == null || format != InputImageFormat.nv21) return null;

    if (image.planes.length != 1) return null;
    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation, // used only in Android
        format: format, // used only in iOS
        bytesPerRow: plane.bytesPerRow, // used only in iOS
      ),
    );
  }
}

// This is the type used by the popup menu below.
enum SampleItem { itemOne, itemTwo }

class MyClipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) {
    return Rect.fromCenter(
        center: const Offset(0, 0), width: size.width, height: size.width);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) {
    return false;
  }
}
