--[[
    NOVA Framework - Fuel Client Main
    Consumo dinâmico, exports GetFuel/SetFuel, vehicle undriveable a 0%
]]

local fuelLevels = {} -- [netId] = fuelLevel
local isRefueling = false

-- ============================================================
-- FUEL MANAGEMENT
-- ============================================================

--- Obter fuel do veículo
---@param vehicle number entity handle
---@return number fuel level 0-100
local function InternalGetFuel(vehicle)
    if not vehicle or not DoesEntityExist(vehicle) then return 0 end
    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    if fuelLevels[netId] then
        return fuelLevels[netId]
    end
    return GetVehicleFuelLevel(vehicle)
end

--- Definir fuel do veículo
---@param vehicle number entity handle
---@param amount number fuel level 0-100
local function InternalSetFuel(vehicle, amount)
    if not vehicle or not DoesEntityExist(vehicle) then return end
    amount = math.max(0.0, math.min(100.0, amount + 0.0))
    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    fuelLevels[netId] = amount
    SetVehicleFuelLevel(vehicle, amount)
    -- Gerir undriveable
    if amount <= 0.0 then
        SetVehicleUndriveable(vehicle, true)
    else
        SetVehicleUndriveable(vehicle, false)
    end
end

-- ============================================================
-- EXPORTS (Compatível com LegacyFuel)
-- ============================================================

exports('GetFuel', function(vehicle)
    return InternalGetFuel(vehicle)
end)

exports('SetFuel', function(vehicle, amount)
    InternalSetFuel(vehicle, amount)
end)

-- ============================================================
-- CONSUMO DE COMBUSTÍVEL
-- ============================================================

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)

        if vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == ped and not isRefueling then
            local class = GetVehicleClass(vehicle)
            local classMultiplier = FuelConfig.ClassMultiplier[class] or 1.0

            -- Sem consumo para bicicletas e comboios
            if classMultiplier > 0.0 then
                local currentFuel = InternalGetFuel(vehicle)

                if currentFuel > 0.0 then
                    -- Calcular consumo baseado em RPM
                    local rpm = GetVehicleCurrentRpm(vehicle)
                    local consumption = rpm * 0.06 * classMultiplier * FuelConfig.GlobalMultiplier

                    -- Motor desligado = sem consumo
                    if not GetIsVehicleEngineRunning(vehicle) then
                        consumption = 0.0
                    end

                    local newFuel = math.max(0.0, currentFuel - consumption)
                    InternalSetFuel(vehicle, newFuel)

                    -- Notificar quando fica com pouco combustível
                    if newFuel <= 10.0 and currentFuel > 10.0 then
                        exports['nova_notify']:Notify('error', 'Combustível baixo! (' .. math.floor(newFuel) .. '%)', 4000)
                    end

                    -- Sem combustível
                    if newFuel <= 0.0 then
                        exports['nova_notify']:Notify('error', 'Sem combustível!', 5000)
                    end
                else
                    -- Garantir que fica parado
                    SetVehicleUndriveable(vehicle, true)
                end
            end

            Wait(FuelConfig.ConsumptionInterval)
        else
            Wait(500)
        end
    end
end)

-- ============================================================
-- SYNC: Quando entra num veículo, ler fuel nativo
-- ============================================================

CreateThread(function()
    local lastVehicle = 0
    while true do
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)

        if vehicle ~= 0 and vehicle ~= lastVehicle then
            -- Entrou num veículo novo
            local netId = NetworkGetNetworkIdFromEntity(vehicle)
            if not fuelLevels[netId] then
                fuelLevels[netId] = GetVehicleFuelLevel(vehicle)
            end
            -- Aplicar o fuel guardado
            SetVehicleFuelLevel(vehicle, fuelLevels[netId])
            if fuelLevels[netId] <= 0.0 then
                SetVehicleUndriveable(vehicle, true)
            end
            lastVehicle = vehicle
        elseif vehicle == 0 then
            lastVehicle = 0
        end

        Wait(1000)
    end
end)

-- ============================================================
-- CLEANUP: Limpar fuel levels de veículos que já não existem
-- ============================================================

CreateThread(function()
    while true do
        Wait(60000) -- A cada minuto
        for netId, _ in pairs(fuelLevels) do
            local entity = NetworkGetEntityFromNetworkId(netId)
            if not entity or not DoesEntityExist(entity) then
                fuelLevels[netId] = nil
            end
        end
    end
end)

-- ============================================================
-- ESTADO DO REFUELING (usado por stations.lua)
-- ============================================================

function SetRefueling(state)
    isRefueling = state
end

function IsRefueling()
    return isRefueling
end
