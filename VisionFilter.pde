// The T2 look (see ref/image sample*.png): not a red tint but a gradient map on brightness, after a contrast boost.
// Black -> crimson at mid tones -> pale cyan-white highlights, flat and clipped (the "blown out" parts).
// The stops were measured from the movie samples (crimson, like ref/image sample 2.png)
class VisionFilter {

  final float CONTRAST = 1.4; // Around mid grey. Higher crushes the shadows and blows out more highlights
  final float GRAIN = 3; // Film grain strength (standard deviation, in brightness levels). 0 disables it

  // Grain: a tile of random brightness offsets, read at a different random offset every frame so it moves.
  // Added before the gradient map, so like film grain it shows in shadows and mid tones but not in the clipped highlights
  final int TILE = 256; // Power of 2, for the wrap around with &
  byte[] grain = new byte[TILE * TILE];

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

    for (int i = 0; i < grain.length; i++) grain[i] = (byte)constrain(round(randomGaussian() * GRAIN), -127, 127);
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
    final int ox = (int)random(TILE), oy = (int)random(TILE); // Where the grain tile is read this frame
    java.util.stream.IntStream.range(0, frame.height).parallel().forEach(y -> {
      int grainRow = ((y + oy) & (TILE - 1)) * TILE;
      for (int x = 0, i = y * w; x < w; x++, i++) {
        int b = luma(src[i]) + grain[grainRow + ((x + ox) & (TILE - 1))];
        dst[i] = lut[b < 0 ? 0 : b > 255 ? 255 : b];
      }
    });
    out.updatePixels();
    return out;
  }

  // A new image with the T2 look, same size as the original (for one-off images, like the target panel close-up).
  // Without grain: on a still image it would just look like a dirty picture
  PImage applyCopy(PImage img) {
    PImage copy = img.copy();
    copy.loadPixels();
    for (int i = 0; i < copy.pixels.length; i++) copy.pixels[i] = lut[luma(copy.pixels[i])];
    copy.updatePixels();
    return copy;
  }

  // Brightness 0..255, weighted like the eye
  int luma(int c) {
    return (((c >> 16) & 0xFF) * 77 + ((c >> 8) & 0xFF) * 150 + (c & 0xFF) * 29) >> 8;
  }
}
