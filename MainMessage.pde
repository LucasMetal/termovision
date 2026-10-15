import java.util.Queue;
import java.util.ArrayDeque;

class MainMessage {

  Queue<String> phrasesQueue = new ArrayDeque<String>();
  final int FLASH_TIME = 3000; // ms flashing after the message is written

  int x, y, speed, tStart, elapsed;
  String message; // null when idle
  PFont font;
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

    if (elapsed < typeTime) { // writing, one more char every "speed" ms
      int chars = elapsed / speed;
      text(message.substring(0, chars), x, y);
      drawRectangle(chars);
    } else if ((elapsed - typeTime) % (speed + speed/2) < speed) { // flashing, shown "speed" ms and hidden "speed/2" ms
      text(message, x, y);
      drawRectangle(message.length());
    }
  }

  void drawRectangle(int charCount) {
    fill(255);
    rect(charCount * 60 + 20 + x, y - 60, 60, 60); // Totally empirical, adjust if font size is changed
  }
}
