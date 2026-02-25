--[[
    NOVA Framework - Jerry Can Client
    Usar item jerrycan para abastecer veículo próximo
]]

-- ============================================================
-- USAR JERRYCAN (evento do inventário)
-- ============================================================

RegisterNetEvent('nova:fuel:useJerrycan', function()
    local ped = PlayerPedId()
    local pCoords = GetEntityCoords(ped)

    -- Verificar se está a pé
    if GetVehiclePedIsIn(ped, false) ~= 0 then
        exports['nova_notify']:Notify('error', 'Sai do veículo primeiro.', 3000)
        return
    end

    -- Encontrar veículo próximo
    local closestVeh = nil
    local closestDist = FuelConfig.JerryCan.useDistance

    local vehs = GetGamePool('CVehicle')
    for _, veh in ipairs(vehs) do
        local dist = #(pCoords - GetEntityCoords(veh))
        if dist < closestDist then
            closestDist = dist
            closestVeh = veh
        end
    end

    if not closestVeh then
        exports['nova_notify']:Notify('error', 'Nenhum veículo próximo.', 3000)
        return
    end

    -- Verificar se precisa de combustível
    local currentFuel = exports['nova_fuel']:GetFuel(closestVeh)
    if currentFuel >= 99.0 then
        exports['nova_notify']:Notify('info', 'O tanque já está cheio.', 3000)
        return
    end

    -- Iniciar animação
    SetRefueling(true)

    local animDict = 'timetable@gardener@filling_can'
    local animName = 'gar_ig_5_filling_can'
    RequestAnimDict(animDict)
    local t = 0
    while not HasAnimDictLoaded(animDict) and t < 50 do Wait(100); t = t + 1 end

    TaskPlayAnim(ped, animDict, animName, 8.0, -8.0, FuelConfig.JerryCan.useDuration, 1, 0, false, false, false)

    -- Progress bar
    pcall(function()
        exports['nova_core']:Progressbar('A abastecer com jerrycan...', FuelConfig.JerryCan.useDuration, { allowMovement = false })
    end)

    Wait(FuelConfig.JerryCan.useDuration)

    -- Parar animação
    ClearPedTasks(ped)

    -- Confirmar uso no server (remover item)
    TriggerServerEvent('nova:fuel:confirmJerrycan')

    -- Aplicar combustível
    local fuelToAdd = (FuelConfig.JerryCan.fuelAmount / FuelConfig.TankCapacity) * 100.0
    local newFuel = math.min(100.0, currentFuel + fuelToAdd)
    exports['nova_fuel']:SetFuel(closestVeh, newFuel)

    exports['nova_notify']:Notify('success', 'Veículo abastecido com jerrycan. (' .. math.floor(newFuel) .. '%)', 3000)

    SetRefueling(false)
end)
