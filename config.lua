--[[
    NOVA Framework - Fuel Config
]]

FuelConfig = {}

-- ============================================================
-- GERAL
-- ============================================================

FuelConfig.PricePerLiter = 3          -- Preço por litro ($)
FuelConfig.TankCapacity = 65          -- Litros (tanque padrão)
FuelConfig.GlobalMultiplier = 1.0     -- Multiplicador global de consumo
FuelConfig.ConsumptionInterval = 1000 -- ms entre cada tick de consumo
FuelConfig.InteractDistance = 5.0     -- Distância para interagir com bomba
FuelConfig.DrawDistance = 15.0        -- Distância para desenhar texto 3D
FuelConfig.InteractKey = 38           -- E

-- ============================================================
-- JERRY CAN
-- ============================================================

FuelConfig.JerryCan = {
    itemName = 'jerrycan',
    fuelAmount = 25,      -- Litros que o jerrycan dá (~38% do tanque)
    useDistance = 3.0,     -- Distância máxima ao veículo
    useDuration = 5000,    -- Duração da animação (ms)
    shopPrice = 200,       -- Preço na loja
}

-- ============================================================
-- CONSUMO POR CLASSE DE VEÍCULO
-- ============================================================

FuelConfig.ClassMultiplier = {
    [0]  = 0.8,   -- Compacts
    [1]  = 0.9,   -- Sedans
    [2]  = 1.0,   -- SUVs
    [3]  = 1.0,   -- Coupes
    [4]  = 1.1,   -- Muscle
    [5]  = 1.3,   -- Sports Classics
    [6]  = 1.5,   -- Sports
    [7]  = 2.0,   -- Super
    [8]  = 1.2,   -- Motorcycles
    [9]  = 0.9,   -- Off-road
    [10] = 1.0,   -- Industrial
    [11] = 1.1,   -- Utility
    [12] = 0.8,   -- Vans
    [13] = 0.0,   -- Cycles (sem combustível)
    [14] = 2.5,   -- Boats
    [15] = 3.0,   -- Helicopters
    [16] = 3.5,   -- Planes
    [17] = 1.0,   -- Service
    [18] = 1.2,   -- Emergency
    [19] = 1.0,   -- Military
    [20] = 1.0,   -- Commercial
    [21] = 0.0,   -- Trains (sem combustível)
}

-- ============================================================
-- BLIPS
-- ============================================================

FuelConfig.Blip = {
    sprite = 361,
    color = 1,
    scale = 0.7,
    label = 'Posto de Gasolina',
}

-- ============================================================
-- NPCs
-- ============================================================

FuelConfig.Ped = {
    model = 'a_m_m_indian_01',
    scenario = 'PROP_HUMAN_SEAT_CHAIR_MP_PLAYER',
}

-- ============================================================
-- POSTOS DE GASOLINA (25 localizações reais de GTA V)
-- ============================================================

FuelConfig.Stations = {
    -- Downtown / Central LS
    { label = 'Davis - Grove St',      coords = vector3(-70.2, -1761.8, 29.5),    pump = vector3(-61.6, -1756.9, 29.4) },
    { label = 'Strawberry',            coords = vector3(265.6, -1261.3, 29.3),    pump = vector3(273.4, -1261.5, 29.2) },
    { label = 'Little Seoul',          coords = vector3(-531.4, -1220.9, 18.5),   pump = vector3(-524.4, -1214.3, 18.2) },
    { label = 'La Mesa',               coords = vector3(819.7, -1027.9, 26.4),    pump = vector3(818.3, -1040.5, 26.8) },
    { label = 'Mirror Park',           coords = vector3(1208.3, -1402.0, 35.2),   pump = vector3(1210.8, -1389.1, 35.4) },
    { label = 'East LS - Murrieta',    coords = vector3(1181.5, -330.3, 69.3),    pump = vector3(1175.7, -323.6, 69.3) },

    -- West LS
    { label = 'Del Perro',             coords = vector3(-1437.6, -276.8, 46.2),   pump = vector3(-1432.6, -268.8, 46.2) },
    { label = 'Morningwood',           coords = vector3(-1444.0, -386.5, 36.0),   pump = vector3(-1436.7, -380.7, 36.0) },
    { label = 'Pacific Bluffs',        coords = vector3(-2096.2, -320.3, 13.2),   pump = vector3(-2090.4, -317.2, 13.2) },
    { label = 'Richman Glen',          coords = vector3(-2555.5, 2334.1, 33.1),   pump = vector3(-2554.3, 2340.4, 33.1) },

    -- Vinewood / North LS
    { label = 'Vinewood - Downtown',   coords = vector3(176.6, -1562.5, 29.3),    pump = vector3(170.1, -1560.1, 29.3) },
    { label = 'Hawick',                coords = vector3(620.8, 268.9, 103.1),     pump = vector3(621.6, 276.6, 103.1) },

    -- East County
    { label = 'Palomino Fwy',          coords = vector3(2581.0, 362.0, 108.5),    pump = vector3(2574.8, 355.8, 108.5) },
    { label = 'Tataviam - Route 68',   coords = vector3(2679.9, 3264.3, 55.2),    pump = vector3(2681.5, 3271.0, 55.2) },

    -- Blaine County
    { label = 'Harmony',               coords = vector3(263.9, 2606.5, 44.9),     pump = vector3(254.6, 2601.1, 44.9) },
    { label = 'Sandy Shores - North',  coords = vector3(2005.3, 3773.9, 32.4),    pump = vector3(2001.0, 3779.2, 32.2) },
    { label = 'Sandy Shores - South',  coords = vector3(1690.9, 4929.1, 42.1),    pump = vector3(1697.5, 4930.2, 42.1) },
    { label = 'Grapeseed',             coords = vector3(1701.1, 6416.1, 32.8),    pump = vector3(1692.6, 6416.3, 32.8) },

    -- North County
    { label = 'Paleto Bay - East',     coords = vector3(179.9, 6602.8, 32.0),     pump = vector3(172.7, 6605.4, 32.0) },
    { label = 'Paleto Bay - West',     coords = vector3(-94.5, 6419.0, 31.5),     pump = vector3(-100.8, 6421.5, 31.5) },
    { label = 'Mt Chiliad',            coords = vector3(1686.6, 4931.0, 42.1),    pump = vector3(1692.8, 4925.1, 42.1) },

    -- Great Ocean Highway
    { label = 'Chumash',               coords = vector3(-3172.0, 1087.5, 20.8),   pump = vector3(-3171.9, 1080.1, 20.8) },
    { label = 'Banham Canyon',         coords = vector3(-2082.5, -342.0, 13.3),   pump = vector3(-2085.7, -349.6, 13.3) },

    -- Airport / Industrial
    { label = 'LSIA',                  coords = vector3(-1605.4, -3143.4, 14.0),  pump = vector3(-1598.2, -3140.0, 14.0) },
    { label = 'Elysian Island',        coords = vector3(49.4, -2779.4, 6.0),      pump = vector3(42.0, -2783.6, 6.0) },
}
