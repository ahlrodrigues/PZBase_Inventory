-- PZBase Inventory (cliente): envia o instantâneo do contêiner ao fechar a interface.
-- Confirmado no código do jogo: ISInventoryPage:close() e self.inventoryPane.inventory.
-- A validar em jogo: origem da posição (getSourceGrid) e tipo do objeto (getParent).
-- Versão de diagnóstico (v0.1.1): imprime cada etapa para descobrir onde o envio para.

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
    print("[PZBI] diag: container=" .. tostring(container))
    if not container then return end

    local grid = container:getSourceGrid()
    print("[PZBI] diag: grid=" .. tostring(grid))
    if not grid then return end

    local parent = container:getParent()
    print("[PZBI] diag: parent=" .. tostring(parent))
    if not parent then return end
    local objectType = parent:getObjectName()
    print("[PZBI] diag: objectType=" .. tostring(objectType))

    local playerObj = getSpecificPlayer(playerIndex)
    if not playerObj then
        print("[PZBI] diag: jogador nao encontrado no indice " .. tostring(playerIndex))
        return
    end

    local items = collectItems(container)
    sendClientCommand(playerObj, CMD_MODULE, CMD_SNAPSHOT, {
        x = grid:getX(),
        y = grid:getY(),
        z = grid:getZ(),
        objectType = objectType,
        items = toList(items),
    })
    print("[PZBI] enviado: " .. tostring(objectType) .. " em " .. grid:getX() .. "," .. grid:getY() .. "," .. grid:getZ())
end

-- Hook: envolve o método original de fechamento sem substituí-lo.
local originalClose = ISInventoryPage.close
function ISInventoryPage:close()
    print("[PZBI] diag: hook ISInventoryPage:close chamado")
    local container = self.inventoryPane and self.inventoryPane.inventory
    sendSnapshot(self.player, container)
    originalClose(self)
end
