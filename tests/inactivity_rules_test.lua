-- Testes da regra de inatividade (fora do jogo).
-- Rodar a partir da raiz do repositório:  lua tests/inactivity_rules_test.lua

function require() end

local R = dofile("42/media/lua/shared/PZBI/InactivityRules.lua")

local failures, passes = 0, 0
local function check(name, cond)
    if cond then
        passes = passes + 1
    else
        failures = failures + 1
        print("FALHOU: " .. name)
    end
end

local DAY = 24

check("visto agora não é inativo", R.isInactive(100, 100, 30) == false)
check("29 dias sem entrar não é inativo", R.isInactive(0, 29 * DAY, 30) == false)
check("exatamente 30 dias não é inativo (limite estrito)", R.isInactive(0, 30 * DAY, 30) == false)
check("31 dias sem entrar é inativo", R.isInactive(0, 31 * DAY, 30) == true)
check("sem registro de último acesso não é inativo", R.isInactive(nil, 999 * DAY, 30) == false)
check("limite inválido não é inativo", R.isInactive(0, 999 * DAY, nil) == false)
check("limite pequeno (teste) funciona", R.isInactive(0, 2, 0.05) == true)

print(string.format("%d ok, %d falha(s)", passes, failures))
os.exit(failures == 0 and 0 or 1)
