import org.yaml.snakeyaml.Yaml;
import java.io.FileInputStream;
import java.util.Map;
import java.util.TreeMap;
import java.util.Arrays;
import controlP5.*;
import ddf.minim.*;

Minim minim;
AudioPlayer player;

boolean playFileOnClick;
float size;

ControlP5 cp5;
DropdownList xAxisOptions, yAxisOptions, circleSizeOptions;
Slider scaleSlider;

Property xAxisProperty;
Property yAxisProperty;
Property circleSizeProperty;

TreeMap<String, PropertyGroup> propertyGroups;
HashMap<String, DataPoint> dataPoints;


void setup() {
  cp5 = new ControlP5(this);
  xAxisOptions = cp5.addDropdownList("xAxisOptions")
    .setPosition(width - 320, 10)
    .setSize(150, 200)
    .setOpen(false);

  yAxisOptions = cp5.addDropdownList("yAxisOptions")
    .setPosition(width - 160, 10)
    .setSize(150, 200)
    .setOpen(false);
    
  circleSizeOptions = cp5.addDropdownList("circleSizeOptions")
    .setPosition(width - 320, 30)
    .setSize(150, 200)
    .setOpen(false);
  
  scaleSlider = cp5.addSlider("scaleSlider")
    .setPosition(width - 160, 30)
    .setSize(150, 20)
    .setMin(1.0)
    .setMax(1.0)
    .setValue(1.0);

  propertyGroups = new TreeMap<String, PropertyGroup>(); 
  readSignatureFiles();
  readAnswerFiles();

  for (Map.Entry<String, PropertyGroup> entry : propertyGroups.entrySet()) {
    PropertyGroup group = entry.getValue();

    for (Map.Entry<String, Property> prop : group.properties.entrySet()) {
      Property p = prop.getValue();

      // filter out some errors in the data
      String [] inValid = { "left", "right", "top", "bottom" };
      if (!Arrays.asList(inValid).contains(group.name)) {

        String name = (p.name != "") ? group.name + " - " + p.name : group.name;

        xAxisOptions.addItem(name, p);
        yAxisOptions.addItem(name, p);
        circleSizeOptions.addItem(name, p);
      }
    }
  }

  size(800, 800);
  stroke(0);

  minim = new Minim(this);
}

void draw() {
  background(255);

  stroke(0);
  line(height/2, 0, height/2, width);
  line(0, width/2, height, width/2);

  drawGraph();
}

PropertyGroup getOrCreatePropertyGroup(String name) {
  PropertyGroup pg;

  if (propertyGroups.containsKey(name)) {
    pg = propertyGroups.get(name);
  } else {
    pg = new PropertyGroup(name);
    propertyGroups.put(name, pg);
  }

  return pg;
}

void readSignatureFiles() {
  String signaturePath = dataPath("sound-uploads-signatures");
  File dir = new File(signaturePath);
  String[] list = dir.list();

  for (int i=0; i<list.length; i++) {
    String filename = list[i];
    String path = signaturePath + "/" + filename;
    try {
      InputStream input = new FileInputStream(new File(path));
      Yaml yaml = new Yaml();

      Map<?, ?> data = (Map<?, ?>) yaml.load(input);

      for (Map.Entry<?, ?> entry : data.entrySet()) {

        if (entry.getKey().equals("value")) {

          Map<?, ?> groups = (Map<?, ?>) entry.getValue();

          for (Map.Entry<?, ?> group : groups.entrySet()) {

            String propName = (String) group.getKey();
            PropertyGroup pg = getOrCreatePropertyGroup(propName);

            Map<?, ?> props = (Map<?, ?>) group.getValue();
            for (Map.Entry<?, ?> prop : props.entrySet()) {
              Property p = pg.getProperty((String) prop.getKey());
              double v;
              if (prop.getValue() instanceof Integer) {
                v = (double) (int) prop.getValue();
              } else {
                v = (double) prop.getValue();
              }

              PropertyValue pv = new PropertyValue(filename.replace(" .wav.sig", ""), v, p);
              p.addValue(filename, pv);
            }
          }
        }
      }
    } 
    catch(Exception e) {
      println(e.toString());
    }
  }
}

void readAnswerFiles() {
  String dirpath = dataPath("answer-data");
  File dir = new File(dirpath);
  String[] list = dir.list();

  for (int i=0; i<list.length; i++) {
    String filename = list[i];
    String filepath = dirpath + "/" + filename;
    println("loading " + filename);
    JSONObject json = loadJSONObject(filepath);

    JSONObject q = json.getJSONObject("question");

    PropertyGroup pgLeft = getOrCreatePropertyGroup(q.getString("labelLeft"));
    PropertyGroup pgRight = getOrCreatePropertyGroup(q.getString("labelRight"));
    PropertyGroup pgTop = getOrCreatePropertyGroup(q.getString("labelTop"));
    PropertyGroup pgBottom = getOrCreatePropertyGroup(q.getString("labelBottom"));

    Property pLeft = pgLeft.getProperty("");
    Property pRight = pgRight.getProperty("");
    Property pTop = pgTop.getProperty("");
    Property pBottom = pgBottom.getProperty("");

    JSONArray answers = json.getJSONArray("answers");
    for (int j = 0; j < answers.size(); j++) {
      JSONObject answer = answers.getJSONObject(j);

      if (answer.getString("mode").toLowerCase().equals("sound")) {
        String soundFileName = answer.getString("participant") + "-" + answer.getString("question");
        PropertyValue pvLeft = new PropertyValue(soundFileName, map(answer.getFloat("x"), -1, 1, 1, 0), pLeft);
        pLeft.addValue(soundFileName, pvLeft);

        PropertyValue pvRight = new PropertyValue(soundFileName, map(answer.getFloat("x"), -1, 1, 0, 1), pRight);
        pRight.addValue(soundFileName, pvRight);

        PropertyValue pvTop = new PropertyValue(soundFileName, map(answer.getFloat("y"), -1, 1, 1, 0), pTop);
        pTop.addValue(soundFileName, pvTop);

        PropertyValue pvBottom = new PropertyValue(soundFileName, map(answer.getFloat("y"), -1, 1, 0, 1), pBottom);
        pBottom.addValue(soundFileName, pvBottom);
      }
    }
  }
}

void controlEvent(ControlEvent theEvent) {
  if (theEvent.isGroup()) {
    println("event from group : "+theEvent.getGroup().getValue()+" from "+theEvent.getGroup());
  } else if (theEvent.isController() && !theEvent.getController().getLabel().contains("Slider")) {
    int index = (int) theEvent.getController().getValue();
    DropdownList d = (DropdownList) theEvent.getController(); 
    Property p = (Property) d.getItem(index).get("value");

    if (d.getName().equals("xAxisOptions")) {
      xAxisProperty = p;
    } else if (d.getName().equals("yAxisOptions")) {
      yAxisProperty = p;
    }
      else if (d.getName().equals("circleSizeOptions")) {
      circleSizeProperty = p;
      }
    updateDataPoints();
  }
}

void updateDataPoints() {
  if (xAxisProperty != null && yAxisProperty != null && circleSizeProperty != null) {
    dataPoints = new HashMap<String, DataPoint>();

    float xDiff = abs((float) xAxisProperty.maxValue - (float) xAxisProperty.minValue);
    float yDiff = abs((float) yAxisProperty.maxValue - (float) yAxisProperty.minValue);
    float circleSizeDiff = abs((float) circleSizeProperty.maxValue - (float) circleSizeProperty.minValue);
    float margin = 0.1;

    for (Map.Entry<String, PropertyValue> val : xAxisProperty.values.entrySet()) {
      PropertyValue pv = val.getValue();
      float x = map((float) pv.value, (float) xAxisProperty.minValue - margin * xDiff, (float) xAxisProperty.maxValue + margin * xDiff, 0, width);

      DataPoint d = new DataPoint(pv.filename);
      d.x = x;
      dataPoints.put(pv.filename, d);
    }

    for (Map.Entry<String, PropertyValue> val : yAxisProperty.values.entrySet()) {
      PropertyValue pv = val.getValue();
      float y = map((float) pv.value, (float) yAxisProperty.minValue - margin * yDiff, (float) yAxisProperty.maxValue + margin * yDiff, height, 0);

      if (dataPoints.containsKey(pv.filename)) {
        DataPoint p = dataPoints.get(pv.filename);
        p.y = y;
      }
    }
      
    for (Map.Entry<String, PropertyValue> val : circleSizeProperty.values.entrySet()) {
      PropertyValue pv = val.getValue();
      
      // map sizes differently than position.
      //float size = (float) pv.value;
      float size = map((float) pv.value, (float) circleSizeProperty.minValue - margin * circleSizeDiff, (float) circleSizeProperty.maxValue + margin * circleSizeDiff, 0, 1);
      if (dataPoints.containsKey(pv.filename)) {
        DataPoint p = dataPoints.get(pv.filename);
        p.size = size;
      } 
    }
  } //?? 
}

void drawGraph() {
  if (dataPoints != null) {
    noStroke();
    fill(0);
    colorMode(HSB);

    DataPoint hover = null;
    DataPoint click = null;

    // loop over all the data points
    for (Map.Entry<String, DataPoint> entry : dataPoints.entrySet()) {
      DataPoint d = entry.getValue();
      if (d.x != Float.MIN_VALUE && d.y != Float.MIN_VALUE) {
        float clr = d.size*255;
        fill(clr,255,255);
        ellipse(d.x * scaleSlider.getValue(), d.y, 10, 10);

        // check if cursor is nearby data point
        if (dist(mouseX, mouseY, (float) d.x * scaleSlider.getValue(), (float) d.y) < (d.size*100)-5) {
          hover = d;

          // store this data point for playback if mouse was clicked
          if (playFileOnClick == true) {
            click = d;
          }
        }
      }
    }

    // if there was a data point near the cursor
    if (hover != null) {
      fill(0,0,0);
      textSize(8);
      text(hover.filename, hover.x, hover.y);
    //  text("X " + hover.x, 2, 10);
    }

    // if there was a data point near the cursor AND the mouse was clicked
    // (was put out of the loop to only load/play 1 sample)
    if (click != null) {
      String soundFileName = click.filename + ".wav";
      
      // construct filepath for filename
      String path = dataPath("sounds/" + soundFileName); 
      File f = new File(path);
      
      // println(path);

      // check if file exists
      if (f.exists()) {
        // stop currently playing sample and load new sample
        minim.stop(); 

        player = minim.loadFile(path);
        player.play();
      }


      // reset click state
      playFileOnClick = false;
    }
  }
}

void mouseClicked() {
  playFileOnClick = true;
}