-- PZBase Inventory (cliente): marcação de base por dois cantos, pelo menu de contexto.
-- Clique com o botão direito num tile: "marcar canto 1" e depois "marcar canto 2 e criar base".
-- Nome da cidade fixo em "Base" nesta versão; caixa de texto fica para o passo seguinte.
-- Status: NÃO testado em jogo. APIs a validar: Events.OnFillWorldObjectContextMenu,
-- context:addOption, IsoObject:getSquare, IsoGridSquare:getX/getY/getZ, IsoPlayer:Say.
-- O servidor valida tudo e só registra a recusa no log; o cliente não recebe retorno.

require "PZBI/Config"

local CMD_MODULE = "PZBI"
local CMD_CREATE = "createBase"
local DEFAULT_CITY = "Base"

-- Canto 1 pendente por índice de jogador local: { x, y, z }
local pendingCorner = {}

-- Primeiro quadrado encontrado entre os objetos clicados.
local function squareOf(worldObjects)
    for _, obj in ipairs(worldObjects) do
        if obj.getSquare then
            local sq = obj:getSquare()
            if sq then return sq end
        end
    end
    return nil
end

local function say(player, text)
    if player and player.Say then player:Say(text) end
end

local function markCorner(playerIndex, player, sq)
    pendingCorner[playerIndex] = { x = sq:getX(), y = sq:getY(), z = sq:getZ() }
    say(player, "Canto 1 marcado em " .. sq:getX() .. ", " .. sq:getY() .. ".")
end

local function createBase(playerIndex, player, sq)
    local first = pendingCorner[playerIndex]
    if not first then
        say(player, "Marque o canto 1 primeiro.")
        return
    end
    if first.z ~= sq:getZ() then
        say(player, "Os dois cantos precisam estar no mesmo andar.")
        pendingCorner[playerIndex] = nil
        return
    end

    local area = {
        x1 = math.min(first.x, sq:getX()),
        y1 = math.min(first.y, sq:getY()),
        x2 = math.max(first.x, sq:getX()),
        y2 = math.max(first.y, sq:getY()),
        z = first.z,
    }
    pendingCorner[playerIndex] = nil
    sendClientCommand(player, CMD_MODULE, CMD_CREATE, { city = DEFAULT_CITY, area = area })
    say(player, "Pedido de base enviado (" .. DEFAULT_CITY .. ").")
end

local function onFillMenu(playerIndex, context, worldObjects, test)
    local player = getSpecificPlayer(playerIndex)
    local sq = squareOf(worldObjects)
    if not player or not sq then return end

    context:addOption("PZBI: marcar canto 1 da base", nil, function()
        markCorner(playerIndex, player, sq)
    end)
    context:addOption("PZBI: marcar canto 2 e criar base", nil, function()
        createBase(playerIndex, player, sq)
    end)
    if pendingCorner[playerIndex] then
        context:addOption("PZBI: cancelar marcação", nil, function()
            pendingCorner[playerIndex] = nil
            say(player, "Marcação cancelada.")
        end)
    end
end

Events.OnFillWorldObjectContextMenu.Add(onFillMenu)
