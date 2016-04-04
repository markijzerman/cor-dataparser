class DataPoint {
  String filename;
  float x = Float.MIN_VALUE;
  float y = Float.MIN_VALUE;
  float size = Float.MIN_VALUE;

  DataPoint(String filename) {
    this.filename = filename;
  }
}