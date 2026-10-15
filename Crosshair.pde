class Crosshair{

  final int DETECT_SCALE = 5; // Faces are detected on a frame downscaled by this factor, for speed

  int size, x, y;
  PGraphics aim;
  OpenCV opencv; // null when following the mouse
  PImage small; // Downscaled copy of the frame for detection, allocated once

  Crosshair (int size, boolean useFaceDetection){
    this.size = size;
    x = y = 0;

    if (useFaceDetection) {
      opencv = new OpenCV(TermoVision.this, width/DETECT_SCALE, height/DETECT_SCALE);
      opencv.loadCascade(OpenCV.CASCADE_FRONTALFACE);
      small = createImage(width/DETECT_SCALE, height/DETECT_SCALE, RGB);
    }

    createAim();
  }
  
  void createAim() {

    aim = createGraphics (200, 200);
    aim.beginDraw();
    aim.background(0);
    aim.smooth();

    // Visible circle
    aim.noStroke();
    aim.fill(255);
    aim.circle(aim.width/2, aim.height/2, 200);

    // Remove lines
    aim.stroke(0);
    aim.noFill();
    aim.strokeWeight(5);
    aim.line(40, 100, 160, 100);
    aim.line(100, 110, 100, 90);
    aim.line(100, 0, 100, 40);
    aim.line(100, 200, 100, 160);

    // Remove circle
    aim.strokeWeight(5);
    aim.circle(aim.width/2, aim.height/2, 120);

    aim.endDraw();

    aim.loadPixels();

    color c = color (255, 255, 255, 80); // Semi transparent white

    // Whites to semitransparent, black to invisible
    for (var i=0; i < aim.pixels.length; i++) {
      aim.pixels[i] = (aim.pixels[i] & 0xFF) == 0xFF ? c : 0; // visible / hidden
    }
    aim.updatePixels();
  }
  
  // Follows the first detected face (or stays put if there's none), or the mouse without face detection
  void update(PImage frame){
    if (opencv == null) {
      x = mouseX;
      y = mouseY;
      return;
    }

    small.copy(frame, 0, 0, frame.width, frame.height, 0, 0, small.width, small.height);

    opencv.loadImage(small);
    Rectangle[] faces = opencv.detect();

    //for (int i = 0; i < faces.length; i++) {
        //println(faces[i].x + "," + faces[i].y);
        //rect(faces[i].x, faces[i].y, faces[i].width, faces[i].height);
    //}

    if (faces.length > 0) {
      x = (faces[0].x + faces[0].width/2) * DETECT_SCALE;
      y = (faces[0].y + faces[0].height/2) * DETECT_SCALE;
    }
  }

  void draw(){
    image(aim, x - aim.width/2, y - aim.height/2);    
  }

/*
void createAim2() {
 
 PGraphics mask = createGraphics(200, 200);
 mask.beginDraw();
 
 mask.stroke(255);
 mask.noFill();
 mask.strokeWeight(10);
 mask.line(0, 100, 200, 100);
 mask.line(100, 110, 100, 90);
 
 mask.strokeWeight(5);
 mask.circle(mask.width/2, mask.height/2, 100);
 
 mask.loadPixels();
 
 // Invert
 for (var i=0; i < mask.pixels.length; i++) {
 mask.pixels[i] = (mask.pixels[i] & 0xFF) == 0xFF  ? 0 : 128; // hidden / visible
 }
 mask.updatePixels();
 
 mask.endDraw();
 
 aim = createGraphics (200, 200);
 aim.beginDraw();
 aim.noStroke();
 aim.fill(255);
 aim.circle(aim.width/2, aim.height/2, 200);
 aim.endDraw();
 
 doMask(aim, mask);
 }
 
 void doMask(PImage target, PImage mask) {
 mask.loadPixels();
 target.loadPixels();
 if (mask.pixels.length != target.pixels.length) {
 println("Images are not the same size");
 } else {
 for (int i=0; i<target.pixels.length; i++) {
 if ((target.pixels[i] & 0xff000000) == 0) continue; // Added by me
 target.pixels[i] = ((mask.pixels[i] & 0xff) << 24) | (target.pixels[i] & 0xffffff);
 }
 target.updatePixels();
 }
 }
 */ 
}
