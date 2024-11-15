import 'dart:convert';
import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:registro_de_asistencias/ML/recognition.dart';
import 'package:registro_de_asistencias/ML/recognizer.dart';
import 'package:registro_de_asistencias/models/collaborator.dart';
import 'package:registro_de_asistencias/service/auth_api.dart';
import 'package:registro_de_asistencias/service/save_data.dart';
import 'package:registro_de_asistencias/service/take_photo.dart';
import 'package:registro_de_asistencias/tools/arrow_icons.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class FaceRegistrerScreenPage extends StatefulWidget {
  const FaceRegistrerScreenPage({super.key});

  @override
  State<FaceRegistrerScreenPage> createState() =>
      _FaceRegistrerScreenPageState();
}

class _FaceRegistrerScreenPageState extends State<FaceRegistrerScreenPage> {
  /*------------------------------------------------------------------------/
  /                                                                         /
  /                     DECLARACION DE VARIABLES                            /
  /                                                                         /
  /------------------------------------------------------------------------*/
  // Declaracion de faceDetector
  late FaceDetector faceDetector;
  List<Face> faces = [];
  // FaceRecognizer
  var image;
  late Recognizer _recognizer;

  // Campos a registrar
  File? _imageToRegistrer;
  String _idUser = "";
  Recognition? _recognition;
  bool _isRegistrer = false;
  // Tamaño y tipo del dispositivo
  late Size mediaSize;
  var dT = Device.screenType;

  // Controladores del inputText
  late TextEditingController _textFieldController;
  String _emptyId = "";
  String _emptyFace = "";

  // API-RESTFUL
  final AuthAPI _authAPI = AuthAPI();
  List<Collaborator> _collaboratorsList = [];

  /*------------------------------------------------------------------------/
  /                                                                         /
  /                                 METODOS                                 /
  /                                                                         /
  /------------------------------------------------------------------------*/

  _initializeFaceDetector() {
    final options =
        FaceDetectorOptions(performanceMode: FaceDetectorMode.accurate);
    faceDetector = FaceDetector(options: options);
  }

  _initializeController() {
    _textFieldController = TextEditingController();
    _textFieldController.addListener(_updateIdUser);
  }

  void _updateIdUser() {
    setState(() {
      _idUser = _textFieldController.text;
      if (_textFieldController.text.isNotEmpty) _emptyId = '';
    });
  }

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

  _loadUserMobile() async {
    _getCollaborators().then(
      (value) {
        setState(() {
          _collaboratorsList = value;
          for (var element in _collaboratorsList) {
            debugPrint(element.toString());
          }
        });
      },
    );
  }

  //Validación de que los campos no esten vacios
  _validarCampos(Recognition? recognition) {
    if (_textFieldController.text.isEmpty) {
      _emptyId = 'Favor de ingresar el codigo del colaborador';
    } else {
      _emptyId = '';
    }

    if (_imageToRegistrer == null) {
      _emptyFace = 'Favor de capturar una foto';
    }

    if (_textFieldController.text.isNotEmpty &&
        _imageToRegistrer != null &&
        _recognition != null) {
      /// Si no estan vacios llama el siguiente metodo para registrar al usuario
      _registrarUsuario(recognition);
    } else {
      /// Alerta si un campo esta vacio o es invalido
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          margin: const EdgeInsets.all(15.0),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 2000),
          content: Text(
            'Campo(s) invalido(s)',
            style: TextStyle(fontSize: 15.sp),
            textAlign: TextAlign.center,
          )));
    }
    setState(() {});
  }

  // Registrar colaborador en la base de datos local
  _registrarUsuario(Recognition? recognition) async {
    String status = '';
    _isRegistrer = false;
    for (var element in _collaboratorsList) {
      if (_textFieldController.text.compareTo(element.code.toString()) == 0) {
        try {
          _isRegistrer = true;
          showDialog(
              context: context,
              builder: (context) {
                return const Center(child: CircularProgressIndicator());
              },
              barrierDismissible: false);

          /// Hace la petición a la base de datos local para registrar al
          /// colaborador
          status = await saveUser(int.parse(_idUser), _imageToRegistrer!.path,
              _recognition!.embeddings);

          Navigator.of(context).pop();

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              margin: const EdgeInsets.all(15.0),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(milliseconds: 2000),
              content: Text(
                status,
                style: TextStyle(fontSize: 15.sp),
                textAlign: TextAlign.center,
              )));
          _imageToRegistrer = null;
          _recognition = null;
          _textFieldController.clear();
        } catch (ex) {
          Navigator.of(context).pop();

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              margin: const EdgeInsets.all(15.0),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(milliseconds: 2000),
              content: Text(
                'No se pudo registrar al colaborador@',
                style: TextStyle(fontSize: 15.sp),
                textAlign: TextAlign.center,
              )));
        }
        return;
      }
    }
    if (!_isRegistrer) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          margin: const EdgeInsets.all(15.0),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 2000),
          content: Text(
            'El codigo de colaborador ingresado no existe',
            style: TextStyle(fontSize: 15.sp),
            textAlign: TextAlign.center,
          )));
    }

    setState(() {});
  }

  // Método llamado para detectar el rostro y realizar la incrustación con el
  // modelo ML, utilizando la clase recognizer.dart
  processInputImage() async {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text('Recortando rostro...',
                  style: TextStyle(
                      color: const Color.fromRGBO(32, 53, 140, 1.0),
                      fontSize: 20.sp)),
              content: SizedBox(
                  height: dT == ScreenType.mobile ? 100 : 200,
                  child: const Center(child: CircularProgressIndicator())),
              icon: Icon(
                Icons.info_outline,
                size: dT == ScreenType.mobile ? 40 : 50,
                color: const Color.fromRGBO(32, 53, 140, 1.0),
              ),
            ),
        barrierDismissible: false);

    InputImage inputImage = InputImage.fromFile(_imageToRegistrer!);

    /// Detección de rostros en la imagen de entrada
    faces = await faceDetector.processImage(inputImage);

    image = await decodeImageFromList(_imageToRegistrer!.readAsBytesSync());

    /// Si no se detecto un rostro lanza una alerta
    if (faces.isEmpty) {
      Navigator.of(context).pop();
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: Text('Sin rostro detectado',
                    style: TextStyle(
                        color: const Color.fromRGBO(32, 53, 140, 1.0),
                        fontSize: 20.sp)),
                content: Text(
                  'No se detecto ningun rostro , favor '
                  'de volver a tomar la fotografia',
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
                        _emptyFace = 'Sin rostro';
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
      setState(() {
        _emptyFace = '';
      });

      /// Obtiene el primer rostro reconocido
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

      final bytes = _imageToRegistrer!.readAsBytesSync();
      img.Image? faceImg = img.decodeImage(bytes);
      img.Image croppedFace = img.copyCrop(faceImg!,
          x: left.toInt(),
          y: top.toInt(),
          width: width.toInt(),
          height: height.toInt());

      /// Realiza la incrustación del rostro
      _recognition = _recognizer.recognize(croppedFace, boundingBox);

      Navigator.of(context).pop();
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeFaceDetector();
    _recognizer = Recognizer();
    _loadUserMobile();
    _initializeController();
  }

  @override
  void dispose() {
    _textFieldController.dispose();
    faceDetector.close();
    _recognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    mediaSize = MediaQuery.of(context).size;
    return Scaffold(
      appBar: _appBar(),
      body: _body(),
      bottomNavigationBar: BottomAppBar(
        elevation: 0,
        child: Image(width: 100, image: Image.asset('assets/logo.png').image),
      ),
    );
  }

  PreferredSizeWidget _appBar() => AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Arrow.arrow_circle_left,
            size: 50,
            color: Color.fromRGBO(240, 231, 18, 1.0),
          ),
        ),
        toolbarHeight: dT == ScreenType.mobile ? 80 : 120,
      );

  Widget _body() => SingleChildScrollView(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: <Widget>[
              AutoSizeText(
                'Registre al colaborador',
                style: TextStyle(
                    fontSize: dT == ScreenType.mobile ? 35 : 60,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromRGBO(32, 53, 140, 1.0)),
                maxLines: 1,
                maxFontSize: 60,
                minFontSize: 20,
              ),
              SizedBox(height: mediaSize.height * 0.01),
              Container(
                  margin:
                      EdgeInsets.fromLTRB(0, 0, 0, mediaSize.height * 0.01)),
              _imageButton(),
              _emptyFace.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 35.0),
                      child: Text(_emptyFace,
                          style: TextStyle(color: Colors.red, fontSize: 15.sp)),
                    )
                  : const SizedBox(),
              Container(
                  margin:
                      EdgeInsets.fromLTRB(0, 0, 0, mediaSize.height * 0.05)),
              _inputTextField(),
              _emptyId.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 35.0),
                      child: Text(_emptyId,
                          style: TextStyle(color: Colors.red, fontSize: 15.sp)),
                    )
                  : const SizedBox(),
              Container(
                  margin:
                      EdgeInsets.fromLTRB(0, mediaSize.height * 0.05, 0, 0)),
              _buttonRegistrer('Registrar', () => _validarCampos(_recognition)),
            ],
          ),
        ),
      );

  Widget _buttonRegistrer(String txt, onPress) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 35),
        width: mediaSize.width * 0.7,
        height: mediaSize.height * 0.07,
        decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  offset: const Offset(0, 4),
                  blurRadius: 2,
                  spreadRadius: 2)
            ],
            borderRadius: BorderRadius.circular(50),
            color: const Color.fromRGBO(32, 53, 140, 1.0)),
        child: TextButton(
            style: ButtonStyle(
                foregroundColor:
                    MaterialStateProperty.all<Color>(Colors.white)),
            onPressed: onPress,
            child: Text(
              txt,
              style: const TextStyle(fontSize: 25),
            )),
      );

  Widget _imageButton() => Material(
        child: InkWell(
          onTap: () async {
            try {
              final pickedFile = await getImage();
              if (pickedFile != null) {
                setState(() {
                  _imageToRegistrer = File(pickedFile.path);
                  _emptyFace = '';
                });
                processInputImage();
              }
            } catch (e) {
              _imageToRegistrer = null;
            }
          },
          child: Container(
              width: mediaSize.width * 0.7,
              height: mediaSize.width * 0.7,
              alignment: Alignment.center,
              decoration: _imageToRegistrer != null
                  ? BoxDecoration(
                      image: DecorationImage(
                          fit: BoxFit.fill,
                          image: Image.file(_imageToRegistrer!).image),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color.fromRGBO(32, 53, 140, 1.0),
                          width: 4))
                  : BoxDecoration(
                      image: DecorationImage(
                          image:
                              Image.asset('assets/user_registrer_02.png').image,
                          scale: 5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color.fromRGBO(32, 53, 140, 1.0),
                          width: 4),
                      color: const Color.fromRGBO(32, 53, 140, 1.0),
                    )),
        ),
      );

  Widget _inputTextField() => Container(
        height: MediaQuery.of(context).size.height * 0.07,
        decoration: BoxDecoration(
            border: Border.all(
                width: 2, color: const Color.fromRGBO(32, 53, 140, 1.0)),
            borderRadius: BorderRadius.circular(15)),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        margin: EdgeInsets.symmetric(horizontal: mediaSize.width * 0.15),
        alignment: Alignment.center,
        child: TextFormField(
          keyboardType: TextInputType.number,
          style: const TextStyle(
              fontSize: 25, color: Color.fromRGBO(32, 53, 140, 1.0)),
          decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'ID del colaborador',
              hintStyle: TextStyle(color: Color.fromRGBO(32, 53, 140, 0.5))),
          controller: _textFieldController,
        ),
      );
}

class FacePainter extends CustomPainter {
  List<Face> faces;
  dynamic imageFile;

  FacePainter({
    required this.faces,
    @required this.imageFile,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // TODO: implement paint
    final Paint paint1 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white;

    if (imageFile != null) {
      canvas.drawImage(imageFile, Offset.zero, Paint());
    }

    if (faces.isNotEmpty) {
      Face face = faces.first;
      canvas.drawRect(face.boundingBox, paint1);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
