ESX = {}
ESX.Players = {}
ESX.Items = {}
ESX.Pickups = {}
ESX.PickupId = 0
ESX.Jobs = {}
ESX.Groups = {}
ESX.RegisteredCommands = {}
ESX.UsableItemsCallbacks = {}
ESX.vehicleTypesByModel = {}

exports('getSharedObject', function()
	return ESX
end)

AddEventHandler('esx:getSharedObject', function(cb)
	local Invoke = GetInvokingResource()

	print(('[^1ERREUR^7] La resource: ^5%s^7 utilise l\'évènement: ^5getSharedObject^7 côter server !'):format(Invoke))
end)

local function StartDBSync()
    CreateThread(function()
        local interval = 10 * 60 * 1000

        while true do
            Wait(interval)
            ESX.SavePlayers()
        end
    end)
end

MySQL.ready(function()
    local items = MySQL.query.await('SELECT * FROM items')

    for _, v in ipairs(items) do
        ESX.Items[v.name] = {
            label = v.label,
            weight = v.weight,
            rare = v.rare,
            canRemove = v.can_remove
        }
    end

    ESX.RefreshJobs()
    StartDBSync()
end)