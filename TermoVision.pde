import processing.video.*;
import gab.opencv.*;
import java.awt.*;

// Artifacts ideas:
// Port (port open/closed, base for adding an external piece of hardware maybe?)

Capture cam;
Boolean useCam = true;
Boolean useOpenCV = true;
PImage camFrame;
PImage fakeFrame;
int tDemoStart, demoStep = -1;
boolean wasOn; // Power state on the previous frame, to detect when it turns on

Crosshair crosshair;
Grid grid;
MainMessage mainMessage;
PowerSystem powerSystem;
CodePage codePage;
TargetPanel targetPanel;

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

  // Not P2D: with the camera it's barely faster (OpenCV is the bottleneck) and face tracking gets jumpy,
  // since Capture's pixels[] are only filled through loadPixels() from the GPU buffer
  size(1920, 1080);
}

void setup() {
  
  // Init cam
  if (useCam) {
    cam = new Capture(this, width, height);
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
  
  crosshair = new Crosshair(200, useCam && useOpenCV);

  grid = new Grid(width - 500, 100, 400, 300, 10, 180);

  codePage = new CodePage();

  mainMessage = new MainMessage (width/2, height - 200); // Centered

  targetPanel = new TargetPanel((int)(width * 0.4), (int)(height * 0.5), 60);

  println ("Started");
}

void draw() {

  surface.setTitle("TermoVision - FPS " + nf(frameRate, 0, 1)); // show FPS in title
  
  int t = millis();  
  
  // No per-frame copies: a new full-size image every frame is slow, and very slow in P2D (one new texture per frame)
  camFrame = useCam ? cam : fakeFrame;
  
  runDemo(t);
  
  powerSystem.draw(t, camFrame);

  boolean on = powerSystem.isOn();
  if (on && !wasOn && demoStep < 0) startBootSequence(); // The demo runs its own sequence
  wasOn = on;
  if (!on) return;

  grid.update(t);
  grid.draw();

  codePage.update(t);
  codePage.draw();

  mainMessage.update(t);
  mainMessage.draw();

  crosshair.update(t, camFrame);
  if (crosshair.targetAcquired) targetPanel.show(camFrame, crosshair.face);
  if (crosshair.targetLost) mainMessage.enqueueOnce("SEARCH MODE");

  targetPanel.update(t);
  if (targetPanel.identified) mainMessage.enqueueOnce("IDENT POSITIVE");
  targetPanel.draw();

  crosshair.draw();
}

void mousePressed() {
  if (!powerSystem.isOn()) return; // It would play unseen while off
  mainMessage.startRandom();
}

void keyPressed(){
  // Showing the code page or the grid starts a timer that would run out unseen while off.
  // Queued messages (f, i) are fine, the queue waits
  if (!powerSystem.isOn() && (key == 'c' || key == 'g' || key == 't')) return;

  switch(key){
    case 'c':{
      codePage.showNext();
      break;
    }
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
    case 't':{ // Target panel around the mouse, for testing without face detection
      targetPanel.show(camFrame, new Rectangle(mouseX - 150, mouseY - 150, 300, 300));
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

// Runs each time the power turns on outside the demo. Not in setup, the sketch starts off and the grid would time out unseen
void startBootSequence(){
  grid.show(20);
  startInitMessages();
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
      if (dt < 28) return;
      codePage.show(1); // Page 2 doesn't overlap the main message
      demoStep++;
      break;
    }
    case 7: {
      if (dt < 33) return; // ~4s for the code page to write, flash and hide
      powerSystem.powerOff();
      demoStep++;
      break;
    }
    default:{
      demoStep = -1; // demo end
    }
  }
  
}
