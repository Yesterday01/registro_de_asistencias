import 'package:flutter/material.dart';
import 'package:another_flutter_splash_screen/another_flutter_splash_screen.dart';
import 'package:flutter/services.dart';
import 'package:registro_de_asistencias/view/face_detector_screen_page.dart';
import 'package:registro_de_asistencias/view/login_screen_page.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreenPage extends StatefulWidget {
  const SplashScreenPage({super.key});

  @override
  State<SplashScreenPage> createState() => _SplashScreenPageState();
}

class _SplashScreenPageState extends State<SplashScreenPage> {
  SharedPreferences? _prefs;
  var dT = Device.screenType;

  // carga las preferencias y comprueba si hay datos, si si los hay, entonces
  // redirige a la interfaz gráfica para registrar asistencias, sino hay datos,
  // entonces redirige a la interfaz gráfica para el inicio de sesión
  _chargePreferences() async {
    _prefs = await SharedPreferences.getInstance();

    if (_prefs!.getString('user') == null ||
        _prefs!.getString('pass') == null ||
        _prefs!.getString('user')!.isEmpty ||
        _prefs!.getString('pass')!.isEmpty) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => const LoginScreenPage()));
    } else {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const FaceDetectorScreenPage()));
    }
  }

  // Construcción del widget/interfaz gráfica
  @override
  Widget build(BuildContext context) {
    return FlutterSplashScreen.fadeIn(
        backgroundColor: Colors.white,
        onInit: () => debugPrint('On init'),
        onEnd: () => debugPrint('On End'),
        childWidget: SizedBox(
          width: dT == ScreenType.mobile ? 400 : 700,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: dT == ScreenType.mobile ? 20 : 40,
              ),
              Text(
                'Registro de asistencias',
                style: TextStyle(
                    color: const Color.fromRGBO(32, 53, 140, 1.0),
                    fontSize: 23.sp,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(
                height: dT == ScreenType.mobile ? 120 : 160,
              ),
              Image(
                  width: dT == ScreenType.mobile ? 450 : 700,
                  image: Image.asset('assets/logo.png').image),
              SizedBox(
                height: dT == ScreenType.mobile ? 120 : 160,
              ),
              Image(
                width: dT == ScreenType.mobile ? 100 : 200,
                image: Image.asset('assets/michelin.png').image,
              ),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Image(
                  width: dT == ScreenType.mobile ? 100 : 200,
                  image: Image.asset('assets/uniroyal.png').image,
                ),
                Image(
                  width: dT == ScreenType.mobile ? 100 : 200,
                  image: Image.asset('assets/bf.png').image,
                ),
              ]),
            ],
          ),
        ),
        animationDuration: const Duration(milliseconds: 6000),
        onAnimationEnd: () => debugPrint('On fade in end'),
        // Usado para realizar alguna función asincrona, antes de pasar a la
        // siguiente ventana
        asyncNavigationCallback: () async {
          await Future.delayed(const Duration(milliseconds: 6000));
          _chargePreferences();
        });
  }

  // Tareas a realizar al inicializar el estado/widget
  @override
  void initState() {
    // Quitar la barra superior e inferior de la aplicación
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky,
        overlays: []);
    super.initState();
  }
}
