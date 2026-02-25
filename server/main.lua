--[[
    NOVA Framework - Fuel Server
    Pagamento, jerry can logic, exports
]]

-- ============================================================
-- HELPERS
-- ============================================================

local function GetPlayer(src)
    return exports['nova_core']:GetPlayer(src)
end

local function Notify(src, nType, msg)
    TriggerClientEvent('nova:client:notify', src, { type = nType, message = msg, duration = 3000 })
end

local function GetMoney(player, moneyType)
    if player and player.money then return player.money[moneyType] or 0 end
    return 0
end

local function SyncMoney(player)
    if player and player.source then
        TriggerClientEvent('nova:client:updatePlayerData', player.source, {
            type = 'money',
            data = player.money,
        })
    end
end

-- ============================================================
-- COMPRAR COMBUSTÍVEL (Posto de gasolina)
-- ============================================================

RegisterNetEvent('nova:fuel:purchase', function(price, amount)
    local src = source
    local player = GetPlayer(src)
    if not player then return end

    price = tonumber(price) or 0
    amount = tonumber(amount) or 0

    if price <= 0 or amount <= 0 then
        Notify(src, 'error', 'Dados inválidos.')
        TriggerClientEvent('nova:fuel:purchaseResult', src, false, 0)
        return
    end

    -- Verificar limite de preço
    local maxPrice = math.ceil(FuelConfig.TankCapacity * FuelConfig.PricePerLiter)
    if price > maxPrice then price = maxPrice end

    -- Verificar dinheiro (banco)
    local bankMoney = GetMoney(player, 'bank')
    if bankMoney < price then
        Notify(src, 'error', 'Dinheiro insuficiente. ($' .. price .. ')')
        TriggerClientEvent('nova:fuel:purchaseResult', src, false, 0)
        return
    end

    -- Deduzir dinheiro (via export do core para persistir)
    local ok, removed = pcall(function()
        return exports['nova_core']:RemovePlayerMoney(src, 'bank', price)
    end)
    if not ok or removed == false then
        Notify(src, 'error', 'Erro ao processar pagamento.')
        TriggerClientEvent('nova:fuel:purchaseResult', src, false, 0)
        return
    end

    Notify(src, 'success', 'Pago $' .. price .. ' de combustível.')
    TriggerClientEvent('nova:fuel:purchaseResult', src, true, amount)
end)

-- ============================================================
-- JERRY CAN
-- ============================================================

-- Usar jerrycan do inventário
RegisterNetEvent('nova:inventory:useItem', function(slot, itemName)
    -- Este evento já é tratado pelo nova_inventory
    -- Mas se o item for jerrycan, redireccionamos para o client
end)

-- Item usado via nova_core (registar useable)
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    -- Registar uso do item jerrycan
    -- O nova_inventory vai chamar o evento de uso, e nós interceptamos
end)

-- Confirmar uso de jerrycan (remover item)
RegisterNetEvent('nova:fuel:confirmJerrycan', function()
    local src = source
    local player = GetPlayer(src)
    if not player then return end

    -- Remover item jerrycan
    local ok, result = pcall(function()
        return exports['nova_inventory']:RemoveItem(src, FuelConfig.JerryCan.itemName, 1)
    end)

    if not ok or not result then
        Notify(src, 'error', 'Erro ao remover jerrycan.')
    end
end)

-- ============================================================
-- USAR ITEM (interceptar do inventário)
-- ============================================================

-- Ouvir quando o jogador usa qualquer item
AddEventHandler('nova:inventory:server:useItem', function(src, item)
    if item and item.name == FuelConfig.JerryCan.itemName then
        TriggerClientEvent('nova:fuel:useJerrycan', src)
    end
end)

-- ============================================================
-- PRINT INIT
-- ============================================================

CreateThread(function()
    Wait(1000)
    print('[NOVA] [Fuel] ^2Sistema de combustível carregado com ' .. #FuelConfig.Stations .. ' postos^0')
end)
