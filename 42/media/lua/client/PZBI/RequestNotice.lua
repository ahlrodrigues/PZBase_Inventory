-- PZBase Inventory (cliente): avisa o dono, ao entrar no jogo, sobre pedidos de inscrição pendentes (seção 3).
-- Usa PZBI.pendingRequestsFor, definida em BaseMenu.lua.
-- Status: NÃO testado em jogo. Em multijogador, o ModData pode não estar pronto neste momento.

require "PZBI/Config"

local function noticeOnStart()
    local player = getPlayer()
    if not player or not PZBI.pendingRequestsFor then return end
    local count = #PZBI.pendingRequestsFor(player:getUsername())
    if count > 0 then
        player:Say(getText("IGUI_PZBI_PendingOnLogin", tostring(count)))
    end
end

Events.OnGameStart.Add(noticeOnStart)
