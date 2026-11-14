-- PZBase Inventory: constantes compartilhadas (cliente e servidor).
-- Carregado em shared/ para que ambos os lados usem os mesmos valores.

PZBI = PZBI or {}

-- Chave do ModData do mod. Cada base e cada contêiner são guardados em
-- sub-tabelas separadas (a sincronização envia a tabela inteira).
PZBI.MOD_DATA_KEY = "PZBaseInventory"

-- Regra de inatividade do dono (especificação, seção 6).
PZBI.INACTIVITY_DAYS = 30

-- Versão do formato de dados, para migrações futuras.
PZBI.DATA_VERSION = 1
