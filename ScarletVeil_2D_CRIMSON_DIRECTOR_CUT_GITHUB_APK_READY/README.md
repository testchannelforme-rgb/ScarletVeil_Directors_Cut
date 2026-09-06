# SCARLET VEIL — CRIMSON DIRECTOR CUT

A **Godot 4.7.2 / GDScript / 2D dark-fantasy Metroidvania** built to run on desktop and export to Android through GitHub Actions.

This package is a substantial playable vertical slice, not a claim that a 30-hour commercial campaign is finished.

## Why Godot

For this project, Godot is the best fit: strong native 2D workflow, GDScript iteration speed, a lightweight mobile-friendly Compatibility renderer, built-in Android export, no proprietary runtime dependency, and straightforward headless CI. See `SOURCES.md` for the technical/design references used.

## What is playable

- Forgotten Sanctuary
- Ashen Hollow
- Cradle Court
- Iron Choir / Bell Court
- Drowned Archive traversal section
- Crimson Approach / Regent's Bridge
- Heartwell ending threshold

### Seren
- responsive acceleration and air control
- coyote time + jump buffering
- variable jump height
- reduced gravity near jump apex
- wall jump
- one air dash per airtime
- Threadblade grapple + swing momentum
- 3-hit combo
- charged heavy strike
- aerial/down strike
- parry / perfect counter
- dash afterimages
- **Thread Resonance** combat-flow meter

### Bosses
1. **Mother Thren — The Empty Cradle**
   - Veil lullaby projectiles
   - grief shockwaves
   - summoned Mourners
   - defensive second phase

2. **The Bellkeeper — The Last Command**
   - sword attacks
   - warning-bell shockwaves
   - ground slam
   - defensive behavior

3. **The Pale Regent — Memory Without Grief**
   - sword lunges
   - teleport/vanish attacks
   - Veil projectile fans
   - three health phases
   - borrowed-memory summons

### Signature systems
- 3 functional Heartglass masks: Veilbound / Hunter / Echo
- 12 collectible Memory Shards
- contradictory memory writing
- Memory Gallery
- **Memory Loom** permanent narrative choice
- save/load/checkpoints
- NPC dialogue
- adaptive voice ducking
- original/placeholder voice lines and SFX included
- custom animated Heartwell loading screen
- cinematic title screen using Scarlet Veil branding
- Android virtual joystick + Jump / Attack / Dash / Chain / Parry / Mask / Use / Pause

## Open locally

1. Install/open Godot **4.7.2 stable**.
2. Import the folder containing `project.godot`.
3. Run `scenes/Main.tscn` (it is already configured as the main scene).

Keyboard:
- A/D or arrows — move
- Space/W/Up — jump
- J — Threadblade
- K/Shift — dash
- L — grapple
- Q — parry
- R — cycle mask
- E/Enter — interact
- Esc/P — pause

## GitHub → Android APK

Upload the **contents of this folder** to a GitHub repository. `project.godot` should be visible at the repository root. Make sure the hidden `.github` directory is included.

The workflow is:

`.github/workflows/android.yml`

Then:

1. GitHub repository → **Actions**
2. **Build Scarlet Veil Android APK**
3. **Run workflow**
4. Wait for the job to turn green
5. Open the successful run
6. Download artifact **ScarletVeil-Android-debug**
7. Extract the downloaded artifact ZIP
8. Install `ScarletVeil.apk`

The workflow automatically:
- locates `project.godot` even if the project is accidentally nested;
- installs Java 17 + Android SDK components;
- downloads Godot 4.7.2 + matching export templates;
- installs the included stable development debug keystore so successive test APKs share the same signing identity;
- enforces ETC2/ASTC Android texture import;
- imports the Godot project headlessly;
- runs a runtime smoke test looking for common script/resource failures;
- exports the ARM64 debug APK;
- uploads it as a GitHub artifact.

## Important

A GitHub Actions artifact is always downloaded as a ZIP. **That is normal.** Extract it once to get the actual `.apk` file.

## Performance target

The project is deliberately built around a 1280×720 reference viewport, Compatibility renderer, lightweight procedural 2D geometry, modest atmospheric layering and ARM64 Android export. Target: ~60 FPS on capable modern Android devices, but actual device testing is still required.

## Read next

- `DESIGN_DIRECTOR.md` — game direction and the new memory-choice hook
- `SOURCES.md` — engineering/design references
- `QA_REPORT.md` — static validation and gameplay-logic QA performed on this package
- `RELEASE_CHECKLIST.md` — shortest GitHub → APK path
