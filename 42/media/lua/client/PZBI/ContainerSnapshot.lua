-- PZBase Inventory (cliente): envia o instantâneo do contêiner ao fechar a interface.
-- Confirmado no código do jogo: ISInventoryPage:close() e self.inventoryPane.inventory.
-- A validar em jogo: origem da posição (getSourceGrid) e tipo do objeto (getParent).

require "PZBI/Config"

local CMD_MODULE = "PZBI"
local CMD_SNAPSHOT = "snapshot"

-- Monta a lista agregada de itens: { ["Base.Apple"] = 3, ... }
local function collectItems(container)
    local counts = {}
    local items = container:getItems()
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        local fullType = item:getFullType()
        counts[fullType] = (counts[fullType] or 0) + 1
    end
    return counts
end

-- Converte a tabela agregada em lista simples (formato enviado ao servidor).
local function toList(counts)
    local list = {}
    for fullType, count in pairs(counts) do
        table.insert(list, { type = fullType, count = count })
    end
    return list
end

-- Envia o instantâneo se o contêiner tiver posição conhecida (contêiner de mundo).
local function sendSnapshot(playerIndex, container)
    if not container then return end
    local grid = container:getSourceGrid()
    if not grid then return end -- contêiner de veículo ou inventário do jogador: tratado depois

    local parent = container:getParent()
    if not parent then return end
    local objectType = parent:getObjectName()

    local playerObj = getSpecificPlayer(playerIndex)
    if not playerObj then return end

    sendClientCommand(playerObj, CMD_MODULE, CMD_SNAPSHOT, {
        x = grid:getX(),
        y = grid:getY(),
        z = grid:getZ(),
        objectType = objectType,
        items = toList(collectItems(container)),
    })
end

-- Hook: envolve o método original de fechamento sem substituí-lo.
local originalClose = ISInventoryPage.close
function ISInventoryPage:close()
    local container = self.inventoryPane and self.inventoryPane.inventory
    sendSnapshot(self.player, container)
    originalClose(self)
end
