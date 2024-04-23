CreateThread(function()
    SetMapName('Los Santos')
    SetGameType('Baycity')
end)

RegisterNetEvent('esx:onPlayerJoined')
AddEventHandler('esx:onPlayerJoined', function()
    if not ESX.Players[source] then
        onPlayerJoined(source)
    end
end)

function onPlayerJoined(playerId)
    local identifier
    local license

    for k, v in ipairs(GetPlayerIdentifiers(playerId)) do
        if string.match(v, Config.PrimaryIdentifier) then
            identifier = v
        end

        if string.match(v, 'license:') then
            license = v
        end
    end

    if identifier then
        MySQL.Async.fetchScalar('SELECT 1 FROM players WHERE identifier = @identifier', {
            ['@identifier'] = identifier
        }, function(result)
            if result then
                loadPlayer(identifier, playerId)
            else
                local accounts = {}

                for account, money in pairs(Config.StartingAccountMoney) do
                    accounts[account] = money
                end

                MySQL.Async.execute('INSERT INTO players (accounts, identifier, license) VALUES (@accounts, @identifier, @license)', {
                    ['@accounts'] = json.encode(accounts),
                    ['@identifier'] = identifier,
                    ['@license'] = license
                }, function(rowsChanged)
                    loadPlayer(identifier, playerId)
                end)
            end
        end)
    else
        DropPlayer(playerId, 'ERROR CODE 11055 (Identifiant manquant !)')
    end
end

function loadPlayer(identifier, playerId)
    local userData = {
        accounts = {},
        inventory = {},
        job = {},
        group = {},
        playerName = GetPlayerName(playerId),
        weight = 0
    }

    MySQL.Async.fetchAll('SELECT * FROM players WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    }, function(result)
        local job, grade, jobObject, gradeObject = result[1].job, tostring(result[1].job_grade)
        local foundAccounts, foundItems = {}, {}
        local firstname = result[1].firstname
        local lastname = result[1].lastname
        local datebirth = result[1].datebirth
        local lieubirth = result[1].lieubirth
        local sex = result[1].sex
        local height = result[1].height

        if result[1].accounts and result[1].accounts ~= '' then
            local accounts = json.decode(result[1].accounts)

            for account, money in pairs(accounts) do
                foundAccounts[account] = money
            end
        end

        for account, label in pairs(Config.Accounts) do
            table.insert(userData.accounts, {
                name = account,
                money = foundAccounts[account] or Config.StartingAccountMoney[account] or 0,
                label = label
            })
        end

        if ESX.DoesJobExist(job, grade) then
            jobObject, gradeObject = ESX.Jobs[job], ESX.Jobs[job].grades[grade]
        else
            print(('[^3ATTENTION^7] Job invalide ignoré %s [job: %s, grade: %s]'):format(identifier, job, grade))
            job, grade = 'unemployed', '0'
            jobObject, gradeObject = ESX.Jobs[job], ESX.Jobs[job].grades[grade]
        end

        userData.job.id = jobObject.id
        userData.job.name = jobObject.name
        userData.job.label = jobObject.label
        userData.job.grade = tonumber(grade)
        userData.job.grade_name = gradeObject.name
        userData.job.grade_label = gradeObject.label
        userData.job.grade_salary = gradeObject.salary
        userData.job.skin_male = {}
        userData.job.skin_female = {}

        if gradeObject.skin_male then
            userData.job.skin_male = json.decode(gradeObject.skin_male)
        end

        if gradeObject.skin_female then
            userData.job.skin_female = json.decode(gradeObject.skin_female)
        end

        if result[1].inventory and result[1].inventory ~= '' then
            local inventory = json.decode(result[1].inventory)

            for name, count in pairs(inventory) do
                local item = ESX.Items[name]

                if item then
                    foundItems[name] = count
                else
                    print(('[^3ATTENTION^7] Item invalide ignoré %s for %s'):format(name, identifier))
                end
            end
        end

        for name, item in pairs(ESX.Items) do
            local count = foundItems[name] or 0

            if count > 0 then
                userData.weight = userData.weight + (item.weight * count)
            end

            table.insert(userData.inventory, {
                name = name,
                count = count,
                label = item.label,
                weight = item.weight,
                usable = ESX.UsableItemsCallbacks[name] ~= nil,
                rare = item.rare,
                canRemove = item.canRemove
            })
        end

        table.sort(userData.inventory, function(a, b)
            return a.label < b.label
        end)

        if result[1].group then
            userData.group = result[1].group
        else
            userData.group = 'user'
        end

        if result[1].position and result[1].position ~= '' then
            userData.coords = json.decode(result[1].position)
        else
            userData.coords = Config.FirstSpawn
        end

        local xPlayer = CreatePlayer(playerId, identifier, userData.group, userData.accounts, userData.inventory, userData.weight, userData.job, userData.playerName, userData.coords, firstname, lastname, datebirth, lieubirth, sex, height)

        ESX.Players[playerId] = xPlayer
        TriggerEvent('esx:playerLoaded', playerId, xPlayer)

        xPlayer.triggerEvent('esx:playerLoaded', {
            accounts = xPlayer.getAccounts(),
            coords = xPlayer.getCoords(),
            identifier = xPlayer.getIdentifier(),
            inventory = xPlayer.getInventory(),
            job = xPlayer.getJob(),
            group = xPlayer.getGroup(),
            maxWeight = xPlayer.getMaxWeight(),
            money = xPlayer.getMoney()
        })

        xPlayer.triggerEvent('esx:createMissingPickups', ESX.Pickups)
        xPlayer.triggerEvent('esx:registerSuggestions', ESX.RegisteredCommands)

        print(('[^2SYSTEM^7] Joueur : (^4%s^7) connecté au serveur'):format(xPlayer.getName()))
    end)
end

AddEventHandler('playerDropped', function(reason)
    local playerId = source
    local xPlayer = ESX.GetPlayerFromId(playerId)
	local playername = GetPlayerName(playerId)

    if xPlayer then
        TriggerEvent('esx:playerDropped', playerId, reason)

        ESX.SavePlayer(xPlayer, function()
            ESX.Players[playerId] = nil
        end)

		print('[^2SYSTEM^7] Joueur : (^4' ..playername.. '^7) déconnecté !')
    end
end)

AddEventHandler('esx:playerLogout', function(playerId, cb)
    local xPlayer = ESX.GetPlayerFromId(playerId)

    if xPlayer then
        TriggerEvent('esx:playerDropped', playerId)

        ESX.SavePlayer(xPlayer, function()
            ESX.Players[playerId] = nil

            if cb then
                cb()
            end
        end)
    end

    TriggerClientEvent('esx:onPlayerLogout', playerId)
end)

RegisterNetEvent('esx:updateCoords')
AddEventHandler('esx:updateCoords', function(coords)
    local xPlayer = ESX.GetPlayerFromId(source)

    if xPlayer then
        xPlayer.updateCoords(coords)
    end
end)

RegisterNetEvent('esx:giveInventoryItem')
AddEventHandler('esx:giveInventoryItem', function(target, type, itemName, itemCount)
	local playerId = source
	local sourceXPlayer = ESX.GetPlayerFromId(playerId)
	local targetXPlayer = ESX.GetPlayerFromId(target)

	if type == 'item_standard' then
		local sourceItem = sourceXPlayer.getInventoryItem(itemName)

		if itemCount > 0 and sourceItem.count >= itemCount then
			if targetXPlayer.canCarryItem(itemName, itemCount) then
				sourceXPlayer.removeInventoryItem(itemName, itemCount)
				targetXPlayer.addInventoryItem(itemName, itemCount)
				sourceXPlayer.showNotification(('Vous avez donné ~g~%s~s~ ~g~%s~s~ à ~g~quelqu\'un'):format(itemCount, sourceItem.label, targetXPlayer.name))
				targetXPlayer.showNotification(('~g~Quelqu\'un ~s~vous a donné ~g~%s~s~ ~g~%s~s~'):format(itemCount, sourceItem.label, sourceXPlayer.name))
			else
				sourceXPlayer.showNotification(('~r~la personne a les poches pleines'):format(targetXPlayer.name))
			end
		else
			sourceXPlayer.showNotification('~r~Quantité invalide')
		end
	elseif type == 'item_account' then
		if itemCount > 0 and sourceXPlayer.getAccount(itemName).money >= itemCount then
			sourceXPlayer.removeAccountMoney(itemName, itemCount)
			targetXPlayer.addAccountMoney(itemName, itemCount)
			sourceXPlayer.showNotification(('Vous avez donné ~g~$%s~s~ (%s) à ~g~quelqu\'un'):format(ESX.Math.GroupDigits(itemCount), Config.Accounts[itemName], targetXPlayer.name))
			targetXPlayer.showNotification(('~g~Quelqu\'un ~s~vous a donné ~g~$%s~s~'):format(ESX.Math.GroupDigits(itemCount), Config.Accounts[itemName], sourceXPlayer.name))
		else
			sourceXPlayer.showNotification('~r~Montant invalide')
		end
	end
end)

RegisterNetEvent('esx:removeInventoryItem')
AddEventHandler('esx:removeInventoryItem', function(type, itemName, itemCount)
	local playerId = source
	local xPlayer = ESX.GetPlayerFromId(source)

	if type == 'item_standard' then
		if itemCount == nil or itemCount < 1 then
			xPlayer.showNotification('~r~Quantité invalide')
		else
			local xItem = xPlayer.getInventoryItem(itemName)

			if (itemCount > xItem.count or xItem.count < 1) then
				xPlayer.showNotification('~r~Quantité invalide')
			else
				xPlayer.removeInventoryItem(itemName, itemCount)
				local pickupLabel = ('~y~%s~s~ [~b~%s~s~]'):format(xItem.label, itemCount)

				ESX.CreatePickup('item_standard', itemName, itemCount, pickupLabel, playerId)
				xPlayer.showNotification(('Vous avez jeté ~g~x%s~s~ ~g~%s~s~'):format(itemCount, xItem.label))
			end
		end
	elseif type == 'item_account' then
		if itemCount == nil or itemCount < 1 then
			xPlayer.showNotification('~r~Montant invalide')
		else
			local account = xPlayer.getAccount(itemName)

			if (itemCount > account.money or account.money < 1) then
				xPlayer.showNotification('~r~Montant invalide')
			else
				xPlayer.removeAccountMoney(itemName, itemCount)
				-- local pickupLabel = ('~y~%s~s~ [~g~%s~s~]'):format(account.label, _U('locale_currency', ESX.Math.GroupDigits(itemCount)))
                local pickupLabel = ('~y~%s~s~ [~g~%s~s~]'):format(account.label, '$'..ESX.Math.GroupDigits(itemCount))
                -- local pickupLabel = '~g~' .. ESX.Math.GroupDigits(itemCount) .. '$~s~'

				ESX.CreatePickup('item_account', itemName, itemCount, pickupLabel, playerId)
                xPlayer.showNotification(('Vous avez jeté ~g~x%s~s~ ~g~%s~s~'):format(ESX.Math.GroupDigits(itemCount), string.lower(account.label)))
			end
		end
	end
end)

RegisterNetEvent('esx:useItem')
AddEventHandler('esx:useItem', function(itemName)
    local xPlayer = ESX.GetPlayerFromId(source)
    local count = xPlayer.getInventoryItem(itemName).count

    if count > 0 then
        ESX.UseItem(source, itemName)
    else
        xPlayer.showNotification('~r~Actions impossible !')
    end
end)

RegisterNetEvent('esx:onPickup')
AddEventHandler('esx:onPickup', function(pickupId)
	local pickup, xPlayer, success = ESX.Pickups[pickupId], ESX.GetPlayerFromId(source)

	if pickup then
		if pickup.type == 'item_standard' then
			if xPlayer.canCarryItem(pickup.name, pickup.count) then
				xPlayer.addInventoryItem(pickup.name, pickup.count)
				success = true
			else
				xPlayer.showNotification('~r~Vous avez les poches pleine')
			end
		elseif pickup.type == 'item_account' then
			success = true
			xPlayer.addAccountMoney(pickup.name, pickup.count)
		end

		if success then
			ESX.Pickups[pickupId] = nil
			TriggerClientEvent('esx:removePickup', -1, pickupId)
		end
	end
end)

ESX.RegisterServerCallback('esx:getPlayerData', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)

    cb({
        identifier = xPlayer.identifier,
        accounts = xPlayer.getAccounts(),
        inventory = xPlayer.getInventory(),
        job = xPlayer.getJob(),
        money = xPlayer.getMoney()
    })
end)

ESX.RegisterServerCallback('esx:getOtherPlayerData', function(source, cb, target)
    local xPlayer = ESX.GetPlayerFromId(target)

    cb({
        identifier = xPlayer.identifier,
        accounts = xPlayer.getAccounts(),
        inventory = xPlayer.getInventory(),
        job = xPlayer.getJob(),
        money = xPlayer.getMoney()
    })
end)

ESX.RegisterServerCallback('esx:getPlayerNames', function(source, cb, players)
    players[source] = nil

    for playerId, v in pairs(players) do
        local xPlayer = ESX.GetPlayerFromId(playerId)

        if xPlayer then
            players[playerId] = xPlayer.getName()
        else
            players[playerId] = nil
        end
    end

    cb(players)
end)

ESX.StartPayCheck()