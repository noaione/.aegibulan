# N4O Aegisub Script

A collection of my script that I use sometimes.

All of my scripts need DependencyControl to work.

## Centipede
Create a stacked subtitle screenshot with the main sub (or the first one) being the full uncropped images, while the other are cropped into the specific sub boundary with some padding.

Totally not inspired by people posting a screenshot of subtitle to r/Hololive

**Requirements**:
- `ffmpeg.exe`
    - Put this into your `automation\autoload\bin` folder
    - Or put it into PATH
- l0.ASSFoundation
- a-mo.LineCollection

To use, just install everything, then select the sub you want to stack together, open `Automation` then `Centipede`.

This will generate a file beside your `.ass` file with the filename format: `centipede_YOUR_ASS_FILE_NAME.png`

It's basically running a series of ffmpeg command extract frame, crop, and stack together the frame.

## AutoRealign
**Status:** `Broken`

Automatically realign to another alignment without losing the original position.

Will be recomitted whenever I got time to fix it.
