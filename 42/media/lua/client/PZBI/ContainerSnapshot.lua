-- PZBase Inventory (cliente): envio do instantâneo dos contêineres de base.
-- O instantâneo é enviado ao fechar a janela de um contêiner dentro de base (hook em setVisible).
-- Não há mais botões nem painel na janela do contêiner: toda a interação fica no inventário do personagem
-- (botão Bases, ver BasesWindow.lua).
-- Janelas de lista criadas pelo próprio mod (flag pzbiList) são ignoradas aqui.
-- Ainda não lidos: contêineres de veículo e o inventário do jogador (sem posição).
-- Status: envio validado em jogo (versões anteriores); hook após v0.2.18 NÃO testado.

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

-- Posição e tipo do contêiner de mundo, ou nil (inventário do jogador, veículo sem grid etc.).
local function worldInfo(container)
    if not container then return nil end
    local grid = container:getSourceGrid()
    if not grid then return nil end
    local parent = container:getParent()
    if not parent then return nil end
    local sprite = parent:getSprite()
    local objectType = (sprite and sprite:getName()) or parent:getObjectName()
    return { x = grid:getX(), y = grid:getY(), z = grid:getZ(), objectType = objectType }
end

-- Só contêineres dentro da área de uma base (ver ContainerRules.lua).
local function insideBase(info)
    return info ~= nil and PZBI.ContainerRules.findOwnerBase(PZBI.listBases(), info.x, info.y, info.z) ~= nil
end

-- Envia o instantâneo se o contêiner for de mundo e estiver dentro de base.
local function sendSnapshot(playerIndex, container)
    local info = worldInfo(container)
    if not insideBase(info) then return end
    local playerObj = getSpecificPlayer(playerIndex)
    if not playerObj then return end
    sendClientCommand(playerObj, CMD_MODULE, CMD_SNAPSHOT, {
        x = info.x,
        y = info.y,
        z = info.z,
        objectType = info.objectType,
        items = toList(collectItems(container)),
    })
end

-- Exposto para o BasesWindow.lua (varredura das bases).
PZBI.sendSnapshot = sendSnapshot

-- Última assinatura enviada por contêiner, para não reenviar sem mudança.
local lastSent = {}

-- Envia o instantâneo só se os itens mudaram desde o último envio. Devolve true se enviou.
local function sendSnapshotIfChanged(playerIndex, container)
    local info = worldInfo(container)
    if not insideBase(info) then return false end
    local counts = collectItems(container)
    local parts = {}
    for fullType, count in pairs(counts) do
        table.insert(parts, fullType .. ":" .. count)
    end
    table.sort(parts)
    local sig = table.concat(parts, "|")
    local key = PZBI.ContainerRules.containerKey(info.x, info.y, info.z, info.objectType)
    if lastSent[key] == sig then return false end
    lastSent[key] = sig
    sendSnapshot(playerIndex, container)
    return true
end

PZBI.sendSnapshotIfChanged = sendSnapshotIfChanged

-- Hook: envolve setVisible sem substituí-lo. Ao esconder uma janela de contêiner, envia o instantâneo.
local originalSetVisible = ISInventoryPage.setVisible
function ISInventoryPage:setVisible(bVisible, ...)
    if not bVisible and not self.pzbiList then
        sendSnapshot(self.player, self.inventoryPane and self.inventoryPane.inventory)
    end
    return originalSetVisible(self, bVisible, ...)
end
