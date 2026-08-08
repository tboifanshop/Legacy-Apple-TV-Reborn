# Resources

This directory contains prerendered PNG asset placeholders for Legacy Apple TV Reborn themes.

## Theme Resources

Theme assets are stored on-device at:

```
/Library/Application Support/LegacyAppleTVReborn/Themes/<themeID>/
```

### Frutiger Aero (`com.legacyappletvreborn.theme.frutigeraero`)

| File | Description | Notes |
|------|-------------|-------|
| `FrutigerAeroBackground.png` | Home screen background image | Recommended: 1920×1080 px JPEG/PNG |
| `FrutigerAeroCursor.png` | Focus cursor image (mouse pointer) | Recommended: 64×80 px with transparency |

If these files are absent, Reborn falls back to a programmatically drawn cursor and a plain dark background.

## Soundtrack

### Automatic download (manifest-backed tracks)

Soundtrack entries are declared in:
```
/Library/Application Support/LegacyAppleTVReborn/SoundtrackManifest.plist
```

When a soundtrack is needed, Reborn automatically downloads the audio file
once and caches it locally at:
```
/var/mobile/Library/LegacyAppleTVReborn/Soundtracks/
```

No audio files are bundled in the repository or the package.

The Frutiger Aero default soundtrack is **Going Up** by Stevia Sphere,
downloaded automatically from the Internet Archive on first use:
```
https://ia600700.us.archive.org/16/items/stevia-sphere-tracks-from-soundcloud-01-going-up/Stevia%20Sphere%20-%20Tracks%20From%20Soundcloud%20-%2001%20Going%20Up.mp3
```
Cached at: `/var/mobile/Library/LegacyAppleTVReborn/Soundtracks/GoingUp.mp3`

### User-supplied tracks

You may also place your own audio files directly in the Soundtracks directory:
```
/var/mobile/Library/LegacyAppleTVReborn/Soundtracks/
```
Supported formats: `.m4a`, `.mp3`, `.aac`, `.wav`, `.caf`

### Kodi

If Kodi is installed, a copy of each downloaded track is also placed in:
```
/var/mobile/Library/Application Support/Kodi/userdata/Music/
```
so Kodi users can access the track through Kodi's music library.

## Safe Mode

To disable all Reborn theme hooks (stock Apple TV appearance):

```
touch /var/mobile/Library/Preferences/com.legacyappletvreborn.disable-theme
```

Remove the file to re-enable Reborn.

Recovery is also always available via SSH by disabling the MobileSubstrate plist:
```
/Library/MobileSubstrate/DynamicLibraries/AppleTVLauncher.plist
```
