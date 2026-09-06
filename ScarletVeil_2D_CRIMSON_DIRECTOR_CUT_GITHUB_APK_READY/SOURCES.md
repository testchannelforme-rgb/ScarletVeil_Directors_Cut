# Scarlet Veil — Design & Technical References

This project uses original code, original procedural/vector presentation, and the supplied Scarlet Veil branding. The sources below were used as **design/engineering references**, not as asset sources.

## Godot / Android

1. Godot Engine documentation — **Exporting for Android**  
   https://docs.godotengine.org/en/latest/tutorials/export/exporting_for_android.html  
   Used for Android export workflow decisions: matching Godot export templates, Java/Android SDK configuration, debug keystore variables, APK export, and Android launcher/icon considerations.

2. Godot Engine documentation — **GPU optimization**  
   https://docs.godotengine.org/en/latest/tutorials/performance/gpu_optimization.html  
   Used for mobile-first rendering decisions: Compatibility renderer, restrained overdraw/post-processing, testing for mobile/tiled GPUs, and avoiding expensive full-screen effects.

3. Godot Engine documentation — **2D meshes / optimizing pixels drawn**  
   https://docs.godotengine.org/en/latest/tutorials/2d/2d_meshes.html  
   Referenced for the principle that large transparent layers can be costly on mobile. Scarlet Veil therefore favors compact procedural geometry and restrained atmospheric layers.

## Game feel / movement

4. Maddy Thorson — **Celeste game-feel thread** (archived by Thread Reader)  
   https://threadreaderapp.com/thread/1238338574220546049.html  
   Referenced for proven platforming-feel techniques such as coyote time, jump buffering, variable jump height, and softer gravity around the jump apex. Scarlet Veil implements its own values and code.

## Metroidvania world design

5. PC Gamer — **How to design a great Metroidvania map**, discussing Team Cherry's Hollow Knight process  
   https://www.pcgamer.com/how-to-design-a-great-metroidvania-map/  
   Referenced for the design principles of curiosity-driven exploration, ability-gated progression, useful world connections, backtracking rewards, and iterating map structure around discovery rather than a purely linear sequence.

## What was deliberately *not* copied

- No Hollow Knight, Celeste, Ori, Souls, or other commercial game assets are included.
- No proprietary plugins are required.
- Bosses, lore, scripts, masks, memory system, Thread Resonance, Memory Loom choice, UI, and world layout are Scarlet Veil-specific implementations.
