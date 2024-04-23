ESX.Streaming = {}

ESX.Streaming.RequestModel = function(modelHash, cb)
	modelHash = (type(modelHash) == 'number' and modelHash or GetHashKey(modelHash))

	if not HasModelLoaded(modelHash) and IsModelInCdimage(modelHash) then
		RequestModel(modelHash)
		while not HasModelLoaded(modelHash) do
			Wait(0)
		end
	end

	if cb ~= nil then
		cb()
	end
end

ESX.Streaming.RequestStreamedTextureDict = function(textureDict, cb)
	if not HasStreamedTextureDictLoaded(textureDict) then
		RequestStreamedTextureDict(textureDict)
		while not HasStreamedTextureDictLoaded(textureDict) do
			Wait(1)
		end
	end

	if cb ~= nil then
		cb()
	end
end

ESX.Streaming.RequestNamedPtfxAsset = function(assetName, cb)
	if not HasNamedPtfxAssetLoaded(assetName) then
		RequestNamedPtfxAsset(assetName)
		while not HasNamedPtfxAssetLoaded(assetName) do
			Wait(0)
		end
	end

	if cb ~= nil then
		cb()
	end
end

ESX.Streaming.RequestAnimSet = function(animSet, cb)
	if not HasAnimSetLoaded(animSet) then
		RequestAnimSet(animSet)
		while not HasAnimSetLoaded(animSet) do
			Wait(0)
		end
	end

	if cb ~= nil then
		cb()
	end
end

ESX.Streaming.RequestAnimDict = function(animDict, cb)
	if not HasAnimDictLoaded(animDict) then
		RequestAnimDict(animDict)
		while not HasAnimDictLoaded(animDict) do
			Wait(0)
		end
	end

	if cb ~= nil then
		cb()
	end
end

ESX.Streaming.RequestWeaponAsset = function(weaponHash, cb)
	if not HasWeaponAssetLoaded(weaponHash) then
		RequestWeaponAsset(weaponHash)
		while not HasWeaponAssetLoaded(weaponHash) do
			Wait(0)
		end
	end

	if cb ~= nil then
		cb()
	end
end