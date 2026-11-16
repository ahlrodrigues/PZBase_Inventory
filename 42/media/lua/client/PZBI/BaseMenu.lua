-- PZBase Inventory (cliente): menu de contexto "PZBase" com submenus.
-- Submenus: Criar, Ver, Apagar (BaseTool/BaseViewer); Inscrever/Cancelar inscrição neste móvel (seção 3);
-- Pedidos de inscrição, para o dono da base aprovar ou recusar; Cancelar quando houver ação pendente.
-- Textos vêm de Translate/<IDIOMA>/IG_UI.json.
-- Status: criar/apagar testados em jogo; inscrições e pedidos NÃO testados.

require "PZBI/Config"
require "PZBI/ContainerRules"
require "ISUI/ISContextMenu"

local CMD_MODULE = "PZBI"
local REQUESTS_KEY = PZBI.MOD_DATA_KEY .. "_requests"

-- Primeiro objeto com inventário sob o clique: coordenadas e tipo, no mesmo formato do instantâneo.
local function containerTarget(worldObjects)
    for _, obj in ipairs(worldObjects) do
        if obj.getContainer and obj:getContainer() then
            local sq = obj.getSquare and obj:getSquare()
            if sq then
                local sprite = obj:getSprite()
                local objectType = (sprite and sprite:getName()) or obj:getObjectName()
                return { x = sq:getX(), y = sq:getY(), z = sq:getZ(), objectType = objectType }
            end
        end
    end
    return nil
end

local function say(player, text)
    if player and player.Say then player:Say(text) end
end

local function subscribe(player, target)
    local base = PZBI.ContainerRules.findOwnerBase(PZBI.listBases(), target.x, target.y, target.z)
    if base == nil or base.owner == player:getUsername() then
        say(player, getText("IGUI_PZBI_SubOpen"))
    else
        say(player, getText("IGUI_PZBI_SubRequest"))
    end
    sendClientCommand(player, CMD_MODULE, "subscribe", target)
end

local function unsubscribe(player, target)
    say(player, getText("IGUI_PZBI_SubCancelled"))
    sendClientCommand(player, CMD_MODULE, "unsubscribe", target)
end

-- Pedidos ainda válidos para este dono: a base do móvel precisa existir e ser dele.
local function pendingRequestsFor(username)
    local list = {}
    local requests = ModData.get(REQUESTS_KEY)
    if not requests then return list end
    local bases = PZBI.listBases()
    for _, req in pairs(requests) do
        local base = PZBI.ContainerRules.findOwnerBase(bases, req.x, req.y, req.z)
        if base and base.owner == username and req.user then
            table.insert(list, req)
        end
    end
    return list
end

PZBI.pendingRequestsFor = pendingRequestsFor

local function decide(player, req, approve)
    local args = { x = req.x, y = req.y, z = req.z, objectType = req.objectType, user = req.user }
    sendClientCommand(player, CMD_MODULE, approve and "approve" or "deny", args)
    say(player, getText(approve and "IGUI_PZBI_Approved" or "IGUI_PZBI_Denied", req.user))
end

local function addRequestsMenu(player, sub)
    local list = pendingRequestsFor(player:getUsername())
    if #list == 0 then return end
    local root = sub:addOption(getText("IGUI_PZBI_Requests", tostring(#list)), nil, nil)
    local requestsMenu = ISContextMenu:getNew(sub)
    sub:addSubMenu(root, requestsMenu)
    for _, req in ipairs(list) do
        local item = requestsMenu:addOption(getText("IGUI_PZBI_RequestItem", req.user, req.city), nil, nil)
        local itemMenu = ISContextMenu:getNew(requestsMenu)
        requestsMenu:addSubMenu(item, itemMenu)
        itemMenu:addOption(getText("IGUI_PZBI_Approve"), nil, function() decide(player, req, true) end)
        itemMenu:addOption(getText("IGUI_PZBI_Deny"), nil, function() decide(player, req, false) end)
    end
end

Events.OnFillWorldObjectContextMenu.Add(function(playerIndex, context, worldObjects, test)
    local player = getSpecificPlayer(playerIndex)
    if not player then return end

    local root = context:addOption(getText("IGUI_PZBI_Menu"), worldObjects, nil)
    local sub = ISContextMenu:getNew(context)
    context:addSubMenu(root, sub)

    sub:addOption(getText("IGUI_PZBI_Create"), nil, function()
        PZBI.Tool.startCreate(player)
    end)
    sub:addOption(getText("IGUI_PZBI_View"), nil, function()
        PZBI.showBases(player)
    end)
    sub:addOption(getText("IGUI_PZBI_Delete"), nil, function()
        PZBI.Tool.startDelete(player)
    end)

    local target = containerTarget(worldObjects)
    if target then
        sub:addOption(getText("IGUI_PZBI_Subscribe"), nil, function()
            subscribe(player, target)
        end)
        sub:addOption(getText("IGUI_PZBI_Unsubscribe"), nil, function()
            unsubscribe(player, target)
        end)
    end

    addRequestsMenu(player, sub)

    if PZBI.Tool.mode then
        sub:addOption(getText("IGUI_PZBI_Cancel"), nil, function()
            PZBI.Tool.cancel()
        end)
    end
end)
