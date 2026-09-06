# GitHub → APK release checklist

1. Extract the Scarlet Veil ZIP.
2. Upload **everything inside the extracted folder** to the repository root.
3. Confirm `project.godot` is visible on the repository home page.
4. Confirm `.github/workflows/android.yml` exists.
5. Confirm `.github/ci/scarletveil-debug.keystore` exists (development debug signing only).
6. Open **Actions → Build Scarlet Veil Android APK**.
7. Run the workflow on `main`.
8. A green run produces the artifact **ScarletVeil-Android-debug**.
9. GitHub downloads Actions artifacts as ZIP files. Extract that ZIP once.
10. Install `ScarletVeil.apk` on Android.

For a public store release, create a private release keystore and store its credentials in GitHub Secrets. Never ship using the included public debug key.
