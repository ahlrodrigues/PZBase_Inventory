-- Testes das regras de contêineres e inscrições (fora do jogo).
-- Rodar a partir da raiz do repositório:  lua tests/container_rules_test.lua

function require() end

PZBI = { MOD_DATA_KEY = "PZBaseInventory" }
local R = dofile("42/media/lua/shared/PZBI/ContainerRules.lua")

local failures, passes = 0, 0
local function check(name, cond)
    if cond then
        passes = passes + 1
    else
        failures = failures + 1
        print("FALHOU: " .. name)
    end
end

local bases = {
    { owner = "ana", area = { x1 = 10, y1 = 10, x2 = 20, y2 = 20, z = 0 } },
}

-- Dono derivado da base
check("contêiner dentro da base tem dono", R.findOwnerBase(bases, 15, 15, 0).owner == "ana")
check("contêiner fora da base não tem dono", R.findOwnerBase(bases, 50, 50, 0) == nil)
check("contêiner em outro andar não tem dono", R.findOwnerBase(bases, 15, 15, 1) == nil)
check("borda da base conta como dentro", R.findOwnerBase(bases, 20, 20, 0) ~= nil)
check("sem bases não há dono", R.findOwnerBase({}, 15, 15, 0) == nil)

-- Chave estável
check("chave de contêiner tem o formato esperado",
    R.containerKey(1, 2, 3, "furniture_storage_01_13") == "PZBaseInventory_1_2_3_furniture_storage_01_13")

-- Inscrição direta sem dono
local r1 = {}
check("sem dono: inscrição aberta", R.subscribe(r1, "bob", nil) == "aberta")
check("sem dono: entra em subscribers", r1.subscribers.bob == true)

-- Dono se inscreve no próprio contêiner
local r2 = {}
check("dono inscreve direto no próprio contêiner", R.subscribe(r2, "ana", "ana") == "aberta")

-- Pedido em contêiner de outro dono
local r3 = {}
check("outro jogador em base alheia: pendente", R.subscribe(r3, "bob", "ana") == "pendente")
check("pedido fica em requests, não em subscribers", r3.requests.bob == true and r3.subscribers.bob == nil)

-- Aprovação só pelo dono
local ok1, why1 = R.approve(r3, "ana", "bob", "bob")
check("não-dono não aprova", ok1 == false and why1 == "not_owner")
local ok2 = R.approve(r3, "ana", "ana", "bob")
check("dono aprova o pedido", ok2 == true)
check("aprovado vira inscrito e sai dos pedidos", r3.subscribers.bob == true and r3.requests.bob == nil)

-- Recusa
local r4 = {}
R.subscribe(r4, "bob", "ana")
local ok3 = R.deny(r4, "ana", "ana", "bob")
check("dono recusa o pedido", ok3 == true and r4.requests.bob == nil and r4.subscribers.bob == nil)
local ok4, why4 = R.approve(r4, "ana", "ana", "bob")
check("aprovar pedido inexistente falha", ok4 == false and why4 == "no_request")

-- Cancelar inscrição
R.unsubscribe(r3, "bob")
check("cancelar remove inscrição", r3.subscribers.bob == nil and r3.requests.bob == nil)

-- Sem dono (base removida): não há aprovação possível
local r5 = {}
R.subscribe(r5, "bob", nil)
local ok5 = R.approve(r5, nil, "ana", "bob")
check("sem dono não há aprovação", ok5 == false)

print(string.format("%d ok, %d falha(s)", passes, failures))
os.exit(failures == 0 and 0 or 1)
