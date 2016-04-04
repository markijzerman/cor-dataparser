class PropertyGroup {
  String name;
  HashMap<String, Property> properties;

  PropertyGroup(String name) {
    this.name = name;
    this.properties = new HashMap<String, Property>();
  }

  Property getProperty(String name) {
    if (this.properties.containsKey(name)) {
      return this.properties.get(name);
    } else {
      Property p = new Property(name);
      this.properties.put(name, p);
      return p;
    }
  }
}