import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class NetworkController {
  final Connectivity _connectivity = Connectivity();
  BuildContext context;
  NetworkController(this.context);
  void onInit() {
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  _updateConnectionStatus(List<ConnectivityResult> connectivityResult) {
    if (connectivityResult.first == ConnectivityResult.none) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          margin: const EdgeInsets.all(15),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(days: 1),
          content: Text(
            'Sin conexión a internet',
            style: TextStyle(fontSize: 16.sp),
          )));
    } else {
      if (ScaffoldMessenger.of(context).mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
      }
    }
  }
}
