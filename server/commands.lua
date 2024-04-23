ESX.RegisterCommand({'setcoords', 'tp', 'tpc'}, 'modo', function(xPlayer, args, showError)
	xPlayer.setCoords({x = args.x, y = args.y, z = args.z})
end, false, {help = 'Téléportation sur coordonnées', validate = true, arguments = {
	{name = 'x', help = 'Coordonnées X', type = 'coordinate'},
	{name = 'y', help = 'Coordonnées Y', type = 'coordinate'},
	{name = 'z', help = 'Coordonnées Z', type = 'coordinate'},
}})

ESX.RegisterCommand({'setjob', 'addjob', 'changejob'}, 'modo', function(xPlayer, args, showError)
	if not ESX.DoesJobExist(args.job, args.grade) then
        return showError('Le job, le grade ou les 2 sont invalide !')
    end

    args.playerId.setJob(args.job, args.grade)
end, true, {help = 'Assigner un job', validate = true, arguments = {
	{name = 'playerId', help = 'PlayerId', type = 'player'},
	{name = 'job', help = 'Nom du job', type = 'string'},
	{name = 'grade', help = 'Nom du grade', type = 'number'},
}})

ESX.RegisterCommand({'setgroup', 'group', 'addgroup', 'changegroup'}, 'staff', function(xPlayer, args, showError)
    args.playerId.setGroup(args.group)
end, true, {help = 'Assigner un groupes', validate = true, arguments = {
	{name = 'playerId', help = 'PlayerId', type = 'player'},
	{name = 'group', help = 'Groupes', type = 'string'},
}})

ESX.RegisterCommand('slap', 'staff', function(xPlayer, args, showError)
	xPlayer.triggerEvent('esx:slapPlayer')
end, true, {help = 'Propulser un joueur', validate = true, arguments = {
	{name = 'playerId', help = 'PlayerId', type = 'player'},
}})

local upgrades = Config.SpawnVehMaxUpgrades and {
    modEngine = 3,
    modBrakes = 3,
    modTransmission = 3,
    modSuspension = 3,
    modArmor = true,
    windowTint = 1,
} or {}

ESX.RegisterCommand('car', 'modo', function(xPlayer, args, showError)
	if not xPlayer then
		return
	end

	local playerPed = GetPlayerPed(xPlayer.source)
    local playerCoords = GetEntityCoords(playerPed)
    local playerHeading = GetEntityHeading(playerPed)
    local playerVehicle = GetVehiclePedIsIn(playerPed)

	if not args.car or type(args.car) ~= 'string' then
		args.car = 'sultan'
	end

	if playerVehicle then
		DeleteEntity(playerVehicle)
	end

	ESX.OneSync.SpawnVehicle(args.car, playerCoords, playerHeading, upgrades, function(networkId)
		if networkId then
			local vehicle = NetworkGetEntityFromNetworkId(networkId)

			for _ = 1, 20 do
				Wait(0)
				SetPedIntoVehicle(playerPed, vehicle, -1)

				if GetVehiclePedIsIn(playerPed, false) == vehicle then
					break
				end
			end

			if GetVehiclePedIsIn(playerPed, false) ~= vehicle then
				showError('Vous n\'êtes pas dans un véhicule !')
			end
		end
	end)
end, false, {help = 'Faire spawn un véhicule', validate = false, arguments = {
	{name = 'car', validate = false, help = 'Model du véhicule', type = 'string'},
}})

ESX.RegisterCommand({'cardel', 'dv'}, 'modo', function(xPlayer, args, showError)
	xPlayer.triggerEvent('esx:deleteVehicle')
end, false, {help = 'Supprimer le véhicule'})

ESX.RegisterCommand({'fix', 'repair'}, 'modo', function(xPlayer, args, showError)
    local xTarget = args.playerId
    local ped = GetPlayerPed(xTarget.source)
    local pedVehicle = GetVehiclePedIsIn(ped, false)

    if not pedVehicle or GetPedInVehicleSeat(pedVehicle, -1) ~= ped then
        return showError('Vous n\'êtes pas dans un véhicule !')
    end

    xTarget.triggerEvent('esx:repairVehiclePed')
	TriggerClientEvent('chatMessage', xPlayer.source, 'SYSTEM ', {255, 0, 0}, 'Véhicule réparer')

    if xPlayer.source ~= xTarget.source then
        xTarget.showNotification('Votre véhicule à été réparer par un membre du staff')
    end
end, true, {help = 'Réparer le véhicule', validate = false, arguments = {
    {name = 'playerId', help = 'Vide ou PlayerId', type = 'player'},
}})

ESX.RegisterCommand({'giveaccountmoney', 'givemoney', 'giveaccount', 'addmoney', 'addaccount'}, 'staff', function(xPlayer, args, showError)
	if args.playerId.getAccount('money') then
		args.playerId.addAccountMoney('money', args.amount)
		xPlayer.sendChatMessage('Argent ajouté avec succès')
	else
		showError('Compte invalide !')
	end
end, true, {help = 'Ajout d\'argent', validate = true, arguments = {
	{name = 'playerId', help = 'PlayerId', type = 'player'},
	{name = 'amount', help = 'Montant à ajouter', type = 'number'},
}})

ESX.RegisterCommand({'removeaccountmoney', 'removemoney', 'removeaccount'}, 'staff', function(xPlayer, args, showError)
	if args.playerId.getAccount('money') then
		args.playerId.removeAccountMoney('money', args.amount)
		xPlayer.sendChatMessage('Argent retiré avec succès')
	else
		showError('Compte invalide !')
	end
end, true, {help = 'Retrait d\'argent', validate = true, arguments = {
	{name = 'playerId', help = 'PlayerId', type = 'player'},
	{name = 'amount', help = 'Montant à retirer', type = 'number'},
}})

ESX.RegisterCommand({'giveitem', 'give', 'additem'}, 'modo', function(xPlayer, args, showError)
	args.playerId.addInventoryItem(args.item, args.count)
	xPlayer.sendChatMessage('Item ajouté avec succès '..args.item)
end, true, {help = 'Give un item', validate = true, arguments = {
	{name = 'playerId', help = 'PlayerId', type = 'player'},
	{name = 'item', help = 'Nom de l\'item', type = 'item'},
	{name = 'count', help = 'Quantité à give', type = 'number'},
}})

ESX.RegisterCommand({'clearinventory', 'clearinv', 'clsinv'}, 'staff', function(xPlayer, args, showError)
	for k,v in ipairs(args.playerId.inventory) do
		if v.count > 0 then
			args.playerId.setInventoryItem(v.name, 0)
			xPlayer.sendChatMessage('Inventaire vider avec succès')
		end
	end
end, true, {help = 'Vider l\'inventaire', validate = true, arguments = {
	{name = 'playerId', help = 'PlayerId', type = 'player'}
}})

ESX.RegisterCommand({'clear', 'cls', 'clearall'}, 'user', function(xPlayer, args, showError)
	xPlayer.triggerEvent('chat:clear')
end, false, {help = 'Vider le chat'})

ESX.RegisterCommand({'_clearall', 'debug_clearall', 'clsall'}, 'staff', function(xPlayer, args, showError)
	TriggerClientEvent('chat:clear', -1)
	TriggerClientEvent('chatMessage', xPlayer.source, 'SYSTEM ', {255, 0, 0}, 'Chat videz pour tous le monde')
end, false, {help = 'Vider le chat pour tout le monde'})

ESX.RegisterCommand({'getcoords', 'coords'}, 'admin', function(xPlayer)
	local ped = GetPlayerPed(xPlayer.source)
	local coords = GetEntityCoords(ped, false)
	local heading = GetEntityHeading(ped)

	print(('Coords - Vector3: ^5%s^0'):format(vector3(coords.x, coords.y, coords.z)))
	print(('Coords - Vector4: ^5%s^0'):format(vector4(coords.x, coords.y, coords.z, heading)))
end, true)

ESX.RegisterCommand('refreshjobs', '_dev', function(xPlayer)
	ESX.RefreshJobs()
	xPlayer.sendChatMessage('Jobs actualiser !')
end, true, {help = 'Actualiser les jobs'})

ESX.RegisterCommand({'tpm', 'tpw'}, 'modo', function(xPlayer)
	xPlayer.triggerEvent('esx:tpw')
end, false, {help = 'Téléportation sur marqueur', validate = false})

ESX.RegisterCommand('stuck', 'user', function(xPlayer, args, showError)
	xPlayer.triggerEvent('esx:stuck')
end, true, {help = 'Débloquer son personnage', validate = true})

ESX.RegisterCommand('bring', 'support', function(xPlayer, args, showError)
	SetEntityCoords(GetPlayerPed(args.playerId.source), xPlayer.getCoords(true), 0, 0, 0, 0)
	TriggerClientEvent('chatMessage', args.playerId.source, 'SYSTEM ', {255, 0, 0}, 'Vous avez teleporté par ^2' .. xPlayer.getName())
	TriggerClientEvent('chatMessage', xPlayer.source, 'SYSTEM ', {255, 0, 0}, 'Joueur ^2' .. args.playerId.getName() .. '^0 a été teleporté')
end, true, {help = 'Téléporter un joueur à soi', validate = true, arguments = {
	{name = 'playerId', help = 'PlayerId', type = 'player'},
}})

ESX.RegisterCommand('goto', 'support', function(xPlayer, args, showError)
	SetEntityCoords(xPlayer.source, args.playerId.getCoords(true), 0, 0, 0, 0)
	TriggerClientEvent('chatMessage', xPlayer.source, 'SYSTEM ', {255, 0, 0}, 'Téléporté au joueur ^2' .. args.playerId.getName() .. '')
end, true, {help = 'Se téléporter à un joueur', validate = true, arguments = {
	{name = 'playerId', help = 'PlayerId', type = 'player'},
}})

ESX.RegisterCommand('freeze', 'support', function(xPlayer, args)
    args.playerId.triggerEvent('esx:freezePlayer', 'freeze')
end, true, {help = 'Geler un joueur', validate = true, arguments = {
    {name = 'playerId', help = 'PlayerId', type = 'player'},
}})

ESX.RegisterCommand('unfreeze', 'support', function(xPlayer, args)
    args.playerId.triggerEvent('esx:freezePlayer', 'unfreeze')
end, true, {help = 'Dégeler un joueur', validate = true, arguments = {
    {name = 'playerId', help = 'PlayerId', type = 'player'},
}})

ESX.RegisterCommand({'slay', 'kill'}, 'staff', function(xPlayer, args, showError)
	args.playerId.triggerEvent('esx:setHealth', 0)
	TriggerClientEvent('chatMessage', xPlayer.source, 'SYSTEM ', {255, 0, 0}, '^1^*Tu as tué ' .. args.playerId.getName())
end, true, {help = 'Tuer un joueur', validate = true, arguments = {
	{name = 'playerId', help = 'PlayerId', type = 'player'},
}})

ESX.RegisterCommand('heal', 'modo', function(xPlayer, args, showError)
	args.playerId.triggerEvent('esx:setHealth', 200)
	TriggerClientEvent('chatMessage', args.playerId.source, 'SYSTEM ', {255, 0, 0}, 'Vous avez été soigné par ^2' .. xPlayer.getName())
	TriggerClientEvent('chatMessage', xPlayer.source, 'SYSTEM ', {255, 0, 0}, 'Le joueur ^2' .. args.playerId.getName() .. '^0 a été soigné.')
end, true, {help = 'Heal un joueur', validate = true, arguments = {
	{name = 'playerId', help = 'Vide ou PlayerId', type = 'player'},
}})

ESX.RegisterCommand('revive', 'modo', function(xPlayer, args, showError)
	TriggerClientEvent('esx:revive', args.playerId.source)
	TriggerClientEvent('chatMessage', xPlayer.source, 'SYSTEM ', {255, 0, 0}, 'Revive du joueur...')
end, true, {help = 'Revive un joueur', validate = true, arguments = {
	{name = 'playerId', help = 'Vide ou PlayerId', type = 'player'},
}})

ESX.RegisterCommand('reviveall', 'staff', function(xPlayer, args, showError)
	TriggerClientEvent('esx:revive', -1)
	TriggerClientEvent('chatMessage', xPlayer.source, 'SYSTEM ', {255, 0, 0}, 'Revive de tous les joueurs...')
end, false, {help = 'Revive de tous les joueurs', validate = false})

ESX.RegisterCommand('destroyvehicle', 'modo', function(xPlayer, args, showError)
	local vehicle = GetVehiclePedIsIn(GetPlayerPed(args.playerId.source), false)
	
	args.playerId.triggerEvent('esx:setVehicleProps', NetworkGetNetworkIdFromEntity(vehicle), {
		bodyHealth = 0,
		engineHealth = 0,
		tankHealth = 0,
	})

	TriggerClientEvent('chatMessage', xPlayer.source, 'SYSTEM ', {255, 0, 0}, 'Le joueur ^2' .. args.playerId.getName() .. '^0 a maintenant un véhicule détruit')
end, true, {help = 'Détruire le moteur du joueur', validate = true, arguments = {
	{name = 'playerId', help = 'PlayerId', type = 'player'},
}})

ESX.RegisterCommand('save', 'user', function(xPlayer, args, showError)
	ESX.SavePlayer(args.playerId)
end, true, {help = 'Sauvegarder votre personnage', validate = true, arguments = {
	{name = 'playerId', help = 'PlayerId', type = 'player'}
}})