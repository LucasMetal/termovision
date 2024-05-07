import java.util.Queue;
import java.util.ArrayDeque;

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

  int tStart, animationState;
  float animationDuration;
  PowerState state;

  PowerSystem () {
    animationDuration = 1000;
    state = PowerState.OFF;
  }

  void powerOn() {
    if (state != PowerState.OFF) return;
    
    state = PowerState.POWERING_ON;
    tStart = 0;
    animationState = 0;
  }

  void powerAlternateOn() {
    if (state != PowerState.OFF) return;
    
    state = PowerState.POWERING_ALTERNATE_ON;
    tStart = 0;
    animationState = 0;
  }

  void powerOff() {
    if (state != PowerState.ON) return;
    
    state = PowerState.POWERING_OFF;
    tStart = 0;
    animationState = 0;
  }

  Boolean isOn() {
    return state == PowerState.ON;
  }

  void update() {
  }

  void draw(int t, PImage camFrame) {

    if (tStart == 0) tStart = t;

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

        int dt = t - tStart;

        background(0);
        tint(#FF0000); // Red
        
        switch (animationState){
          case 0:{ // Shrinking vertically
              int newHeight = (int)max(lerp(camFrame.height, camFrame.height * 0.01, dt/animationDuration), camFrame.height * 0.01);
              image(camFrame, 0, (height - newHeight) / 2 , width, newHeight);
              
              if (dt > animationDuration) {
                tStart = t;
                animationState++;
              }
            break;
          }
          case 1:{ // Shrinking horizontally
              int newHeight = (int)(camFrame.height * 0.01);
              int newWidth = (int)max(lerp(camFrame.width, camFrame.width * 0.01, dt/animationDuration), camFrame.width * 0.01);
              image(camFrame, (width - newWidth)/2, (height - newHeight) / 2 , newWidth, newHeight);
              
              if (dt > animationDuration) {
                tStart = t;
                animationState++;
              }
            break;
          }
          case 2:{ // Shrinking grey point
              float diameter = lerp(20, 0, dt/animationDuration);
              fill(128);
              noStroke();
              circle (width/2, height/2, diameter);
              
              if (dt > animationDuration) {
                state = PowerState.OFF;
              }
            break;
          }          
        }       
        
        noTint();
        break;
      }
    case OFF:{ // We draw the power off screen

        background(0);
        break;
      }
    case POWERING_ALTERNATE_ON: // TODO
    case POWERING_ON:{

        int dt = t - tStart;

        background(0);
        tint(#FF0000); // Red
        
        switch (animationState){
          case 0:{ // Expading vertically
              int newWidth = (int)(camFrame.width * 0.04);
              int newHeight = (int)lerp(0, camFrame.height, dt/animationDuration);
              image(camFrame, (width-newWidth)/2, (height - newHeight) / 2 , newWidth, newHeight);
              
              if (dt > animationDuration) {
                tStart = t;
                animationState++;
              }
            break;
          }
          case 1:{ // Expading horizontally              
              int newWidth = (int)lerp(camFrame.width * 0.04, camFrame.width, dt/animationDuration);
              image(camFrame, (width - newWidth)/2, 0 , newWidth, height);
              
              if (dt > animationDuration) {
                state = PowerState.ON;
              }
            break;
          }                    
        }       
        
        noTint();
        break;
      }    
    case ON:{ // We draw the normal frame

        tint(#FF0000); // Red
        image(camFrame, 0, 0, width, height);
        noTint();

        break;
      }
    }
  }
  
}
