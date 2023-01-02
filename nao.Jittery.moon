[[
    A script to jitter a specific/multiple tags
    on a selected line(s) with random amount.

    The GUI will be generated based on the available
    and valid tags on the selected line(s).

    The jitter amount calculation are based on
    unanimted's Hyperdimensional Relocator "shake" function.
]]

export script_name = "Jittery"
export script_description = "Jitter/shake many type of ASS tags with a random amount"
export script_version = "0.1.0"
export script_author = "noaione"
export script_namespace = "nao.Jittery"

DependencyControl = require 'l0.DependencyControl'
depCtrl = DependencyControl{
    feed: "https://raw.githubusercontent.com/noaione/.aegibulan/master/DependencyControl.json",
    {
        {"a-mo.LineCollection", version: "1.3.0", url: "https://github.com/TypesettingTools/Aegisub-Motion",
        feed: "https://raw.githubusercontent.com/TypesettingTools/Aegisub-Motion/DepCtrl/DependencyControl.json"},
        {"l0.ASSFoundation", version: "0.5.0", url: "https://github.com/TypesettingTools/ASSFoundation",
        feed: "https://raw.githubusercontent.com/TypesettingTools/ASSFoundation/master/DependencyControl.json"},
    }
}

LineCollection, ASSF = depCtrl\requireModules!
logger = depCtrl\getLogger!

-- The valid tags that can be changed.
assf_valid = {
    "alpha", "alpha1", "alpha2", "alpha3", "alpha4",
    "fontsize", "scale_x", "scale_y",
    "angle", "angle_x", "angle_y",
    "shear_x", "shear_y",
    "position", "move",
    "outline", "shadow", "outline_x", "outline_y", "shadow_x", "shadow_y", "blur"
}
-- The mapping to the original ass tag name
assf_to_tags = {
    alpha: "alpha",
    alpha1: "1a",
    alpha2: "2a",
    alpha3: "3a",
    alpha4: "4a",
    fontsize: "fs",
    scale_x: "fscx",
    scale_y: "fscy",
    angle: "frz",
    angle_x: "frx",
    angle_y: "fry",
    shear_x: "fax",
    shear_y: "fay",
    position: "pos",
    move: "move",
    outline: "bord",
    shadow: "shad",
    outline_x: "xbord",
    outline_y: "ybord",
    shadow_x: "xshad",
    shadow_y: "yshad",
    blur: "blur"
}

num_to_hex = (number, max, min) ->
    if max ~= nil and number > max
        number = max
    if min ~= nil and number < min
        number = min
    hexa = string.format "%02x", number
    return hexa

hex_to_num = (hexa) ->
    number = tonumber hexa, 16
    return number

is_in = (value, table) ->
    for i in *table
        if i == value
            return true
    return false

collect_tags = (subs, sel) ->
    tag_table = {}
    logger\log "Collecting tags from selected line(s)..."
    lines = LineCollection subs, sel
    lines\runCallback (lines, line, i) ->
        data = ASSF\parse line
        data\callback (section) ->
            if section.class == ASSF.Section.Tag
                for tag in *section\getTags!
                    tagname = tag.__tag.name
                    isValidTag = is_in(tagname, assf_valid)
                    isInTable = is_in(tagname, tag_table)
                    if isValidTag and not isInTable
                        tag_table[#tag_table + 1] = tagname

    -- stringify the tag_table for log
    if #tag_table == 0
        logger\log "No valid tags found on selected line(s)!"
        aegisub.cancel!
    else
        return tag_table

create_dialogs = (tag_table) ->
    dialogs = {
        {
            x: 0, y: 0, class: "label",
            label: "Jitter amount",
            name: "label_jitter"
        },
        {
            x: 0, y: 1, class: "floatedit",
            hint: "The amount of shifting/jitter to apply (randomized)",
            value: 0.0, min: 0.0,
            name: "jitter_amount"
        },
        {
            x: 0, y: 2, class: "checkbox",
            label: "Smooth", value: false,
            hint: "Smooth the jitter by averaging the previous and next value",
            name: "jitter_smooth"
        }
        {
            x: 1, y: 0, class: "label",
            label: "Select tags to jitter",
            name: "label_tags"
        }
    }

    -- the selection is on the right side, start at x=1, y=1
    max_col = math.max math.ceil(math.sqrt #tag_table), 1
    count = 0
    -- iterate throught the tag_table
    for tagname in *tag_table
        x = 1 + count % max_col
        y = 1 + math.floor count / max_col
        count += 1

        -- add the tagname to the dialog
        aegi_tag = assf_to_tags[tagname]
        dialogs[#dialogs + 1] = {
            x: x, y: y, class: "checkbox",
            label: aegi_tag, value: false,
            name: "tag_" .. tagname
        }
    return dialogs

run_jitter = (subs, sel, res) ->
    enabled_tags = {}
    for key, value in pairs res
        -- some sketchy string checking because
        -- lua is being a bitch.
        isTag = string.sub(key, 1, 4) == "tag_"
        if isTag and value
            enabled_tags[#enabled_tags + 1] = key\sub(5)

    if #enabled_tags == 0
        logger\log "No tags selected!"
        aegisub.cancel!
        return

    smooth = res.jitter_smooth

    lines = LineCollection subs, sel
    logger\log "Jittering " .. #lines .. " line(s)..."
    lines\runCallback (lines, line) ->
        lineData = ASSF\parse line
        pos, align, org = lineData\getPosition!

        for tagname in *enabled_tags
            if tagname == "position" or tagname == "move" then
                jit = math.random(-100, 100) / 100 * res.jitter_amount
                if smooth and ljit != nil then
                    jit = (jit + 3 * ljit) / 4
                ljit = jit
                if pos.class == ASSF.Tag.Move
                    pos.startPos.x = pos.startPos.x + jit
                    pos.startPos.y = pos.startPos.y + jit
                    pos.endPos.x = pos.endPos.x + jit
                    pos.endPos.y = pos.endPos.y + jit
                else
                    pos.x = pos.x + jit
                    pos.y = pos.y + jit
                lineData\replaceTags {pos}
            else
                lineData\modTags tagname, (tag) ->
                    jit = math.random(-100, 100) / 100 * res.jitter_amount
                    if smooth and ljit != nil then
                        jit = (jit + 3 * ljit) / 4
                    ljit = jit
                    tag\add jit
        lineData\commit!
    lines\replaceLines!

main = (subs, sel) ->
    buttons = {"Jitter", "Cancel"}
    tag_table = collect_tags subs, sel
    DIALOGS = create_dialogs tag_table

    btn, res = aegisub.dialog.display DIALOGS, buttons
    switch btn
        when "Cancel" then aegisub.cancel!
        when "Jitter" then run_jitter subs, sel, res

depCtrl\registerMacro main
