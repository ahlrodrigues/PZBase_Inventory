-- PZBase Inventory (cliente): instantâneo do contêiner e botões na janela do contêiner.
-- Envia o instantâneo ao fechar a janela (hook em setVisible) e oferece, para contêineres dentro de base:
--   - "Atualizar instantâneo": envia o estado atual sem fechar a janela;
--   - "Ver no painel do jogador": abre o painel filtrado por este contêiner.
-- Achado no código do jogo: ISPanel:close() apenas chama self:setVisible(false), e a
-- janela de contêiner também pode ser escondida direto com setVisible(false).
-- Por isso o hook fica em setVisible, que cobre os dois caminhos.
-- Validado em jogo (v0.1.4): contêineres de mundo (móveis) retornam grid e objeto pai.
-- Ainda não lidos: contêineres de veículo e o inventário do jogador (sem posição).
-- Status dos botões: NÃO testado em jogo (posição e tamanho na janela).

require "PZBI/Config"
require "PZBI/ContainerRules"
require "ISUI/ISButton"

local CMD_MODULE = "PZBI"
local CMD_SNAPSHOT = "snapshot"
local BTN_H = 22
local BTN_W = 170

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

local function currentContainer(page)
    return page.inventoryPane and page.inventoryPane.inventory
end

-- Cria os dois botões uma vez por janela.
local function ensureButtons(page)
    if page.pzbiButtons then return end

    local snapshotBtn = ISButton:new(10, 0, BTN_W, BTN_H, getText("IGUI_PZBI_ContainerSnapshot"), nil, function()
        sendSnapshot(page.player, currentContainer(page))
    end)
    snapshotBtn:initialise()
    page:addChild(snapshotBtn)

    local panelBtn = ISButton:new(10 + BTN_W + 8, 0, BTN_W, BTN_H, getText("IGUI_PZBI_ContainerPanel"), nil, function()
        local info = worldInfo(currentContainer(page))
        if not insideBase(info) then return end
        local playerObj = getSpecificPlayer(page.player)
        if not playerObj then return end
        local key = PZBI.ContainerRules.containerKey(info.x, info.y, info.z, info.objectType)
        PZBI.PlayerPanel.openFiltered(playerObj, key)
    end)
    panelBtn:initialise()
    page:addChild(panelBtn)

    page.pzbiButtons = { snapshotBtn, panelBtn }
end

-- Posiciona os botões no rodapé e mostra só se o contêiner atual estiver dentro de base.
local function updateButtons(page)
    ensureButtons(page)
    local show = insideBase(worldInfo(currentContainer(page)))
    local y = page:getHeight() - BTN_H - 6
    for _, b in ipairs(page.pzbiButtons) do
        b:setY(y)
        b:setVisible(show)
    end
end

-- Hook: envolve setVisible sem substituí-lo. Ao esconder, envia o instantâneo; ao mostrar, atualiza os botões.
local originalSetVisible = ISInventoryPage.setVisible
function ISInventoryPage:setVisible(bVisible, ...)
    if not bVisible then
        sendSnapshot(self.player, currentContainer(self))
    else
        updateButtons(self)
    end
    return originalSetVisible(self, bVisible, ...)
end
