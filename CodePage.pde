// Ideas:
// Add more pages (picked randomly or by context, e.g. when a face is detected)

enum CodePageState {
  HIDDEN,
  WRITING,
  FLASHING
}

// A group of lines drawn together. All values are fractions of the screen size, so it adapts to any resolution
class CodeBlock {

  float x, y, lineHeight, charWidth, fontSize;
  String[] lines;

  CodeBlock (float x, float y, float lineHeight, float charWidth, float fontSize, String[] lines) {
    this.x = x * width;
    this.y = y * height;
    this.lineHeight = lineHeight * height;
    this.charWidth = charWidth * width;
    this.fontSize = fontSize * height;
    this.lines = lines;
  }
}

class CodePage {

  final int FLASHES = 3;

  CodeBlock[][] pages;
  CodeBlock[] page;
  CodePageState state;
  int pageIndex, lineCount, totalLines, toggles, speed, flashSpeed, tprev;
  Boolean visible;
  PFont font;

  CodePage () {
    speed = 60; // ms per line
    flashSpeed = 150; // ms per flash toggle
    state = CodePageState.HIDDEN;
    visible = false;

    font = createFont("modern-vision.ttf", 32);

    pages = new CodeBlock[][] {
      createPage1(),
      createPage2()
    };
    pageIndex = -1;
  }

  // Cycles through the pages
  void showNext() {
    show((pageIndex + 1) % pages.length);
  }

  void show(int pageIndex) {
    this.pageIndex = pageIndex;
    page = pages[pageIndex];

    totalLines = 0;
    for (CodeBlock block : page) totalLines += block.lines.length;

    lineCount = 0;
    toggles = 0;
    visible = true;
    tprev = millis();
    state = CodePageState.WRITING;
  }

  void update(int t) {

    switch (state) {
      case WRITING: { // One more line every "speed" ms
        if (t - tprev > speed) {
          lineCount++;
          tprev = t;
        }

        if (lineCount >= totalLines) state = CodePageState.FLASHING;
        break;
      }
      case FLASHING: { // hide/show FLASHES times, then hide for good
        if (t - tprev > flashSpeed) {
          visible = !visible;
          toggles++;
          tprev = t;
        }

        if (toggles > FLASHES * 2) state = CodePageState.HIDDEN;
        break;
      }
      case HIDDEN:
        break;
    }
  }

  void draw() {
    if (state == CodePageState.HIDDEN || !visible) return;

    push();
    textFont(font);
    fill(255);
    textAlign(CENTER, BASELINE);

    int remaining = lineCount;
    for (CodeBlock block : page) {
      textSize(block.fontSize);

      for (int i = 0; i < Math.min(remaining, block.lines.length); i++) {
        drawMonospaced(block.lines[i], block.x, block.y + i * block.lineHeight, block.charWidth);
      }

      remaining -= block.lines.length;
      if (remaining <= 0) break;
    }

    pop();
  }

  // The font isn't monospaced, so each char is centered in a fixed width cell to keep the columns aligned
  void drawMonospaced(String line, float x, float y, float charWidth) {
    float capHeight = textAscent() * 0.75; // Empirical for modern-vision.ttf

    stroke(255);
    strokeWeight(textAscent() * 0.08);

    for (int i = 0; i < line.length(); i++) {
      char c = line.charAt(i);
      if (c == ' ') continue;

      float cx = x + i * charWidth + charWidth / 2;

      // Bullets are drawn by hand, the font doesn't have them
      if (c == '•') {
        circle(cx, y - capHeight / 2, charWidth * 0.3);
        continue;
      }

      text(c, cx, y);

      // Slashed zero, like in the movie (otherwise it's identical to D in this font)
      if (c == '0') line(cx + charWidth * 0.35, y - capHeight * 1.1, cx - charWidth * 0.35, y + capHeight * 0.1);
    }
  }

  String bullets(int count) {
    return "•".repeat(count);
  }

  // Taken from the movie (6502 machine code + checksums)
  CodeBlock[] createPage1() {
    return new CodeBlock[] {
      new CodeBlock(0.061, 0.041, 0.0232, 0.007, 0.021, new String[] {
        "136  6085  A0 0A",
        "137  6087  B9 E1 60",
        "138  608A  99 F0 03",
        "139  608D  88",
        "140  608E  10 F7",
        "141  6090  AD F3 03",
        "142  6093  49 A5",
        "143  6095  8D F4 03",
        "144",
        "145",
        "146",
        "147  6098  A9 03",
        "148  609A  A0 F0",
        "149  609C  85 3D",
        "150  609E  85 43",
        "151  60A0  84 3C",
        "152  60A2  84 42",
        "153  60A4  A9 03",
        "154  60A6  A0 FA",
        "155  60A8  85 3F",
        "156  60AA  84 3E",
        "157  60AC  38",
        "158  60AD  20 11 C3",
        "159",
        "160",
        "161",
        "162  60B0  A9 60",
        "163  60B2  A0 EF",
        "164  60B4  85 3D",
        "165  60B6  85 43",
        "166  60B8  84 3C",
        "167  60BA  84 42",
        "168  60BC  A9 64",
        "169  60BE  A0 5D",
        "170  60C0  85 3F",
        "171  60C2  84 3E",
        "172  60C4  38"
      }),
      new CodeBlock(0.739, 0.579, 0.0266, 0.008, 0.024, new String[] {
        "   2B33       9310 - 935F",
        "   2848       9360 - 93AF",
        "   2A5C       93B0 - 93FF",
        "   295C       9400 - 944F",
        "   2A09       9450 - 949F",
        "   21C0       94A0 - 94EF",
        "   243D       94F0 - 953F",
        "   28FD       9540 - 958F",
        "   279F       9590 - 95DF",
        "     BB       95E0 - 95E1",
        "PROGRAM CHECK IS  :   0502"
      })
    };
  }

  // Taken from the movie (6502 assembler source)
  CodeBlock[] createPage2() {
    return new CodeBlock[] {
      new CodeBlock(0.075, 0.084, 0.0264, 0.0085, 0.025, new String[] {
        " 8 " + bullets(19),
        " 9",
        "10          ORG  $4000",
        "11 A1       =    $3C",
        "12 A2       =    $3E",
        "13 A4       =    $42",
        "14 AUXMOVE  =    $C311",
        "15",
        "16 " + bullets(28),
        "17 • SETUP - move data for VTOC",
        "18 • and catalog to auxmem at",
        "19 • B000-B3FF (pseudo trk 11",
        "20 • 0-3)",
        "21 " + bullets(26),
        "22 SETUP    LDA  #<VTOC",
        "23          STA  A1",
        "24          LDA  #>VTOC",
        "25          STA  A1+1",
        "26          LDA  #<END",
        "27          STA  A2",
        "28          LDA  #>END",
        "29          STA  A2+1",
        "30          LDA  #$00",
        "31          STA  A4",
        "32          LDA  #$B0",
        "33          STA  A4+1",
        "34          SEC",
        "35          JMP  AUXMOVE",
        "36",
        "37          DS   4",
        "38 " + bullets(15)
      })
    };
  }
}
