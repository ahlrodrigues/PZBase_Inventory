-- PZBase Inventory: regra pura de inatividade do dono (especificação, seção 6).
-- Sem chamadas à API do jogo; testada fora do jogo (tests/inactivity_rules_test.lua).
--
-- O tempo é tempo real, em milissegundos (getTimestampMs no jogo). A contagem é feita a partir
-- do último login do dono: o relógio do jogo para quando ninguém está jogando, então não serve.

require "PZBI/Config"

PZBI = PZBI or {}
PZBI.InactivityRules = PZBI.InactivityRules or {}
local R = PZBI.InactivityRules

R.MS_PER_DAY = 24 * 60 * 60 * 1000

-- true se o dono estiver inativo por mais de limitDays dias (estritamente maior).
function R.isInactive(lastLoginMs, nowMs, limitDays)
    if type(lastLoginMs) ~= "number" or type(nowMs) ~= "number" or type(limitDays) ~= "number" then
        return false
    end
    return (nowMs - lastLoginMs) > limitDays * R.MS_PER_DAY
end

return R
