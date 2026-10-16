class Crosshair{

  final int DETECT_SCALE = 5; // Faces are detected on a frame downscaled by this factor, for speed
  final float EASING_MS = 70; // How fast the crosshair catches up with the detected face (lower is faster)

  int size, tPrev;
  float x, y;
  PGraphics aim;
  OpenCV opencv; // null when following the mouse
  PImage small; // Downscaled copy of the frame for detection, allocated once

  final int LOST_MS = 1500; // Without a face for this long, the target is lost (detection misses some frames)

  // Search mode: without a target it scans the scene in straight lines, each one with its own speed (px per second) and pause
  final float SEARCH_MIN_SPEED = 400, SEARCH_MAX_SPEED = 2000;
  final int SEARCH_MAX_PAUSE_MS = 400;
  float segFromX, segFromY, segToX, segToY;
  int tSegStart, segTravelMs, segPauseMs;

  // Shared with the detection thread. While "detecting" is true only that thread touches "small" and "opencv"
  volatile boolean detecting;
  volatile int targetX, targetY;
  volatile int tLastSeen = -LOST_MS; // millis() of the last detected face
  volatile Rectangle face; // Last detected face at full resolution. A new object each time, so it's never read half updated

  // Target tracking. targetAcquired/targetLost are true only on the frame it changes
  boolean tracking, targetAcquired, targetLost;

  Crosshair (int size, boolean useFaceDetection){
    this.size = size;
    x = targetX = width/2;
    y = targetY = height/2;

    if (useFaceDetection) {
      opencv = new OpenCV(TermoVision.this, width/DETECT_SCALE, height/DETECT_SCALE);
      opencv.loadCascade(OpenCV.CASCADE_FRONTALFACE);
      small = createImage(width/DETECT_SCALE, height/DETECT_SCALE, RGB);
    }

    createAim();
  }
  
  void createAim() {

    float s = size / 200.0; // The reticle was designed at 200 px, everything is scaled from that

    aim = createGraphics (size, size);
    aim.beginDraw();
    aim.background(0);
    aim.smooth();

    // Visible circle
    aim.noStroke();
    aim.fill(255);
    aim.circle(aim.width/2, aim.height/2, size);

    // Remove lines
    aim.stroke(0);
    aim.noFill();
    aim.strokeWeight(5 * s);
    aim.line(40 * s, 100 * s, 160 * s, 100 * s);
    aim.line(100 * s, 110 * s, 100 * s, 90 * s);
    aim.line(100 * s, 0, 100 * s, 40 * s);
    aim.line(100 * s, 200 * s, 100 * s, 160 * s);

    // Remove circle
    aim.strokeWeight(5 * s);
    aim.circle(aim.width/2, aim.height/2, 120 * s);

    aim.endDraw();

    aim.loadPixels();

    color c = color (255, 255, 255, 80); // Semi transparent white

    // Whites to semitransparent, black to invisible
    for (var i=0; i < aim.pixels.length; i++) {
      aim.pixels[i] = (aim.pixels[i] & 0xFF) == 0xFF ? c : 0; // visible / hidden
    }
    aim.updatePixels();
  }
  
  // Follows the first detected face, searches the scene when there's none, or follows the mouse without face detection.
  // Detection is slower than the frame rate, so it runs in a background thread and the crosshair eases towards its last result
  void update(int t, PImage frame){
    if (opencv == null) {
      x = mouseX;
      y = mouseY;
      return;
    }

    if (!detecting) {
      small.copy(frame, 0, 0, frame.width, frame.height, 0, 0, small.width, small.height);
      detecting = true;

      Thread detection = new Thread(this::detect);
      detection.setDaemon(true); // Doesn't keep the sketch alive on exit
      detection.start();
    }

    boolean wasTracking = tracking;
    tracking = t - tLastSeen < LOST_MS;
    targetAcquired = tracking && !wasTracking;
    targetLost = !tracking && wasTracking;

    if (tracking) {
      // Time-based easing, so it moves the same at any frame rate
      float k = 1 - exp(-(t - tPrev) / EASING_MS);
      x = lerp(x, targetX, k);
      y = lerp(y, targetY, k);
    } else {
      search(t);
    }
    tPrev = t;
  }

  // Moves along the current straight segment, starting a new one when it ends (or when the search starts)
  void search(int t){
    if (targetLost || t - tSegStart >= segTravelMs + segPauseMs) newSegment(t);

    float p = constrain((t - tSegStart) / (float)segTravelMs, 0, 1); // Stays at the end during the pause
    x = lerp(segFromX, segToX, p);
    y = lerp(segFromY, segToY, p);
  }

  // From the current position to a random point on screen (keeping the reticle inside), with random speed and pause
  void newSegment(int t){
    segFromX = x;
    segFromY = y;
    segToX = random(size/2, width - size/2);
    segToY = random(size/2, height - size/2);

    float speed = random(SEARCH_MIN_SPEED, SEARCH_MAX_SPEED);
    segTravelMs = max(1, (int)(dist(segFromX, segFromY, segToX, segToY) / speed * 1000));
    segPauseMs = (int)random(SEARCH_MAX_PAUSE_MS);
    tSegStart = t;
  }

  // Runs in the detection thread
  void detect(){
    opencv.loadImage(small);
    Rectangle[] faces = opencv.detect();

    //for (int i = 0; i < faces.length; i++) {
        //println(faces[i].x + "," + faces[i].y);
        //rect(faces[i].x, faces[i].y, faces[i].width, faces[i].height);
    //}

    if (faces.length > 0) {
      Rectangle f = faces[0];
      face = new Rectangle(f.x * DETECT_SCALE, f.y * DETECT_SCALE, f.width * DETECT_SCALE, f.height * DETECT_SCALE);
      targetX = face.x + face.width/2;
      targetY = face.y + face.height/2;
      tLastSeen = millis();
    }

    detecting = false; // Last, hands "small" back to the main thread
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
