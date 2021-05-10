[[
    Automatically realign to a new alignment without making too much changes on position.

    This is not yet completed, and need more small adjustments to make shifting perfect.
]]

export script_name        = "Auto Realign"
export script_description = "Automatically realign to a new alignment without making too much changes on position."
export script_version     = "0.1.0"
export script_author      = "N4O"
export script_namespace   = "nao.AutoRealign"

DependencyControl = require "l0.DependencyControl"
rec = DependencyControl{
    feed: "https://raw.githubusercontent.com/noaione/.aegibulan/master/DependencyControl.json",
    {
        {"a-mo.LineCollection", version: "1.3.0", url: "https://github.com/TypesettingTools/Aegisub-Motion",
        feed: "https://raw.githubusercontent.com/TypesettingTools/Aegisub-Motion/DepCtrl/DependencyControl.json"},
        {"l0.ASSFoundation", version: "0.5.0", url: "https://github.com/TypesettingTools/ASSFoundation",
        feed: "https://raw.githubusercontent.com/TypesettingTools/ASSFoundation/master/DependencyControl.json"},
    }
}

LineCollection, ASSF = rec\requireModules!

-----------------------------
-- x0,y0 ----------------
--   |                   |
--   |                   |
--    ---------------- x1,y1
-----------------------------
NudgeAmount = (x0, y0, x1, y1, oldAlignment, newAlignment) ->
    -- Start by creating an unholy table
    halfX = (x1 - x0) / 2
    halfY = (y1 - y0) / 2
    realPosition = {
        "1": { x0, y1 },
        "2": { x0 + halfX, y1 },
        "3": { x1, y1 },
        "4": { x0, y0 + halfY },
        "5": { x0 + halfX, y0 + halfY },
        "6": { x1, y0 + halfY },
        "7": { x0, y0 },
        "8": { x0 + halfX, y0 },
        "9": { x1, y0 }
    }

    { xOld, yOld } = realPosition[oldAlignment]
    { xNew, yNew } = realPosition[newAlignment]
    return xNew - xOld, yNew - yOld

Realign = (subs, sel, _an) ->
    xres, yres, ar, artype = aegisub\video_size!
    if yres == nil
        aegisub.log "ERROR: Please provide video for calculation."
        aegisub\cancel!

    lines = LineCollection subs, sel, () -> true
    lines\runCallback (lines, line) ->
        lineData = ASSF\parse line
        pos, align, org = lineData\getPosition!

        haveDrawings, haveRotation, w, h = false, false
        lineData\callback (section,sections,i) -> haveDrawings = true,
            ASSF.Section.Drawing

        bounds = lineData\getLineBounds true
        x0, y0, x1, y1 = bounds[1].x, bounds[1].y, bounds[2].x, bounds[2].y
        w, h = bounds.w, bounds.h

        shiftX, shiftY = NudgeAmount x0, y0, x1, y1, tostring(align.value), tostring(_an)

        newAlign = align\copy!
        newAlign.value = tonumber _an

        new_posX = pos.x + shiftX
        new_posY = pos.y + shiftY

        -- Replace \pos number with the new calculated one
        pos.x = new_posX
        pos.y = new_posY

        lineData\replaceTags {newAlign, pos}

        lineData\commit!
    lines\replaceLines!


Align1 = (subs, sel) ->
    -- Align to \an1
    Realign(subs, sel, 1)

Align2 = (subs, sel) ->
    -- Align to \an2
    Realign(subs, sel, 2)

Align3 = (subs, sel) ->
    -- Align to \an3
    Realign(subs, sel, 3)

Align4 = (subs, sel) ->
    -- Align to \an4
    Realign(subs, sel, 4)

Align5 = (subs, sel) ->
    -- Align to \an5
    Realign(subs, sel, 5)

Align6 = (subs, sel) ->
    -- Align to \an6
    Realign(subs, sel, 6)

Align7 = (subs, sel) ->
    -- Align to \an7
    Realign(subs, sel, 7)

Align8 = (subs, sel) ->
    -- Align to \an8
    Realign(subs, sel, 8)

Align9 = (subs, sel) ->
    -- Align to \an9
    Realign(subs, sel, 9)

rec\registerMacros{
	{"Alignment 1 {\\an1}", "Realign to \\an1", Align1},
	{"Alignment 2 {\\an2}", "Realign to \\an2", Align2},
	{"Alignment 3 {\\an3}", "Realign to \\an3", Align3},
	{"Alignment 4 {\\an4}", "Realign to \\an4", Align4},
	{"Alignment 5 {\\an5}", "Realign to \\an5", Align5},
	{"Alignment 6 {\\an6}", "Realign to \\an6", Align6},
	{"Alignment 7 {\\an7}", "Realign to \\an7", Align7},
	{"Alignment 8 {\\an8}", "Realign to \\an8", Align8},
	{"Alignment 9 {\\an9}", "Realign to \\an9", Align9}}, 'Auto Realign'