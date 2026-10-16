class Grid{

  int w, h, step, x, y, speed, tStart, endTime; // speed in px per second
  float xLine, yLine, xOffset, yOffset;
  boolean visible;
  PGraphics g;

  Grid (int x, int y, int w, int h, int step, int speed){
    this.w = w;
    this.h = h;
    this.step = step;
    this.x = x;
    this.y = y;
    this.speed = speed;

    initGrid();
  }

  void initGrid(){
    g = createGraphics(w+1, h+1); // +1 so it shows the border
    g.beginDraw();
    g.stroke(HUD_COLOR);

    // Vertical lines
    for (int i = 0; i <= step; i++ ) {
      float lx = i * w / (float)step;
      g.line(lx, 0, lx, h);
    }

    // Horizontal lines
    for (int i = 0; i <= step; i++ ) {
      float ly = i * h / (float)step;
      g.line(0, ly, w, ly);
    }

    g.endDraw();
  }

  void show(int seconds){
    visible = true;
    tStart = millis();
    endTime = tStart + seconds * 1000;

    // Random start position and direction for each scan line (a full bounce cycle is 2 * size)
    xOffset = random(2 * w);
    yOffset = random(2 * h);
  }

  void hide(){
    visible = false;
  }

  // The scan lines position is derived from the time elapsed since show
  void update(int t){

    if (!visible) return;

    if (t > endTime) {
      visible = false;
      return;
    }

    int e = t - tStart;
    xLine = pingPong(e, w, xOffset);
    yLine = pingPong(e, h, yOffset);
  }

  // Bounces between 0 and max, moving "speed" px per second, starting "offset" px into the cycle
  float pingPong(int e, int max, float offset) {
    float p = (e * speed / 1000.0 + offset) % (2 * max);
    return p < max ? p : 2 * max - p;
  }

  void draw ()
  {
    if (!visible) return;

    image(g, x, y);

    push();
    stroke(HUD_COLOR);
    strokeWeight(5);
    line(x + xLine, y, x + xLine, y + h);
    line(x, y + yLine, x + w, y + yLine);
    pop();
  }
}
