import java.util.Queue;
import java.util.ArrayDeque;

class MainMessage {

  Queue<String> phrasesQueue = new ArrayDeque<String>();
  int x, y, count, speed, mode, tprev, tflash, tshow;
  String message;
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
    mode = 3; // Starts checking the queue
  }

  void start (String message) {
    count = 0;
    mode = 0;
    tprev = 0;

    this.message = message;

    println("started : " + message);
  }

  void startRandom() {
    start(phrases[(int)random(0, phrases.length)]);
  }

  void enqueue(String message) {
    phrasesQueue.add(message);
    println("enqueued : " + message);
  }

  void update() {
  }

  void draw(int t) {

    //textSize(100);
    textFont(font);

    switch (mode) {
      case 0:
        { // writing
  
          if (t - tprev > speed) {
            count++;
            tprev = t;
          }
  
          text(message.substring(0, Math.min(count, message.length())), x, y);
          drawRectangle(count);
  
          if (count == message.length()) {
            mode++;
            tflash = t;
            tshow = t;
          }
  
          break;
        }
      case 1:
        { // flashing - show
  
          text(message, x, y);
          drawRectangle(message.length());
  
          println("show - sub :" + (t - tshow));
          
          if ((t - tshow) > speed) {
            mode++;
            tshow = t;
          }
  
          break;
        }
      case 2:
        { // flashing - hide
  
          if ((t - tflash) > 3 * 1000) mode++;
  
          println("hide - sub :" + (t - tshow));
          
          println(String.format("hide - t : %s - tshow: %s", t, tshow));
          
          
          
          if ((t - tshow) > speed/2) {
            mode--;
            tshow = t;
            println("hide - update mode");
          }
  
          break;
        }
      case 3:
        { // ended
          if (phrasesQueue.size() > 0) {
            start(phrasesQueue.remove());
          }
          break;
        }
      }
  }

  void drawRectangle(int charCount) {
    fill(255);
    rect(charCount * 60 + 20 + x, y - 60, 60, 60); // Totally empirical, adjust if font size is changed
  }
}
