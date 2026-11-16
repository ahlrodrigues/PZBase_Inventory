-- PZBase Inventory: regra pura de inatividade do dono (especificação, seção 6).
-- Sem chamadas à API do jogo; testada fora do jogo (tests/inactivity_rules_test.lua).
--
-- O tempo é medido em horas de jogo (idade do mundo), porque é o que o Lua do jogo expõe.
-- Consequência: o relógio só avança enquanto o mundo roda. Decisão a confirmar com o autor.

require "PZBI/Config"

PZBI = PZBI or {}
PZBI.InactivityRules = PZBI.InactivityRules or {}
local R = PZBI.InactivityRules

-- true se o dono estiver inativo por mais de limitDays dias (estritamente maior).
function R.isInactive(lastSeenHours, nowHours, limitDays)
    if type(lastSeenHours) ~= "number" or type(nowHours) ~= "number" or type(limitDays) ~= "number" then
        return false
    end
    return (nowHours - lastSeenHours) > limitDays * 24
end

return R
