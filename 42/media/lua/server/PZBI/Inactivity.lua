-- PZBase Inventory (servidor): inatividade do dono (especificação, seção 6).
-- O cliente avisa o servidor ao entrar e a cada hora (ActivityPing.lua). O servidor registra o login
-- do jogador que enviou o aviso, e não o jogador local: assim funciona em solo e em multijogador.
-- Ordem ao receber um aviso: primeiro verifica os donos (com o último login ANTERIOR), depois registra este.
-- Regra pura em shared/PZBI/InactivityRules.lua. Remoção em BaseServer.lua (PZBI.removeBase).
-- Status: NÃO testado em jogo nem em servidor dedicado.

require "PZBI/Config"
require "PZBI/InactivityRules"
require "PZBI/BaseServer"

local CMD_MODULE = "PZBI"
local CMD_SEEN = "seen"
local PLAYERS_KEY = PZBI.MOD_DATA_KEY .. "_players"
local INDEX_KEY = PZBI.MOD_DATA_KEY .. "_bases"

local function baseKey(id)
    return PZBI.MOD_DATA_KEY .. "_base_" .. tostring(id)
end

local function nowMs()
    return getTimestampMs()
end

-- Remove as bases cujo dono não logou há mais de INACTIVITY_DAYS.
local function checkInactiveOwners()
    local index = ModData.get(INDEX_KEY)
    if not index or not index.ids then return end
    local seen = ModData.getOrCreate(PLAYERS_KEY)
    local now = nowMs()
    for _, id in ipairs(index.ids) do
        local record = ModData.get(baseKey(id))
        if record and not record.removed then
            local lastLogin = seen[record.owner] or record.createdAt
            if PZBI.InactivityRules.isInactive(lastLogin, now, PZBI.INACTIVITY_DAYS) then
                local days = (now - lastLogin) / PZBI.InactivityRules.MS_PER_DAY
                PZBI.removeBase(record, string.format("dono sem login ha %.2f dias", days))
            end
        end
    end
end

-- Aviso de atividade de um jogador: checa os demais com o login anterior dele, depois registra o login dele.
local function onSeen(player)
    checkInactiveOwners()
    local seen = ModData.getOrCreate(PLAYERS_KEY)
    seen[player:getUsername()] = nowMs()
    ModData.transmit(PLAYERS_KEY)
end

Events.OnGameStart.Add(function()
    checkInactiveOwners()
end)

Events.EveryHours.Add(function()
    checkInactiveOwners()
end)

Events.OnClientCommand.Add(function(module, command, player, args)
    if module ~= CMD_MODULE or command ~= CMD_SEEN then return end
    onSeen(player)
end)
