-- PZBase Inventory (cliente): avisa o servidor que este jogador está ativo (especificação, seção 6).
-- Envia ao entrar no jogo e a cada hora. O servidor registra o login de quem enviou o aviso
-- (Inactivity.lua), por isso funciona em solo e em multijogador.
-- Status: NÃO testado em jogo nem em servidor dedicado.

require "PZBI/Config"

local CMD_MODULE = "PZBI"
local CMD_SEEN = "seen"

local function ping()
    local player = getPlayer()
    if not player then return end
    sendClientCommand(player, CMD_MODULE, CMD_SEEN, {})
end

Events.OnGameStart.Add(ping)
Events.EveryHours.Add(ping)
