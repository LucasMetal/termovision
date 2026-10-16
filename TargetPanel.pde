// "TARGET ACQUIRED" panel from the movie (see ref/target acquired.png): a pixelated close-up of the face
// that gets enhanced a few times, then the label on top of it.
// The face is usually big and close to the camera, so the panel goes on the side opposite to it instead of the center
class TargetPanel {

  final int[] BLOCKS = {48, 24, 12, 1}; // Pixel size of each enhancement step, 1 is the final sharp image
  final int STEP_MS = 500; // Duration of each enhancement step
  final int LABEL_MS = 3000; // How long the label shows after the last step
  final float FACE_SCALE = 1.4; // Crop size relative to the face, to include head and shoulders. Lower for tighter crop

  int x, y, w, h, margin, tStart, elapsed;
  PImage[] steps; // One image per enhancement step, null when hidden
  PFont font;
  float capHeight;
  boolean identified; // true only on the frame the label appears

  TargetPanel(int w, int h, int margin) {
    this.w = w;
    this.h = h;
    this.margin = margin;

    font = createFont("modern-vision.ttf", 80);
    capHeight = font.getGlyph('H').topExtent; // Measured from the font, textAscent() is shorter than the capitals
  }

  boolean isVisible() {
    return steps != null;
  }

  void hide() {
    steps = null;
  }

  // Takes the close-up from the frame now, the panel shows that snapshot
  void show(PImage frame, Rectangle face) {
    if (isVisible()) return;

    // Crop around the face with the panel's aspect ratio, kept inside the frame
    float cropH = min(face.height * FACE_SCALE, frame.height);
    float cropW = cropH * w / h;
    if (cropW > frame.width) {
      cropW = frame.width;
      cropH = cropW * h / w;
    }
    float faceCenterX = face.x + face.width / 2.0;
    int cropX = (int)constrain(faceCenterX - cropW / 2, 0, frame.width - cropW);
    int cropY = (int)constrain(face.y + face.height / 2.0 - cropH / 2, 0, frame.height - cropH);

    PImage crop = frame.get(cropX, cropY, (int)cropW, (int)cropH);
    crop.resize(w, h);

    steps = new PImage[BLOCKS.length];
    for (int i = 0; i < BLOCKS.length; i++) steps[i] = pixelate(crop, BLOCKS[i]);

    // On the side opposite to the face, so it doesn't cover it
    x = faceCenterX < width / 2 ? width - margin - w : margin;
    y = margin;

    tStart = millis();
    elapsed = 0;
  }

  // Averages blocks of block x block pixels (resizing down) and scales back up without smoothing, so the blocks are sharp
  PImage pixelate(PImage src, int block) {
    if (block <= 1) return src;

    PImage small = src.copy();
    small.resize(max(1, src.width / block), max(1, src.height / block));

    PImage out = createImage(src.width, src.height, RGB);
    out.loadPixels();
    for (int py = 0; py < out.height; py++) {
      int sy = min(py / block, small.height - 1);
      for (int px = 0; px < out.width; px++) {
        int sx = min(px / block, small.width - 1);
        out.pixels[py * out.width + px] = small.pixels[sy * small.width + sx];
      }
    }
    out.updatePixels();
    return out;
  }

  void update(int t) {
    identified = false;
    if (!isVisible()) return;

    int labelStart = BLOCKS.length * STEP_MS;
    int prev = elapsed;
    elapsed = t - tStart;

    identified = prev < labelStart && elapsed >= labelStart;

    if (elapsed >= labelStart + LABEL_MS) steps = null;
  }

  void draw() {
    if (!isVisible()) return;

    push();

    tint(#FF0000); // Red, like the camera frame
    image(steps[min(elapsed / STEP_MS, BLOCKS.length - 1)], x, y);
    noTint();

    if (elapsed >= BLOCKS.length * STEP_MS) {
      textFont(font);
      fill(255);
      textAlign(CENTER, BASELINE);
      text("TARGET", x + w / 2, y + h * 0.68);
      text("ACQUIRED", x + w / 2, y + h * 0.68 + capHeight * 1.25); // Line spacing like in the movie
    }

    pop();
  }
}
