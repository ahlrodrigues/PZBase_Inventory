-- PZBase Inventory (cliente): marcação de base arrastando sobre o chão, no mesmo padrão da área dos animais.
-- Botão direito num tile: "PZBI: marcar base" abre a ferramenta.
-- Arraste sobre o chão para definir a área (preenchida com a cor da área dos animais),
-- digite o nome da cidade e clique em "Criar base".
-- Padrão copiado de client/ISUI/Animal/ISAddDesignationAnimalZoneUI.lua (jogo).
-- Status: NÃO testado em jogo. APIs a validar: screenToIsoX/Y, getCell():getGridSquare,
-- addAreaHighlightForPlayer, ISTextEntryBox, ISButton e os eventos ...Outside.
-- O servidor valida tudo (regras em shared/PZBI/BaseRules.lua) e só registra a recusa no log.

require "PZBI/Config"
require "ISUI/ISPanel"

local CMD_MODULE = "PZBI"
local CMD_CREATE = "createBase"
local MAX_CITY_LENGTH = 40   -- mesmo limite do servidor
local PANEL_WIDTH = 280
local PANEL_HEIGHT = 150

local function zoneColor()
    return {
        r = DesignationZoneAnimal and DesignationZoneAnimal.ZONE_COLOR_R or 0.2,
        g = DesignationZoneAnimal and DesignationZoneAnimal.ZONE_COLOR_G or 0.6,
        b = DesignationZoneAnimal and DesignationZoneAnimal.ZONE_COLOR_B or 0.2,
        a = 0.5,
    }
end

ISBaseTool = ISPanel:derive("ISBaseTool")

function ISBaseTool:new(x, y, width, height, player)
    local o = ISPanel.new(self, x, y, width, height)
    o.player = player
    o.playerNum = player:getPlayerNum()
    o.z = player:getZ()
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0.8 }
    o.borderColor = { r = 0.4, g = 0.4, b = 0.4, a = 1 }
    o.zoneColor = zoneColor()
    o.startingX, o.startingY, o.endX, o.endY = nil, nil, nil, nil
    o.dragging = false
    return o
end

function ISBaseTool:createChildren()
    self.nameEntry = ISTextEntryBox:new("Base", 10, 40, self.width - 20, 22)
    self.nameEntry:initialise()
    self.nameEntry:instantiate()
    self:addChild(self.nameEntry)

    self.buttonCreate = ISButton:new(10, self.height - 34, 120, 24, "Criar base", self, ISBaseTool.onCreate)
    self.buttonCreate:initialise()
    self.buttonCreate:instantiate()
    self:addChild(self.buttonCreate)

    self.buttonClose = ISButton:new(self.width - 130, self.height - 34, 120, 24, "Fechar", self, ISBaseTool.close)
    self.buttonClose:initialise()
    self.buttonClose:instantiate()
    self:addChild(self.buttonClose)
end

-- Quadrado do chão sob a posição de tela informada.
function ISBaseTool:pickSquare(screenX, screenY)
    local wx = screenToIsoX(self.playerNum, screenX, screenY, self.z)
    local wy = screenToIsoY(self.playerNum, screenX, screenY, self.z)
    return getCell():getGridSquare(wx, wy, self.z)
end

function ISBaseTool:onMouseDownOutside(x, y)
    if self.playerNum ~= 0 then return end
    local sq = self:pickSquare(x + self:getAbsoluteX(), y + self:getAbsoluteY())
    if sq then
        self.startingX, self.startingY = sq:getX(), sq:getY()
        self.endX, self.endY = sq:getX(), sq:getY()
        self.dragging = true
        ISWorldObjectContextMenu.disableWorldMenu = true
    end
end

function ISBaseTool:onMouseMoveOutside(dx, dy)
    if self.playerNum ~= 0 or not self.dragging then return end
    local sq = self:pickSquare(getMouseX(), getMouseY())
    if sq then
        self.endX, self.endY = sq:getX(), sq:getY()
    end
end

function ISBaseTool:onMouseUpOutside(x, y)
    if self.playerNum ~= 0 then return end
    self.dragging = false
    self:restoreWorldMenu()
end

-- O jogo usa essa flag para bloquear o menu do mundo durante o arrasto (ver ISAddDesignationAnimalZoneUI).
-- Precisa ser desfeita ao soltar o mouse ou ao fechar, senão o botão direito deixa de abrir o menu.
function ISBaseTool:restoreWorldMenu()
    if ISWorldObjectContextMenu then
        ISWorldObjectContextMenu.disableWorldMenu = false
    end
end

-- Desenha a área marcada com a cor da área dos animais.
function ISBaseTool:prerender()
    ISPanel.prerender(self)
    self:drawText("Arraste no chão para marcar a área", 10, 10, 1, 1, 1, 1, UIFont.Small)
    if self.startingX and self.endX then
        local x1, x2 = math.min(self.startingX, self.endX), math.max(self.startingX, self.endX)
        local y1, y2 = math.min(self.startingY, self.endY), math.max(self.startingY, self.endY)
        local c = self.zoneColor
        addAreaHighlightForPlayer(self.playerNum, x1, y1, x2 + 1, y2 + 1, self.z, c.r, c.g, c.b, c.a)
    end
end

local function say(player, text)
    if player and player.Say then player:Say(text) end
end

function ISBaseTool:onCreate()
    if not self.startingX then
        say(self.player, "Arraste no chão para marcar a área.")
        return
    end
    local city = self.nameEntry:getText():match("^%s*(.-)%s*$")
    if #city == 0 or #city > MAX_CITY_LENGTH then
        say(self.player, "Digite um nome de cidade com até " .. MAX_CITY_LENGTH .. " caracteres.")
        return
    end

    local area = {
        x1 = math.min(self.startingX, self.endX),
        y1 = math.min(self.startingY, self.endY),
        x2 = math.max(self.startingX, self.endX),
        y2 = math.max(self.startingY, self.endY),
        z = self.z,
    }
    sendClientCommand(self.player, CMD_MODULE, CMD_CREATE, { city = city, area = area })
    say(self.player, "Pedido de base enviado (" .. city .. ").")
    self:close()
end

function ISBaseTool:close()
    self:restoreWorldMenu()
    self:setVisible(false)
    self:removeFromUIManager()
    if ISBaseTool.instance == self then ISBaseTool.instance = nil end
end

function ISBaseTool.open(player)
    if ISBaseTool.instance then ISBaseTool.instance:close() end
    local x = getCore():getScreenWidth() / 2 - PANEL_WIDTH / 2
    local y = getCore():getScreenHeight() / 2 - PANEL_HEIGHT / 2
    local o = ISBaseTool:new(x, y, PANEL_WIDTH, PANEL_HEIGHT, player)
    o:initialise()
    o:createChildren()
    o:addToUIManager()
    o:setVisible(true)
    ISBaseTool.instance = o
end

Events.OnFillWorldObjectContextMenu.Add(function(playerIndex, context, worldObjects, test)
    local player = getSpecificPlayer(playerIndex)
    if not player then return end
    context:addOption("PZBI: marcar base", nil, function()
        ISBaseTool.open(player)
    end)
end)
