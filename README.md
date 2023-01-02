# N4O Aegisub Script

A collection of my script that I use sometimes.

All of my scripts need DependencyControl to work.

**Scripts**
- [`nao.AutoRealign`](#naoautorealign)
- [`nao.Centipede`](#naocentipede)
- [`nao.Jittery`](#naojittery)

## [`nao.AutoRealign`](https://github.com/noaione/.aegibulan/blob/master/nao.AutoRealign.moon)
Automatically realign to another alignment without losing the original position.

**Requirements**:
- [l0.ASSFoundation](https://github.com/TypesettingTools/ASSFoundation)
- [a-mo.LineCollection](https://github.com/TypesettingTools/Aegisub-Motion)
- [SubInspector](https://github.com/TypesettingTools/SubInspector)

To use, just install everything, then select the line you want to realign, open `Auto Realign` then pick whatever new alignment you want

**Caveats**:
- Shifting is not perfect yet, I'll cross out this caveats when I found a perfect solution to readjust some small number
- Doesn't work nicely with `\fsp`
- Doesn't work with drawing

## [`nao.Centipede`](https://github.com/noaione/.aegibulan/blob/master/nao.Centipede.moon)
Create a stacked subtitle screenshot with the main sub (or the first one) being the full uncropped images, while the other are cropped into the specific sub boundary with some padding.

Totally not inspired by people posting a screenshot of subtitle to r/Hololive

**Requirements**:
- `ffmpeg.exe`
    - Put this into your `automation\autoload\bin` folder
    - Or put it into PATH
- [l0.ASSFoundation](https://github.com/TypesettingTools/ASSFoundation)
- [a-mo.LineCollection](https://github.com/TypesettingTools/Aegisub-Motion)
- [SubInspector](https://github.com/TypesettingTools/SubInspector)

To use, just install everything, then select the sub you want to stack together, open `Automation` then `Centipede`.

This will generate a file beside your `.ass` file with the filename format: `centipede_YOUR_ASS_FILE_NAME.png`

It's basically running a series of ffmpeg command extract frame, crop, and stack together the frame.

**Caveats**:
- The speed of the script can be really slow if the video gets longer and longer
- ~~If there's a line with same start time, it will be duplicated~~ Added in **Version 0.3.0**
- Since it takes the first frame of the sub, sadly you can use \fade effect or it'll be broken.

**Sample**

![Sample](https://raw.githubusercontent.com/noaione/.aegibulan/master/assets/centipede9frame_testsub.ass.png)

## [`nao.Jittery`](https://github.com/noaione/.aegibulan/blob/master/nao.Jittery.moon)
Jitter or Shake a multiple selected line tags with a random amount.

It's based on unanimated's Hyperdimensional Relocator shake function but with more ASS tags support.

**Requirements**:
- [l0.ASSFoundation](https://github.com/TypesettingTools/ASSFoundation)
- [a-mo.LineCollection](https://github.com/TypesettingTools/Aegisub-Motion)

To use, select the line you want to jitter, then select the `Jittery` from your automation list.<br/>
After that enter the amount of jitter diff and enable smoothing if you want.<br />
Don't forget to select the tags that you want to affect with the jitter.

After that, just click the `Jitter` button.

To make the multiple line, you can use Hyperdimensional Relocator -> line2fbf to split the line every frame
or you can made it manually depending on what you wanna do.

**Demo**

https://user-images.githubusercontent.com/34302902/210222116-f033fa22-3bf0-490d-8b71-9f50672a8570.mp4


