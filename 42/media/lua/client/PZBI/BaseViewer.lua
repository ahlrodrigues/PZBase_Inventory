-- PZBase Inventory (cliente): listar e destacar as bases do save.
-- Usada pelo submenu "PZBase > Ver áreas" (ver BaseMenu.lua).
-- Lê o índice e os registros de base do ModData (gravados pelo servidor em BaseServer.lua).
-- Status: NÃO testado em jogo. Depende de ModData.get no cliente (em solo, o servidor é o mesmo processo).

require "PZBI/Config"

PZBI = PZBI or {}

local INDEX_KEY = PZBI.MOD_DATA_KEY .. "_bases"
local SHOW_FRAMES = 300   -- quantos frames o destaque fica visível

local function baseKey(id)
    return PZBI.MOD_DATA_KEY .. "_base_" .. tostring(id)
end

-- Bases ativas gravadas no ModData, cada uma com id, owner, city e area.
function PZBI.listBases()
    local index = ModData.get(INDEX_KEY)
    local bases = {}
    if not index or not index.ids then return bases end
    for _, id in ipairs(index.ids) do
        local record = ModData.get(baseKey(id))
        if record and not record.removed and record.area then
            table.insert(bases, record)
        end
    end
    return bases
end

local highlighted = {}
local framesLeft = 0

local function zoneColor()
    return {
        r = DesignationZoneAnimal and DesignationZoneAnimal.ZONE_COLOR_R or 0.2,
        g = DesignationZoneAnimal and DesignationZoneAnimal.ZONE_COLOR_G or 0.6,
        b = DesignationZoneAnimal and DesignationZoneAnimal.ZONE_COLOR_B or 0.2,
        a = 0.5,
    }
end

-- Fala o resumo e destaca as áreas por alguns segundos.
function PZBI.showBases(player)
    local bases = PZBI.listBases()
    if #bases == 0 then
        if player.Say then player:Say("Nenhuma base marcada neste save.") end
        return
    end
    local parts = {}
    for _, base in ipairs(bases) do
        table.insert(parts, base.city .. " (" .. tostring(base.owner) .. ")")
    end
    if player.Say then player:Say(#bases .. " base(s): " .. table.concat(parts, "; ")) end
    highlighted = bases
    framesLeft = SHOW_FRAMES
end

Events.OnRenderTick.Add(function()
    if framesLeft <= 0 then return end
    framesLeft = framesLeft - 1
    local c = zoneColor()
    for _, base in ipairs(highlighted) do
        local a = base.area
        addAreaHighlightForPlayer(0, a.x1, a.y1, a.x2 + 1, a.y2 + 1, a.z, c.r, c.g, c.b, c.a)
    end
end)
