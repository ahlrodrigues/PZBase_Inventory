-- PZBase Inventory (cliente): menu de contexto "PZBase" com submenus.
-- Submenus: Criar, Ver, Apagar (BaseTool/BaseViewer) e Cancelar quando houver ação pendente.
-- Textos vêm de Translate/<IDIOMA>/PZBI_UI.json (acentos preservados pelo próprio jogo).
-- Status: criar/apagar testados em jogo; tradução a validar.

require "PZBI/Config"
require "ISUI/ISContextMenu"

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
    if PZBI.Tool.mode then
        sub:addOption(getText("IGUI_PZBI_Cancel"), nil, function()
            PZBI.Tool.cancel()
        end)
    end
end)
