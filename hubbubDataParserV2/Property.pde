class Property {
  String name;
  PropertyGroup group;
  HashMap<String, PropertyValue> values;
  double maxValue;
  double minValue;

  Property(String name) {
    this.name = name; 
    this.values = new HashMap<String, PropertyValue>();
    this.maxValue = Double.MIN_VALUE;
    this.minValue = Double.MAX_VALUE;
  }

  void addValue(String filename, PropertyValue value) {
    if (value.value > this.maxValue) {
      this.maxValue = value.value;
    }
    if (value.value < this.minValue) {
      this.minValue = value.value;
    }
    values.put(filename, value);
  }
}