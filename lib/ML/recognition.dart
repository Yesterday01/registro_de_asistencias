import 'dart:ui';

class Recognition {
  int code;
  Rect location;
  List<double> embeddings;
  double distance;
  String facePath;

  /// Constructs a Category.
  Recognition(
      this.code, this.location, this.embeddings, this.distance, this.facePath);
}
