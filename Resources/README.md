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

User-supplied audio files belong in:

```
/var/mobile/Library/LegacyAppleTVReborn/Soundtracks/
```

Supported formats: `.m4a`, `.mp3`, `.aac`, `.wav`, `.caf`

**The Frutiger Aero default soundtrack is `WiiU_MiiEditing` (Wii U GamePad – Mii Editing).
This audio file is NOT bundled — it is copyrighted by Nintendo.
Users who own the Wii U must supply the file themselves.**

Place the file at:
```
/var/mobile/Library/LegacyAppleTVReborn/Soundtracks/WiiU_MiiEditing.m4a
```

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
