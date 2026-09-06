# SCARLET VEIL — CRIMSON DIRECTOR CUT QA REPORT

Build target: Godot 4.7.2 stable / Android landscape / ARM64

## Validation completed in the generation environment

- Project/resource reference scan across GDScript, scenes, resources and config files: **0 missing literal `res://` references**.
- GDScript structural scan: **28 scripts**, no duplicate function definitions, no mixed leading-space indentation, balanced brackets/parentheses/braces.
- Scene/resource inventory: **23 `.tscn` scenes/resources**, project main scene present.
- Memory database: valid JSON, **12 Memory Shards**.
- Audio: **22 WAV files** opened successfully and contain audio frames.
- Art: **9 PNG files** validated successfully.
- GitHub Actions YAML parsed successfully.
- Android export preset includes launcher visibility, landscape project configuration, ARM64, immersive mode and app icon.
- APK workflow includes project discovery, matching Godot 4.7.2 export templates, Java/Android setup, project import, runtime smoke boot, APK export and artifact upload.
- A stable **development-only debug keystore** is included so successive GitHub debug APKs can update one another without generating a new signing identity each run. Do not use this public debug key for a store/release build.

## Gameplay/logic fixes made during the Director Cut pass

- Bosses remain dormant until their arena is entered.
- Boss death respawn points are inside sealed arenas, preventing a death soft-lock behind a closed gate.
- Bellkeeper's delayed second shockwave cannot retrigger once per physics frame.
- Memory Shards keep their intended world height while bobbing.
- Moving platforms and floating Ink Wraiths preserve their intended origin positions.
- Memory Loom choices now have actual persistent gameplay consequences:
  - **Truth** builds a physical shortcut and slows Thread Resonance decay.
  - **Mercy** permanently raises Seren's maximum Heartglass to at least 7.
- Enemy and boss attacks gained stronger visual windup telegraphs for fair mobile play.
- Touch joystick now visually follows the player's initial thumb position.
- Drowned Archive and Crimson Approach decoration helpers are actually instantiated in the world.
- HUD boss bar made resolution-responsive.

## Runtime limitation

A runnable Godot 4.7.2 editor binary is not installed in this generation container, and outbound binary download is blocked here. Therefore I did **not** claim a local full engine playthrough.

The included GitHub workflow compensates by performing two engine-level gates before APK export:

1. `godot --headless --editor --path ... --quit` — imports/parses the project.
2. An 8-second headless runtime smoke boot — rejects common script/resource failures before the APK step.

A real Android device playthrough is still required for frame pacing, touch ergonomics, audio balance and difficulty tuning.
