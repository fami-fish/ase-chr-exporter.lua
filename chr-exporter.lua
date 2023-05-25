-- Licensed under GNU GPLv3 --

ScriptInfo = {
    version = "1.1.0",
    remote = "https://github.com/nick-1666/ase-chr-exporter.lua/"
}

local truth_table = {
    [00] = function()
        return 0, 0
    end,
    [01] = function()
        return 1, 0
    end,
    [02] = function()
        return 0, 1
    end,
    [03] = function()
        return 1, 1
    end
}

local dlg = Dialog {title = "CHR Exporter"}

local function get_tile_stream(img, tx, ty)
    local bp1 = {}
    local bp2 = {}

    for y = 0, 8 - 1 do
        local byte_1 = 0
        local byte_2 = 0
        for x = 0, 8 - 1 do
            local index = img:getPixel(tx * 8 + x, ty * 8 + y) % 4

            local v1, v2 = truth_table[index]()

            byte_1 = byte_1 + v1 * 2 ^ (-x + 7)
            byte_2 = byte_2 + v2 * 2 ^ (-x + 7)
        end

        table.insert(bp1, byte_1)
        table.insert(bp2, byte_2)
    end

    local sbp1 = string.char(table.unpack(bp1))
    local sbp2 = string.char(table.unpack(bp2))

    local tile = sbp1 .. sbp2
    return tile
end

dlg:file {
    id = "exportFile",
    title = "Save as...",
    save = true,
    filename = app.activeSprite ~= nil and app.fs.filePathAndTitle(app.activeSprite.filename) .. ".chr" or "",
    filetypes = {"chr"}
}

dlg:button {
    id = "ok",
    text = "&Export",
    focus = true,
    onclick = function()
        local sprite = app.activeSprite
        if sprite == nil then
            print("You must be on a sprite to export!")
            dlg:close()
            return
        end

        local frame = app.activeFrame
        local img = Image(sprite.spec)

        if img.colorMode ~= ColorMode.INDEXED then
            print("Image's Color Mode must be indexed!")
            dlg:close()
            return
        end

        img:drawSprite(sprite, frame)

        local w = sprite.width
        local h = sprite.height

        if w % 8 ~= 0 or h % 8 ~= 0 then
            print("Image's width and height must be divisible by 8")
            dlg:close()
            return
        end

        local tw = w / 8
        local th = h / 8

        local f = io.open(dlg.data.exportFile, "w")
        io.output(f)

        local stream = ""

        for ty = 0, th - 1 do
            for tx = 0, tw - 1 do
                stream = stream .. get_tile_stream(img, tx, ty)
            end
        end

        f:write(stream)
        f:close()
        dlg:close()
    end
}

dlg:button {
    id = "cancel",
    text = "&Cancel",
    onclick = function()
        dlg:close()
    end
}
dlg:label {
    text = "v" .. ScriptInfo.version .. " - Nick-1666"
}
dlg:show {wait = false}
