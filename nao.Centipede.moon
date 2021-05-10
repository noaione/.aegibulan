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
export script_version     = "0.1.0"
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
    }
}

LCollect, ConfigHandler, ASSF = depCtrl\requireModules!

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

GenerateName = (frameName) ->
    return aegisub.decode_path("?temp") .. "\\" .. "centipede_" .. frameName\gsub ":", "_"

GenerateImageCommand = (tableData, assFile, videoFile, shouldCrop) ->
    BASE = "echo Cutting down time %s\n"\format tableData.frame
    assFile = assFile\gsub "\\", "\\\\"
    assFile = assFile\gsub ":", "\\:"
    input_file = INPUT_FMT\format videoFile
    fname = GenerateName(tableData.frame) .. "_frameTemp.png"
    tspart = FRAME_SELECT\format tableData.frame
    assFuck = ASS_FMT\format assFile
    output_file = OUTPUT_FMT\format fname
    cropping = CROP_FMT\format tableData.width, tableData.height, tableData.x, tableData.y
    ffmpeg_cmd = "%s %s %s -vf \"%s"\format FFMPEG, input_file, tspart, assFuck
    if shouldCrop
        ffmpeg_cmd = ffmpeg_cmd .. ",%s"\format cropping
    ffmpeg_cmd = ffmpeg_cmd .. "\" %s"\format output_file
    return BASE .. ffmpeg_cmd .. "\n\n", fname

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
    lines = LCollect subs, sel, () -> true
    lines\runCallback (lines, line) ->
        lineData = ASSF\parse line
        pos, align, org = lineData\getPosition!

        if line.text == "" or line.text == " "
            -- Empty line, throw it away
            return

        st = tonumber(line.start_time)
        timecode = ToTimecode st

        haveDrawings, haveRotation, w, h = false, false
        lineData\callback (section,sections,i) -> haveDrawings = true,
            ASSF.Section.Drawing

        if haveDrawings
            aegisub.log "Sorry, this script does not support drawing yet"
            aegisub\cancel!

        metrics, tagList, shape = lineData\getTextMetrics true
        w, h = metrics.width, metrics.height

        realHeight = CalculateHeight pos.y, h, align.value
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

        finalized = {
            sortFrame: st,
            frame: timecode,
            width: xres,
            height: finalH,
            x: 0,
            y: finalY,
        }

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
    ass_file = scriptPath .. fname
    finalized_centipede = scriptPath .. "centipede_%s.png"\format fname
    aegisub.log "Generating output to %s\n"\format finalized_centipede

    temp_file = aegisub.decode_path("?temp/centipede.bat")

    fh = io.open(temp_file, "w")
    fh\write BASE_STRING\format script_version
    fh\write "setlocal\r\n"
    table.sort centipedeBonanza, (a, b) -> a.sortFrame < b.sortFrame
    finalizedFileName = {}
    shouldCrop = false
    for i, centi in ipairs centipedeBonanza
        cmd_add, filename = GenerateImageCommand centi, ass_file, video_path, shouldCrop
        fh\write cmd_add
        table.insert(finalizedFileName, filename)
        if not shouldCrop
            shouldCrop = true
    FINAL_COMMAND = FFMPEG
    totalPairs = 0
    for i, fnameFinal in ipairs finalizedFileName
        inputF = INPUT_FMT\format fnameFinal
        FINAL_COMMAND = FINAL_COMMAND .. " %s"\format inputF
        totalPairs = totalPairs + 1
    final_cmd_extension = " -filter_complex \"vstack=inputs=%d\" -c png \"%s\""\format totalPairs, finalized_centipede
    FINAL_COMMAND = FINAL_COMMAND .. final_cmd_extension
    fh\write "echo Generating final centipede images...\n" .. FINAL_COMMAND .. "\n\n"
    fh\write "endlocal\r\n"
    fh\close!
    aegisub.log "Executing script...\n"
    os.execute '"' .. temp_file .. '"'
    aegisub.log "Cleaning up file...\n"
    os.remove temp_file
    for i, fnameFinal in ipairs finalizedFileName
        os.remove fnameFinal

    aegisub.log "Centipede generated!"

    -- someone please revive the Aegisub website so I can see the correct API to be used
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
