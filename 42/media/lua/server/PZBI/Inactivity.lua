-- PZBase Inventory (servidor): inatividade do dono (especificação, seção 6).
-- Registra o último login de cada jogador (tempo real, ms) e remove as bases de donos inativos.
-- Ordem ao entrar no jogo: primeiro verifica os donos (com o último login ANTERIOR), depois registra o login atual.
-- Regra pura em shared/PZBI/InactivityRules.lua. Remoção em BaseServer.lua (PZBI.removeBase).
-- Status: NÃO testado em jogo. Pendências: contêineres sem dono (seção 3) e notificação de inscritos.

require "PZBI/Config"
require "PZBI/InactivityRules"
require "PZBI/BaseServer"

local PLAYERS_KEY = PZBI.MOD_DATA_KEY .. "_players"
local INDEX_KEY = PZBI.MOD_DATA_KEY .. "_bases"

local function baseKey(id)
    return PZBI.MOD_DATA_KEY .. "_base_" .. tostring(id)
end

local function nowMs()
    return getTimestampMs()
end

-- Registra o login do jogador local (chamado depois da verificação).
local function markLocalPlayerSeen()
    local player = getPlayer()
    if not player then return end
    local seen = ModData.getOrCreate(PLAYERS_KEY)
    seen[player:getUsername()] = nowMs()
    ModData.transmit(PLAYERS_KEY)
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

-- Ao entrar no jogo: checa com o login anterior e só então registra este login.
Events.OnGameStart.Add(function()
    checkInactiveOwners()
    markLocalPlayerSeen()
end)

-- Durante o jogo: o dono está ativo, então registra o login e checa os demais.
Events.EveryHours.Add(function()
    markLocalPlayerSeen()
    checkInactiveOwners()
end)
