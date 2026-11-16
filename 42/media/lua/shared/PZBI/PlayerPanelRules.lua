-- PZBase Inventory: regras puras do painel do jogador (especificação, seção 7).
-- Agrupa itens por categoria, soma pesos e monta o texto. Sem chamadas à API do jogo.
-- Testada fora do jogo (tests/player_panel_rules_test.lua).

PZBI = PZBI or {}
PZBI.PlayerPanelRules = PZBI.PlayerPanelRules or {}
local P = PZBI.PlayerPanelRules

P.MS_PER_DAY = 24 * 60 * 60 * 1000

-- Dias inteiros desde sinceMs. Devolve nil se não houver instantâneo.
function P.daysSince(sinceMs, nowMs)
    if type(sinceMs) ~= "number" or type(nowMs) ~= "number" then return nil end
    local days = math.floor((nowMs - sinceMs) / P.MS_PER_DAY)
    if days < 0 then days = 0 end
    return days
end

-- entries: { category, name, count, unitWeight (nil se desconhecido), location }.
-- Devolve grupos ordenados por categoria, com itens ordenados por nome e local.
function P.groupByCategory(entries)
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
            if a.name ~= b.name then return a.name < b.name end
            return (a.location or "") < (b.location or "")
        end)
        table.insert(groups, g)
    end
    return groups
end

-- labels: units, unknownWeight, partial, totalWeight, daysAgo(n), today, noSnapshot (funções ou textos).
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

-- Monta o relatório em texto: contêineres com estado e data do instantâneo, depois itens por categoria.
function P.buildText(title, containers, groups, labels)
    local lines = { title, "", labels.containers .. ":" }
    if #containers == 0 then
        table.insert(lines, "  " .. labels.noContainers)
    end
    for _, c in ipairs(containers) do
        table.insert(lines, "  " .. containerLine(c, labels))
    end

    table.insert(lines, "")
    table.insert(lines, labels.items .. ":")
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

return P
