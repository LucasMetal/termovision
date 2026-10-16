// Ideas:
// This could control external leds for the eyes (if this were mounted on a robot)

enum PowerState {
    POWERING_OFF,
    OFF,
    POWERING_ON,
    POWERING_ALTERNATE_ON,
    ON
}

class PowerSystem {

  final int PHASE_MS = 1000; // Duration of each phase of the power on/off animations
  final int POWERING_ON_PHASES = 2; // Expand vertically, expand horizontally
  final int POWERING_OFF_PHASES = 3; // Shrink vertically, shrink horizontally, shrink the grey point

  PowerState state;
  int tStart, elapsed; // Since the current power on/off started

  PowerSystem () {
    state = PowerState.OFF;
  }

  void powerOn() {
    if (state != PowerState.OFF) return;
    start(PowerState.POWERING_ON);
  }

  void powerAlternateOn() {
    if (state != PowerState.OFF) return;
    start(PowerState.POWERING_ALTERNATE_ON);
  }

  void powerOff() {
    if (state != PowerState.ON) return;
    start(PowerState.POWERING_OFF);
  }

  void start(PowerState state) {
    this.state = state;
    tStart = millis();
    elapsed = 0;
  }

  boolean isOn() {
    return state == PowerState.ON;
  }

  // State transitions. The animations are derived from the time elapsed since the power on/off started
  void update(int t) {
    elapsed = t - tStart;

    switch (state) {
      case POWERING_ALTERNATE_ON: // TODO, same as POWERING_ON for now
      case POWERING_ON:
        if (elapsed >= POWERING_ON_PHASES * PHASE_MS) state = PowerState.ON;
        break;
      case POWERING_OFF:
        if (elapsed >= POWERING_OFF_PHASES * PHASE_MS) state = PowerState.OFF;
        break;
      default:
        break;
    }
  }

  // Current phase of the animation, and how far it is through it (0..1)
  int phase() {
    return elapsed / PHASE_MS;
  }

  float phaseProgress() {
    return constrain((elapsed % PHASE_MS) / (float)PHASE_MS, 0, 1);
  }

  void draw(PImage camFrame) {

    push();
    if (state != PowerState.ON) background(0); // When on, the frame covers the whole screen
    tint(#FF0000); // Red

    switch (state) {
      case POWERING_OFF:{

        // When turned off:
        // compact to thick horizontal line (you can still see the image)
        // shrink the line to a big white point
        // shrink point till it disappears

        // When destroyed:
        // compact to red thick horizontal line
        // shrink the line to a red point
        // set point grey
        // shrink point till it disappears

        float p = phaseProgress();
        float lineHeight = height * 0.01;

        switch (phase()) {
          case 0:{ // Shrinking vertically
            float h = lerp(height, lineHeight, p);
            image(camFrame, 0, (height - h) / 2, width, h);
            break;
          }
          case 1:{ // Shrinking horizontally
            float w = lerp(width, width * 0.01, p);
            image(camFrame, (width - w) / 2, (height - lineHeight) / 2, w, lineHeight);
            break;
          }
          case 2:{ // Shrinking grey point
            fill(128);
            noStroke();
            circle(width/2, height/2, lerp(20, 0, p));
            break;
          }
        }
        break;
      }
      case OFF: // Just the black background
        break;

      case POWERING_ALTERNATE_ON: // TODO, same as POWERING_ON for now
      case POWERING_ON:{

        float p = phaseProgress();
        float lineWidth = width * 0.04;

        switch (phase()) {
          case 0:{ // Expanding vertically
            float h = lerp(0, height, p);
            image(camFrame, (width - lineWidth) / 2, (height - h) / 2, lineWidth, h);
            break;
          }
          case 1:{ // Expanding horizontally
            float w = lerp(lineWidth, width, p);
            image(camFrame, (width - w) / 2, 0, w, height);
            break;
          }
        }
        break;
      }
      case ON:{ // The normal frame
        image(camFrame, 0, 0, width, height);
        break;
      }
    }

    pop(); // Restores tint, fill and stroke, so they don't leak into the other artifacts
  }
}
