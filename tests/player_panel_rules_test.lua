-- Testes das regras do painel do jogador (fora do jogo).
-- Rodar a partir da raiz do repositório:  lua tests/player_panel_rules_test.lua

function require() end

PZBI = { MOD_DATA_KEY = "PZBaseInventory" }
local P = dofile("42/media/lua/shared/PZBI/PlayerPanelRules.lua")

local failures, passes = 0, 0
local function check(name, cond)
    if cond then
        passes = passes + 1
    else
        failures = failures + 1
        print("FALHOU: " .. name)
    end
end

-- Dias
local DAY = P.MS_PER_DAY
check("dias: sem instantâneo é nil", P.daysSince(nil, 1000) == nil)
check("dias: mesmo instante é 0", P.daysSince(5000, 5000) == 0)
check("dias: 2 dias e meio é 2", P.daysSince(0, 2 * DAY + DAY / 2) == 2)
check("dias: relógio andando para trás é 0", P.daysSince(9000, 1000) == 0)

local entries = {
    { category = "Comida", name = "Maçã", count = 3, unitWeight = 0.2, location = "Mochila" },
    { category = "Ferramentas", name = "Martelo", count = 1, unitWeight = 1.5, location = "Mochila" },
    { category = "Comida", name = "Água", count = 2, unitWeight = nil, location = "Base A / Armário" },
    { category = "Comida", name = "Arroz", count = 1, unitWeight = 0.5, location = "Mochila" },
}

-- Filtro
check("filtro vazio devolve tudo", #P.filterEntries(entries, "") == 4)
check("filtro nil devolve tudo", #P.filterEntries(entries, nil) == 4)
check("filtro ignora maiúsculas", #P.filterEntries(entries, "MART") == 1)
check("filtro sem resultado", #P.filterEntries(entries, "zzz") == 0)

-- Agrupamento e ordenação
local groups = P.groupByCategory(entries, P.SORT_NAME)
check("agrupa em duas categorias", #groups == 2)
check("categorias em ordem alfabética", groups[1].category == "Comida" and groups[2].category == "Ferramentas")
check("comida tem três itens", #groups[1].items == 3)
check("ordem por nome", groups[1].items[1].name == "Arroz" and groups[1].items[2].name == "Maçã")
check("ordem por quantidade (maior primeiro)", P.groupByCategory(entries, P.SORT_QUANTITY)[1].items[1].name == "Maçã")
check("peso total soma unidade × quantidade", math.abs(groups[2].weightTotal - 1.5) < 1e-9)
check("peso desconhecido marca o grupo como parcial", groups[1].weightUnknown == true)
check("grupo sem peso desconhecido não é parcial", groups[2].weightUnknown == false)

-- Contêineres
local sorted = P.sortContainers({
    { location = "Base B / Caixa", state = "aberta", days = 1 },
    { location = "Base A / Armário", state = "pendente", days = 2 },
    { location = "Base A / Armário", state = "aberta", days = 0 },
})
check("contêineres por local", sorted[1].location == "Base A / Armário" and sorted[3].location == "Base B / Caixa")
check("contêineres com mesmo local por estado", sorted[1].state == "aberta" and sorted[2].state == "pendente")

-- Texto
local labels = {
    containers = "Contêineres", items = "Itens", noContainers = "Nenhum contêiner",
    noItems = "Nenhum item", units = "un.", unknownWeight = "peso ?", partial = "(parcial)",
    totalWeight = "peso total", today = "hoje", noSnapshot = "sem instantâneo",
    daysAgo = function(n) return "há " .. n .. " dia(s)" end,
}
local containers = {
    { location = "Base A / Armário", state = "aberta", days = 3 },
    { location = "Fora de base / Caixa", state = "pendente", days = nil },
}
local text = P.buildText("Painel", containers, groups, labels)
check("texto tem o título", text:sub(1, 6) == "Painel")
check("texto mostra o estado e a data do contêiner", text:find("Base A / Armário — aberta — há 3 dia%(s%)") ~= nil)
check("contêiner sem instantâneo diz isso", text:find("sem instantâneo") ~= nil)
check("texto mostra peso parcial", text:find("%[Comida%] peso total: 1.10 kg %(parcial%)") ~= nil)
check("linha de item traz quantidade e local", text:find("Maçã: 3 un., 0.60 kg, Mochila", 1, true) ~= nil)
check("item sem peso mostra o texto de peso desconhecido", text:find("Água: 2 un., peso ?, Base A / Armário", 1, true) ~= nil)
check("coluna de contêineres não traz itens", P.containersText(containers, labels):find("Maçã", 1, true) == nil)
check("coluna de itens não traz contêineres", P.itemsText(groups, labels):find("sem instantâneo", 1, true) == nil)

local empty = P.buildText("Painel", {}, {}, labels)
check("sem nada, avisa nos dois blocos", empty:find("Nenhum contêiner", 1, true) and empty:find("Nenhum item", 1, true))

print(string.format("%d ok, %d falha(s)", passes, failures))
os.exit(failures == 0 and 0 or 1)
