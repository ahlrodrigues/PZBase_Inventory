-- PZBase Inventory (cliente): menu de contexto "PZBase" com submenus.
-- Submenus: Criar área (BaseTool), Ver áreas (BaseViewer), Apagar área (BaseTool).
-- Status: NÃO testado em jogo. APIs a validar: context:addOption, ISContextMenu:getNew, context:addSubMenu.

require "PZBI/Config"
require "ISUI/ISContextMenu"

Events.OnFillWorldObjectContextMenu.Add(function(playerIndex, context, worldObjects, test)
    local player = getSpecificPlayer(playerIndex)
    if not player then return end

    local root = context:addOption("PZBase", worldObjects, nil)
    local sub = ISContextMenu:getNew(context)
    context:addSubMenu(root, sub)

    sub:addOption("Criar área", nil, function()
        PZBI.Tool.startCreate(player)
    end)
    sub:addOption("Ver áreas", nil, function()
        PZBI.showBases(player)
    end)
    sub:addOption("Apagar área", nil, function()
        PZBI.Tool.startDelete(player)
    end)
    if PZBI.Tool.mode then
        sub:addOption("Cancelar", nil, function()
            PZBI.Tool.cancel()
        end)
    end
end)
