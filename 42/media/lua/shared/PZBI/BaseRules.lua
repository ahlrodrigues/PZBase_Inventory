-- PZBase Inventory: regras puras de marcação de base (sem chamadas à API do jogo).
-- Fica em shared/ para ser usado pelo servidor e testado fora do jogo (tests/base_rules_test.lua).
--
-- Área (v1): retângulo em coordenadas de tile, {x1, y1, x2, y2, z}.
-- Contorno livre (especificação, seção 2) fica para uma versão posterior.
--
-- Regras da especificação, seção 2:
-- - Um jogador pode ter uma base por cidade.
-- - Uma área não pode se sobrepor a outra base. Vale quem marcou primeiro.

require "PZBI/Config"

PZBI = PZBI or {}
PZBI.BaseRules = PZBI.BaseRules or {}
local R = PZBI.BaseRules

local MAX_CITY_LENGTH = 40

-- Retorna true se o valor for um número finito.
local function isNumber(v)
    return type(v) == "number" and v == v and v ~= math.huge and v ~= -math.huge
end

-- Normaliza um retângulo (troca os cantos se necessário). Retorna nil se for inválido.
function R.normalizeArea(area)
    if type(area) ~= "table" then return nil end
    if not (isNumber(area.x1) and isNumber(area.y1) and isNumber(area.x2)
        and isNumber(area.y2) and isNumber(area.z)) then
        return nil
    end
    return {
        x1 = math.min(area.x1, area.x2),
        y1 = math.min(area.y1, area.y2),
        x2 = math.max(area.x1, area.x2),
        y2 = math.max(area.y1, area.y2),
        z = area.z,
    }
end

-- Dois retângulos se sobrepõem se estiverem no mesmo andar e se cruzarem em x e y.
function R.overlaps(a, b)
    if a.z ~= b.z then return false end
    return a.x1 <= b.x2 and b.x1 <= a.x2 and a.y1 <= b.y2 and b.y1 <= a.y2
end

-- Valida um pedido de criação de base.
-- bases: lista de bases existentes (somente as ativas), cada uma com owner, city e area.
-- request: { city = string, area = {x1,y1,x2,y2,z} }
-- Retorna ok, motivo, área normalizada.
function R.validateCreate(bases, owner, request)
    if type(request) ~= "table" then return false, "request" end

    local city = request.city
    if type(city) ~= "string" then return false, "city" end
    city = city:match("^%s*(.-)%s*$")
    if #city == 0 or #city > MAX_CITY_LENGTH then return false, "city" end

    local area = R.normalizeArea(request.area)
    if not area then return false, "area" end

    for _, base in ipairs(bases or {}) do
        if base.owner == owner and base.city == city then
            return false, "duplicate_city"
        end
        if R.overlaps(base.area, area) then
            return false, "overlap"
        end
    end

    return true, nil, { city = city, area = area }
end

-- Só o dono pode remover a própria base.
function R.canRemove(base, username)
    return base ~= nil and base.owner == username
end

return R
