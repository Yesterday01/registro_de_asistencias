import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

double translateX(
  double x,
  Size canvasSize,
  Size imageSize,
  InputImageRotation rotation,
  CameraLensDirection cameraLensDirection,
) {
  switch (rotation) {
    case InputImageRotation.rotation90deg:
      return x * canvasSize.width / imageSize.height;
    case InputImageRotation.rotation270deg:
      return canvasSize.width - x * canvasSize.width / imageSize.height;
    case InputImageRotation.rotation180deg || InputImageRotation.rotation0deg:
      switch (cameraLensDirection) {
        case CameraLensDirection.back:
          return x * canvasSize.width / imageSize.width;
        default:
          return canvasSize.width - x * canvasSize.width / imageSize.width;
      }
  }
}

double translateY(
  double y,
  Size canvasSize,
  Size imageSize,
  InputImageRotation rotation,
  CameraLensDirection cameraLensDirection,
) {
  switch (rotation) {
    case InputImageRotation.rotation90deg || InputImageRotation.rotation270deg:
      return y * canvasSize.height / imageSize.width;
    case InputImageRotation.rotation0deg || InputImageRotation.rotation180deg:
      return y * canvasSize.height / imageSize.height;
  }
}
