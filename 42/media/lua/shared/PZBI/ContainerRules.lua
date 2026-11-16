-- PZBase Inventory: regras puras de contêineres, donos e inscrições (especificação, seções 1 e 3).
-- Sem chamadas à API do jogo; testada fora do jogo (tests/container_rules_test.lua).
--
-- Dono do contêiner: o dono da base que contém o contêiner. Sem base, não há dono.
-- Como o dono é derivado da base atual, remover a base deixa os contêineres sem dono automaticamente.
-- Inscrição:
--   - sem dono (fora de base) ou dono do próprio contêiner: inscrição direta, status "aberta";
--   - com dono de outra pessoa: pedido, status "pendente", até o dono aprovar ou recusar.
-- Depois de aprovado, record.approved[user] = true (status "aprovada" no painel).

require "PZBI/Config"

PZBI = PZBI or {}
PZBI.ContainerRules = PZBI.ContainerRules or {}
local R = PZBI.ContainerRules

-- Chave estável do contêiner: coordenadas + tipo do objeto (mesmo formato de SnapshotServer.lua).
function R.containerKey(x, y, z, objectType)
    return string.format("%s_%d_%d_%d_%s", PZBI.MOD_DATA_KEY, x, y, z, objectType)
end

-- Base ativa que contém a posição, ou nil.
function R.findOwnerBase(bases, x, y, z)
    for _, base in ipairs(bases or {}) do
        local a = base.area
        if a and a.z == z and x >= a.x1 and x <= a.x2 and y >= a.y1 and y <= a.y2 then
            return base
        end
    end
    return nil
end

-- Garante as tabelas de inscrição no registro do contêiner.
function R.ensure(record)
    record.subscribers = record.subscribers or {}
    record.requests = record.requests or {}
    record.approved = record.approved or {}
    return record
end

-- Pede inscrição. owner é o dono atual (nil se não houver base).
-- Retorna o status: "aberta" ou "pendente".
function R.subscribe(record, user, owner)
    R.ensure(record)
    if owner == nil or owner == user then
        record.subscribers[user] = true
        record.requests[user] = nil
        record.approved[user] = nil
        return "aberta"
    end
    record.requests[user] = true
    return "pendente"
end

-- O dono aprova um pedido pendente. Só o dono da base pode aprovar.
function R.approve(record, owner, approver, user)
    R.ensure(record)
    if owner == nil or approver ~= owner then return false, "not_owner" end
    if not record.requests[user] then return false, "no_request" end
    record.requests[user] = nil
    record.subscribers[user] = true
    record.approved[user] = true
    return true
end

-- O dono recusa um pedido pendente. Só o dono da base pode recusar.
function R.deny(record, owner, approver, user)
    R.ensure(record)
    if owner == nil or approver ~= owner then return false, "not_owner" end
    if not record.requests[user] then return false, "no_request" end
    record.requests[user] = nil
    return true
end

-- Cancela a inscrição ou o pedido do próprio jogador.
function R.unsubscribe(record, user)
    R.ensure(record)
    record.subscribers[user] = nil
    record.requests[user] = nil
    record.approved[user] = nil
end

return R
