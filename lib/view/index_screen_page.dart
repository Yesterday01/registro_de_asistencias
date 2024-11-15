import 'package:flutter/material.dart';
import 'package:registro_de_asistencias/view/admin_screen_page.dart';
import 'package:registro_de_asistencias/view/face_detector_screen_page.dart';

class IndexScreenPage extends StatefulWidget {
  const IndexScreenPage({super.key});

  @override
  State<IndexScreenPage> createState() => _IndexScreenPageState();
}

class _IndexScreenPageState extends State<IndexScreenPage> {
  Widget _createButton01(String txt, VoidCallback onPress) => Container(
        width: 350,
        height: 70,
        decoration: BoxDecoration(
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

  Widget _createButton02(String txt, Function() onPress) => Container(
        width: 350,
        height: 70,
        decoration: BoxDecoration(
            border: Border.all(
                color: const Color.fromRGBO(32, 53, 140, 1.0), width: 4),
            borderRadius: BorderRadius.circular(50),
            color: Colors.white),
        child: TextButton(
            style: ButtonStyle(
                foregroundColor: MaterialStateProperty.all<Color>(
                    const Color.fromRGBO(32, 53, 140, 1.0))),
            onPressed: onPress,
            child: Text(
              txt,
              style: const TextStyle(fontSize: 25),
            )),
      );

  Widget _body() => Container(
        margin: const EdgeInsets.fromLTRB(0, 10, 0, 0),
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Spacer(),
            const Text(
              '¡Bienvenido de nuevo!',
              style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color.fromRGBO(32, 53, 140, 1.0)),
            ),
            const Text(
              '¿Qué desea hacer?',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.normal,
                  color: Color.fromRGBO(32, 53, 140, 1.0)),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(0, 0, 0, 30),
            ),
            Image(
              width: 250,
              image: Image.asset(
                'assets/Landscape.jpg',
              ).image,
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(0, 0, 0, 50),
            ),
            _createButton01(
                'Registrar asistencia',
                () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const FaceDetectorScreenPage()))),
            Container(
              margin: const EdgeInsets.fromLTRB(0, 0, 0, 30),
            ),
            _createButton02(
                'Registrar usuario',
                () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AdminScreenPage()))),
            Container(
              margin: const EdgeInsets.fromLTRB(0, 0, 0, 30),
            ),
            _createButton02(
                'Registrar administradores',
                () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AdminScreenPage()))),
            const Spacer(),
            Image(
              width: 100,
              image: Image.asset(
                'assets/logo.png',
              ).image,
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _body(),
    );
  }
}
