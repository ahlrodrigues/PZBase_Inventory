-- PZBase Inventory (cliente): leitura automática dos contêineres quando o jogador está perto da base.
-- Mesma ideia do Proximity Inventory: basta estar perto para os contêineres carregados serem lidos,
-- sem abrir cada um. Aqui a referência é a área marcada da base (com uma margem em volta).
-- Só envia quando os itens de um contêiner mudam (ContainerSnapshot.lua).
-- Varredura limitada a um intervalo mínimo, para não pesar no jogo.
-- Status: NÃO testado em jogo.

local NEAR_MARGIN = 12        -- tiles em volta da área da base em que a leitura acontece
local THROTTLE_MS = 3000      -- intervalo mínimo entre varreduras

local lastRun = 0

-- O jogador está dentro da área da base ou a até NEAR_MARGIN tiles dela, no mesmo andar.
local function nearBase(player, area)
    if player:getZ() ~= area.z then return false end
    local px, py = player:getX(), player:getY()
    return px >= area.x1 - NEAR_MARGIN and px <= area.x2 + NEAR_MARGIN
        and py >= area.y1 - NEAR_MARGIN and py <= area.y2 + NEAR_MARGIN
end

-- Lê os contêineres carregados dentro da área da base.
local function scanArea(playerIndex, area)
    local cell = getCell()
    if not cell then return end
    for x = area.x1, area.x2 do
        for y = area.y1, area.y2 do
            local sq = cell:getGridSquare(x, y, area.z)
            if sq then
                local objs = sq:getObjects()
                for i = 0, objs:size() - 1 do
                    local obj = objs:get(i)
                    local c = obj and obj:getContainer()
                    if c then
                        PZBI.sendSnapshotIfChanged(playerIndex, c)
                    end
                end
            end
        end
    end
end

Events.OnPlayerUpdate.Add(function(player)
    if not player or not player:isLocalPlayer() then return end
    local now = getTimestampMs()
    if now - lastRun < THROTTLE_MS then return end
    lastRun = now
    if not PZBI.listBases or not PZBI.sendSnapshotIfChanged then return end
    local playerIndex = player:getPlayerNum()
    for _, base in ipairs(PZBI.listBases()) do
        if nearBase(player, base.area) then
            scanArea(playerIndex, base.area)
        end
    end
end)
