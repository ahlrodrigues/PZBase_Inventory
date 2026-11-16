-- PZBase Inventory (cliente): botão "Bases" na janela do inventário do personagem.
-- Um clique abre a lista dos itens das bases na janela padrão do inventário, com filtro por base.
-- Dois cliques no mesmo botão atualizam: varrem os contêineres das bases carregados perto do personagem
-- (sem abrir nada) e destacam os que foram lidos.
-- Varredura: getCell():getGridSquare, getObjects e getContainer (mesma técnica do Proximity Inventory,
-- sem copiar código). Destaque: setHighlighted + cor do jogo, desligado ao fechar a janela.
-- Dependências: ContainerSnapshot.lua (PZBI.sendSnapshot), BaseViewer.lua (PZBI.listBases).
-- Status: NÃO testado em jogo.

require "PZBI/Config"
require "PZBI/ContainerRules"
require "ISUI/ISButton"
require "ISUI/ISInventoryPage"

local DOUBLE_CLICK_MS = 400
local BTN_W, BTN_H = 110, 22
local MAX_ITEMS = 1000       -- limite de sanidade para a lista de itens
local CONTAINERS_KEY = PZBI.MOD_DATA_KEY .. "_containers"

PZBI.Bases = PZBI.Bases or {}
local B = PZBI.Bases
B.filterCity = nil      -- nil = todas as bases
B.page = nil            -- janela padrão com a lista de itens
B.playerPage = nil     -- janela do inventário do personagem
B.highlighted = {}     -- objetos de contêiner destacados
B.lastClick = nil

-- Destaca ou libera os objetos (mesmas chamadas que o Proximity Inventory usa).
local function setHighlight(player, objects, on)
    for _, obj in ipairs(objects) do
        if on then
            obj:setHighlighted(player, true, false)
            obj:setHighlightColor(player, getCore():getObjectHighlitedColor())
        else
            obj:setHighlighted(player, false)
            obj:setOutlineHighlight(player, false)
        end
    end
end

-- Varre os quadrados de cada base que estiverem carregados e envia o instantâneo de cada contêiner.
-- Devolve os objetos de contêiner encontrados.
local function scanBases(playerNum)
    local found = {}
    local cell = getCell()
    if not cell then return found end
    for _, base in ipairs(PZBI.listBases()) do
        local a = base.area
        for x = a.x1, a.x2 do
            for y = a.y1, a.y2 do
                local sq = cell:getGridSquare(x, y, a.z)
                if sq then
                    local objs = sq:getObjects()
                    for i = 0, objs:size() - 1 do
                        local obj = objs:get(i)
                        local c = obj and obj:getContainer()
                        if c then
                            PZBI.sendSnapshot(playerNum, c)
                            table.insert(found, obj)
                        end
                    end
                end
            end
        end
    end
    return found
end

-- Nomes das cidades das bases, em ordem.
local function cityList()
    local seen, cities = {}, {}
    for _, base in ipairs(PZBI.listBases()) do
        if not seen[base.city] then
            seen[base.city] = true
            table.insert(cities, base.city)
        end
    end
    table.sort(cities)
    return cities
end

-- Próximo filtro: todas -> primeira cidade -> ... -> todas.
local function nextFilter()
    local cities = cityList()
    if #cities == 0 then
        B.filterCity = nil
        return
    end
    if B.filterCity == nil then
        B.filterCity = cities[1]
        return
    end
    local idx
    for i, c in ipairs(cities) do
        if c == B.filterCity then idx = i end
    end
    B.filterCity = (idx and cities[idx + 1]) or nil
end

-- Monta um contêiner temporário com os itens das bases (filtradas por cidade, se houver filtro).
-- Não gera loot: só usa o que os instantâneos já registraram.
local function buildItemContainer(city)
    local container = ItemContainer.new("pzbiBases", nil, nil)
    container:setExplored(true)
    container:setOnlyAcceptCategory("none")
    container:setCapacity(0)

    local bases = PZBI.listBases()
    local index = ModData.get(CONTAINERS_KEY) or {}
    local added = 0
    for key, pos in pairs(index) do
        local base = PZBI.ContainerRules.findOwnerBase(bases, pos.x, pos.y, pos.z)
        local record = ModData.get(key)
        if base and record and (city == nil or base.city == city) then
            for _, it in ipairs(record.items or {}) do
                for _ = 1, it.count do
                    if added >= MAX_ITEMS then return container end
                    local item = instanceItem(it.type)
                    if item then
                        container:AddItem(item)
                        added = added + 1
                    end
                end
            end
        end
    end
    return container
end

local function clearHighlight(player)
    setHighlight(player, B.highlighted, false)
    B.highlighted = {}
end

-- Fecha a janela de itens (se estiver aberta) e abre uma nova com o filtro atual.
local function openList(page)
    if B.page then
        B.page:removeFromUIManager()
        B.page = nil
    end
    local x = page:getX() + page:getWidth() + 2
    local y = page:getY()
    local w, h = 300, 360
    local win = ISInventoryPage:new(x, y, w, h, buildItemContainer(B.filterCity), false)
    win:setVisible(true)
    win:initialise()
    win:addToUIManager()
    B.page = win
    B.playerPage = page

    local label = B.filterCity and getText("IGUI_PZBI_BasesFilter", B.filterCity) or getText("IGUI_PZBI_BasesAll")
    local btn = ISButton:new(6, h - BTN_H - 6, w - 12, BTN_H, label, nil, function()
        nextFilter()
        openList(page)
    end)
    btn:initialise()
    win:addChild(btn)
end

-- Varredura + destaque + atualização da lista aberta.
local function update(page)
    local player = page.player
    clearHighlight(player)
    B.highlighted = scanBases(player)
    setHighlight(player, B.highlighted, true)
    if B.page then openList(page) end
    local playerObj = getSpecificPlayer(player)
    if playerObj then
        playerObj:Say(getText("IGUI_PZBI_BasesUpdated", tostring(#B.highlighted)))
    end
end

-- Um clique abre a lista; dois cliques seguidos atualizam.
local function onButtonClick(page)
    local now = getTimestampMs()
    if B.lastClick and now - B.lastClick < DOUBLE_CLICK_MS then
        B.lastClick = nil
        update(page)
    else
        B.lastClick = now
        openList(page)
    end
end

-- Cria o botão uma vez por janela do personagem, no rodapé à esquerda.
local function ensureButton(page)
    if page.pzbiBasesBtn then
        page.pzbiBasesBtn:setY(page:getHeight() - BTN_H - 6)
        return
    end
    local btn = ISButton:new(6, page:getHeight() - BTN_H - 6, BTN_W, BTN_H, getText("IGUI_PZBI_BasesButton"), nil, function()
        onButtonClick(page)
    end)
    btn:initialise()
    page:addChild(btn)
    page.pzbiBasesBtn = btn
end

-- Hook: ao mostrar a janela do personagem, garante o botão. Ao fechar a lista, limpa o destaque.
local originalSetVisible = ISInventoryPage.setVisible
function ISInventoryPage:setVisible(bVisible, ...)
    if bVisible and self.onCharacter then
        ensureButton(self)
    end
    if not bVisible and self == B.page then
        clearHighlight(self.player)
        B.page = nil
    end
    return originalSetVisible(self, bVisible, ...)
end
