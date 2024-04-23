local Group = setmetatable({}, Group)

function Group.New(Name, Inherits)
	local _Group = {
		Name = tostring(Name),
		Inherits = tostring(Inherits)
	}

	return setmetatable(_Group, Group)
end

ESX.AddGroup = function(name, inherits)
	ExecuteCommand('add_principal group.' .. name .. ' group.' .. inherits)
	ESX.Groups[name] = Group.New(name, inherits)
end

ESX.AddGroup('user', '')
ESX.AddGroup('support', 'user')
ESX.AddGroup('modo', 'support')
ESX.AddGroup('staff', 'modo')
ESX.AddGroup('_dev', 'staff')