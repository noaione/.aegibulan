[[
    [Windows only]
    Also need DependencyControl and the following module installed:
    - Aegisub Motion: LineCollection (I'll try to remove this dependecies in future)
    - ASSFoundation

    Magically create a image centipede a.k.a Vertical stack of multiple images
    easily for posting at r/Hololive

    This script will crop only the 2nd sub selection afterwards while retaining the
    first image fully uncropped.
]]

export script_name        = "Centipede"
export script_description = "Create a vertical stacked image of your subtitles"
export script_version     = "0.2.0"
export script_author      = "noaione"
export script_namespace   = "nao.Centipede"

DependencyControl = require "l0.DependencyControl"
depCtrl = DependencyControl{
    feed: "https://raw.githubusercontent.com/noaione/.aegibulan/master/DependencyControl.json"
    {
        {"a-mo.LineCollection", version: "1.3.0", url: "https://github.com/TypesettingTools/Aegisub-Motion",
        feed: "https://raw.githubusercontent.com/TypesettingTools/Aegisub-Motion/DepCtrl/DependencyControl.json"},
        {"a-mo.ConfigHandler", version: "1.1.4", url: "https://github.com/TypesettingTools/Aegisub-Motion",
        feed: "https://raw.githubusercontent.com/TypesettingTools/Aegisub-Motion/DepCtrl/DependencyControl.json"}
        {"l0.ASSFoundation", version: "0.5.0", url: "https://github.com/TypesettingTools/ASSFoundation",
        feed: "https://raw.githubusercontent.com/TypesettingTools/ASSFoundation/master/DependencyControl.json"},
        "json"
    }
}

LCollect, ConfigHandler, ASSF, json = depCtrl\requireModules!

-- Some stuff that I'll probably forgot
BASE_STRING = "@echo off\necho Starting Centipede version %s...\n"
CROP_FMT = "crop=%d:%d:%d:%d"
ASS_FMT = "ass=\'%s\'"
FRAME_SELECT = "-ss \"%s\" -vframes 1"
OUTPUT_FMT = "-c png \"%s\""
INPUT_FMT = "-i \"%s\""

ToTimecode = (ttc) ->
    splitTime = (t, d) ->
      s = t % d
      return s, (t - s) / d

    splits = {}
    splits.f, ttc = splitTime ttc, 1000
    splits.s, ttc = splitTime ttc, 60
    splits.m, ttc = splitTime ttc, 60
    splits.h = ttc

    return "%01d:%02d:%02d.%02d"\format splits.h, splits.m, splits.s, splits.f / 10

CountTable = (aTable) ->
    c = 0
    for i, v in ipairs(aTable)
        c = c + 1
    return c

-----------------------
-- Find FFMPEG binaries
-- Script totally not stolen from
-- https://github.com/idolactivities/vtuber-things/blob/master/clipper/clipper-windows.lua
-- :)
-----------------------
FileExists = (name) ->
    f = io.open(name, "r")
    if f ~= nil
        io.close(f)
        return true
    return false

FindBinOrError = (name) ->
    -- Check user directory
    -- This should take precedence, as it is recommended by the install instructions
    file = aegisub.decode_path("?user/automation/autoload/bin/%s"\format name)
    if FileExists(file)
        return file

    -- If that fails, check install directory
    file = aegisub.decode_path("?data/automation/autoload/bin/%s"\format name)
    if FileExists(file)
        return file

    -- If that fails, check for executable in path
    path = os.getenv('PATH') or ''
    for prefix in path\gmatch '([^:]+):?'
        file = prefix .. '/' .. name
        if FileExists(file)
            return name

    -- Else, error
    error(('Could not find %s.' ..
              'Make sure it is in Aegisub\'s "automation/autoload/bin" folder ' ..
              'or in your PATH.')\format name)

FFMPEG = FindBinOrError "ffmpeg.exe"

CalculateHeight = (yPos, lineHeight, alignment) ->
    if alignment == 1 or alignment == 2 or alignment == 3
        -- Bottom alignment
        return { top: yPos - lineHeight, bottom: yPos }
    elseif alignment == 4 or alignment == 5 or alignment == 6
        -- Middle alignment
        lineHalf = lineHeight / 2
        return { top: yPos - lineHalf, bottom: yPos + lineHalf }
    elseif alignment == 7 or alignment == 8 or alignment == 9
        -- Top alignment
        return { top: yPos, bottom: yPos + lineHeight }
    else
        aegisub.log "Unknown alignment"
        aegisub\cancel!

GenerateUncroppedImage = (centipedeBonanza, assFile, videoFile) ->
    BASE = "echo Generating image snapshot...\n"
    assFile = assFile\gsub "\\", "\\\\"
    assFile = assFile\gsub ":", "\\:"
    assFuck = ASS_FMT\format assFile
    input_file = INPUT_FMT\format videoFile
    ccImage = 0
    ffmpeg_cmd = "\"%s\" %s -vf \"%s,select='"\format FFMPEG, input_file, assFuck
    centipede_select = {}
    for i, centi in ipairs centipedeBonanza
        table.insert(centipede_select, "eq(n\\,%d)"\format centi.frame)
        ccImage = ccImage + 1
    final_cmd = "\'\" -vsync 0 -vframes %d "\format ccImage
    -- Use double %, to escape the character properly
    final_cmd = final_cmd .. "\"" .. aegisub.decode_path("?temp") .. "\\centipede_frame%%03d.png\""
    ffmpeg_cmd = ffmpeg_cmd .. table.concat(centipede_select, "+") .. final_cmd
    return BASE .. ffmpeg_cmd

GenerateFinalCentipede = (centipedeBonanza, outputFileName) ->
    BASE = "echo Generating final centipede image...\n"
    counter = 1
    tempFolder = aegisub.decode_path("?temp") .. "\\"
    ffmpeg_cmd = "\"%s\""\format FFMPEG
    centipede_select = {}
    for i, centi in ipairs centipedeBonanza
        fname = tempFolder .. "centipede_frame%03d.png"\format counter
        input_file = INPUT_FMT\format fname
        ffmpeg_cmd = ffmpeg_cmd .. " %s"\format input_file
        counter = counter + 1
    ffmpeg_cmd = ffmpeg_cmd .. " -filter_complex \""
    counter = 1
    fcomplex = {}
    firstOne = true
    for i, centi in ipairs centipedeBonanza
        if firstOne
            firstOne = false
            continue
        cropping = CROP_FMT\format centi.width, centi.height, centi.x, centi.y
        complexStuff = "[%d:v]%s[frame%d]"\format counter, cropping, counter
        counter = counter + 1
        table.insert(fcomplex, complexStuff)
    ffmpeg_cmd = ffmpeg_cmd .. table.concat(fcomplex, ";") .. ";"
    counter = 0
    for i, centi in ipairs centipedeBonanza
        if counter == 0
            ffmpeg_cmd = ffmpeg_cmd .. "[0]"
        else
            ffmpeg_cmd = ffmpeg_cmd .. "[frame%d]"\format counter
        counter = counter + 1
    ffmpeg_cmd = ffmpeg_cmd .. "vstack=inputs=%d"\format counter
    ffmpeg_cmd = ffmpeg_cmd .. "[out]\" -map \"[out]\" -c png \"" .. outputFileName .. "\""
    return BASE .. ffmpeg_cmd

MakeCentipede = (subs, sel, res) ->
    xres, yres, ar, artype = aegisub\video_size!
    if yres == nil
        aegisub.log "Please open a video!"
        aegisub\cancel!

    if CountTable(sel) < 1
        aegisub.log "Please select a line!"
        aegisub\cancel!

    project_prop = aegisub\project_properties!
    video_path = project_prop.video_file

    centipedeBonanza = {}

    aegisub.log "Collecting lines...\n"
    ccLine = 0
    lines = LCollect subs, sel, () -> true
    lines\runCallback (lines, line) ->
        lineData = ASSF\parse line
        pos, align, org = lineData\getPosition!

        if line.text == "" or line.text == " "
            -- Empty line, throw it away
            return

        haveDrawings, haveRotation, w, h = false, false
        lineData\callback (section,sections,i) -> haveDrawings = true,
            ASSF.Section.Drawing

        if haveDrawings
            aegisub.log "Sorry, this script does not support drawing yet"
            aegisub\cancel!

        lineBounds = lineData\getLineBounds true

        w, h = lineBounds.w, lineBounds.h

        realHeight = {
            top: lineBounds[1].y,
            bottom: lineBounds[2].y,
        }
        realWidth = {
            left: 0,
            right: xres,
        }

        halfPad = res.padding / 2

        -- Check if the image crop will be out of bounds
        finalH = h + res.padding
        if finalH > yres
            finalH = yres
        elseif finalH < 0
            finalH = 0
        finalY = realHeight.top - halfPad
        if finalY > yres
            finalY = yres
        elseif finalY < 0
            finalY = 0

        realFrame = aegisub.frame_from_ms(line.start_time)

        finalized = {
            sortFrame: line.start_time,
            frame: realFrame,
            width: xres,
            height: finalH,
            x: 0,
            y: finalY,
        }
        if res.dryRun
            aegisub.log ">> Raw data for line %d: %s\n"\format ccLine, json.encode(finalized)
        ccLine = ccLine + 1

        table.insert(centipedeBonanza, finalized)

    actualFiltered = 0
    if CountTable(centipedeBonanza) < 1
        aegisub.log "All selected lines only contains empty lines, so nothing is selected!"
        aegisub\cancel!
    elseif CountTable(centipedeBonanza) < 2
        aegisub.log "Please select more than 1 for the centipede (empty lines, not counted)"
        aegisub\cancel!

    fname = aegisub\file_name!
    scriptPath = aegisub.decode_path("?script") .. "\\"
    tempFolder = aegisub.decode_path("?temp") .. "\\"
    ass_file = scriptPath .. fname
    finalized_centipede = scriptPath .. "centipede%dframe_%s.png"\format ccLine, fname
    aegisub.log "Generating output to %s\n"\format finalized_centipede

    table.sort centipedeBonanza, (a, b) -> a.sortFrame < b.sortFrame
    if res.dryRun
        aegisub.log "Dry running, this script will be run:\n\n---\n"
        fftext = BASE_STRING\format script_version
        fftext = fftext .. "setlocal\n"
        uncroppedCmd = GenerateUncroppedImage centipedeBonanza, ass_file, video_path
        fftext = fftext .. uncroppedCmd .. "\n\n"
        centipedImage = GenerateFinalCentipede centipedeBonanza, finalized_centipede
        fftext = fftext .. centipedImage .. "\n\n"
        fftext = fftext .. "endlocal\n"
        aegisub.log fftext
        aegisub.log "---\n" 
        return lines\getSelection!

    temp_file = aegisub.decode_path("?temp/centipede.bat")

    fh = io.open(temp_file, "w")
    fh\write BASE_STRING\format script_version
    fh\write "setlocal\r\n"
    uncroppedCmd = GenerateUncroppedImage centipedeBonanza, ass_file, video_path
    fh\write uncroppedCmd .. "\n\n"
    centipedImage = GenerateFinalCentipede centipedeBonanza, finalized_centipede
    fh\write centipedImage .. "\n\n"
    fh\write "endlocal\r\n"
    fh\close!

    aegisub.log "Executing script...\n"
    os.execute '"' .. temp_file .. '"'
    aegisub.log "Cleaning up file...\n"
    os.remove temp_file
    counter = 0
    for i, centi in ipairs centipedeBonanza
        fname = tempFolder .. "centipede_frame%03d.png"\format counter
        counter = counter + 1
        os.remove fname

    aegisub.log "Centipede generated!"

    return lines\getSelection!


CentipedeDialog = (subs, sel, res) ->
    dialog = {
        main: {
            paddingLabel: {
                class: "label",
                x: 0,
                y: 0,
                width: 1,
                height: 1,
                label: "Padding: "
            }
            padding: {
                class: "intedit",
                x: 1,
                y: 0,
                width: 1,
                height: 1,
                min: 1,
                value: 30,
                config: true,
                hint: "Overall height padding (in pixel). For examples 30 is the value, this will set the top and bottom padding as 15px"
            },
            dryRun: {
                class: "checkbox",
                x: 0,
                y: 1,
                width: 2,
                height: 1,
                value: false,
                config: false,
                label: "Dry run",
                hint: "This will not run the script, but instead will output out the script that will be run if you use it."
            }
        }
    }

    options = ConfigHandler dialog, depCtrl.configFile, false, script_version, depCtrl.configDir
    options\read!
    options\updateInterface "main"
    btn, res = aegisub.dialog.display dialog.main
    if btn
        options\updateConfiguration res, "main"
        options\write!
        MakeCentipede subs, sel, res


depCtrl\registerMacro CentipedeDialog, ->
    if aegisub.project_properties!.video_file == ""
        return false, "A video must be loaded to run #{script_name}."
    else return true, script_description
