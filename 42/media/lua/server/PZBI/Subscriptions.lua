-- PZBase Inventory (servidor): inscrições e pedidos em contêineres (especificação, seção 3).
-- Regras puras em shared/PZBI/ContainerRules.lua. Dono derivado da base que contém o contêiner.
-- Comandos: subscribe, unsubscribe (qualquer jogador); approve, deny (só o dono da base).
-- Status: NÃO testado em jogo. Pendências: notificar o dono no login, painel (seção 7).

require "PZBI/Config"
require "PZBI/ContainerRules"
require "PZBI/BaseServer"

local CMD_MODULE = "PZBI"
local MAX_TYPE_LENGTH = 100

local function validTarget(args)
    return type(args) == "table"
        and type(args.x) == "number" and type(args.y) == "number" and type(args.z) == "number"
        and type(args.objectType) == "string" and #args.objectType > 0 and #args.objectType <= MAX_TYPE_LENGTH
end

local function ownerAt(args)
    local base = PZBI.ContainerRules.findOwnerBase(PZBI.loadActiveBases(), args.x, args.y, args.z)
    return base and base.owner or nil
end

local function recordFor(args)
    local key = PZBI.ContainerRules.containerKey(args.x, args.y, args.z, args.objectType)
    return ModData.getOrCreate(key), key
end

local function onSubscribe(player, args)
    if not validTarget(args) then return end
    local user = player:getUsername()
    local record, key = recordFor(args)
    local status = PZBI.ContainerRules.subscribe(record, user, ownerAt(args))
    ModData.transmit(key)
    print("[PZBI] inscricao " .. status .. ": " .. args.objectType .. " por " .. user)
end

local function onUnsubscribe(player, args)
    if not validTarget(args) then return end
    local user = player:getUsername()
    local record, key = recordFor(args)
    PZBI.ContainerRules.unsubscribe(record, user)
    ModData.transmit(key)
    print("[PZBI] inscricao cancelada: " .. args.objectType .. " por " .. user)
end

local function onDecide(player, args, approve)
    if not validTarget(args) or type(args.user) ~= "string" then return end
    local approver = player:getUsername()
    local record, key = recordFor(args)
    local owner = ownerAt(args)
    local ok, why
    if approve then
        ok, why = PZBI.ContainerRules.approve(record, owner, approver, args.user)
    else
        ok, why = PZBI.ContainerRules.deny(record, owner, approver, args.user)
    end
    if ok then
        ModData.transmit(key)
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
