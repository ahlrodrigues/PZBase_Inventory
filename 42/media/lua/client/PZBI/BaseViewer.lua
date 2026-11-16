-- PZBase Inventory (cliente): mostra as bases existentes no save.
-- Botão direito num tile: "PZBI: ver bases". Destaca cada base com a cor da área dos animais
-- por alguns segundos e fala um resumo (cidade e dono) no personagem.
-- Lê o índice e os registros de base do ModData (gravados pelo servidor em BaseServer.lua).
-- Status: NÃO testado em jogo. Depende de ModData.get no cliente (em solo, o servidor é o mesmo processo).

require "PZBI/Config"

local INDEX_KEY = PZBI.MOD_DATA_KEY .. "_bases"
local SHOW_FRAMES = 300   -- quantos frames o destaque fica visível

local function baseKey(id)
    return PZBI.MOD_DATA_KEY .. "_base_" .. tostring(id)
end

local function zoneColor()
    return {
        r = DesignationZoneAnimal and DesignationZoneAnimal.ZONE_COLOR_R or 0.2,
        g = DesignationZoneAnimal and DesignationZoneAnimal.ZONE_COLOR_G or 0.6,
        b = DesignationZoneAnimal and DesignationZoneAnimal.ZONE_COLOR_B or 0.2,
        a = 0.5,
    }
end

-- Bases ativas gravadas no ModData.
local function listBases()
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

local highlighted = {}   -- bases a destacar
local framesLeft = 0

local function say(player, text)
    if player and player.Say then player:Say(text) end
end

local function showBases(playerIndex)
    local player = getSpecificPlayer(playerIndex)
    if not player then return end
    local bases = listBases()
    if #bases == 0 then
        say(player, "Nenhuma base marcada neste save.")
        return
    end
    local parts = {}
    for _, base in ipairs(bases) do
        table.insert(parts, base.city .. " (" .. tostring(base.owner) .. ")")
    end
    say(player, #bases .. " base(s): " .. table.concat(parts, "; "))
    highlighted = bases
    framesLeft = SHOW_FRAMES
end

-- Desenha os destaques enquanto o tempo não acabar.
Events.OnRenderTick.Add(function()
    if framesLeft <= 0 then return end
    framesLeft = framesLeft - 1
    local c = zoneColor()
    for _, base in ipairs(highlighted) do
        local a = base.area
        addAreaHighlightForPlayer(0, a.x1, a.y1, a.x2 + 1, a.y2 + 1, a.z, c.r, c.g, c.b, c.a)
    end
end)

Events.OnFillWorldObjectContextMenu.Add(function(playerIndex, context, worldObjects, test)
    local player = getSpecificPlayer(playerIndex)
    if not player then return end
    context:addOption("PZBI: ver bases", nil, function()
        showBases(playerIndex)
    end)
end)
