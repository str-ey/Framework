local _ExecuteCommand = ExecuteCommand
local _TriggerClientEvent = TriggerClientEvent
local _DropPlayer = DropPlayer
local _TriggerEvent = TriggerEvent

function CreatePlayer(playerId, identifier, group, accounts, inventory, weight, job, name, coords, firstname, lastname, datebirth, lieubirth, sex, height)
    local self = {}

    self.accounts = accounts
    self.coords = coords
    self.group = group
    self.identifier = identifier
    self.inventory = inventory
    self.job = job
    self.name = name
    self.playerId = playerId
    self.source = playerId
    self.variables = {}
    self.weight = weight
    self.maxWeight = Config.MaxWeight
	self.firstname = firstname
	self.lastname = lastname
	self.identity = firstname ..' '.. lastname
	self.datebirth = datebirth
	self.lieubirth = lieubirth
	self.sex = sex
	self.height = height

    _ExecuteCommand(('add_principal identifier.%s group.%s'):format(self.identifier, self.group))

    self.triggerEvent = function(eventName, ...)
        _TriggerClientEvent(eventName, self.source, ...)
    end

    self.setCoords = function(coords)
        self.updateCoords(coords)
        self.triggerEvent('esx:teleport', coords)
    end

    self.updateCoords = function(coords)
        self.coords = {
            x = ESX.Math.Round(coords.x, 1),
            y = ESX.Math.Round(coords.y, 1),
            z = ESX.Math.Round(coords.z, 1),
            heading = ESX.Math.Round(coords.heading or 0.0, 1)
        }
    end

    self.getCoords = function(vector)
        if vector then
            return vector3(self.coords.x, self.coords.y, self.coords.z)
        else
            return self.coords
        end
    end

    self.kick = function(reason)
        _DropPlayer(self.source, reason)
    end

    self.setMoney = function(money)
        money = ESX.Math.Round(money)
        self.setAccountMoney('money', money)
    end

    self.getMoney = function()
        return self.getAccount('money').money
    end

    self.addMoney = function(money)
        money = ESX.Math.Round(money)
        self.addAccountMoney('money', money)
    end

    self.removeMoney = function(money)
        money = ESX.Math.Round(money)
        self.removeAccountMoney('money', money)
    end

    self.getIdentifier = function()
        return self.identifier
    end

    self.getGroup = function()
		return self.group
	end

	self.setGroup = function(group)
		local lastGroup = group

        if ESX.Groups[group] then
		    self.group = group

		    for k, v in pairs(ESX.Groups) do
		    	_ExecuteCommand(('remove_principal identifier.%s group.%s'):format(self.identifier, k))
		    end

		    _ExecuteCommand(('add_principal identifier.%s group.%s'):format(self.identifier, group))
		    _TriggerEvent('esx:setGroup', self.source, self.group, lastGroup)
		    self.triggerEvent('esx:setGroup', self.group, lastGroup)
		else
			print(('[^3WARNING^7] Ignore l\'usage invalide de .setGroup() pour %s'):format(self.identifier))
        end
	end

    self.set = function(k, v)
        self.variables[k] = v
    end

    self.get = function(k)
        return self.variables[k]
    end

    self.getAccounts = function(minimal)
        if minimal then
            local minimalAccounts = {}

            for k, v in ipairs(self.accounts) do
                minimalAccounts[v.name] = v.money
            end

            return minimalAccounts
        else
            return self.accounts
        end
    end

    self.getAccount = function(account)
        for k, v in ipairs(self.accounts) do
            if v.name == account then
                return v
            end
        end
    end

    self.getInventory = function(minimal)
        if minimal then
            local minimalInventory = {}

            for k, v in ipairs(self.inventory) do
                if v.count > 0 then
                    minimalInventory[v.name] = v.count
                end
            end

            return minimalInventory
        else
            return self.inventory
        end
    end

    self.getJob = function()
        return self.job
    end

    self.getName = function()
        return self.name
    end

    self.setName = function(newName)
        self.name = newName
    end

    self.getFirstname = function()
        return self.firstname
    end

    self.getLastname = function()
        return self.lastname
    end

    self.getIdentity = function()
        return self.identity
    end

    self.getDateBirth = function()
        return self.datebirth
    end

    self.getLieuBirth = function()
        return self.lieubirth
    end

    self.getSex = function()
        return self.sex
    end

    self.getHeight = function()
        return self.height
    end

    self.setAccountMoney = function(accountName, money)
        if money >= 0 then
            local account = self.getAccount(accountName)

            if account then
                local prevMoney = account.money
                local newMoney = ESX.Math.Round(money)

                account.money = newMoney
                self.triggerEvent('esx:setAccountMoney', account)
            end
        end
    end

    self.addAccountMoney = function(accountName, money)
        if money > 0 then
            local account = self.getAccount(accountName)

            if account then
                local newMoney = account.money + ESX.Math.Round(money)

                account.money = newMoney
                self.triggerEvent('esx:setAccountMoney', account)
            end
        end
    end

    self.removeAccountMoney = function(accountName, money)
        if money > 0 then
            local account = self.getAccount(accountName)

            if account then
                local newMoney = account.money - ESX.Math.Round(money)

                account.money = newMoney
                self.triggerEvent('esx:setAccountMoney', account)
            end
        end
    end

    self.getInventoryItem = function(name)
        for k, v in ipairs(self.inventory) do
            if v.name == name then
                return v
            end
        end

        return
    end

    self.addInventoryItem = function(name, count)
        local item = self.getInventoryItem(name)

        if item then
            count = ESX.Math.Round(count)
            item.count = item.count + count
            self.weight = self.weight + (item.weight * count)
            _TriggerEvent('esx:onAddInventoryItem', self.source, item.name, item.count)
            self.triggerEvent('esx:addInventoryItem', item.name, item.count)
        end
    end

    self.removeInventoryItem = function(name, count)
        local item = self.getInventoryItem(name)

        if item then
            count = ESX.Math.Round(count)
            local newCount = item.count - count

            if newCount >= 0 then
                item.count = newCount
                self.weight = self.weight - (item.weight * count)
                _TriggerEvent('esx:onRemoveInventoryItem', self.source, item.name, item.count)
                self.triggerEvent('esx:removeInventoryItem', item.name, item.count)
            end
        end
    end

    self.setInventoryItem = function(name, count)
        local item = self.getInventoryItem(name)

        if item and count >= 0 then
            count = ESX.Math.Round(count)

            if count > item.count then
                self.addInventoryItem(item.name, count - item.count)
            else
                self.removeInventoryItem(item.name, item.count - count)
            end
        end
    end

    self.getWeight = function()
        return self.weight
    end

    self.getMaxWeight = function()
        return self.maxWeight
    end

    self.canCarryItem = function(name, count)
        local currentWeight, itemWeight = self.weight, ESX.Items[name].weight
        local newWeight = currentWeight + (itemWeight * count)

        return newWeight <= self.maxWeight
    end

    self.canSwapItem = function(firstItem, firstItemCount, testItem, testItemCount)
        local firstItemObject = self.getInventoryItem(firstItem)
        local testItemObject = self.getInventoryItem(testItem)

        if firstItemObject.count >= firstItemCount then
            local weightWithoutFirstItem = ESX.Math.Round(self.weight - (firstItemObject.weight * firstItemCount))
            local weightWithTestItem = ESX.Math.Round(weightWithoutFirstItem + (testItemObject.weight * testItemCount))

            return weightWithTestItem <= self.maxWeight
        end

        return false
    end

    self.setMaxWeight = function(newWeight)
        self.maxWeight = newWeight
        self.triggerEvent('esx:setMaxWeight', self.maxWeight)
    end

    self.setJob = function(job, grade)
        grade = tostring(grade)
        local lastJob = json.decode(json.encode(self.job))

        if ESX.DoesJobExist(job, grade) then
            local jobObject, gradeObject = ESX.Jobs[job], ESX.Jobs[job].grades[grade]

            self.job.id = jobObject.id
            self.job.name = jobObject.name
            self.job.label = jobObject.label
            self.job.grade = tonumber(grade)
            self.job.grade_name = gradeObject.name
            self.job.grade_label = gradeObject.label
            self.job.grade_salary = gradeObject.salary

            if gradeObject.skin_male then
                self.job.skin_male = json.decode(gradeObject.skin_male)
            else
                self.job.skin_male = {}
            end

            if gradeObject.skin_female then
                self.job.skin_female = json.decode(gradeObject.skin_female)
            else
                self.job.skin_female = {}
            end

            _TriggerEvent('esx:setJob', self.source, self.job, lastJob)
            self.triggerEvent('esx:setJob', self.job)
        else
            print(('[^3ATTENTION^7] Ignore l\'usage invalide de .setJob() pour %s'):format(self.identifier))
        end
    end

    self.sendChatMessage = function(msg, prefix, color)
		if prefix == nil then
            prefix = ''
        end

		if color == nil then
            color = {0, 0, 0}
        end
        
		_TriggerClientEvent('chatMessage', self.source, prefix, color, msg)
	end

    self.Notification = function(msg)
		self.triggerEvent('esx:Notification', msg)
	end

	self.showNotification = function(msg, hudColorIndex)
        self.triggerEvent('esx:showNotification', msg, hudColorIndex)
    end

	self.showAdvancedNotification = function(sender, subject, msg, textureDict, iconType, flash, saveToBrief, hudColorIndex)
		self.triggerEvent('esx:showAdvancedNotification', sender, subject, msg, textureDict, iconType, flash, saveToBrief, hudColorIndex)
	end

    self.showHelpNotification = function(msg, thisFrame, beep, duration)
        self.triggerEvent('esx:showHelpNotification', msg, thisFrame, beep, duration)
    end

    self.showMissionText = function(msg, time)
        self.triggerEvent('esx:showMissionText', msg, time)
    end

    return self
end