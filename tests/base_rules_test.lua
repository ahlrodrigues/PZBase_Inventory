-- Testes das regras de base (fora do jogo).
-- Rodar a partir da raiz do repositório:  lua tests/base_rules_test.lua

-- O jogo fornece require; fora dele, basta ignorar.
function require() end

local R = dofile("42/media/lua/shared/PZBI/BaseRules.lua")

local failures, passes = 0, 0
local function check(name, cond)
    if cond then
        passes = passes + 1
    else
        failures = failures + 1
        print("FALHOU: " .. name)
    end
end

local function area(x1, y1, x2, y2, z)
    return { x1 = x1, y1 = y1, x2 = x2, y2 = y2, z = z or 0 }
end

local existing = {
    { owner = "ana", city = "Muldraugh", area = area(10, 10, 20, 20) },
}

-- Criação válida
local ok, reason = R.validateCreate(existing, "bob", { city = "Riverside", area = area(50, 50, 60, 60) })
check("criação válida é aceita", ok == true and reason == nil)

-- Área invertida é normalizada
local ok2, _, norm = R.validateCreate({}, "bob", { city = "X", area = area(60, 60, 50, 50) })
check("área invertida é aceita", ok2 == true)
check("área invertida é normalizada", norm.area.x1 == 50 and norm.area.y1 == 50 and norm.area.x2 == 60)

-- Sobreposição: quem marcou primeiro vence
local ok3, reason3 = R.validateCreate(existing, "bob", { city = "Riverside", area = area(15, 15, 30, 30) })
check("sobreposição é recusada", ok3 == false and reason3 == "overlap")

-- Toque em borda conta como sobreposição (limites inclusivos)
local ok4, reason4 = R.validateCreate(existing, "bob", { city = "Riverside", area = area(20, 20, 25, 25) })
check("toque na borda é sobreposição", ok4 == false and reason4 == "overlap")

-- Mesma área em outro andar não sobrepõe
local ok5 = R.validateCreate(existing, "bob", { city = "Riverside", area = area(15, 15, 30, 30, 1) })
check("andar diferente não sobrepõe", ok5 == true)

-- Mesmo jogador, mesma cidade: recusa
local ok6, reason6 = R.validateCreate(existing, "ana", { city = "Muldraugh", area = area(70, 70, 80, 80) })
check("duplicata de cidade do mesmo dono é recusada", ok6 == false and reason6 == "duplicate_city")

-- Outro jogador na mesma cidade: permitido
local ok7 = R.validateCreate(existing, "bob", { city = "Muldraugh", area = area(70, 70, 80, 80) })
check("outro jogador pode marcar na mesma cidade", ok7 == true)

-- Entradas inválidas
check("cidade vazia é recusada", R.validateCreate({}, "bob", { city = "   ", area = area(0, 0, 1, 1) }) == false)
check("cidade longa é recusada", R.validateCreate({}, "bob", { city = string.rep("a", 41), area = area(0, 0, 1, 1) }) == false)
check("coordenada não numérica é recusada", R.validateCreate({}, "bob", { city = "X", area = { x1 = "a", y1 = 0, x2 = 1, y2 = 1, z = 0 } }) == false)
check("coordenada infinita é recusada", R.validateCreate({}, "bob", { city = "X", area = area(0, 0, math.huge, 1) }) == false)
check("pedido nil é recusado", R.validateCreate({}, "bob", nil) == false)

-- Remoção só pelo dono
check("dono pode remover", R.canRemove(existing[1], "ana") == true)
check("outro jogador não pode remover", R.canRemove(existing[1], "bob") == false)
check("base inexistente não pode ser removida", R.canRemove(nil, "ana") == false)

print(string.format("%d ok, %d falha(s)", passes, failures))
os.exit(failures == 0 and 0 or 1)
