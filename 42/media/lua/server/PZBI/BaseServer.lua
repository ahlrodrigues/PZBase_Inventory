-- PZBase Inventory (servidor): criação e remoção de bases.
-- Regras puras ficam em shared/PZBI/BaseRules.lua (testadas fora do jogo).
-- Armazenamento: um ModData por base, mais um índice com os ids ativos (a sincronização envia a tabela inteira).
-- Status: NÃO testado em jogo. Validar com a rodada de testes de bases.

require "PZBI/Config"
require "PZBI/BaseRules"
print("[PZBI] server: BaseServer carregado")

local CMD_MODULE = "PZBI"
local CMD_CREATE = "createBase"
local CMD_REMOVE = "removeBase"
local INDEX_KEY = PZBI.MOD_DATA_KEY .. "_bases"

local function baseKey(id)
    return PZBI.MOD_DATA_KEY .. "_base_" .. tostring(id)
end

-- Lê o índice e devolve as bases ativas e o próprio índice.
local function loadActiveBases()
    local index = ModData.getOrCreate(INDEX_KEY)
    index.ids = index.ids or {}
    index.nextId = index.nextId or 1
    local bases = {}
    for _, id in ipairs(index.ids) do
        local record = ModData.get(baseKey(id))
        if record and not record.removed then
            table.insert(bases, record)
        end
    end
    return bases, index
end

local function onCreate(player, args)
    local bases, index = loadActiveBases()
    local owner = player:getUsername()
    local ok, reason, clean = PZBI.BaseRules.validateCreate(bases, owner, args)
    if not ok then
        print("[PZBI] base recusada: " .. tostring(reason) .. " de " .. owner)
        return
    end

    local id = index.nextId
    index.nextId = id + 1
    table.insert(index.ids, id)

    local key = baseKey(id)
    local record = ModData.getOrCreate(key)
    record.id = id
    record.owner = owner
    record.city = clean.city
    record.area = clean.area
    record.createdAt = getGameTime():getWorldAgeHours()
    record.dataVersion = PZBI.DATA_VERSION
    record.removed = false

    ModData.transmit(key)
    ModData.transmit(INDEX_KEY)
    print("[PZBI] base " .. id .. " criada por " .. owner .. " em '" .. clean.city .. "'")
end

local function onRemove(player, args)
    if type(args) ~= "table" or type(args.id) ~= "number" then
        print("[PZBI] remoção recusada: id inválido de " .. player:getUsername())
        return
    end

    local bases, index = loadActiveBases()
    local target
    for _, base in ipairs(bases) do
        if base.id == args.id then target = base end
    end
    if not PZBI.BaseRules.canRemove(target, player:getUsername()) then
        print("[PZBI] remoção recusada: sem permissão ou base inexistente, de " .. player:getUsername())
        return
    end

    target.removed = true
    local remaining = {}
    for _, id in ipairs(index.ids) do
        if id ~= target.id then table.insert(remaining, id) end
    end
    index.ids = remaining

    ModData.transmit(baseKey(target.id))
    ModData.transmit(INDEX_KEY)
    print("[PZBI] base " .. target.id .. " removida por " .. player:getUsername())
end

-- Remoção compartilhada (pedido do dono ou inatividade). Mantém o registro, marcado como removido.
function PZBI.removeBase(record, reason)
    local index = ModData.getOrCreate(INDEX_KEY)
    index.ids = index.ids or {}
    local remaining = {}
    for _, id in ipairs(index.ids) do
        if id ~= record.id then table.insert(remaining, id) end
    end
    index.ids = remaining
    record.removed = true
    ModData.transmit(baseKey(record.id))
    ModData.transmit(INDEX_KEY)
    print("[PZBI] base " .. record.id .. " removida: " .. reason)
end

Events.OnClientCommand.Add(function(module, command, player, args)
    if module ~= CMD_MODULE then return end
    if command == CMD_CREATE then
        onCreate(player, args)
    elseif command == CMD_REMOVE then
        onRemove(player, args)
    end
end)
