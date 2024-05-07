import processing.video.*;
import gab.opencv.*;
import java.awt.*;

// Artifacts ideas:
// Target Acquired (with maximazed pic)
// Port (port open/closed, base for adding an external piece of hardware maybe?)
// Code pages

Capture cam;
OpenCV opencv;
Boolean useCam = true;
Boolean useOpenCV = true;
Rectangle[] faces;
PImage camFrame;
PImage fakeFrame;
int tDemoStart, demoStep = -1;

Crosshair crosshair;
Grid grid;
MainMessage mainMessage;
PowerSystem powerSystem;

void settings() {
  /*
    if (useOpenCV){
   //size(1600, 900);
   size(1366, 768);
   } else size(1920, 1080);
   */
   
  // Uncomment for testing
  //useCam = false;
  //useOpenCV = false;

  size(1920, 1080);
}

void setup() {
  
  // Init cam
  if (useCam) {
    cam = new Capture(this, width, height);

    if (useOpenCV) {
      opencv = new OpenCV(this, width/5, height/5);
      opencv.loadCascade(OpenCV.CASCADE_FRONTALFACE);
    }

    cam.start();
    printArray(Capture.list());
  }
  else
  {
    fakeFrame = loadImage("john.jpg");
    fakeFrame.resize(width, height);
  }
  
  // Init artifacts

  powerSystem = new PowerSystem();
  
  crosshair = new Crosshair(200);

  grid = new Grid(width - 500, 100, 400, 300, 10, useCam && useOpenCV ? 9 : 3);
  grid.show(20);

  mainMessage = new MainMessage (width/3, height - 200);  
  startInitMessages();
  
  println ("Started");
}

void draw() {

  int t = millis();  
  
  if (useCam) {
    camFrame = cam.get();    
  } else {
    camFrame = fakeFrame.copy();
  }
  
  runDemo(t);
  
  powerSystem.draw(t, camFrame);
  if (!powerSystem.isOn()) return;

  grid.update(t);
  grid.draw();

  mainMessage.update();
  mainMessage.draw(t);

  // All this could be inside the crosshair
  if (useCam && useOpenCV) {
    camFrame.resize(width/5, height/5);

    opencv.loadImage(camFrame);
    faces = opencv.detect();
    
    //for (int i = 0; i < faces.length; i++) {
        //println(faces[i].x + "," + faces[i].y);
        //rect(faces[i].x, faces[i].y, faces[i].width, faces[i].height);
    //}
    
    if (faces.length > 0) {
      crosshair.update(
        (int)map(faces[0].x + faces[0].width/2, 0, width/5, 0, width),
        (int)map(faces[0].y + faces[0].height/2, 0, height/5, 0, height));
    }
  } else {
    crosshair.update(mouseX, mouseY);
  }
  crosshair.draw();
  
}

void mousePressed() {
  mainMessage.startRandom();
}

void keyPressed(){
  switch(key){
    case 'd':{
      startDemo();
      break;
    }
    case 'f':{
      mainMessage.enqueue("FUCK YOU, ASSHOLE");
      break;
    }
    case 'g':{
      grid.show(10);
      break;
    }
    case 'i':{
      startInitMessages();
      break;
    }    
    case '1':{
      powerSystem.powerOn();
      break;
    }
    case '2':{
      powerSystem.powerAlternateOn();
      break;
    }
    case '3':{
      powerSystem.powerOff();
      break;
    }
  }
}

void captureEvent(Capture c) {
  c.read();
}

void startInitMessages(){
  mainMessage.enqueue("SYSTEM INTERRUPT");
  mainMessage.enqueue("DIAGNOSTIC");
}

void startDemo(){
  demoStep = 0;
  tDemoStart = 0;
}

void runDemo(int t){
  if (demoStep < 0) return; // no demo running
  
  if (tDemoStart == 0) tDemoStart = t;  
  int dt = (t - tDemoStart) / 1000;  
  
  switch (demoStep){
    case 0: {
      powerSystem.powerOn();
      demoStep++;
      break;
    }
    case 1: {
      if (dt < 3) return;
      startInitMessages();
      demoStep++;
      break;
    }
    case 2: {
      if (dt < 6) return;
      grid.show(10);
      demoStep++;
      break;
    }
    case 3: {
      if (dt < 16) return;
      mainMessage.enqueue("FUCK YOU, ASSHOLE");
      demoStep++;
      break;
    }
    case 4: {
      if (dt < 26) return;
      mainMessage.enqueue("PORT OPEN");
      demoStep++;
      break;
    }
    case 5: {
      if (dt < 27) return;
      grid.show(10);
      demoStep++;
      break;
    }
    case 6: {
      if (dt < 30) return;
      powerSystem.powerOff();
      demoStep++;
      break;
    }
    default:{
      demoStep = -1; // demo end
    }
  }
  
}
