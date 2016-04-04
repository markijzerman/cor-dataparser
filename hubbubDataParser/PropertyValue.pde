class PropertyValue {
  String filename;
  Property prop;
  double value;

  PropertyValue(String filename, double value, Property prop) {
    this.filename = filename;
    this.value = value;
    this.prop = prop;
  }
}