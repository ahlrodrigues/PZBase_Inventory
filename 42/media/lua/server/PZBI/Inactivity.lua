-- PZBase Inventory (servidor): inatividade do dono (especificação, seção 6).
-- Registra o último acesso de cada jogador (em horas de jogo) e remove as bases de donos inativos.
-- Regra pura em shared/PZBI/InactivityRules.lua. Remoção em BaseServer.lua (PZBI.removeBase).
-- Status: NÃO testado em jogo. Pendências: contêineres sem dono (seção 3) e notificação dos inscritos
-- (ainda não há inscrições); no multijogador, o último acesso só é registrado para o jogador local.

require "PZBI/Config"
require "PZBI/InactivityRules"
require "PZBI/BaseServer"

local PLAYERS_KEY = PZBI.MOD_DATA_KEY .. "_players"
local INDEX_KEY = PZBI.MOD_DATA_KEY .. "_bases"

local function baseKey(id)
    return PZBI.MOD_DATA_KEY .. "_base_" .. tostring(id)
end

local function nowHours()
    return getGameTime():getWorldAgeHours()
end

-- Registra o último acesso do jogador local.
local function markLocalPlayerSeen()
    local player = getPlayer()
    if not player then return end
    local seen = ModData.getOrCreate(PLAYERS_KEY)
    seen[player:getUsername()] = nowHours()
    ModData.transmit(PLAYERS_KEY)
end

-- Remove as bases cujo dono está inativo há mais de INACTIVITY_DAYS.
local function checkInactiveOwners()
    local index = ModData.get(INDEX_KEY)
    if not index or not index.ids then return end
    local seen = ModData.getOrCreate(PLAYERS_KEY)
    local now = nowHours()
    for _, id in ipairs(index.ids) do
        local record = ModData.get(baseKey(id))
        if record and not record.removed then
            local last = seen[record.owner] or record.createdAt
            if PZBI.InactivityRules.isInactive(last, now, PZBI.INACTIVITY_DAYS) then
                PZBI.removeBase(record, "dono inativo desde " .. tostring(last) .. " horas de jogo")
            end
        end
    end
end

Events.OnGameStart.Add(markLocalPlayerSeen)
Events.EveryHours.Add(function()
    markLocalPlayerSeen()
    checkInactiveOwners()
end)
