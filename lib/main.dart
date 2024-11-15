import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:registro_de_asistencias/database/isar_helper.dart';
import 'view/splash_screen_page.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  ///Iniciar base de datos local Isar
  await IsarHelper.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    ///Orientación de la aplicación
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    ///ResponsiveSizer permite que la aplicación sea responsiva
    return ResponsiveSizer(builder: (context, orientation, deviceType) {
      return MaterialApp(
        theme: ThemeData(fontFamily: 'K2D'),
        title: 'Flutter Demo',
        home: const SplashScreenPage(),
        debugShowCheckedModeBanner: false,
      );
    });
  }
}
