import java.util.Queue;
import java.util.ArrayDeque;

class MainMessage {

  Queue<String> phrasesQueue = new ArrayDeque<String>();
  final int FLASH_TIME = 3000; // ms flashing after the message is written

  int x, y, speed, tStart, elapsed; // x is the horizontal center, y the baseline
  String message; // null when idle
  PFont font;
  float capHeight; // Height of the capital letters, also the cursor size
  String[] phrases = {
    // [QUESTIONS/ANSWERS]
    // POSSIBLE RESPONSE:
    // YES/NO
    // OR WHAT?
    // GO AWAY
    // PLEASE COME BACK LATER
    // FUCK YOU
    "FUCK YOU, ASSHOLE",
    "MATCH",
    "TARGET ACQUIRED",
    "IDENT POSITIVE",
    "IMAGE ENHANCE",
    "PORT OPEN",
    "SYSTEM INTERRUPT",
    "DIAGNOSTIC",
    "MOTION SELECT",
    "ANALYSIS",
    "HUMAN CASUALTIES: 0.0",
    "THREAT ASSESSMENT",
    "SEARCH MODE",
    "REROUTE",
    "ALTERNATE POWER"
  };

  MainMessage (int x, int y) {
    this.x = x;
    this.y = y;
    speed = 100;

    font = createFont("modern-vision.ttf", 100);
    capHeight = font.getGlyph('H').topExtent; // Measured from the font, in pixels at its size
  }

  void start (String message) {
    this.message = message;
    tStart = millis();

    println("started : " + message);
  }

  void startRandom() {
    start(phrases[(int)random(0, phrases.length)]);
  }

  void enqueue(String message) {
    phrasesQueue.add(message);
    println("enqueued : " + message);
  }

  // Everything is derived from the time elapsed since start: writing, then flashing for FLASH_TIME ms, then idle
  void update(int t) {
    elapsed = t - tStart;

    if (message != null && elapsed >= message.length() * speed + FLASH_TIME) message = null;

    if (message == null && phrasesQueue.size() > 0) {
      start(phrasesQueue.remove());
      elapsed = 0;
    }
  }

  void draw() {
    if (message == null) return;

    textFont(font);

    int typeTime = message.length() * speed;

    // Centered on the full message plus the cursor, so the text doesn't move while it's being written
    float left = x - (textWidth(message) + capHeight * 1.8) / 2;

    if (elapsed < typeTime) { // writing, one more char every "speed" ms
      int chars = elapsed / speed;
      String typed = message.substring(0, chars);
      text(typed, left, y);
      drawRectangle(left, typed);
    } else if ((elapsed - typeTime) % (speed + speed/2) < speed) { // flashing, shown "speed" ms and hidden "speed/2" ms
      text(message, left, y);
      drawRectangle(left, message);
    }
  }

  // Square cursor right after the typed text, as tall as the capital letters (see ref/message 1.png).
  // The font isn't monospaced, so the text is measured. The gap is 0.8 cap heights, the square 1 (1.8 in total)
  void drawRectangle(float left, String typed) {
    push();
    noStroke(); // Otherwise the default black stroke shows as a border on bright frames
    fill(255);
    rect(left + textWidth(typed) + capHeight * 0.8, y - capHeight, capHeight, capHeight);
    pop();
  }
}
