# VR Headset Training

Quest 2 training app for the Learning Resource Center at Esfahan Oil Refining Company (EORC).

In-headset text is Persian. All install, package, workflow, and artifact names are English.

- App name on the headset: `VR Headset Training`
- Android package: `com.eorc.headsettraining`
- APK file: `headset-training.apk`

## What you get after GitHub Actions

A debug-signed APK for sideload on Meta Quest 2 (Unknown Sources). Not a Meta Store release build.

## Push to GitHub (Windows Command Prompt)

Create an **empty** GitHub repository first. Do not add a README on GitHub.

```bat
cd C:\Users\Administrator\headset-training-vr
git init
git add .
git commit -m "Initial Quest 2 headset training app"
git branch -M main
git remote add origin https://github.com/YOUR_USER/YOUR_REPO.git
git push -u origin main
```

Replace `YOUR_USER/YOUR_REPO` with your repository.

## Download the APK

1. Open the repository on GitHub.
2. Open the **Actions** tab.
3. Open the run named **Build Quest 2 APK**.
4. Wait until it is green.
5. Download the artifact **headset-training-quest2-apk**.
6. Unzip it. Use `headset-training.apk`.

The first run usually takes several minutes (Godot + Android export).

## Install on Quest 2

1. Enable Developer Mode in the Meta Quest phone app.
2. Connect the headset with USB and allow access.
3. Install with SideQuest, Meta Quest Developer Hub, or:

```bat
adb install headset-training.apk
```

4. In the headset library, open **Unknown Sources** and launch **VR Headset Training**.

## Training content (inside the app, Persian)

Controller: Trigger, Grip, Thumbstick, Thumbstick click, A, B, X, Y, Menu.
Headset hardware: volume and power (explained only; power is not required).
Simple work table: screwdriver, cutter, wrench, cup, and a part to place.
Teleport and smooth move are included after the button lessons.

The Meta / system button is Quest OS and is not available to apps. The lesson explains it; it cannot be detected in-app.

## Project layout

- `project.godot` — Godot 4.3, OpenXR, mobile renderer
- `export_presets.cfg` — Quest Android ARM64 Gradle export
- `.github/workflows/build-apk.yml` — APK build on push to `main`
- `scenes/main.tscn` / `scenes/main.gd` — room, table, tools, lessons
- `scripts/xr_init.gd` — OpenXR startup
- `assets/logo.png` — company logo
- `assets/fonts/` — Vazirmatn (OFL) for Persian UI

The OpenXR Vendors addon is downloaded in CI. It is not stored in this repo.

## Engine

Godot **4.3-stable** only. Keep that version. Changing Godot version can break `export_presets.cfg` keys.
