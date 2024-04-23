ESX = {}
ESX.PlayerData = {}
ESX.PlayerLoaded = false

ESX.IsPlayerLoaded = function()
    return ESX.PlayerLoaded
end

ESX.GetPlayerData = function()
    return ESX.PlayerData
end

ESX.SetPlayerData = function(key, val)
    local current = ESX.PlayerData[key]
    ESX.PlayerData[key] = val

    if key ~= 'inventory' then
        if type(val) == 'table' or val ~= current then
            TriggerEvent('esx:setPlayerData', key, val, current)
        end
    end
end

ESX.GetAccount = function(account)
    for i = 1, #ESX.PlayerData.accounts, 1 do
        if ESX.PlayerData.accounts[i].name == account then
            return ESX.PlayerData.accounts[i]
        end
    end

    return nil
end

ESX.Notification = function(msg)
    if Notification then
        RemoveNotification(Notification)
    end

    SetNotificationTextEntry('STRING')
    AddTextComponentSubstringPlayerName(msg)
    Notification = DrawNotification(0, 1)
end

ESX.ShowNotification = function(msg)
	AddTextEntry('esxNotification', msg)
    BeginTextCommandThefeedPost('esxNotification')

	if hudColorIndex then
        ThefeedNextPostBackgroundColor(hudColorIndex)
    end

	EndTextCommandThefeedPostTicker(false, true)
end

ESX.ShowAdvancedNotification = function(sender, subject, msg, textureDict, iconType, flash, saveToBrief, hudColorIndex)
    if saveToBrief == nil then
        saveToBrief = true
    end

    AddTextEntry('esxAdvancedNotification', msg)
    BeginTextCommandThefeedPost('esxAdvancedNotification')

    if hudColorIndex then
        ThefeedNextPostBackgroundColor(hudColorIndex)
    end

    EndTextCommandThefeedPostMessagetext(textureDict, textureDict, false, iconType, sender, subject)
    EndTextCommandThefeedPostTicker(flash or false, saveToBrief)
end

ESX.ShowHelpNotification = function(msg, thisFrame, beep, duration)
    AddTextEntry('esxHelpNotification', msg)

    if thisFrame then
        DisplayHelpTextThisFrame('esxHelpNotification', false)
    else
        if beep == nil then
            beep = true
        end

        BeginTextCommandDisplayHelp('esxHelpNotification')
        EndTextCommandDisplayHelp(0, false, beep, duration or -1)
    end
end

ESX.ShowMissionText = function(msg, time)
    ClearPrints()
    BeginTextCommandPrint('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandPrint(time, true)
end

RegisterNetEvent('esx:Notification')
AddEventHandler('esx:Notification', function(msg)
	ESX.Notification(msg)
end)

RegisterNetEvent('esx:showNotification')
AddEventHandler('esx:showNotification', function(msg, hudColorIndex)
    ESX.ShowNotification(msg, hudColorIndex)
end)

RegisterNetEvent('esx:showAdvancedNotification')
AddEventHandler('esx:showAdvancedNotification', function(sender, subject, msg, textureDict, iconType, flash, saveToBrief, hudColorIndex)
    ESX.ShowAdvancedNotification(sender, subject, msg, textureDict, iconType, flash, saveToBrief, hudColorIndex)
end)

RegisterNetEvent('esx:showHelpNotification')
AddEventHandler('esx:showHelpNotification', function(msg, thisFrame, beep, duration)
    ESX.ShowHelpNotification(msg, thisFrame, beep, duration)
end)

RegisterNetEvent('esx:showMissionText')
AddEventHandler('esx:showMissionText', function(msg, time)
	ESX.ShowMissionText(msg, time)
end)

local mismatchedTypes = {
    ['airtug'] = 'automobile',
    ['avisa'] = 'submarine',
    ['blimp'] = 'heli',
    ['blimp2'] = 'heli',
    ['blimp3'] = 'heli',
    ['caddy'] = 'automobile',
    ['caddy2'] = 'automobile',
    ['caddy3'] = 'automobile',
    ['chimera'] = 'automobile',
    ['docktug'] = 'automobile',
    ['forklift'] = 'automobile',
    ['kosatka'] = 'submarine',
    ['mower'] = 'automobile',
    ['policeb'] = 'bike',
    ['ripley'] = 'automobile',
    ['rrocket'] = 'automobile',
    ['sadler'] = 'automobile',
    ['sadler2'] = 'automobile',
    ['scrap'] = 'automobile',
    ['slamtruck'] = 'automobile',
    ['Stryder'] = 'automobile',
    ['submersible'] = 'submarine',
    ['submersible2'] = 'submarine',
    ['thruster'] = 'heli',
    ['towtruck'] = 'automobile',
    ['towtruck2'] = 'automobile',
    ['tractor'] = 'automobile',
    ['tractor2'] = 'automobile',
    ['tractor3'] = 'automobile',
    ['trailersmall2'] = 'trailer',
    ['utillitruck'] = 'automobile',
    ['utillitruck2'] = 'automobile',
    ['utillitruck3'] = 'automobile',
}

ESX.GetVehicleType = function(model)
    model = type(model) == 'string' and GetHashKey(model) or model

    if not IsModelInCdimage(model) then
        return
    end

    if mismatchedTypes[model] then
        return mismatchedTypes[model]
    end

    local vehicleType = GetVehicleClassFromName(model)
    local types = {
        [8] = 'bike',
        [11] = 'trailer',
        [13] = 'bike',
        [14] = 'boat',
        [15] = 'heli',
        [16] = 'plane',
        [21] = 'train',
    }

    return types[vehicleType] or 'automobile'
end