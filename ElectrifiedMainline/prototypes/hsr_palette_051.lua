-- 051: native HSR palette experiment. Do not modify rails' geometry or
-- ordinary rail art. Multiply existing static tint on authored native layers.
local M={}
local colors={
    ties={r=.55,g=.82,b=1},
    stone_path={r=.76,g=.89,b=1},
    stone_path_background={r=.86,g=.94,b=1},
}
local rails={
    {"straight-rail","em-high-speed-straight-rail"},
    {"half-diagonal-rail","em-half-diagonal-high-speed-rail"},
    {"curved-rail-a","em-curved-high-speed-rail"},
    {"curved-rail-b","em-curved-high-speed-rail-b"},
}
local directions={"north","northeast","east","southeast","south","southwest","west","northwest"}
local function shade(sprite,c)
    if type(sprite)~="table" then return 0 end
    if sprite.layers then
        local count=0
        for _,layer in ipairs(sprite.layers) do count=count+shade(layer,c) end
        return count
    end
    if sprite.sheet then return shade(sprite.sheet,c) end
    if sprite.sheets then
        local count=0
        for _,sheet in ipairs(sprite.sheets) do count=count+shade(sheet,c) end
        return count
    end
    if sprite.filename or sprite.filenames or sprite.stripes then
        if sprite.draw_as_shadow or sprite.draw_as_light or sprite.apply_runtime_tint then return 0 end
        local t=sprite.tint or {}
        sprite.tint={r=(t.r or t[1] or 1)*c.r,g=(t.g or t[2] or 1)*c.g,
                     b=(t.b or t[3] or 1)*c.b,a=t.a or t[4] or 1}
        return 1
    end
    local count=0
    for _,variation in ipairs(sprite) do count=count+shade(variation,c) end
    return count
end
function M.apply(raw,copy)
    local count=0
    for _,id in ipairs(rails) do
        local rail=assert(raw[id[1]][id[2]])
        rail.pictures=copy(assert(rail.pictures))
        for _,name in ipairs(directions) do
            local piece=rail.pictures[name]
            if piece then
                for layer,c in pairs(colors) do
                    if piece[layer] then count=count+shade(piece[layer],c) end
                end
            end
        end
    end
    return count
end
if data then
    local n=M.apply(data.raw,table.deepcopy)
    log("[EM051] native HSR palette tinted sprite leaves="..n)
end
return M
