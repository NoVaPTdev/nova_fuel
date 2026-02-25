--[[
    NOVA Framework - Fuel Stations Client
    NPCs, blips, interação nas bombas, animações, progress bar
]]

local SpawnedPeds = {}
local StationBlips = {}
local isNuiOpen = false
local currentStation = nil
local currentVehicle = nil

-- Estado do abastecimento interactivo
local pendingRefuel = nil   -- { amount, vehicle, pumpCoords }
local holdingNozzle = false
local nozzleProp = nil
local ropeId = nil
local ropePumpPos = nil     -- vec3 do topo da bomba

-- ============================================================
-- HELPERS
-- ============================================================

local function DrawText3D(x, y, z, text)
    SetTextScale(0.28, 0.28)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextColour(197, 255, 0, 215)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(2, 0, 0, 0, 150)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry('STRING')
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end

local function LoadModel(model)
    local hash = type(model) == 'number' and model or GetHashKey(model)
    if not IsModelValid(hash) then return hash end
    RequestModel(hash)
    local t = 0
    while not HasModelLoaded(hash) and t < 50 do Wait(100); t = t + 1 end
    return hash
end

-- ============================================================
-- MODELOS DE BOMBAS & FUNÇÕES DE PROCURA
-- ============================================================

local PumpModels = {
    `prop_gas_pump_1a`,
    `prop_gas_pump_1b`,
    `prop_gas_pump_1c`,
    `prop_gas_pump_1d`,
    `prop_gas_pump_old1`,
    `prop_gas_pump_old2`,
    `prop_gas_pump_old3`,
    `prop_vintage_pump`,
    `prop_gas_pump_1d_bl`,
}

-- Encontrar a bomba mais próxima (prop real do mundo)
local function GetClosestPump(coords, maxDist)
    local closestDist = maxDist or 10.0
    local closestPump = nil
    local closestPumpCoords = nil

    for _, model in ipairs(PumpModels) do
        local pump = GetClosestObjectOfType(coords.x, coords.y, coords.z, closestDist, model, false, false, false)
        if pump ~= 0 and DoesEntityExist(pump) then
            local pumpPos = GetEntityCoords(pump)
            local d = #(coords - pumpPos)
            if d < closestDist then
                closestDist = d
                closestPump = pump
                closestPumpCoords = pumpPos
            end
        end
    end

    return closestPump, closestPumpCoords, closestDist
end

-- Encontrar o posto mais próximo (para label e preço)
local function GetClosestStation(coords)
    local best = nil
    local bestDist = 999.0
    for _, station in ipairs(FuelConfig.Stations) do
        local d = #(coords - station.coords)
        if d < bestDist then
            bestDist = d
            best = station
        end
    end
    return best
end

-- Encontrar o veículo mais próximo do jogador (a pé)
local function GetClosestVehicle(coords, maxDist)
    local vehicles = GetGamePool('CVehicle')
    local closest = nil
    local closestDist = maxDist or 8.0
    for _, veh in ipairs(vehicles) do
        if DoesEntityExist(veh) then
            local vCoords = GetEntityCoords(veh)
            local d = #(coords - vCoords)
            if d < closestDist then
                closestDist = d
                closest = veh
            end
        end
    end
    return closest, closestDist
end

-- ============================================================
-- BLIPS
-- ============================================================

local function CreateStationBlips()
    for _, blip in ipairs(StationBlips) do
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end
    StationBlips = {}

    for _, station in ipairs(FuelConfig.Stations) do
        local blip = AddBlipForCoord(station.coords)
        SetBlipSprite(blip, FuelConfig.Blip.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, FuelConfig.Blip.scale)
        SetBlipColour(blip, FuelConfig.Blip.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(station.label or FuelConfig.Blip.label)
        EndTextCommandSetBlipName(blip)
        table.insert(StationBlips, blip)
    end
end

-- ============================================================
-- NPCs
-- ============================================================

local function SpawnStationPeds()
    for _, ped in ipairs(SpawnedPeds) do
        if DoesEntityExist(ped) then DeleteEntity(ped) end
    end
    SpawnedPeds = {}

    local hash = LoadModel(FuelConfig.Ped.model)
    for _, station in ipairs(FuelConfig.Stations) do
        local ped = CreatePed(4, hash, station.coords.x, station.coords.y, station.coords.z - 1.0, 0.0, false, true)
        if DoesEntityExist(ped) then
            SetEntityInvincible(ped, true)
            FreezeEntityPosition(ped, true)
            SetBlockingOfNonTemporaryEvents(ped, true)
            SetEntityAsMissionEntity(ped, true, true)
            SetPedFleeAttributes(ped, 0, false)
            SetPedCombatAttributes(ped, 17, true)
            SetPedDefaultComponentVariation(ped)
            TaskStartScenarioInPlace(ped, FuelConfig.Ped.scenario, 0, true)
            table.insert(SpawnedPeds, ped)
        end
    end
    SetModelAsNoLongerNeeded(hash)
end

-- ============================================================
-- NUI
-- ============================================================

local function OpenFuelNUI(station, vehicle)
    if isNuiOpen or IsRefueling() then return end

    currentStation = station
    currentVehicle = vehicle

    local currentFuel = exports['nova_fuel']:GetFuel(vehicle)
    local maxFuel = 100.0
    local fuelNeeded = maxFuel - currentFuel
    local litersNeeded = (fuelNeeded / 100.0) * FuelConfig.TankCapacity
    local maxPrice = math.ceil(litersNeeded * FuelConfig.PricePerLiter)

    isNuiOpen = true
    SetNuiFocus(true, true)

    SendNUIMessage({
        action = 'open',
        currentFuel = math.floor(currentFuel),
        maxFuel = math.floor(maxFuel),
        pricePerLiter = FuelConfig.PricePerLiter,
        tankCapacity = FuelConfig.TankCapacity,
        maxPrice = maxPrice,
        stationName = station.label or 'Posto de Gasolina',
    })
end

local function CloseFuelNUI()
    if not isNuiOpen then return end
    isNuiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    currentStation = nil
end

-- ============================================================
-- NUI CALLBACKS
-- ============================================================

RegisterNUICallback('closeFuel', function(_, cb)
    CloseFuelNUI()
    cb('ok')
end)

RegisterNUICallback('refuel', function(data, cb)
    local amount = tonumber(data.amount) or 0
    local price = tonumber(data.price) or 0

    if amount <= 0 or not currentVehicle or not DoesEntityExist(currentVehicle) then
        cb('error')
        return
    end

    CloseFuelNUI()

    -- Pedir pagamento ao server
    TriggerServerEvent('nova:fuel:purchase', price, amount)
    cb('ok')
end)

-- ============================================================
-- RESULTADO DO PAGAMENTO
-- ============================================================

RegisterNetEvent('nova:fuel:purchaseResult', function(success, amount)
    if not success then return end
    if not currentVehicle or not DoesEntityExist(currentVehicle) then return end

    -- Encontrar a bomba mais próxima para referência
    local ped = PlayerPedId()
    local pCoords = GetEntityCoords(ped)
    local pump, pumpCoords = GetClosestPump(pCoords, 15.0)

    pendingRefuel = {
        amount = amount,
        vehicle = currentVehicle,
        pumpCoords = pumpCoords or pCoords,
    }

    exports['nova_notify']:Notify('info', 'Vai à bomba e pressiona [E] para pegar a mangueira.', 5000)
end)

-- ============================================================
-- HELPERS PARA PROPS
-- ============================================================

local function LoadAnimDict(dict)
    RequestAnimDict(dict)
    local t = 0
    while not HasAnimDictLoaded(dict) and t < 50 do Wait(100); t = t + 1 end
end

local function InitRope(pumpPos)
    -- Limpar rope anterior
    if ropeId then DeleteRope(ropeId); ropeId = nil end

    RopeLoadTextures()
    local t = 0
    while not RopeAreTexturesLoaded() and t < 200 do Wait(100); t = t + 1 end
    if not RopeAreTexturesLoaded() then return end

    ropePumpPos = vector3(pumpPos.x, pumpPos.y, pumpPos.z + 1.2)

    local rope = AddRope(
        ropePumpPos.x, ropePumpPos.y, ropePumpPos.z,
        0.0, 0.0, 0.0,
        12.0, 4, 12.0, 0.5, 0.5,
        false, false, false, 1.0, false, 0
    )

    if rope then
        ropeId = rope
        ActivatePhysics(ropeId)
    end
end

local function AttachNozzleToHand(pump)
    local ped = PlayerPedId()
    local pedCoords = GetEntityCoords(ped)

    -- Nozzle prop
    local nozzleHash = GetHashKey('prop_cs_fuel_nozle')
    RequestModel(nozzleHash)
    local t = 0
    while not HasModelLoaded(nozzleHash) and t < 50 do Wait(100); t = t + 1 end

    if HasModelLoaded(nozzleHash) then
        nozzleProp = CreateObject(nozzleHash, pedCoords.x, pedCoords.y, pedCoords.z, true, true, false)
        if nozzleProp and DoesEntityExist(nozzleProp) then
            local bone = GetPedBoneIndex(ped, 57005)
            AttachEntityToEntity(nozzleProp, ped, bone, 0.11, 0.03, 0.03, 15.0, -80.0, 0.0, true, true, false, true, 1, true)
        end
    end
    SetModelAsNoLongerNeeded(nozzleHash)

    -- Criar rope nativo
    if pump and DoesEntityExist(pump) then
        InitRope(GetEntityCoords(pump))
    end
end

local function AttachNozzleToCar(vehicle)
    if not nozzleProp or not DoesEntityExist(nozzleProp) then return end

    DetachEntity(nozzleProp, true, true)
    AttachEntityToEntity(nozzleProp, vehicle, 0,
        -0.8, -1.8, 0.5,
        -90.0, 0.0, 0.0,
        true, true, false, true, 1, true
    )
end

local function CleanupProps()
    if ropeId then DeleteRope(ropeId); ropeId = nil end
    RopeUnloadTextures()
    ropePumpPos = nil

    if nozzleProp and DoesEntityExist(nozzleProp) then
        DetachEntity(nozzleProp, true, true)
        DeleteObject(nozzleProp)
        nozzleProp = nil
    end
    holdingNozzle = false
end

-- ============================================================
-- THREAD: POSICIONAR TODOS OS VÉRTICES DA ROPE A CADA FRAME
-- Fixar todos = nunca desaparece + forma de catenária controlada
-- ============================================================

CreateThread(function()
    while true do
        if ropeId and ropePumpPos and nozzleProp and DoesEntityExist(nozzleProp) then
            local nozzlePos = GetEntityCoords(nozzleProp)
            local vertexCount = GetRopeVertexCount(ropeId)

            if vertexCount > 1 then
                local startPos = ropePumpPos
                local endPos = nozzlePos
                local dist = #(startPos - endPos)
                local sag = math.max(dist * 0.2, 0.3)

                for i = 0, vertexCount - 1 do
                    local t = i / (vertexCount - 1)

                    local px = startPos.x + (endPos.x - startPos.x) * t
                    local py = startPos.y + (endPos.y - startPos.y) * t

                    -- Catenária: Z cai no meio e volta a subir
                    local linearZ = startPos.z + (endPos.z - startPos.z) * t
                    local sagOffset = sag * (4.0 * t * (t - 1.0))
                    local pz = linearZ + sagOffset

                    PinRopeVertex(ropeId, i, px, py, pz)
                end
            end

            Wait(50)
        else
            Wait(200)
        end
    end
end)

-- ============================================================
-- THREAD: FLUXO INTERACTIVO DE ABASTECIMENTO
-- [E] bomba -> pega mangueira -> [E] carro -> abastece
-- ============================================================

CreateThread(function()
    while true do
        if pendingRefuel and not holdingNozzle then
            -- FASE 1: Jogador precisa ir à bomba e pressionar E para pegar a mangueira
            local ped = PlayerPedId()
            local pCoords = GetEntityCoords(ped)

            -- Não mostrar se está dentro de veículo
            if GetVehiclePedIsIn(ped, false) == 0 then
                local pump, pumpCoords, pumpDist = GetClosestPump(pCoords, FuelConfig.DrawDistance)

                if pump and pumpCoords and pumpDist < FuelConfig.InteractDistance + 1.0 then
                    DrawText3D(pumpCoords.x, pumpCoords.y, pumpCoords.z + 1.5, '~g~[E]~w~ Pegar mangueira')

                    if IsControlJustPressed(0, FuelConfig.InteractKey) then
                        -- Pegar a mangueira - passar a bomba para criar a corda
                        AttachNozzleToHand(pump)
                        holdingNozzle = true
                        exports['nova_notify']:Notify('info', 'Vai ao veículo e pressiona [E] para abastecer. [Backspace] para cancelar.', 5000)
                    end
                end
            end
            Wait(50)

        elseif pendingRefuel and holdingNozzle then
            -- FASE 2: Jogador tem a mangueira, precisa ir ao carro e pressionar E
            local ped = PlayerPedId()
            local pCoords = GetEntityCoords(ped)
            local vehicle = pendingRefuel.vehicle

            if not vehicle or not DoesEntityExist(vehicle) then
                -- Veículo desapareceu, cancelar
                CleanupProps()
                pendingRefuel = nil
                SetRefueling(false)
                exports['nova_notify']:Notify('error', 'Veículo não encontrado.', 3000)
                Wait(500)
            else
                local vehCoords = GetEntityCoords(vehicle)
                local dist = #(pCoords - vehCoords)

                if dist < 4.0 then
                    DrawText3D(vehCoords.x, vehCoords.y, vehCoords.z + 1.2, '~g~[E]~w~ Abastecer veículo')

                    if IsControlJustPressed(0, FuelConfig.InteractKey) then
                        -- FASE 3: Abastecer
                        SetRefueling(true)
                        local amount = pendingRefuel.amount

                        -- Duração
                        local duration = math.max(3000, math.floor(amount * 80))
                        duration = math.min(duration, 12000)

                        -- Virar para o veículo
                        local heading = GetHeadingFromVector_2d(vehCoords.x - pCoords.x, vehCoords.y - pCoords.y)
                        SetEntityHeading(ped, heading)
                        Wait(200)

                        -- Mover o nozzle da mão para o carro + recriar corda
                        AttachNozzleToCar(vehicle)

                        -- Animação de espera (braços cruzados / a olhar)
                        local animDict = 'amb@world_human_leaning@male@wall@back@idle_a'
                        LoadAnimDict(animDict)
                        TaskPlayAnim(ped, animDict, 'idle_a', 2.0, -2.0, duration, 1, 0, false, false, false)

                        -- Progress bar
                        pcall(function()
                            exports['nova_core']:Progressbar('A abastecer...', duration, { allowMovement = false })
                        end)

                        Wait(duration)

                        ClearPedTasks(ped)
                        RemoveAnimDict(animDict)

                        -- Aplicar combustível
                        local currentFuel = exports['nova_fuel']:GetFuel(vehicle)
                        local newFuel = math.min(100.0, currentFuel + amount)
                        exports['nova_fuel']:SetFuel(vehicle, newFuel)

                        exports['nova_notify']:Notify('success', 'Abastecido! (' .. math.floor(newFuel) .. '%)', 3000)

                        -- Limpar
                        CleanupProps()
                        pendingRefuel = nil
                        currentVehicle = nil
                        SetRefueling(false)
                    end
                else
                    -- Mostrar indicação de direcção
                    DrawText3D(vehCoords.x, vehCoords.y, vehCoords.z + 1.2, 'Aproxima-te do veículo')
                end
                Wait(50)
            end
        else
            Wait(500)
        end
    end
end)

-- Cancelar se pressionar Backspace enquanto segura mangueira
CreateThread(function()
    while true do
        if holdingNozzle and pendingRefuel then
            -- Backspace (177) para cancelar
            if IsControlJustPressed(0, 177) then
                CleanupProps()
                pendingRefuel = nil
                currentVehicle = nil
                SetRefueling(false)
                exports['nova_notify']:Notify('info', 'Abastecimento cancelado.', 3000)
            end
            Wait(50)
        else
            Wait(500)
        end
    end
end)

-- ============================================================
-- LOOP PRINCIPAL - INTERAÇÃO NOS POSTOS
-- ============================================================

CreateThread(function()
    while true do
        local sleep = 500
        local ped = PlayerPedId()
        local pCoords = GetEntityCoords(ped)
        local vehicle = GetVehiclePedIsIn(ped, false)
        local isInVeh = vehicle ~= 0

        -- Só mostrar interação da bomba se NÃO tiver abastecimento pendente/em curso
        if not isNuiOpen and not IsRefueling() and not pendingRefuel and not holdingNozzle then
            local pump, pumpCoords, pumpDist = GetClosestPump(pCoords, FuelConfig.DrawDistance)

            if pump and pumpCoords then
                sleep = 5

                if pumpDist < FuelConfig.InteractDistance then
                    if isInVeh then
                        DrawText3D(pumpCoords.x, pumpCoords.y, pumpCoords.z + 1.5, 'Sai do veículo para abastecer')
                    else
                        local nearVeh, nearDist = GetClosestVehicle(pCoords, 8.0)

                        if nearVeh and DoesEntityExist(nearVeh) then
                            local currentFuel = exports['nova_fuel']:GetFuel(nearVeh)
                            DrawText3D(pumpCoords.x, pumpCoords.y, pumpCoords.z + 1.5, '[E] Abastecer (' .. math.floor(currentFuel) .. '%)')

                            if IsControlJustPressed(0, FuelConfig.InteractKey) then
                                if currentFuel >= 99.0 then
                                    exports['nova_notify']:Notify('info', 'O tanque já está cheio.', 3000)
                                else
                                    currentVehicle = nearVeh
                                    local station = GetClosestStation(pCoords)
                                    if station then
                                        OpenFuelNUI(station, nearVeh)
                                    else
                                        OpenFuelNUI({ label = 'Posto de Gasolina', coords = pumpCoords, pump = pumpCoords }, nearVeh)
                                    end
                                end
                            end
                        else
                            DrawText3D(pumpCoords.x, pumpCoords.y, pumpCoords.z + 1.5, 'Estaciona um veículo perto da bomba')
                        end
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

-- ESC para fechar NUI
CreateThread(function()
    while true do
        if isNuiOpen then
            DisableControlAction(0, 200, true)
            if IsDisabledControlJustPressed(0, 200) then CloseFuelNUI() end
            Wait(0)
        else
            Wait(500)
        end
    end
end)

-- ============================================================
-- INIT
-- ============================================================

CreateThread(function()
    while not exports['nova_core']:IsPlayerLoaded() do Wait(500) end
    Wait(1000)
    -- Blips geridos centralmente em nova_core/config/blips.lua
    SpawnStationPeds()
end)

-- Cleanup
AddEventHandler('onResourceStop', function(res)
    if GetCurrentResourceName() ~= res then return end
    for _, ped in ipairs(SpawnedPeds) do if DoesEntityExist(ped) then DeleteEntity(ped) end end
    for _, blip in ipairs(StationBlips) do if DoesBlipExist(blip) then RemoveBlip(blip) end end
    if isNuiOpen then SetNuiFocus(false, false) end
    CleanupProps()
end)
