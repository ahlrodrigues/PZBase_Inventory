-- PZBase Inventory (servidor): inscrições e pedidos em contêineres (especificação, seção 3).
-- Regras puras em shared/PZBI/ContainerRules.lua. Dono derivado da base que contém o contêiner.
-- Comandos: subscribe, unsubscribe (qualquer jogador); approve, deny (só o dono da base).
-- Pedidos pendentes ficam numa lista própria (PZBI_requests), lida pelo cliente do dono.
-- Status: NÃO testado em jogo. Pendências: notificação no login e remoção de pedidos ao apagar a base.

require "PZBI/Config"
require "PZBI/ContainerRules"
require "PZBI/BaseServer"

local CMD_MODULE = "PZBI"
local MAX_TYPE_LENGTH = 100
local REQUESTS_KEY = PZBI.MOD_DATA_KEY .. "_requests"

local function validTarget(args)
    return type(args) == "table"
        and type(args.x) == "number" and type(args.y) == "number" and type(args.z) == "number"
        and type(args.objectType) == "string" and #args.objectType > 0 and #args.objectType <= MAX_TYPE_LENGTH
end

local function baseAt(args)
    return PZBI.ContainerRules.findOwnerBase(PZBI.loadActiveBases(), args.x, args.y, args.z)
end

local function recordFor(args)
    local key = PZBI.ContainerRules.containerKey(args.x, args.y, args.z, args.objectType)
    return ModData.getOrCreate(key), key
end

-- Chave da entrada na lista de pedidos: um por contêiner e jogador.
local function requestKey(args, user)
    return PZBI.ContainerRules.containerKey(args.x, args.y, args.z, args.objectType) .. "|" .. user
end

local function setRequest(args, user, base)
    local requests = ModData.getOrCreate(REQUESTS_KEY)
    requests[requestKey(args, user)] = {
        x = args.x, y = args.y, z = args.z, objectType = args.objectType,
        user = user, owner = base.owner, city = base.city,
    }
    ModData.transmit(REQUESTS_KEY)
end

local function clearRequest(args, user)
    local requests = ModData.getOrCreate(REQUESTS_KEY)
    requests[requestKey(args, user)] = nil
    ModData.transmit(REQUESTS_KEY)
end

local function onSubscribe(player, args)
    if not validTarget(args) then return end
    local user = player:getUsername()
    local base = baseAt(args)
    local record, key = recordFor(args)
    local status = PZBI.ContainerRules.subscribe(record, user, base and base.owner or nil)
    ModData.transmit(key)
    if status == "pendente" then
        setRequest(args, user, base)
    else
        clearRequest(args, user)
    end
    print("[PZBI] inscricao " .. status .. ": " .. args.objectType .. " por " .. user)
end

local function onUnsubscribe(player, args)
    if not validTarget(args) then return end
    local user = player:getUsername()
    local record, key = recordFor(args)
    PZBI.ContainerRules.unsubscribe(record, user)
    ModData.transmit(key)
    clearRequest(args, user)
    print("[PZBI] inscricao cancelada: " .. args.objectType .. " por " .. user)
end

local function onDecide(player, args, approve)
    if not validTarget(args) or type(args.user) ~= "string" then return end
    local approver = player:getUsername()
    local record, key = recordFor(args)
    local base = baseAt(args)
    local owner = base and base.owner or nil
    local ok, why
    if approve then
        ok, why = PZBI.ContainerRules.approve(record, owner, approver, args.user)
    else
        ok, why = PZBI.ContainerRules.deny(record, owner, approver, args.user)
    end
    if ok then
        ModData.transmit(key)
        clearRequest(args, args.user)
    end
    print("[PZBI] " .. (approve and "aprovacao" or "recusa") .. " de " .. args.user .. " por " .. approver
        .. (ok and "" or (" recusada: " .. tostring(why))))
end

Events.OnClientCommand.Add(function(module, command, player, args)
    if module ~= CMD_MODULE then return end
    if command == "subscribe" then
        onSubscribe(player, args)
    elseif command == "unsubscribe" then
        onUnsubscribe(player, args)
    elseif command == "approve" then
        onDecide(player, args, true)
    elseif command == "deny" then
        onDecide(player, args, false)
    end
end)
