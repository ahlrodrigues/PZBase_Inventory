-- PZBase Inventory (cliente): menu de contexto "PZBase" com submenus.
-- Submenus: Criar, Ver, Apagar (BaseTool/BaseViewer); Inscrever/Cancelar inscrição neste móvel (seção 3);
-- Cancelar quando houver ação pendente da marcação.
-- Textos vêm de Translate/<IDIOMA>/PZBI_UI.json.
-- Status: criar/apagar testados em jogo; inscrições NÃO testadas.

require "PZBI/Config"
require "PZBI/ContainerRules"
require "ISUI/ISContextMenu"

local CMD_MODULE = "PZBI"

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
    local owner = nil
    local base = PZBI.ContainerRules.findOwnerBase(PZBI.listBases(), target.x, target.y, target.z)
    if base then owner = base.owner end
    if owner == nil or owner == player:getUsername() then
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

    if PZBI.Tool.mode then
        sub:addOption(getText("IGUI_PZBI_Cancel"), nil, function()
            PZBI.Tool.cancel()
        end)
    end
end)
