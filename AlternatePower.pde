// Power on with alternate power, like in the movie (see ref/reroute.png and ref/alternate power.png):
// glitchy video that stabilizes, a circuit board with "REROUTE", the alternate power path drawn on it
// with "ALTERNATE POWER", then everything disappears and the normal video shows.
// Driven by PowerSystem while in POWERING_ALTERNATE_ON, everything is derived from the elapsed time
class AlternatePower {

  final int GLITCH_MS = 1500; // Glitchy video, from heavy to light
  final int REROUTE_AT = 1500; // Board and "REROUTE" appear
  final int PATH_AT = 2600; // The path starts being drawn, "ALTERNATE POWER"
  final int PATH_MS = 400; // Time to draw the whole path
  final int OFF_AT = 4500; // Everything flickers off
  final int DURATION_MS = 5000;

  // Board, in fractions of the screen, with the movie's proportions (about 2:1)
  final float BOARD_X = 0.13, BOARD_Y = 0.10, BOARD_W = 0.74, BOARD_H = 0.64;
  final color BOARD_COLOR = color(225, 95, 85);
  final color TRACE_COLOR = color(140, 25, 25);
  final float TRACE_W = 11, OUTLINE_W = 2.5, LANE_SPACING = 15; // px. Traces are outlined bands, like the copper on a PCB

  // Path in fractions of the board (see ref/alternate power circuit active.png): from the start box at the left edge,
  // steeply down along the bus, along the bottom and up into the target
  final float[][] PATH = {
    {0.10, 0.36}, {0.29, 0.36}, {0.41, 0.735}, {0.52, 0.735}, {0.545, 0.67}, {0.565, 0.625}
  };
  final float[][] START_BOX = {{0.008, 0.33}, {0.10, 0.33}, {0.10, 0.39}, {0.008, 0.39}};
  final float[][] TARGET = {{0.53, 0.625}, {0.575, 0.41}, {0.61, 0.41}, {0.665, 0.625}};

  int bx, by, bw, bh, elapsed;
  PGraphics board, scanlines;
  PVector[] path;
  float pathLength;
  MainMessage message; // Its own instance: the HUD isn't drawn while powering on

  AlternatePower() {
    bx = (int)(width * BOARD_X);
    by = (int)(height * BOARD_Y);
    bw = (int)(width * BOARD_W);
    bh = (int)(height * BOARD_H);

    board = createBoard();
    scanlines = createScanlines();

    path = toScreen(PATH);
    for (int i = 1; i < path.length; i++) pathLength += PVector.dist(path[i - 1], path[i]);

    message = new MainMessage(width / 2, height - 110);
  }

  void reset() {
    elapsed = 0;
    message.clear();
  }

  boolean isDone() {
    return elapsed >= DURATION_MS;
  }

  void update(int elapsed) {
    int prev = this.elapsed;
    this.elapsed = elapsed;

    if (prev < REROUTE_AT && elapsed >= REROUTE_AT) message.start("REROUTE");
    if (prev < PATH_AT && elapsed >= PATH_AT) message.start("ALTERNATE POWER");
    message.update(millis());

    if (isDone()) message.clear();
  }

  void draw(PImage frame) {
    push();

    if (elapsed < GLITCH_MS) {
      drawGlitched(frame, 1 - elapsed / (float)GLITCH_MS);
    } else {
      image(frame, 0, 0, width, height);
    }

    if (isBoardVisible()) {
      tint(255, 240); // Almost opaque, the video shows a little through it
      image(board, bx, by);
      noTint();

      if (elapsed >= PATH_AT) drawPath(constrain((elapsed - PATH_AT) / (float)PATH_MS, 0, 1));

      message.draw();
    }

    image(scanlines, 0, 0);

    pop();
  }

  // Flickers in when it appears and flickers off at the end
  boolean isBoardVisible() {
    if (elapsed < REROUTE_AT) return false;
    if (elapsed < REROUTE_AT + 240) return ((elapsed - REROUTE_AT) / 60) % 2 == 0;
    if (elapsed < OFF_AT) return true;
    return ((elapsed - OFF_AT) / 80) % 2 == 1;
  }

  // Bad signal: dropped frames, vertical roll, displaced horizontal bands and noise lines. Intensity goes from 1 to 0
  void drawGlitched(PImage frame, float intensity) {
    if (random(1) < intensity * 0.15) return; // Dropped frame, stays black

    // Vertical hold slipping: the image rolls, wrapping around
    int roll = random(1) < intensity * 0.3 ? (int)random(-height / 3, height / 3) : 0;
    image(frame, 0, roll, width, height);
    if (roll != 0) image(frame, 0, roll > 0 ? roll - height : roll + height, width, height);

    // Bands of the image shifted sideways (the frame can be smaller than the screen, so the source rows are scaled)
    int bands = (int)(intensity * 14);
    for (int i = 0; i < bands; i++) {
      int y = (int)random(height);
      int h = (int)random(4, 50);
      float dx = random(-1, 1) * 250 * intensity;
      float s = frame.height / (float)height;
      image(frame, dx, y, width, h, 0, (int)(y * s), frame.width, (int)((y + h) * s));
    }

    // Noise lines
    int lines = (int)(intensity * 8);
    for (int i = 0; i < lines; i++) {
      stroke(HUD_COLOR, random(60, 200));
      strokeWeight(random(1, 3));
      float y = random(height);
      line(0, y, width, y);
    }
  }

  // The active path: a glowing white band, drawn up to "progress" (0..1) of its length.
  // The start box lights up first, the target when the path reaches it
  void drawPath(float progress) {
    glow(toScreen(START_BOX), true, 12);

    float remaining = pathLength * progress;
    ArrayList<PVector> drawn = new ArrayList<PVector>();
    drawn.add(path[0]);
    for (int i = 1; i < path.length && remaining > 0; i++) {
      float segment = PVector.dist(path[i - 1], path[i]);
      drawn.add(remaining >= segment ? path[i] : PVector.lerp(path[i - 1], path[i], remaining / segment));
      remaining -= segment;
    }
    glow(drawn.toArray(new PVector[0]), false, 22);

    if (progress >= 1) glow(toScreen(TARGET), true, 14);
  }

  // White line with a soft glow around it
  void glow(PVector[] points, boolean closed, float weight) {
    noFill();
    strokeJoin(MITER);
    float[] weights = {weight * 2.2, weight * 1.5, weight};
    float[] alphas = {40, 80, 255};
    for (int pass = 0; pass < weights.length; pass++) {
      stroke(HUD_COLOR, alphas[pass]);
      strokeWeight(weights[pass]);
      beginShape();
      for (PVector p : points) vertex(p.x, p.y);
      if (closed) endShape(CLOSE); else endShape();
    }
  }

  PVector[] toScreen(float[][] boardPoints) {
    PVector[] points = new PVector[boardPoints.length];
    for (int i = 0; i < boardPoints.length; i++) {
      points[i] = new PVector(bx + boardPoints[i][0] * bw, by + boardPoints[i][1] * bh);
    }
    return points;
  }

  // ---- Board ----

  ArrayList<PVector[]> traces; // Collected first, drawn in two passes so touching traces merge like copper

  // Circuit board traced from the movie (ref/alternate power circuit.png). Not exact, but the same elements in about
  // the same places. Coordinates are fractions of the board
  PGraphics createBoard() {
    traces = new ArrayList<PVector[]>();

    // Left column: traces from the pads going right
    bus(1, 0.00, 0.12, 0.09, 0.12, 0.115, 0.16, 0.20, 0.16, 0.225, 0.12, 0.30, 0.12, 0.33, 0.17, 0.40, 0.17);
    bus(2, 0.09, 0.185, 0.17, 0.185, 0.20, 0.235, 0.31, 0.235, 0.465, 0.70, 0.53, 0.70);
    bus(1, 0.09, 0.265, 0.15, 0.265, 0.175, 0.30, 0.25, 0.30);
    bus(1, 0.11, 0.455, 0.20, 0.455, 0.225, 0.42, 0.27, 0.42);
    bus(1, 0.12, 0.565, 0.18, 0.565, 0.20, 0.62, 0.21, 0.62);
    bus(1, 0.08, 0.69, 0.14, 0.69, 0.165, 0.73, 0.20, 0.73);

    // The bus the alternate power path follows (horizontal, steep down, along the bottom, up to the target)
    bus(3, flatten(PATH));
    bus(2, 0.30, 0.47, 0.37, 0.78, 0.37, 0.82, 0.46, 0.82);

    // Bottom center steps
    bus(1, 0.44, 0.62, 0.49, 0.62, 0.515, 0.57, 0.56, 0.57);
    bus(2, 0.53, 0.80, 0.60, 0.80, 0.625, 0.75, 0.75, 0.75, 0.775, 0.79, 0.90, 0.79);

    // The big V in the center
    bus(2, 0.42, 0.10, 0.45, 0.17, 0.515, 0.56, 0.535, 0.56, 0.60, 0.17, 0.66, 0.17);
    bus(1, 0.47, 0.20, 0.50, 0.38, 0.52, 0.38);

    // Right side: the "S" shaped bundles
    bus(2, 0.66, 0.24, 0.72, 0.24, 0.745, 0.29, 0.745, 0.55, 0.77, 0.60, 0.84, 0.60, 0.865, 0.55, 0.865, 0.40, 0.84, 0.35, 0.80, 0.35);
    bus(2, 0.62, 0.30, 0.68, 0.30, 0.705, 0.35, 0.705, 0.62, 0.735, 0.67, 0.81, 0.67);
    bus(1, 0.68, 0.10, 0.74, 0.10, 0.77, 0.15, 0.77, 0.20);

    // Top right: long trace along the top that drops down the right edge
    bus(1, 0.80, 0.105, 0.97, 0.105, 0.97, 0.15, 0.92, 0.32, 0.92, 0.72, 0.95, 0.78, 0.99, 0.78);
    // Lower right fan
    bus(2, 0.83, 0.56, 0.875, 0.74, 0.90, 0.74);
    bus(1, 0.97, 0.60, 0.97, 0.66, 0.945, 0.74);

    // Filling the rest, the movie's board has traces almost everywhere
    bus(2, 0.29, 0.08, 0.34, 0.08, 0.365, 0.115, 0.395, 0.115);
    bus(2, 0.565, 0.11, 0.59, 0.11, 0.61, 0.085, 0.62, 0.085);
    bus(1, 0.52, 0.40, 0.55, 0.40, 0.575, 0.34, 0.575, 0.25, 0.555, 0.22);
    bus(2, 0.60, 0.23, 0.635, 0.23, 0.655, 0.27, 0.655, 0.36, 0.685, 0.42, 0.685, 0.56);
    bus(2, 0.78, 0.20, 0.86, 0.20, 0.885, 0.24, 0.885, 0.26);
    bus(2, 0.84, 0.445, 0.90, 0.445);
    bus(1, 0.80, 0.52, 0.84, 0.52, 0.86, 0.48);
    bus(2, 0.77, 0.715, 0.83, 0.715, 0.855, 0.67);
    bus(1, 0.12, 0.41, 0.21, 0.41);
    bus(2, 0.12, 0.625, 0.155, 0.66, 0.20, 0.66);
    bus(1, 0.30, 0.18, 0.37, 0.18, 0.39, 0.215, 0.43, 0.215);
    bus(1, 0.225, 0.075, 0.20, 0.035, 0.13, 0.035);
    bus(2, 0.69, 0.08, 0.76, 0.08);
    bus(1, 0.555, 0.67, 0.60, 0.67, 0.62, 0.70, 0.70, 0.70);
    bus(2, 0.40, 0.33, 0.42, 0.33, 0.465, 0.47, 0.465, 0.60);
    bus(1, 0.125, 0.51, 0.22, 0.51);
    bus(1, 0.30, 0.035, 0.38, 0.035);
    bus(1, 0.76, 0.275, 0.82, 0.275);
    bus(2, 0.95, 0.30, 0.95, 0.56, 0.975, 0.60);
    bus(1, 0.89, 0.20, 0.905, 0.24, 0.905, 0.30);
    bus(2, 0.87, 0.86, 0.98, 0.86);
    bus(2, 0.37, 0.935, 0.60, 0.935);
    bus(1, 0.05, 0.035, 0.09, 0.035);
    bus(2, 0.565, 0.60, 0.60, 0.60, 0.625, 0.55, 0.64, 0.55);
    bus(1, 0.21, 0.69, 0.25, 0.69);
    bus(1, 0.80, 0.56, 0.80, 0.62);

    PGraphics g = createGraphics(bw, bh);
    g.beginDraw();
    g.background(BOARD_COLOR);

    // Traces: the dark band first, then the inside with the board color, which leaves the outline
    g.noFill();
    g.strokeJoin(MITER);
    g.strokeCap(SQUARE);
    for (int pass = 0; pass < 2; pass++) {
      g.stroke(pass == 0 ? TRACE_COLOR : BOARD_COLOR);
      g.strokeWeight(pass == 0 ? TRACE_W : TRACE_W - 2 * OUTLINE_W);
      for (PVector[] t : traces) {
        g.beginShape();
        for (PVector p : t) g.vertex(p.x, p.y);
        g.endShape();
      }
    }

    // Pads along the left edge (the third one is the start box of the path)
    pad(g, 0.02, 0.155, 0.09, 0.21, true);
    pad(g, 0.02, 0.24, 0.09, 0.29, true);
    pad(g, 0.008, 0.33, 0.10, 0.39, false);
    pad(g, 0.02, 0.43, 0.11, 0.48, true);
    pad(g, 0.045, 0.53, 0.12, 0.60, true);
    pad(g, 0.01, 0.67, 0.07, 0.71, false);
    pad(g, 0.01, 0.725, 0.08, 0.755, false);
    // Pads along the top
    pad(g, 0.205, 0.06, 0.29, 0.105, false);
    pad(g, 0.395, 0.06, 0.45, 0.12, true);
    pad(g, 0.49, 0.08, 0.565, 0.14, true);
    pad(g, 0.62, 0.06, 0.69, 0.11, false);
    // Pads in the middle and on the right
    pad(g, 0.50, 0.28, 0.55, 0.33, true);
    pad(g, 0.47, 0.675, 0.53, 0.71, true);
    pad(g, 0.485, 0.79, 0.53, 0.815, false);
    pad(g, 0.775, 0.42, 0.84, 0.47, true);
    pad(g, 0.83, 0.26, 0.89, 0.32, true);
    pad(g, 0.82, 0.13, 0.87, 0.165, true);
    pad(g, 0.895, 0.13, 0.935, 0.17, true);
    pad(g, 0.90, 0.895, 0.97, 0.955, true);
    pad(g, 0.33, 0.43, 0.36, 0.47, false);
    pad(g, 0.70, 0.36, 0.73, 0.40, true);

    // Triangles on the left of the bus, and the target (a trapezoid) next to the V
    polygon(g, true, 0.205, 0.575, 0.24, 0.475, 0.28, 0.575);
    polygon(g, true, 0.22, 0.80, 0.255, 0.64, 0.295, 0.80);
    polygon(g, false, flatten(TARGET));
    pad(g, 0.583, 0.495, 0.617, 0.545, true); // Inside the target
    // Trapezoid around "REACTIVATE AT MINIMUM CAPACITY"
    polygon(g, false, 0.045, 0.935, 0.095, 0.80, 0.25, 0.80, 0.265, 0.775, 0.29, 0.80, 0.32, 0.80, 0.355, 0.935);
    // Warning sign next to "FAILURE"
    polygon(g, false, 0.105, 0.095, 0.12, 0.035, 0.135, 0.095);

    // Labels, from the movie
    PFont font = createFont("modern-vision.ttf", 32);
    g.fill(TRACE_COLOR);
    g.textFont(font);
    label(g, "FAILURE", 0.02, 0.10, 0.09);
    label(g, "MAIN CELL FAILURE", 0.78, 0.97, 0.075);
    label(g, "REACTIVATE AT", 0.095, 0.25, 0.86);
    label(g, "MINIMUM CAPACITY", 0.095, 0.30, 0.91);
    label(g, "PRESERVE FORMER COLUMN 4167SERVICE", 0.365, 0.85, 0.87);
    label(g, "MAIN BUFFER INITATION", 0.65, 0.87, 0.925);
    label(g, "NO RESPONSE", 0.65, 0.81, 0.97);

    g.endDraw();
    return g;
  }

  // A bundle of "lanes" parallel traces along a polyline (x, y pairs in board fractions), LANE_SPACING px apart
  void bus(int lanes, float... xy) {
    PVector[] p = new PVector[xy.length / 2];
    for (int i = 0; i < p.length; i++) p[i] = new PVector(xy[2 * i] * bw, xy[2 * i + 1] * bh);

    for (int lane = 0; lane < lanes; lane++) {
      float d = (lane - (lanes - 1) / 2.0) * LANE_SPACING;
      PVector[] t = new PVector[p.length];
      for (int i = 0; i < p.length; i++) t[i] = offset(p, i, d);
      traces.add(t);
    }
  }

  // Point i of the polyline moved "d" px sideways, mitered at the corners so the lanes stay parallel through the turns
  PVector offset(PVector[] p, int i, float d) {
    PVector before = i > 0 ? normal(p[i - 1], p[i]) : null;
    PVector after = i < p.length - 1 ? normal(p[i], p[i + 1]) : null;
    if (before == null) return PVector.add(p[i], PVector.mult(after, d));
    if (after == null) return PVector.add(p[i], PVector.mult(before, d));

    PVector miter = PVector.add(before, after);
    miter.normalize();
    float cosHalf = max(miter.dot(after), 0.3); // Limited, so very sharp corners don't shoot out
    return PVector.add(p[i], PVector.mult(miter, d / cosHalf));
  }

  PVector normal(PVector a, PVector b) {
    PVector t = PVector.sub(b, a);
    t.normalize();
    return new PVector(-t.y, t.x);
  }

  // Component pad: a rectangle with beveled corners, outlined, optionally with a dark block inside
  void pad(PGraphics g, float x1, float y1, float x2, float y2, boolean filled) {
    float l = x1 * bw, t = y1 * bh, r = x2 * bw, b = y2 * bh;
    float bevel = min(r - l, b - t) * 0.3;

    g.noFill();
    g.stroke(TRACE_COLOR);
    g.strokeWeight(OUTLINE_W + 0.5);
    g.beginShape();
    g.vertex(l + bevel, t);
    g.vertex(r - bevel, t);
    g.vertex(r, t + bevel);
    g.vertex(r, b - bevel);
    g.vertex(r - bevel, b);
    g.vertex(l + bevel, b);
    g.vertex(l, b - bevel);
    g.vertex(l, t + bevel);
    g.endShape(CLOSE);

    if (filled) {
      float inset = min(r - l, b - t) * 0.25;
      g.noStroke();
      g.fill(TRACE_COLOR);
      g.rect(l + inset, t + inset, r - l - 2 * inset, b - t - 2 * inset);
    }
  }

  // Closed outlined polygon (x, y pairs in board fractions), optionally with a dark smaller copy inside
  void polygon(PGraphics g, boolean filled, float... xy) {
    float cx = 0, cy = 0;
    int n = xy.length / 2;
    for (int i = 0; i < n; i++) {
      cx += xy[2 * i] / n;
      cy += xy[2 * i + 1] / n;
    }

    g.noFill();
    g.stroke(TRACE_COLOR);
    g.strokeWeight(OUTLINE_W + 0.5);
    g.beginShape();
    for (int i = 0; i < n; i++) g.vertex(xy[2 * i] * bw, xy[2 * i + 1] * bh);
    g.endShape(CLOSE);

    if (filled) {
      g.noStroke();
      g.fill(TRACE_COLOR);
      g.beginShape();
      for (int i = 0; i < n; i++) g.vertex(lerp(cx, xy[2 * i], 0.45) * bw, lerp(cy, xy[2 * i + 1], 0.45) * bh);
      g.endShape(CLOSE);
    }
  }

  // Text scaled to span from x1 to x2 (board fractions), with its baseline at y
  void label(PGraphics g, String text, float x1, float x2, float y) {
    g.textSize(32);
    g.textSize(32 * (x2 - x1) * bw / g.textWidth(text));
    g.text(text, x1 * bw, y * bh);
  }

  float[] flatten(float[][] points) {
    float[] xy = new float[points.length * 2];
    for (int i = 0; i < points.length; i++) {
      xy[2 * i] = points[i][0];
      xy[2 * i + 1] = points[i][1];
    }
    return xy;
  }

  // CRT scanlines over everything during the sequence
  PGraphics createScanlines() {
    PGraphics g = createGraphics(width, height);
    g.beginDraw();
    g.stroke(0, 70);
    g.strokeWeight(1);
    for (int y = 0; y < height; y += 4) g.line(0, y, width, y);
    g.endDraw();
    return g;
  }
}
