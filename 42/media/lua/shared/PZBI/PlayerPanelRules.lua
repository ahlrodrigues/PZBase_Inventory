-- PZBase Inventory: regras puras do painel do jogador (especificação, seção 7).
-- Filtra por nome, ordena e monta o texto de cada coluna. Sem chamadas à API do jogo.
-- Testada fora do jogo (tests/player_panel_rules_test.lua).

PZBI = PZBI or {}
PZBI.PlayerPanelRules = PZBI.PlayerPanelRules or {}
local P = PZBI.PlayerPanelRules

P.MS_PER_DAY = 24 * 60 * 60 * 1000
P.SORT_NAME = "name"
P.SORT_QUANTITY = "quantity"

-- Dias inteiros desde sinceMs. Devolve nil se não houver instantâneo.
function P.daysSince(sinceMs, nowMs)
    if type(sinceMs) ~= "number" or type(nowMs) ~= "number" then return nil end
    local days = math.floor((nowMs - sinceMs) / P.MS_PER_DAY)
    if days < 0 then days = 0 end
    return days
end

-- Mantém os itens cujo nome contém o texto (sem diferença de maiúsculas, só ASCII).
function P.filterEntries(entries, query)
    if query == nil or query == "" then return entries end
    local q = string.lower(query)
    local kept = {}
    for _, e in ipairs(entries) do
        if string.find(string.lower(e.name), q, 1, true) then
            table.insert(kept, e)
        end
    end
    return kept
end

-- Mantém só os itens de um contêiner (pelo ckey). Sem ckey, devolve todos.
function P.filterByContainer(entries, ckey)
    if ckey == nil then return entries end
    local kept = {}
    for _, e in ipairs(entries) do
        if e.ckey == ckey then table.insert(kept, e) end
    end
    return kept
end

-- Ordena contêineres por local e depois por estado.
function P.sortContainers(containers)
    local sorted = {}
    for _, c in ipairs(containers) do table.insert(sorted, c) end
    table.sort(sorted, function(a, b)
        if a.location ~= b.location then return a.location < b.location end
        return a.state < b.state
    end)
    return sorted
end

-- entries: { category, name, count, unitWeight (nil se desconhecido), location }.
-- Categorias sempre em ordem alfabética. Dentro de cada categoria, sortKey é
-- P.SORT_NAME (nome) ou P.SORT_QUANTITY (quantidade, maior primeiro; depois nome).
function P.groupByCategory(entries, sortKey)
    local byCat, order = {}, {}
    for _, e in ipairs(entries) do
        local cat = e.category or "Outros"
        local g = byCat[cat]
        if not g then
            g = { category = cat, items = {}, weightTotal = 0, weightUnknown = false }
            byCat[cat] = g
            table.insert(order, cat)
        end
        table.insert(g.items, e)
        if e.unitWeight then
            g.weightTotal = g.weightTotal + e.unitWeight * e.count
        else
            g.weightUnknown = true
        end
    end

    table.sort(order)
    local groups = {}
    for _, cat in ipairs(order) do
        local g = byCat[cat]
        table.sort(g.items, function(a, b)
            if sortKey == P.SORT_QUANTITY and a.count ~= b.count then
                return a.count > b.count
            end
            if a.name ~= b.name then return a.name < b.name end
            return (a.location or "") < (b.location or "")
        end)
        table.insert(groups, g)
    end
    return groups
end

-- labels: units, unknownWeight, partial, totalWeight, daysAgo(n), today, noSnapshot,
-- containers, items, noContainers, noItems (textos ou funções).
local function weightText(unitWeight, count, labels)
    if not unitWeight then return labels.unknownWeight end
    return string.format("%.2f kg", unitWeight * count)
end

local function itemLine(e, labels)
    return string.format("%s: %d %s, %s, %s", e.name, e.count, labels.units,
        weightText(e.unitWeight, e.count, labels), e.location or "")
end

-- containers: { location, state, days (nil se sem instantâneo) }.
local function containerLine(c, labels)
    local snapshot
    if c.days == nil then
        snapshot = labels.noSnapshot
    elseif c.days == 0 then
        snapshot = labels.today
    else
        snapshot = labels.daysAgo(c.days)
    end
    return string.format("%s — %s — %s", c.location, c.state, snapshot)
end

-- Texto da coluna de contêineres.
function P.containersText(containers, labels)
    local lines = { labels.containers .. ":" }
    if #containers == 0 then
        table.insert(lines, "  " .. labels.noContainers)
    end
    for _, c in ipairs(containers) do
        table.insert(lines, "  " .. containerLine(c, labels))
    end
    return table.concat(lines, "\n")
end

-- Texto da coluna de itens, agrupado por categoria.
function P.itemsText(groups, labels)
    local lines = { labels.items .. ":" }
    if #groups == 0 then
        table.insert(lines, "  " .. labels.noItems)
    end
    for _, g in ipairs(groups) do
        local partial = g.weightUnknown and (" " .. labels.partial) or ""
        table.insert(lines, string.format("[%s] %s: %.2f kg%s", g.category, labels.totalWeight, g.weightTotal, partial))
        for _, e in ipairs(g.items) do
            table.insert(lines, "  " .. itemLine(e, labels))
        end
    end
    return table.concat(lines, "\n")
end

-- Relatório completo em texto (usado na exportação).
function P.buildText(title, containers, groups, labels)
    return title .. "\n\n" .. P.containersText(containers, labels) .. "\n\n" .. P.itemsText(groups, labels)
end

return P
