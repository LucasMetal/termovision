// Power off when destroyed, like in the movie (see ref/destroyed shutdown.png): a system failure readout with heavy
// scanlines and several glitches (no flashing), then it compacts to a thick horizontal line, the line shrinks
// horizontally into a point, and the grey point shrinks until it disappears.
// Driven by PowerSystem while in POWERING_OFF_DESTROYED, everything is derived from the elapsed time
class DestroyedShutdown {

  final int SCREEN_MS = 3000; // The failure readout, with glitches
  final int COMPACT_MS = 500; // Squashed into a thick horizontal line
  final int SHRINK_MS = 500; // The line shrinks horizontally into a point
  final int DOT_MS = 700; // The grey point shrinks until it disappears
  final int DURATION_MS = SCREEN_MS + COMPACT_MS + SHRINK_MS + DOT_MS;

  final int GLITCHES = 6; // Glitch bursts during the readout
  final color SCREEN_COLOR = color(216, 90, 60); // The flat orange-red of the readout
  final float LINE_H = 0.02; // Thickness of the line, fraction of the screen height

  PGraphics screen, scanlines;
  int elapsed;
  int[] glitchAt = new int[GLITCHES], glitchMs = new int[GLITCHES];
  float[] glitchPower = new float[GLITCHES];

  DestroyedShutdown() {
    screen = createScreen();
    scanlines = createScanlines(90);
  }

  // A new random set of glitch bursts for each shutdown
  void reset() {
    elapsed = 0;
    for (int i = 0; i < GLITCHES; i++) {
      glitchMs[i] = (int)random(80, 300);
      glitchAt[i] = (int)random(150, SCREEN_MS - glitchMs[i]);
      glitchPower[i] = random(0.4, 1);
    }
  }

  boolean isDone() {
    return elapsed >= DURATION_MS;
  }

  void update(int elapsed) {
    this.elapsed = elapsed;
  }

  void draw() {
    push();
    background(0);

    int e = elapsed;
    if (e < SCREEN_MS) {
      drawGlitched(glitchIntensity(e));
    } else if ((e -= SCREEN_MS) < COMPACT_MS) {
      float h = lerp(height, height * LINE_H, e / (float)COMPACT_MS);
      image(screen, 0, (height - h) / 2, width, h);
    } else if ((e -= COMPACT_MS) < SHRINK_MS) {
      float h = height * LINE_H;
      float w = lerp(width, h, e / (float)SHRINK_MS);
      image(screen, (width - w) / 2, (height - h) / 2, w, h);
    } else if ((e -= SHRINK_MS) < DOT_MS) {
      fill(128);
      noStroke();
      circle(width / 2, height / 2, lerp(height * LINE_H, 0, e / (float)DOT_MS));
    }

    image(scanlines, 0, 0);
    pop();
  }

  // 0 when no glitch burst is active
  float glitchIntensity(int e) {
    for (int i = 0; i < GLITCHES; i++) {
      if (e >= glitchAt[i] && e < glitchAt[i] + glitchMs[i]) return glitchPower[i];
    }
    return 0;
  }

  // The readout, shaken by the glitch: sideways jitter, vertical roll, displaced bands and noise lines. No dropped frames
  void drawGlitched(float intensity) {
    if (intensity == 0) {
      image(screen, 0, 0);
      return;
    }

    int dx = (int)(random(-1, 1) * 40 * intensity);
    int roll = random(1) < 0.5 ? (int)(random(-1, 1) * height * 0.25 * intensity) : 0;
    image(screen, dx, roll);
    if (roll != 0) image(screen, dx, roll > 0 ? roll - height : roll + height);

    int bands = (int)(4 + intensity * 12);
    for (int i = 0; i < bands; i++) {
      int y = (int)random(height);
      int h = (int)random(4, 60);
      image(screen, dx + random(-1, 1) * 300 * intensity, y, width, h, 0, y, width, y + h);
    }

    for (int i = 0; i < (int)(intensity * 8); i++) {
      stroke(HUD_COLOR, random(60, 200));
      strokeWeight(random(1, 3));
      float y = random(height);
      line(0, y, width, y);
    }
  }

  // ---- The failure readout ----

  PGraphics g; // While creating the screen
  PFont font;

  // Traced from ref/destroyed shutdown.png. Positions are fractions of the screen. The labels that aren't readable
  // in the movie are made up, the readouts are columns of zeros like in the movie
  PGraphics createScreen() {
    g = createGraphics(width, height);
    font = createFont("modern-vision.ttf", 40);

    g.beginDraw();
    g.background(SCREEN_COLOR);
    g.fill(HUD_COLOR);
    g.textFont(font);
    g.textSize(height * 0.032);

    // Labels
    label(0.035, 0.035, "CODE:", "-------");
    label(0.21, 0.035, "AMBIENT", "TEMPERATURE", "OVERLOAD");
    label(0.44, 0.035, "SYSTEM FAILURE IN", "ALL MAJOR SECTORS");
    label(0.75, 0.035, "PRE VALUES", "NOMINAL 20");
    label(0.75, 0.155, "FUNCTION LEVELS:");
    label(0.75, 0.215, "- - - - - - - - - - - - - - - -");
    label(0.45, 0.35, "SYSTEMS FAILURE", "MODE LEVELS 555");
    label(0.03, 0.49, "NEUTRAL NET MISFIRE", "AT NODE ADDRESSING");
    label(0.04, 0.925, "IMMINENT SHUTDOWN");
    label(0.71, 0.925, "IMMINENT SHUTDOWN");

    // The subsystems, with their readouts next to them
    String[] subsystems = {"BATT", "HEAV", "HYDR", "GRAV", "PRAM", "PRSM", "TMTY", "REGU", "NERV", "PSYN", "VISN", "VLSN", "OPTC", "CRSH"};
    label(0.45, 0.455, subsystems);
    zeros(0.54, 0.455, subsystems.length, "00000");
    zeros(0.63, 0.455, subsystems.length, "0");
    zeros(0.665, 0.455, subsystems.length, "00");

    // Readout blocks
    zeros(0.035, 0.125, 9, "0000");
    zeros(0.095, 0.125, 9, "0000");
    zeros(0.21, 0.19, 6, "00");
    zeros(0.25, 0.19, 6, "00");
    zeros(0.29, 0.19, 6, "00");
    zeros(0.33, 0.19, 18, "0000");
    zeros(0.47, 0.135, 5, "00000");
    zeros(0.57, 0.135, 5, "00000");
    zeros(0.75, 0.305, 15, "0000");
    zeros(0.83, 0.305, 15, "0000");
    zeros(0.90, 0.305, 15, "0");
    zeros(0.93, 0.305, 15, "00");
    zeros(0.045, 0.62, 5, "0000");
    zeros(0.095, 0.62, 5, "000");
    zeros(0.15, 0.62, 5, "00000");
    zeros(0.25, 0.62, 5, "0");

    g.endDraw();
    g.filter(BLUR, 1.2); // The movie's text is soft and smeared
    return g;
  }

  // Lines of text, the first baseline at (x, y)
  void label(float x, float y, String... lines) {
    for (int i = 0; i < lines.length; i++) g.text(lines[i], x * width, (y + i * 0.036) * height);
  }

  // A readout column: "text" repeated in "rows" rows, the first baseline at (x, y)
  void zeros(float x, float y, int rows, String text) {
    for (int r = 0; r < rows; r++) g.text(text, x * width, (y + r * 0.036) * height);
  }
}
