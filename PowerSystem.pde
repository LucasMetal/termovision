// Ideas:
// This could control external leds for the eyes (if this were mounted on a robot)

enum PowerState {
    POWERING_OFF,
    OFF,
    POWERING_ON,
    POWERING_ALTERNATE_ON,
    POWERING_OFF_DESTROYED,
    ON
}

class PowerSystem {

  final int PHASE_MS = 1000; // Duration of each phase of the power on/off animations
  final int POWERING_ON_PHASES = 2; // Expand vertically, expand horizontally
  final int POWERING_OFF_PHASES = 3; // Shrink vertically, shrink horizontally, shrink the grey point

  PowerState state;
  int tStart, elapsed; // Since the current power on/off started
  AlternatePower alternatePower; // The POWERING_ALTERNATE_ON sequence
  DestroyedShutdown destroyedShutdown; // The POWERING_OFF_DESTROYED sequence

  PowerSystem () {
    state = PowerState.OFF;
    alternatePower = new AlternatePower();
    destroyedShutdown = new DestroyedShutdown();
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

  void powerOffDestroyed() {
    if (state != PowerState.ON) return;
    start(PowerState.POWERING_OFF_DESTROYED);
  }

  void start(PowerState state) {
    this.state = state;
    tStart = millis();
    elapsed = 0;
    if (state == PowerState.POWERING_ALTERNATE_ON) alternatePower.reset();
    if (state == PowerState.POWERING_OFF_DESTROYED) destroyedShutdown.reset();
  }

  boolean isOn() {
    return state == PowerState.ON;
  }

  // State transitions. The animations are derived from the time elapsed since the power on/off started
  void update(int t) {
    elapsed = t - tStart;

    switch (state) {
      case POWERING_ON:
        if (elapsed >= POWERING_ON_PHASES * PHASE_MS) state = PowerState.ON;
        break;
      case POWERING_ALTERNATE_ON:
        alternatePower.update(elapsed);
        if (alternatePower.isDone()) state = PowerState.ON;
        break;
      case POWERING_OFF:
        if (elapsed >= POWERING_OFF_PHASES * PHASE_MS) state = PowerState.OFF;
        break;
      case POWERING_OFF_DESTROYED:
        destroyedShutdown.update(elapsed);
        if (destroyedShutdown.isDone()) state = PowerState.OFF;
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

  // camFrame already has the T2 look (VisionFilter)
  void draw(PImage camFrame) {

    push();
    if (state != PowerState.ON) background(0); // When on, the frame covers the whole screen

    switch (state) {
      case POWERING_OFF:{

        // Compact to a thin horizontal line (you can still see the image), shrink it horizontally, then a grey point
        // shrinks till it disappears. When destroyed it's DestroyedShutdown instead

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

      case POWERING_ALTERNATE_ON:
        alternatePower.draw(camFrame);
        break;

      case POWERING_OFF_DESTROYED:
        destroyedShutdown.draw();
        break;

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
