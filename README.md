# LustMix
WoW Addon made using AI to play music when lust is detected


# 🎵 LustMix – Custom Animations & Music Guide

LustMix lets you personalize your Bloodlust/Heroism experience with **your own music** and **your own animations**.  
Adding custom files is simple — just follow the steps below.

---

# 📁 Folder Structure

Your addon should contain these folders:

```
LustMix/
 ├─ Animations/
 │    └─ *.tga   (your custom animation sprite sheets)
 ├─ Music/
 │    └─ *.mp3   (your custom music files)
 ├─ FileList.lua
 ├─ Settings.lua
 ├─ Music.lua
 ├─ Animation.lua
 └─ ...
```

LustMix automatically loads files placed in:

- `LustMix/Animations/`
- `LustMix/Music/`

---

# 🎨 Adding Custom Animations

LustMix supports **TGA sprite sheets** for animations.

### ✔ Requirements
- File format: **.tga**
- Must be a **sprite sheet** (multiple frames arranged in a grid)
- Power‑of‑two dimensions recommended (512×512, 1024×1024, etc.)
- No compression
- 32‑bit TGA (with alpha) recommended

### ✔ How to add your animation

1. Place your `.tga` file into:

```
Interface/AddOns/LustMix/Animations/
```

2. Open `FileList.lua`.

3. Add your file name to the `CUSTOM_ANIMATIONS` table:

```lua
CUSTOM_ANIMATIONS = {
    "LunaSnow.tga",
    "SP_Guy.tga",
    "MyCustomAnimation.tga",   -- Add yours here
}
```

4. Save and **/reload** in-game.

Your animation will now appear in the LustMix settings dropdown.

---

# 🎵 Adding Custom Music

LustMix supports **MP3 files**, but WoW is strict about audio formatting.

### ✔ Requirements
- File format: **.mp3**
- Constant bitrate (CBR)
- 44.1 kHz
- Stereo
- No embedded album art
- ID3v2.3 tags (not v2.4)

### ✔ How to add your music

1. Place your `.mp3` file into:

```
Interface/AddOns/LustMix/Music/
```

2. Open `FileList.lua`.

3. Add your file name to the `CUSTOM_SONGS` table:

```lua
CUSTOM_SONGS = {
    "LunaSnow.mp3",
    "Running90s.mp3",
    "MyCustomSong.mp3",   -- Add yours here
}
```

4. Save and **/reload** in-game.

Your song will now appear in the LustMix settings dropdown.

---

# 🧪 Testing Your Files

Inside the LustMix settings:

- **Test Animation** previews your animation.
- **Test Music** plays your selected song.

Music playback includes:
- Fade‑in
- Preview duration timer
- Fade‑out

If nothing plays, check the troubleshooting section below.

---

# 🛠 Troubleshooting

### ❌ My MP3 doesn’t play
This is almost always a formatting issue.

Try exporting with **Audacity**:

```
File → Export → Export as MP3
Bitrate Mode: Constant
Quality: 192 kbps
Channel Mode: Stereo
ID3 Tags: v2.3
```

Or with **ffmpeg**:

```
ffmpeg -i input.mp3 -codec:a libmp3lame -b:a 192k -id3v2_version 3 output.mp3
```

### ❌ My animation doesn’t show
Check:
- File is `.tga`
- No compression
- Power‑of‑two dimensions
- Added to `CUSTOM_ANIMATIONS`
- UI reloaded

### ❌ My file doesn’t appear in the dropdown
Make sure:
- The filename matches exactly (case‑sensitive)
- No extra spaces
- You saved `FileList.lua`
- You reloaded the UI

---

# 🎯 Advanced Options

LustMix also supports:

- Custom animation FPS  
- Custom animation size  
- Fade‑in duration  
- Fade‑out duration  
- Preview duration  
- Audio channel selection (Master, SFX, Dialog, etc.)  
- Minimap button lock/unlock  
- Debug mode  

Explore the settings panel for full control.

---

# ❤️ Thanks for using LustMix!

If you create cool animations or music setups, feel free to share them with the community!
