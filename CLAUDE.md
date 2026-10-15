# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

TermoVision is a Processing 4 (Java-mode) sketch that recreates the Terminator's red HUD vision over a webcam feed. It's based on https://www.youtube.com/watch?v=CZlEiD6Nmnc.

## Running

You need Processing 4 plus the "OpenCV for Processing" (`gab.opencv`) and "Video Library for Processing 4" (`processing.video`) libraries, installed through Processing's Contribution Manager. There's no build system, linter, or test suite.

- **From the Processing IDE:** open `TermoVision.pde` and press Run.
- **From VS Code:** run the default build task "Run Sketch" (`.vscode/tasks.json`). It calls `processing-java --force --sketch=<root> --output=<root>/out --run`, and the `processing.path` VS Code setting has to point at `processing-java`.
- **From the CLI:** `processing-java --force --sketch="$PWD" --output="$PWD/out" --run`

`out/` holds build output and is gitignored.

## Architecture

All `.pde` files in the root belong to one sketch. Processing joins them into a single class, so the classes in the other tabs are inner classes of `TermoVision`. They call Processing APIs (`image`, `millis`, `width`, `createGraphics`, and so on) directly, and globals defined in one tab are visible from every other tab.

`TermoVision.pde` is the entry point and orchestrator:
- `settings()` sets the window to 1920x1080 with the default `JAVA2D` renderer (`P2D` was tried: barely faster with the camera, and face tracking got jumpy) and has the test toggles. When `useCam = false`, the sketch uses `data/john.jpg` as a fake frame instead of the webcam. When `useOpenCV` is enabled, face detection drives the crosshair; otherwise the crosshair follows the mouse.
- `draw()` takes the frame (`cam` itself or the fake image, never a per-frame copy: a new full-size image each frame tanks the frame rate) and hands it to `PowerSystem.draw()`. **If the power system isn't `ON`, `draw()` returns early, so none of the other HUD elements render.** It then updates and draws `Grid`, `CodePage`, `MainMessage`, and `Crosshair` in that order.
- `runDemo()` is a scripted timeline (a `demoStep` state machine keyed on elapsed seconds) that fires HUD events. Press `d` to start it.
- Keyboard and mouse controls: `c` shows the next code page (cycling), `d` starts the demo, `f` and `i` queue messages, `g` shows the grid, `1`/`2`/`3` power on, power on (alternate), and power off. A mouse click shows a random message.

HUD components ("artifacts") share one pattern: a class with `update(...)` and `draw()` methods, driven by the `millis()` value passed in from `draw()`. Animations store only their start time and derive everything else (characters typed, lines shown, flash on/off, positions) from the elapsed time, so they don't depend on frame rate:
- `PowerSystem` is a `PowerState` enum state machine plus an `animationState` sub-step for the CRT-style power-on/power-off animations. It's also what draws the red-tinted camera frame. `POWERING_ALTERNATE_ON` is still a TODO and currently reuses the `POWERING_ON` animation.
- `MainMessage` holds a queue of strings, which it types out character by character and then flashes. After `FLASH_TIME` (3 s) of flashing it goes idle (`message == null`) and pulls the next queued message. It uses the `data/modern-vision.ttf` font. The cursor rectangle offset in `drawRectangle` is tuned by hand for font size 100.
- `Grid` is a pre-rendered `PGraphics` grid with bouncing scan lines (speed in px per second, random start on each show), visible for N seconds after `show(seconds)` is called.
- `CodePage` holds pages of `CodeBlock`s (positions and sizes stored as fractions of the screen). `show(pageIndex)` reveals the lines one at a time across all blocks, then the page flashes 3 times and disappears. Each character is drawn in a fixed-width cell because the font isn't monospaced, zeros get a hand-drawn slash because in this font `0` looks the same as `D`, and `•` bullets are drawn as circles because the font has no bullet glyph.
- `Crosshair` is a pre-rendered semi-transparent `PGraphics` reticle, made by drawing black "cutouts" and then converting pixels to alpha. It owns the OpenCV face detection: `update(frame)` copies the frame into a preallocated image downscaled by `DETECT_SCALE` (5), detects faces on it and maps them back to full resolution, or follows the mouse when face detection is off. The frame itself isn't modified.

Assets loaded with `loadImage`/`createFont` come from `data/`.
