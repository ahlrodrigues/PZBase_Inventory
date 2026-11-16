-- PZBase Inventory (cliente): envia o instantâneo do contêiner ao fechar a janela.
-- Achado no código do jogo: ISPanel:close() apenas chama self:setVisible(false), e a
-- janela de contêiner também pode ser escondida direto com setVisible(false).
-- Por isso o hook fica em setVisible, que cobre os dois caminhos.
-- Validado em jogo (v0.1.4): contêineres de mundo (móveis) retornam grid e objeto pai.
-- Ainda não lidos: contêineres de veículo e o inventário do jogador (sem posição).

require "PZBI/Config"
require "PZBI/ContainerRules"

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
    if not grid then return end

    local parent = container:getParent()
    if not parent then return end
    local sprite = parent:getSprite()
    local objectType = (sprite and sprite:getName()) or parent:getObjectName()

    local playerObj = getSpecificPlayer(playerIndex)
    if not playerObj then return end
    -- Só contêineres dentro da área de uma base são lidos (ver ContainerRules.lua).
    if not PZBI.ContainerRules.findOwnerBase(PZBI.listBases(), grid:getX(), grid:getY(), grid:getZ()) then return end

    local items = collectItems(container)
    sendClientCommand(playerObj, CMD_MODULE, CMD_SNAPSHOT, {
        x = grid:getX(),
        y = grid:getY(),
        z = grid:getZ(),
        objectType = objectType,
        items = toList(items),
    })
end

-- Hook: envolve setVisible sem substituí-lo. Ao esconder a janela, envia o instantâneo.
local originalSetVisible = ISInventoryPage.setVisible
function ISInventoryPage:setVisible(bVisible, ...)
    if not bVisible then
        local container = self.inventoryPane and self.inventoryPane.inventory
        sendSnapshot(self.player, container)
    end
    return originalSetVisible(self, bVisible, ...)
end
