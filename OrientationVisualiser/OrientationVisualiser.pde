import processing.serial.*;
Serial myPort;

float yaw = 0.0;
float pitch = 0.0;
float roll = 0.0;

float yawOffset = 0.0;

boolean showHelp = false;
boolean showFPS = false;
boolean showUpdateRate = false;
boolean showYPR = false; //show Yaw, Pitch, Roll

int updates = 0;
int updateMillis = 0;
int updatesPerSec = 0;

void setup()
{
  size(600, 500, P3D);

  // if you have only ONE serial port active
  myPort = new Serial(this, Serial.list()[0], 9600); // if you have only ONE serial port active

  // if you know the serial port name
  //myPort = new Serial(this, "COM5:", 9600);        // Windows "COM#:"
  //myPort = new Serial(this, "\\\\.\\COM41", 9600); // Windows, COM10 or higher
  //myPort = new Serial(this, "/dev/ttyACM0", 9600);   // Linux "/dev/ttyACM#"
  //myPort = new Serial(this, "/dev/cu.usbmodem1217321", 9600);  // Mac "/dev/cu.usbmodem######"

  textSize(16); // set text size
  textMode(SHAPE); // set text mode to shape
  //textMode(MODEL); better performance, but ugly
}

void draw()
{
  serialEvent();  // read and parse incoming serial message
  if (millis() - updateMillis >= 1000) {
    updatesPerSec = updates;
    updateMillis = millis();
    updates = 0;
  }
  background(255); // set background to white
  lights();

  translate(width/2, height/2); // set position to centre

  pushMatrix(); // begin object

  float c1 = cos(radians(roll));
  float s1 = sin(radians(roll));
  float c2 = cos(radians(-pitch));
  float s2 = sin(radians(-pitch));
  float c3 = cos(radians((-yaw-yawOffset)%360.0));
  float s3 = sin(radians((-yaw-yawOffset)%360.0));
  applyMatrix( c2*c3, s1*s3+c1*c3*s2, c3*s1*s2-c1*s3, 0,
               -s2, c1*c2, c2*s1, 0,
               c2*s3, c1*s2*s3-c3*s1, c1*c3+s1*s2*s3, 0,
               0, 0, 0, 1);

  drawPropShield();
  //drawArduino();

  popMatrix(); // end of object
  
  drawText(); //after popMatrix so text won't rotate

  // Print values to console
  print(roll);
  print("\t");
  print(-pitch);
  print("\t");
  print((-yaw-yawOffset)%360.0);
  println();
}

void serialEvent()
{
  int newLine = 13; // new line character in ASCII
  String message;
  do {
    message = myPort.readStringUntil(newLine); // read from port until new line
    if (message != null) {
      String[] list = split(trim(message), " ");
      if (list.length >= 4 && list[0].equals("Orientation:")) {
        yaw = float(list[1]); // convert to float yaw
        pitch = float(list[2]); // convert to float pitch
        roll = float(list[3]); // convert to float roll
        updates++;
      }
    }
  } while (message != null);
}

void drawArduino()
{
  /* function contains shape(s) that are rotated with the IMU */
  stroke(0, 90, 90); // set outline colour to darker teal
  fill(0, 130, 130); // set fill colour to lighter teal
  box(300, 10, 200); // draw Arduino board base shape

  stroke(0); // set outline colour to black
  fill(80); // set fill colour to dark grey

  translate(60, -10, 90); // set position to edge of Arduino box
  box(170, 20, 10); // draw pin header as box

  translate(-20, 0, -180); // set position to other edge of Arduino box
  box(210, 20, 10); // draw other pin header as box
}

void keyPressed()
{
  //Only act on characters A-Z, a-z (ASCII 65-90, 97-122)
  if((key >= 'A' && key <= 'Z') || (key >= 'a' && key <= 'z')) {
    int keyAscii = key;
    //convert to lowercase
    if (keyAscii <= 'Z') {
      keyAscii += 32;
    }
    switch (keyAscii) {
      case 'h':
        showHelp = !showHelp;
        break;
      case 'f':
        showFPS = !showFPS;
        break;
      case 'u':
        showUpdateRate = !showUpdateRate;
        break;
      case 'n':
        showYPR = !showYPR;
        break;
      case 'z':
        yawOffset += 18.0f;
        yawOffset = yawOffset % 360.f;
        break;
      case 'x':
        yawOffset -= 18.0f;
        yawOffset = yawOffset % 360.f; //java's modulo is IEEE 754 compatible
        // and will return positive remainder: -5 % 360 = 355
        // https://docs.oracle.com/javase/specs/jls/se7/html/jls-15.html#jls-15.17.3
        break;
    }
  }
}

void drawText() {
  if (showHelp) {
    
    //white-transparent background
    translate(0,0,129);
    fill(255,192);
    rectMode(CENTER);
    rect(0,0,500,400);
    translate(0,0,-129); //back to origin
    
    //text
    fill(0);
    text("press h to show/hide help", -190, -80, 130);
    text("press f to show/hide fps", -190,-40,130);
    text("press u to show/hide orientation update rate", -190, 0, 130);
    text("press n to show/hide yaw, pitch and roll numbers", -190, 40, 130);
    text("press z or x to adjust yaw to match", -190, 80, 130);
    text("your viewing angle", -190, 100, 130);
  }
  
  if (showFPS) {
    text("FPS:",-190,160,130);
    text((int)frameRate, -150,160,130);
  }
  
  if (showUpdateRate) {
    text("Updates per sec:",20,160,130);
    text(updatesPerSec,160,160,130);
  }
  
  if (showYPR) {
    text("Yaw",90,-150,130);
    text(nfp(yaw,3,2),130,-150,130);
    text("Pitch",90,-130,130);
    text(nfp(-pitch,3,2),130,-130,130);
    text("Roll",90,-110,130);
    text(nfp(roll,3,2),130,-110,130);
  }
  
}

void drawPropShield()
{
  // 3D art by Benjamin Rheinland
  stroke(0); // black outline
  fill(0, 128, 0); // fill color PCB green
  box(190, 6, 70); // PCB base shape

  fill(255, 215, 0); // gold color
  noStroke();

  //draw 14 contacts on Y- side
  translate(65, 0, 30);
  for (int i=0; i<14; i++) {
    sphere(4.5); // draw gold contacts
    translate(-10, 0, 0); // set new position
  }

  //draw 14 contacts on Y+ side
  translate(10, 0, -60);
  for (int i=0; i<14; i++) {
    sphere(4.5); // draw gold contacts
    translate(10, 0, 0); // set position
  }

  //draw 5 contacts on X+ side (DAC, 3v3, gnd)
  translate(-10,0,10);
  for (int i=0; i<5; i++) {
    sphere(4.5);
    translate(0,0,10);
  }

  //draw 4 contacts on X+ side (G C D 5)
  translate(25,0,-15);
  for (int i=0; i<4; i++) {
    sphere(4.5);
    translate(0,0,-10);
  }

  //draw 4 contacts on X- side (5V - + GND)
  translate(-180,0,10);
  for (int i=0; i<4; i++) {
    sphere(4.5);
    translate(0,0,10);
  }

  //draw audio amp IC
  stroke(128);
  fill(24);    //Epoxy color
  translate(30,-6,-25);
  box(13,6,13);

  //draw pressure sensor IC
  stroke(64);
  translate(32,0,0);
  fill(192);
  box(10,6,18);

  //draw gyroscope IC
  stroke(128);
  translate(27,0,0);
  fill(24);
  box(16,6,16);

  //draw flash memory IC
  translate(40,0,-15);
  box(20,6,20);

  //draw accelerometer/magnetometer IC
  translate(-5,0,25);
  box(12,6,12);

  //draw 5V level shifter ICs
  translate(42.5,2,0);
  box(6,4,8);
  translate(0,0,-20);
  box(6,4,8);
  
  //reset position to zero
  translate(-76.5,4,10);
}