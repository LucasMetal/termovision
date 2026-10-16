// The T2 look (see ref/image sample*.png): not a red tint but a gradient map on brightness, after a contrast boost.
// Black -> crimson at mid tones -> pale cyan-white highlights, flat and clipped (the "blown out" parts).
// The stops were measured from the movie samples (crimson, like ref/image sample 2.png)
class VisionFilter {

  final float CONTRAST = 1.4; // Around mid grey. Higher crushes the shadows and blows out more highlights

  // Brightness (0..255) -> color
  final int[] STOP_AT = {0, 110, 210, 255};
  final color[] STOP_COLOR = {color(12, 1, 4), color(210, 45, 85), color(200, 220, 240), color(225, 240, 250)};

  int[] lut = new int[256];
  PImage out; // Reused every frame

  VisionFilter() {
    for (int v = 0; v < 256; v++) {
      float x = constrain((v - 128) * CONTRAST + 128, 0, 255);
      int s = 0;
      while (x > STOP_AT[s + 1]) s++;
      lut[v] = lerpColor(STOP_COLOR[s], STOP_COLOR[s + 1], (x - STOP_AT[s]) / (float)(STOP_AT[s + 1] - STOP_AT[s]));
    }
  }

  // The frame with the T2 look, same size. Returns the same image every time.
  // Full resolution on purpose: drawing a smaller image scaled up to the screen is very slow in JAVA2D (~7 fps).
  // The rows are processed in parallel on all the cores
  PImage apply(PImage frame) {
    if (out == null || out.width != frame.width || out.height != frame.height) out = createImage(frame.width, frame.height, RGB);

    frame.loadPixels();
    out.loadPixels();
    final int[] src = frame.pixels, dst = out.pixels;
    final int w = frame.width;
    java.util.stream.IntStream.range(0, frame.height).parallel().forEach(y -> {
      for (int i = y * w, end = i + w; i < end; i++) dst[i] = look(src[i]);
    });
    out.updatePixels();
    return out;
  }

  // A new image with the T2 look, same size as the original (for one-off images, like the target panel close-up)
  PImage applyCopy(PImage img) {
    PImage copy = img.copy();
    copy.loadPixels();
    for (int i = 0; i < copy.pixels.length; i++) copy.pixels[i] = look(copy.pixels[i]);
    copy.updatePixels();
    return copy;
  }

  int look(int c) {
    return lut[(((c >> 16) & 0xFF) * 77 + ((c >> 8) & 0xFF) * 150 + (c & 0xFF) * 29) >> 8]; // Brightness, weighted like the eye
  }
}
