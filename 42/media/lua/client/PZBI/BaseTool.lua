-- PZBase Inventory (cliente): criar e apagar área da base, pelo submenu "PZBase".
-- Criar: arraste sobre o chão (a área aparece preenchida em tempo real). Ao soltar, abre a janela
-- para nomear e salvar. Apagar: clique numa área sua para apagá-la, com confirmação.
-- Eventos globais (OnMouseDown/OnMouseMove/OnMouseUp) em vez dos eventos ...Outside de painel,
-- porque o arrasto precisa funcionar antes de a janela de nome existir.
-- Status: NÃO testado em jogo. APIs a validar: Events.OnMouseDown/OnMouseMove/OnMouseUp,
-- screenToIsoX/Y, addAreaHighlightForPlayer, ISModalDialog e ISTextEntryBox.

require "PZBI/Config"
require "ISUI/ISPanel"

local CMD_MODULE = "PZBI"
local CMD_CREATE = "createBase"
local CMD_REMOVE = "removeBase"
local MAX_CITY_LENGTH = 40   -- mesmo limite do servidor
local NAME_WIDTH = 280
local NAME_HEIGHT = 130

PZBI = PZBI or {}
PZBI.Tool = PZBI.Tool or {}
local T = PZBI.Tool

-- Estado da ferramenta: mode = nil | "create" | "delete"
T.mode = nil
T.player = nil
T.playerNum = 0
T.z = 0
T.dragging = false
T.startX, T.startY, T.endX, T.endY = nil, nil, nil, nil
T.nameWindow = nil

local function say(text)
    if T.player and T.player.Say then T.player:Say(text) end
end

local function zoneColor()
    return {
        r = DesignationZoneAnimal and DesignationZoneAnimal.ZONE_COLOR_R or 0.2,
        g = DesignationZoneAnimal and DesignationZoneAnimal.ZONE_COLOR_G or 0.6,
        b = DesignationZoneAnimal and DesignationZoneAnimal.ZONE_COLOR_B or 0.2,
        a = 0.5,
    }
end

local function setWorldMenu(enabled)
    if ISWorldObjectContextMenu then
        ISWorldObjectContextMenu.disableWorldMenu = not enabled
    end
end

-- Quadrado do chão sob a posição de tela informada, no andar do jogador.
local function squareAt(sx, sy)
    local wx = screenToIsoX(T.playerNum, sx, sy, T.z)
    local wy = screenToIsoY(T.playerNum, sx, sy, T.z)
    return getCell():getGridSquare(wx, wy, T.z)
end

function T.cancel()
    T.mode = nil
    T.dragging = false
    T.startX, T.startY, T.endX, T.endY = nil, nil, nil, nil
    setWorldMenu(true)
    if T.nameWindow then T.nameWindow:close() end
    PZBI.clearHighlight()
end

function T.startCreate(player)
    T.cancel()
    T.player = player
    T.playerNum = player:getPlayerNum()
    T.z = player:getZ()
    T.mode = "create"
    say("Arraste no chão para marcar a área.")
end

function T.startDelete(player)
    T.cancel()
    T.player = player
    T.playerNum = player:getPlayerNum()
    T.z = player:getZ()
    T.mode = "delete"
    PZBI.setHighlight(PZBI.listBases(), nil)
    say("Clique numa área sua para apagá-la.")
end

-- Janela de nome, aberta depois de soltar o arrasto.
ISBaseNameWindow = ISPanel:derive("ISBaseNameWindow")

function ISBaseNameWindow:new(x, y, width, height, onSave, onCancel)
    local o = ISPanel.new(self, x, y, width, height)
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0.85 }
    o.borderColor = { r = 0.4, g = 0.4, b = 0.4, a = 1 }
    o.onSave = onSave
    o.onCancel = onCancel
    return o
end

function ISBaseNameWindow:createChildren()
    self.nameEntry = ISTextEntryBox:new("Base", 10, 40, self.width - 20, 22)
    self.nameEntry:initialise()
    self.nameEntry:instantiate()
    self:addChild(self.nameEntry)

    self.buttonSave = ISButton:new(10, self.height - 34, 120, 24, "Salvar", self, ISBaseNameWindow.save)
    self.buttonSave:initialise()
    self.buttonSave:instantiate()
    self:addChild(self.buttonSave)

    self.buttonCancel = ISButton:new(self.width - 130, self.height - 34, 120, 24, "Cancelar", self, ISBaseNameWindow.cancel)
    self.buttonCancel:initialise()
    self.buttonCancel:instantiate()
    self:addChild(self.buttonCancel)
end

function ISBaseNameWindow:save()
    self.onSave(self.nameEntry:getText())
end

function ISBaseNameWindow:cancel()
    self.onCancel()
end

function ISBaseNameWindow:close()
    self:setVisible(false)
    self:removeFromUIManager()
    if T.nameWindow == self then T.nameWindow = nil end
end

local function openNameWindow()
    local x = getCore():getScreenWidth() / 2 - NAME_WIDTH / 2
    local y = getCore():getScreenHeight() / 2 - NAME_HEIGHT / 2
    local win = ISBaseNameWindow:new(x, y, NAME_WIDTH, NAME_HEIGHT,
        function(city)
            city = city:match("^%s*(.-)%s*$")
            if #city == 0 or #city > MAX_CITY_LENGTH then
                say("Digite um nome de cidade com até " .. MAX_CITY_LENGTH .. " caracteres.")
                return
            end
            local area = {
                x1 = math.min(T.startX, T.endX), y1 = math.min(T.startY, T.endY),
                x2 = math.max(T.startX, T.endX), y2 = math.max(T.startY, T.endY),
                z = T.z,
            }
            sendClientCommand(T.player, CMD_MODULE, CMD_CREATE, { city = city, area = area })
            say("Pedido de base enviado (" .. city .. ").")
            T.cancel()
        end,
        function() T.cancel() end)
    win:initialise()
    win:createChildren()
    win:addToUIManager()
    win:setVisible(true)
    T.nameWindow = win
end

-- Apagar: a base precisa ser sua e a confirmação é obrigatória.
local function onDeleteConfirm(target, button)
    if button.internal ~= "YES" then
        T.cancel()
        return
    end
    sendClientCommand(T.player, CMD_MODULE, CMD_REMOVE, { id = T.pendingDelete.id })
    say("Pedido para apagar a base '" .. T.pendingDelete.city .. "' enviado.")
    T.pendingDelete = nil
    T.cancel()
end

local function deleteAt(x, y)
    local found
    for _, base in ipairs(PZBI.listBases()) do
        local a = base.area
        if x >= a.x1 and x <= a.x2 and y >= a.y1 and y <= a.y2 and T.z == a.z then
            found = base
            break
        end
    end
    if not found then
        say("Nenhuma base aqui.")
        T.cancel()
        return
    end
    if found.owner ~= T.player:getUsername() then
        say("Só o dono pode apagar esta base.")
        T.cancel()
        return
    end
    T.pendingDelete = found
    local modal = ISModalDialog:new(getCore():getScreenWidth() / 2 - 175, getCore():getScreenHeight() / 2 - 75,
        350, 150, "Apagar a base '" .. found.city .. "'?", true, T, onDeleteConfirm)
    modal:initialise()
    modal:addToUIManager()
end

-- Eventos globais: arrastar para criar, clicar para apagar.
Events.OnMouseDown.Add(function(x, y)
    if T.mode == "create" then
        local sq = squareAt(x, y)
        if sq then
            T.startX, T.startY = sq:getX(), sq:getY()
            T.endX, T.endY = sq:getX(), sq:getY()
            T.dragging = true
            setWorldMenu(false)
        end
    elseif T.mode == "delete" then
        local sq = squareAt(x, y)
        if sq then deleteAt(sq:getX(), sq:getY()) end
    end
end)

Events.OnMouseMove.Add(function(x, y)
    if T.mode ~= "create" or not T.dragging then return end
    local sq = squareAt(x, y)
    if sq then
        T.endX, T.endY = sq:getX(), sq:getY()
    end
end)

Events.OnMouseUp.Add(function(x, y)
    if T.mode ~= "create" or not T.dragging then return end
    T.dragging = false
    setWorldMenu(true)
    T.mode = "naming"
    openNameWindow()
end)

-- Pré-visualização da área enquanto arrasta e enquanto nomeia.
Events.OnRenderTick.Add(function()
    if (T.mode == "create" or T.mode == "naming") and T.startX then
        local c = zoneColor()
        addAreaHighlightForPlayer(T.playerNum,
            math.min(T.startX, T.endX), math.min(T.startY, T.endY),
            math.max(T.startX, T.endX) + 1, math.max(T.startY, T.endY) + 1,
            T.z, c.r, c.g, c.b, c.a)
    end
end)
