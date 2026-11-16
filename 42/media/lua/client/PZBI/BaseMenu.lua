-- PZBase Inventory (cliente): menu de contexto "PZBase" com submenus.
-- Submenus: Criar, Ver, Apagar (BaseTool/BaseViewer) e Cancelar quando houver ação pendente.
-- Rótulos sem acento: o texto com "á" saía cortado no submenu (causa a confirmar em jogo).
-- Status: criar/apagar testados em jogo; rótulos a confirmar.

require "PZBI/Config"
require "ISUI/ISContextMenu"

Events.OnFillWorldObjectContextMenu.Add(function(playerIndex, context, worldObjects, test)
    local player = getSpecificPlayer(playerIndex)
    if not player then return end

    local root = context:addOption("PZBase", worldObjects, nil)
    local sub = ISContextMenu:getNew(context)
    context:addSubMenu(root, sub)

    sub:addOption("Criar area", nil, function()
        PZBI.Tool.startCreate(player)
    end)
    sub:addOption("Ver areas", nil, function()
        PZBI.showBases(player)
    end)
    sub:addOption("Apagar area", nil, function()
        PZBI.Tool.startDelete(player)
    end)
    if PZBI.Tool.mode then
        sub:addOption("Cancelar", nil, function()
            PZBI.Tool.cancel()
        end)
    end
end)
