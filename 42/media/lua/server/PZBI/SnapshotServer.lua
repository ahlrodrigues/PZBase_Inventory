-- PZBase Inventory (servidor): recebe instantâneos, valida, compara com o último estado e grava no ModData.
-- Regra da especificação: toda mudança é registrada, mesmo que quem mexeu não esteja inscrito.
-- Dados separados por contêiner: cada contêiner tem seu próprio ModData, pois a sincronização envia a tabela inteira.
-- O log indica primeira leitura e lista cada tipo alterado, com sinal.

require "PZBI/Config"
print("[PZBI] server: SnapshotServer carregado")

local CMD_MODULE = "PZBI"
local CMD_SNAPSHOT = "snapshot"
local MAX_ITEM_TYPES = 500   -- limite de sanidade contra dados falsos
local MAX_COUNT = 10000

-- Chave estável do contêiner: coordenadas + tipo do objeto (especificação, seção 3).
local function containerKey(x, y, z, objectType)
    return string.format("%s_%d_%d_%d_%s", PZBI.MOD_DATA_KEY, x, y, z, objectType)
end

-- Valida o pedido do cliente. Não confia em nada que venha dele.
local function validate(args)
    if type(args) ~= "table" then return false, "args" end
    if type(args.x) ~= "number" or type(args.y) ~= "number" or type(args.z) ~= "number" then
        return false, "coords"
    end
    if type(args.objectType) ~= "string" or #args.objectType > 100 then
        return false, "objectType"
    end
    if type(args.items) ~= "table" or #args.items > MAX_ITEM_TYPES then
        return false, "items"
    end
    for _, entry in ipairs(args.items) do
        if type(entry.type) ~= "string" or type(entry.count) ~= "number"
            or entry.count < 1 or entry.count > MAX_COUNT then
            return false, "item entry"
        end
    end
    return true
end

-- Compara o estado anterior com o novo e devolve as diferenças por tipo.
local function diff(previous, current)
    local before, after, changes = {}, {}, {}
    for _, e in ipairs(previous or {}) do before[e.type] = e.count end
    for _, e in ipairs(current) do after[e.type] = e.count end
    for t, n in pairs(after) do
        local delta = n - (before[t] or 0)
        if delta ~= 0 then table.insert(changes, { type = t, delta = delta }) end
    end
    for t, n in pairs(before) do
        if after[t] == nil then table.insert(changes, { type = t, delta = -n }) end
    end
    return changes
end

local function onSnapshot(player, args)
    local ok, reason = validate(args)
    if not ok then
        print("[PZBI] snapshot rejeitado: " .. tostring(reason) .. " de " .. player:getUsername())
        return
    end

    local key = containerKey(args.x, args.y, args.z, args.objectType)
    local record = ModData.getOrCreate(key)
    local firstRead = record.items == nil
    local changes = diff(record.items, args.items)

    record.items = args.items
    record.updatedBy = player:getUsername()
    record.updatedAt = getGameTime():getWorldAgeHours()
    record.dataVersion = PZBI.DATA_VERSION
    record.lastChanges = changes

    -- Envia a tabela deste contêiner aos clientes.
    ModData.transmit(key)

    local label = firstRead and " (primeira leitura, sem estado anterior)" or ""
    print("[PZBI] instantâneo " .. key .. " por " .. record.updatedBy .. label .. ": " .. #changes .. " tipo(s) alterado(s)")
    for _, c in ipairs(changes) do
        local sign = c.delta > 0 and "+" or ""
        print("[PZBI]   " .. sign .. c.delta .. " " .. c.type)
    end
end

Events.OnClientCommand.Add(function(module, command, player, args)
    if module ~= CMD_MODULE then return end
    if command == CMD_SNAPSHOT then
        onSnapshot(player, args)
    end
end)
