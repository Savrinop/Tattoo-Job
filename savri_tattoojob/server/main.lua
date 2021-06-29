ESX = nil
local target = nil
local datatato = nil
local tattoosList = nil
currentTattoos = {}
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

ESX.RegisterServerCallback('esx_tattooshop:requestPlayerTattoos', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)

	if xPlayer then
		MySQL.Async.fetchAll('SELECT tattoos FROM users WHERE identifier = @identifier', {
			['@identifier'] = xPlayer.identifier
		}, function(result)
			if result[1].tattoos then
				cb(json.decode(result[1].tattoos))
			else
				cb()
			end
		end)
	else
		cb()
	end
end)


RegisterServerEvent('esx_tattooshop:purchaseTattoo')
AddEventHandler('esx_tattooshop:purchaseTattoo', function(playerCurrentTattoos, target, tattoo)
	local xPlayer = ESX.GetPlayerFromId(target)
		table.insert(playerCurrentTattoos, tattoo)
		MySQL.Async.execute('UPDATE users SET tattoos = @tattoos WHERE identifier = @identifier',
		{
			['@tattoos'] = json.encode(playerCurrentTattoos),
			['@identifier'] = xPlayer.identifier
		}, function(rowsChanged)
			TriggerClientEvent('esx_tattooshop:buySuccess', _source, tattoo)
			
		end)
end)

ESX.RegisterServerCallback('esx_tattooshop:getStockItems', function(source, cb)

  TriggerEvent('esx_addoninventory:getSharedInventory', 'tattooshop', function(inventory)
    cb(inventory.items)
  end)

end)


RegisterServerEvent('esx_tattooshop:getStockItem')
AddEventHandler('esx_tattooshop:getStockItem', function(itemName, count)

  local xPlayer = ESX.GetPlayerFromId(source)

  TriggerEvent('esx_addoninventory:getSharedInventory', 'tattooshop', function(inventory)

    local item = inventory.getItem(itemName)

    if item.count >= count then
      inventory.removeItem(itemName, count)
      xPlayer.addInventoryItem(itemName, count)
    else
      TriggerClientEvent('esx:showNotification', xPlayer.source, _U('quantity_invalid'))
    end

    TriggerClientEvent('esx:showNotification', xPlayer.source, _U('you_removed') .. count .. ' ' .. item.label)

  end)

end)

ESX.RegisterServerCallback('esx_tattooshop:getPlayerInventory', function(source, cb)

  local xPlayer    = ESX.GetPlayerFromId(source)
  local items      = xPlayer.inventory

  cb({
    items      = items
  })

end)

RegisterServerEvent('esx_tattooshop:putStockItems')
AddEventHandler('esx_tattooshop:putStockItems', function(itemName, count)

  local xPlayer = ESX.GetPlayerFromId(source)

  TriggerEvent('esx_addoninventory:getSharedInventory', 'tattooshop', function(inventory)

    local item = inventory.getItem(itemName)
    local playerItemCount = xPlayer.getInventoryItem(itemName).count

    if item.count >= 0 and count <= playerItemCount then
      xPlayer.removeInventoryItem(itemName, count)
      inventory.addItem(itemName, count)
    else
      TriggerClientEvent('esx:showNotification', xPlayer.source, _U('invalid_quantity'))
    end

    TriggerClientEvent('esx:showNotification', xPlayer.source, _U('you_added') .. count .. ' ' .. item.label)

  end)

end)
------------------------------------------------------------------------------------------------------------------------ Target

RegisterServerEvent('esx_tattooshop:resetSkin')
AddEventHandler('esx_tattooshop:resetSkin', function(targetId)
TriggerClientEvent("esx_tattooshop:resetSkin", targetId)
end)

RegisterServerEvent('esx_tattooshop:setPedSkin')
AddEventHandler('esx_tattooshop:setPedSkin', function(targetId)
TriggerClientEvent("esx_tattooshop:setPedSkin", targetId)
end)







RegisterServerEvent('esx_tattooshop:setSkin')
AddEventHandler('esx_tattooshop:setSkin', function(skin, target, currentTattoos)
_source = source
targetid = target
TriggerClientEvent("esx_tattooshop:setSkin", source, skin, target, currentTattoos) -- _source
end)










RegisterServerEvent('esx_tattooshop:getSkin')
AddEventHandler('esx_tattooshop:getSkin', function(player)
target = player
_source = source
TriggerClientEvent("esx_tattooshop:getSkin", source, target)
end)

RegisterServerEvent('esx_tattooshop:change')
AddEventHandler('esx_tattooshop:change', function(targetId, collection, name)
TriggerClientEvent("esx_tattooshop:change", targetId, collection, name)
end)




RegisterServerEvent('esx_tattooshop:delete')
AddEventHandler('esx_tattooshop:delete', function()
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)
	if xPlayer.getMoney() >= 50000 then
		xPlayer.removeMoney(50000)
		MySQL.Async.execute('UPDATE users SET tattoos = "{}" WHERE identifier = @identifier',
		{
			['@identifier'] = xPlayer.identifier
		}, function(rowsChanged)
			TriggerClientEvent('esx_tattooshop:reloadTattoos', _source)
			xPlayer.showNotification("~b~Usunięto wszystkie tatuaże")
		end)
	else
		xPlayer.showNotification("~r~Nie masz wystarczająco gotówki")
	end
end)