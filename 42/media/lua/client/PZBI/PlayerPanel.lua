-- PZBase Inventory (cliente): painel do jogador (especificação, seção 7).
-- Mostra a mochila e os contêineres a que o jogador tem acesso (dono da base ou inscrito),
-- com estado da inscrição, data do último instantâneo, itens agrupados por categoria e peso.
-- Regras puras em shared/PZBI/PlayerPanelRules.lua. Textos em IG_UI.json.
-- Exporta o texto para Zomboid/Lua/PZBI_inventario.txt.
-- Status: NÃO testado em jogo. APIs de item (ScriptManager, getDisplayCategory, getActualWeight)
--         e ISRichTextPanel/getFileWriter precisam de confirmação; as chamadas de item estão em pcall.
-- Limitação: contêineres só entram no índice após o primeiro instantâneo (feito pelo painel de contêiner).

require "PZBI/Config"
require "PZBI/ContainerRules"
require "PZBI/PlayerPanelRules"
require "ISUI/ISCollapsableWindow"
require "ISUI/ISRichTextPanel"
require "ISUI/ISButton"

PZBI = PZBI or {}
PZBI.PlayerPanel = PZBI.PlayerPanel or {}
local Panel = PZBI.PlayerPanel

local CONTAINERS_KEY = PZBI.MOD_DATA_KEY .. "_containers"
local EXPORT_FILE = "PZBI_inventario.txt"
local WIN_W, WIN_H = 580, 470

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

        if record and (isOwner or subscribed or pending) then
            local place = base and (base.city .. " / " .. pos.objectType)
                or (labels.outside .. " / " .. pos.objectType)
            local state
            if isOwner then
                state = labels.stateOwner
            elseif subscribed then
                state = (record.approved and record.approved[user]) and labels.stateApproved or labels.stateOpen
            else
                state = labels.statePending
            end
            table.insert(containers, {
                location = place,
                state = state,
                days = PZBI.PlayerPanelRules.daysSince(record.updatedAtMs, nowMs),
            })
            for _, it in ipairs(record.items or {}) do
                local info = typeInfo(it.type)
                table.insert(entries, {
                    category = info.category, name = info.name, count = it.count,
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

local function buildReport(player, labels)
    local containers, entries = containerData(player, labels)
    for _, e in ipairs(backpackEntries(player, labels)) do table.insert(entries, e) end
    local groups = PZBI.PlayerPanelRules.groupByCategory(entries)
    return PZBI.PlayerPanelRules.buildText(getText("IGUI_PZBI_PanelTitle"), containers, groups, labels)
end

local function exportReport(text)
    local ok, writer = pcall(getFileWriter, EXPORT_FILE, true, false)
    if not ok or not writer then return false end
    writer:write(text)
    writer:close()
    return true
end

-- Abre (ou atualiza) a janela do painel.
function Panel.open(player)
    local labels = buildLabels()
    local text = buildReport(player, labels)

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

    local rich = ISRichTextPanel:new(10, 30, WIN_W - 20, WIN_H - 80)
    rich:initialise()
    rich:instantiate()
    rich.autosetheight = false
    rich:addScrollBars()
    rich:setText(text)
    win:addChild(rich)

    local btn = ISButton:new(10, WIN_H - 40, 180, 25, getText("IGUI_PZBI_PanelExport"), nil,
        function()
            if exportReport(text) then
                player:Say(getText("IGUI_PZBI_PanelExported", EXPORT_FILE))
            else
                player:Say(getText("IGUI_PZBI_PanelExportFailed"))
            end
        end)
    btn:initialise()
    win:addChild(btn)
end
