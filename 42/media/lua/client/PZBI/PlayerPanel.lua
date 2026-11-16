-- PZBase Inventory (cliente): painel do jogador (especificação, seção 7).
-- Coluna esquerda: botão "Todos os contêineres" e uma barra vertical com rolagem (filtra a coluna da direita),
-- com os detalhes de estado e data logo abaixo. Coluna direita: itens por categoria, com busca e ordenação.
-- Mostra a mochila e os contêineres a que o jogador tem acesso (dono da base ou inscrito).
-- Regras puras em shared/PZBI/PlayerPanelRules.lua. Textos em IG_UI.json.
-- Exporta a lista completa (sem filtro) para Zomboid/Lua/PZBI_inventario.txt.
-- Status: NÃO testado em jogo. APIs de item (ScriptManager, getDisplayCategory, getActualWeight),
--         ISRichTextPanel, ISTextEntryBox e getFileWriter precisam de confirmação; as de item estão em pcall.
-- Limitação: contêineres só entram no índice após o primeiro instantâneo.

require "PZBI/Config"
require "PZBI/ContainerRules"
require "PZBI/PlayerPanelRules"
require "ISUI/ISCollapsableWindow"
require "ISUI/ISRichTextPanel"
require "ISUI/ISTextEntryBox"
require "ISUI/ISButton"
require "ISUI/ISScrollingListBox"

PZBI = PZBI or {}
PZBI.PlayerPanel = PZBI.PlayerPanel or {}
local Panel = PZBI.PlayerPanel
local R = PZBI.PlayerPanelRules

local CONTAINERS_KEY = PZBI.MOD_DATA_KEY .. "_containers"
local EXPORT_FILE = "PZBI_inventario.txt"
local WIN_W, WIN_H = 720, 500
local LEFT_W = 240
local TOP_Y = 60          -- linha dos botões de ordenação; busca fica na linha acima
local COL_Y = 95
local BTN_H = 25
local BTN_GAP = 30
local LIST_H = 160        -- altura da barra vertical de contêineres (com rolagem)

-- Categoria traduzida se houver texto (IGUI_ItemCat_<cat>); senão, o nome cru.
local function categoryLabel(cat)
    local key = "IGUI_ItemCat_" .. tostring(cat)
    local text = getText(key)
    if text == nil or text == key then return tostring(cat) end
    return text
end

-- Nome, categoria e peso unitário de um item do inventário do jogador.
local function inventoryItemInfo(item)
    local info = { name = item:getFullType(), category = "Outros", unitWeight = nil }
    pcall(function()
        info.name = item:getDisplayName() or info.name
        info.category = item:getDisplayCategory() or info.category
        info.unitWeight = item:getActualWeight()
    end)
    info.category = categoryLabel(info.category)
    return info
end

-- Nome, categoria e peso unitário de um tipo de item (dados do contêiner, só o nome completo).
local function typeInfo(fullType)
    local info = { name = fullType, category = "Outros", unitWeight = nil }
    pcall(function()
        local script = ScriptManager.instance:getItem(fullType)
        if script then
            info.name = script:getDisplayName() or info.name
            info.category = script:getDisplayCategory() or info.category
            info.unitWeight = script:getActualWeight()
        end
    end)
    info.category = categoryLabel(info.category)
    return info
end

local function backpackEntries(player, labels)
    local counts, infos = {}, {}
    local items = player:getInventory():getItems()
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        local fullType = item:getFullType()
        if not infos[fullType] then infos[fullType] = inventoryItemInfo(item) end
        counts[fullType] = (counts[fullType] or 0) + 1
    end
    local entries = {}
    for fullType, count in pairs(counts) do
        local info = infos[fullType]
        table.insert(entries, {
            category = info.category, name = info.name, count = count,
            unitWeight = info.unitWeight, location = labels.backpack,
        })
    end
    return entries
end

-- Contêineres a que o jogador tem acesso: os que estão na base dele, ou em que ele está inscrito.
-- Cada contêiner e cada item de contêiner leva o ckey (chave do ModData), para o filtro por botão.
local function containerData(player, labels)
    local user = player:getUsername()
    local nowMs = getTimestampMs()
    local bases = PZBI.listBases()
    local containers, entries = {}, {}
    local index = ModData.get(CONTAINERS_KEY) or {}

    for key, pos in pairs(index) do
        local record = ModData.get(key)
        local base = PZBI.ContainerRules.findOwnerBase(bases, pos.x, pos.y, pos.z)
        local isOwner = base ~= nil and base.owner == user
        local subscribed = record and record.subscribers and record.subscribers[user]
        local pending = record and record.requests and record.requests[user]

        if base and record and (isOwner or subscribed or pending) then
            local place = base.city .. " / " .. pos.objectType
            local state
            if isOwner then
                state = labels.stateOwner
            elseif subscribed then
                state = (record.approved and record.approved[user]) and labels.stateApproved or labels.stateOpen
            else
                state = labels.statePending
            end
            table.insert(containers, {
                key = key,
                location = place,
                state = state,
                days = R.daysSince(record.updatedAtMs, nowMs),
            })
            for _, it in ipairs(record.items or {}) do
                local info = typeInfo(it.type)
                table.insert(entries, {
                    ckey = key, category = info.category, name = info.name, count = it.count,
                    unitWeight = info.unitWeight, location = place,
                })
            end
        end
    end
    return containers, entries
end

local function buildLabels()
    local function daysAgo(n) return getText("IGUI_PZBI_PanelDaysAgo", tostring(n)) end
    return {
        containers = getText("IGUI_PZBI_PanelContainers"),
        items = getText("IGUI_PZBI_PanelItems"),
        noContainers = getText("IGUI_PZBI_PanelNoContainers"),
        noItems = getText("IGUI_PZBI_PanelNoItems"),
        noSnapshot = getText("IGUI_PZBI_PanelNoSnapshot"),
        today = getText("IGUI_PZBI_PanelToday"),
        daysAgo = daysAgo,
        units = getText("IGUI_PZBI_PanelUnits"),
        unknownWeight = getText("IGUI_PZBI_PanelUnknownWeight"),
        partial = getText("IGUI_PZBI_PanelPartial"),
        totalWeight = getText("IGUI_PZBI_PanelTotalWeight"),
        backpack = getText("IGUI_PZBI_PanelBackpack"),
        outside = getText("IGUI_PZBI_PanelOutside"),
        stateOwner = getText("IGUI_PZBI_PanelStateOwner"),
        stateOpen = getText("IGUI_PZBI_PanelStateOpen"),
        stateApproved = getText("IGUI_PZBI_PanelStateApproved"),
        statePending = getText("IGUI_PZBI_PanelStatePending"),
    }
end

local function exportReport(text)
    local ok, writer = pcall(getFileWriter, EXPORT_FILE, true, false)
    if not ok or not writer then return false end
    writer:write(text)
    writer:close()
    return true
end

-- Redesenha as colunas a partir dos dados guardados, aplicando contêiner, busca e ordenação.
local function refresh()
    local data = Panel.data
    if not data or not Panel.window then return end
    local visible = R.filterEntries(data.entries, Panel.query)
    visible = R.filterByContainer(visible, Panel.filterKey)
    local groups = R.groupByCategory(visible, Panel.sortKey)
    local containers = R.sortContainers(data.containers)
    Panel.detailPanel:setText(R.containersText(containers, data.labels))
    Panel.rightPanel:setText(R.itemsText(groups, data.labels))
end

local function addButton(win, x, y, w, title, onClick)
    local btn = ISButton:new(x, y, w, BTN_H, title, nil, onClick)
    btn:initialise()
    win:addChild(btn)
    return btn
end

-- Coluna esquerda: botão "Todos" e uma barra vertical com rolagem listando todos os contêineres.
-- Clicar num contêiner filtra a coluna da direita. Devolve a linha em que os detalhes começam.
local function buildContainerList(win, containers)
    addButton(win, 10, COL_Y, LEFT_W, getText("IGUI_PZBI_PanelAllContainers"), function()
        Panel.filterKey = nil
        refresh()
    end)
    local listY = COL_Y + BTN_GAP
    local list = ISScrollingListBox:new(10, listY, LEFT_W, LIST_H)
    list:initialise()
    list:instantiate()
    list.itemheight = BTN_GAP
    list.drawBorder = true
    list:setOnMouseDownFunction(Panel, function(_, item)
        Panel.filterKey = item.key
        refresh()
    end)
    for _, c in ipairs(containers) do
        list:addItem(c.location, c)
    end
    win:addChild(list)
    return listY + LIST_H + 5
end

-- Abre (ou atualiza) a janela do painel.
function Panel.open(player)
    local labels = buildLabels()
    local containers, entries = containerData(player, labels)
    for _, e in ipairs(backpackEntries(player, labels)) do table.insert(entries, e) end
    Panel.data = { containers = containers, entries = entries, labels = labels, player = player }
    Panel.query = ""
    Panel.sortKey = R.SORT_NAME
    Panel.filterKey = nil

    if Panel.window then
        Panel.window:removeFromUIManager()
        Panel.window = nil
    end

    local core = getCore()
    local x = (core:getScreenWidth() - WIN_W) / 2
    local y = (core:getScreenHeight() - WIN_H) / 2
    local win = ISCollapsableWindow:new(x, y, WIN_W, WIN_H)
    win:initialise()
    win:addToUIManager()
    win:setVisible(true)
    win.title = getText("IGUI_PZBI_PanelTitle")
    Panel.window = win

    -- Busca: campo + filtrar + limpar.
    local search = ISTextEntryBox:new("", 10, 30, 340, BTN_H)
    search:initialise()
    search:instantiate()
    win:addChild(search)
    Panel.search = search
    addButton(win, 360, 30, 100, getText("IGUI_PZBI_PanelFilter"), function()
        Panel.query = search:getText() or ""
        refresh()
    end)
    addButton(win, 470, 30, 100, getText("IGUI_PZBI_PanelClear"), function()
        search:setText("")
        Panel.query = ""
        refresh()
    end)

    -- Ordenação dos itens dentro de cada categoria.
    addButton(win, 10, TOP_Y, 150, getText("IGUI_PZBI_PanelSortName"), function()
        Panel.sortKey = R.SORT_NAME
        refresh()
    end)
    addButton(win, 170, TOP_Y, 150, getText("IGUI_PZBI_PanelSortQty"), function()
        Panel.sortKey = R.SORT_QUANTITY
        refresh()
    end)

    -- Coluna esquerda: botões dos contêineres e, abaixo, os detalhes. Coluna direita: itens.
    local detailTop = buildContainerList(win, R.sortContainers(containers))
    local detailPanel = ISRichTextPanel:new(10, detailTop, LEFT_W, WIN_H - detailTop - 60)
    detailPanel:initialise()
    detailPanel:instantiate()
    detailPanel.autosetheight = false
    detailPanel:addScrollBars()
    win:addChild(detailPanel)
    Panel.detailPanel = detailPanel

    local rightPanel = ISRichTextPanel:new(10 + LEFT_W + 10, COL_Y, WIN_W - LEFT_W - 40, WIN_H - COL_Y - 60)
    rightPanel:initialise()
    rightPanel:instantiate()
    rightPanel.autosetheight = false
    rightPanel:addScrollBars()
    win:addChild(rightPanel)
    Panel.rightPanel = rightPanel

    addButton(win, 10, WIN_H - 40, 180, getText("IGUI_PZBI_PanelExport"), function()
        local full = R.buildText(getText("IGUI_PZBI_PanelTitle"),
            R.sortContainers(Panel.data.containers),
            R.groupByCategory(Panel.data.entries, Panel.sortKey), labels)
        if exportReport(full) then
            player:Say(getText("IGUI_PZBI_PanelExported", EXPORT_FILE))
        else
            player:Say(getText("IGUI_PZBI_PanelExportFailed"))
        end
    end)

    refresh()
end
