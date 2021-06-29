local currentTattoos, CurrentActionData = {}, {}
local HasAlreadyEnteredMarker, CurrentAction, CurrentActionMsg
ESX = nil

local PlayerData = {}




RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
  PlayerData = xPlayer
end)
RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
  PlayerData.job = job
end)


Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end
end)

AddEventHandler('skinchanger:modelLoaded', function()
	ESX.TriggerServerCallback('esx_tattooshop:requestPlayerTattoos', function(tattooList)
		if tattooList then
			for k,v in pairs(tattooList) do
				ApplyPedOverlay(PlayerPedId(), GetHashKey(v.collection), GetHashKey(Config.TattooList[v.collection][v.texture].nameHash))
			end

			currentTattoos = tattooList
		end
	end)
end)

RegisterNetEvent('esx_tattooshop:reloadTattoos')
AddEventHandler('esx_tattooshop:reloadTattoos', function()
	currentTattoos = {}
	cleanPlayer()
	setPedSkin()
end)

function OpenShopMenu(target, skin, playerCurrentTattoos)
	local elements = {}

	for k,v in pairs(Config.TattooCategories) do
		table.insert(elements, {label= v.name, value = v.value})
	end


	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'tattoo_shop', {
		css = 'tattoo',
		title = _U('tattoos'),
		align = 'bottom-right',
		elements = elements
	}, function(data, menu)
		local currentLabel, currentValue = data.current.label, data.current.value

		if data.current.value then
			elements = {{label = _U('go_back_to_menu'), value = nil}}

			for k,v in pairs(Config.TattooList[data.current.value]) do
				table.insert(elements, {
					label = _U('tattoo_item', k, _U('money_amount', ESX.Math.GroupDigits(v.price))),
					value = k,
					price = v.price
				})
			end

			ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'tattoo_shop_categories', {
				css = 'tattoo',
				title = _U('tattoos') .. ' | '..currentLabel,
				align = 'bottom-right',
				elements = elements
			}, function(data2, menu2)
				if data2.current.value ~= nil then
				--print(playerCurrentTattoos)
				TriggerServerEvent('esx_tattooshop:purchaseTattoo', playerCurrentTattoos, target, {collection = currentValue, texture = data2.current.value})


				else
					OpenShopMenu(target, skin, playerCurrentTattoos)
					TriggerServerEvent("esx_tattooshop:resetSkin", target)
				end

			end, function(data2, menu2)
				menu2.close()
				TriggerServerEvent("esx_tattooshop:setPedSkin", target)
				--setPedSkin()
			end, function(data2, menu2) -- when highlighted
				if data2.current.value ~= nil then
					--drawTattoo(data2.current.value, currentValue)
					TriggerServerEvent("esx_tattooshop:change", target, currentValue, data2.current.value)
				end
			end)
		end
	end, function(data, menu)
		menu.close()
		TriggerServerEvent("esx_tattooshop:setPedSkin", target)
	end)
end

Citizen.CreateThread(function()
	for k,v in pairs(Config.Zones) do
		local blip = AddBlipForCoord(v)
		SetBlipSprite(blip, 75)
		SetBlipScale(blip, 0.6)
		SetBlipColour(blip, 1)
		SetBlipAsShortRange(blip, true)

		BeginTextCommandSetBlipName('STRING')
		AddTextComponentString(_U('tattoo_shop'))
		EndTextCommandSetBlipName(blip)
	end
end)

-- Display markers
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		local coords = GetEntityCoords(PlayerPedId())

		for k,v in pairs(Config.Zones) do
			if (Config.Type ~= -1 and GetDistanceBetweenCoords(coords, v, true) < Config.DrawDistance) then
				DrawMarker(Config.Type, v, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.Size.x, Config.Size.y, Config.Size.z, Config.Color.r, Config.Color.g, Config.Color.b, 100, false, true, 2, false, false, false, false)
			end
		end

		if(PlayerData.job and PlayerData.job.name == "tattoo") then
			for k,v in pairs(Config.Chests) do
				local distance = GetDistanceBetweenCoords(coords, v.x, v.y, v.z, true)
				if(distance < Config.DrawDistance) then
					DrawMarker(Config.Type, v, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.Size.x, Config.Size.y, Config.Size.z, Config.Color.r, Config.Color.g, Config.Color.b, 100, false, true, 2, false, false, false, false)
				
				
					if(distance < 2.0) then
						ESX.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour accéder au coffre.")

						if(IsControlJustPressed(1, 38)) then
							OpentattooActionsMenu()
						end
					end
				
				end
			end
		end
	end
end)

-- Enter / Exit marker events
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(100)

		local coords = GetEntityCoords(PlayerPedId())
		local isInMarker = false
		local currentZone, LastZone

		for k,v in pairs(Config.Zones) do
			if GetDistanceBetweenCoords(coords, v, true) < Config.Size.x then
				isInMarker = true
				currentZone = 'TattooShop'
				LastZone = 'TattooShop'
			end
		end

		if isInMarker and not HasAlreadyEnteredMarker then
			HasAlreadyEnteredMarker = true
			TriggerEvent('esx_tattooshop:hasEnteredMarker', currentZone)
		end

		if not isInMarker and HasAlreadyEnteredMarker then
			HasAlreadyEnteredMarker = false
			TriggerEvent('esx_tattooshop:hasExitedMarker', LastZone)
		end
	end
end)

AddEventHandler('esx_tattooshop:hasEnteredMarker', function(zone)
	if zone == 'TattooShop' then
		CurrentAction = 'tattoo_shop'
		CurrentActionMsg = _U('tattoo_shop_prompt')
		CurrentActionData = {zone = zone}
	end
end)

AddEventHandler('esx_tattooshop:hasExitedMarker', function(zone)
	CurrentAction = nil
	ESX.UI.Menu.CloseAll()
end)

-- Key Controls
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)

		
		if IsControlJustPressed(0, 167) and PlayerData.job and PlayerData.job.name == 'tattoo' then
			OpenMobileActionsMenu()
		end

		if CurrentAction  and PlayerData.job and PlayerData.job.name == 'tattoo' then
			ESX.ShowHelpNotification(CurrentActionMsg)

			if IsControlJustReleased(0, 38) then
				local player, distance = GetClosestPlayer()

				if(player ~= -1 and distance < 3.0) then
					TriggerServerEvent("esx_tattooshop:getSkin", player)
				else
					ESX.ShowNotification("Il n'y a personne autour.")
				end
				--[[if CurrentAction == 'tattoo_shop' then
					OpenShopMenu()
				end]]--
				CurrentAction = nil
			end
		end
	end
end)

function setPedSkin()
	ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin)
		TriggerEvent('skinchanger:loadSkin', skin)
	end)

	Citizen.Wait(1000)

	for k,v in pairs(currentTattoos) do
		ApplyPedOverlay(PlayerPedId(), GetHashKey(v.collection), GetHashKey(Config.TattooList[v.collection][v.texture].nameHash))
	end
end


function drawTattoo(current, collection)
	--SetEntityHeading(PlayerPedId(), 297.7296)
	ClearPedDecorations(PlayerPedId())

	for k,v in pairs(currentTattoos) do
		ApplyPedOverlay(PlayerPedId(), GetHashKey(v.collection), GetHashKey(Config.TattooList[v.collection][v.texture].nameHash))
	end

	TriggerEvent('skinchanger:getSkin', function(skin)
		if skin.sex == 0 then
			TriggerEvent('skinchanger:loadSkin', {
				sex = 0,
				tshirt_1 = 15,
				tshirt_2 = 0,
				arms = 15,
				torso_1 = 91,
				torso_2 = 0,
				pants_1 = 14,
				pants_2 = 0
			})
		else
			TriggerEvent('skinchanger:loadSkin', {
				sex = 1,
				tshirt_1 = 34,
				tshirt_2 = 0,
				arms = 15,
				torso_1 = 101,
				torso_2 = 1,
				pants_1 = 16,
				pants_2 = 0
			})
		end
	end)

	ApplyPedOverlay(PlayerPedId(), GetHashKey(collection), GetHashKey(Config.TattooList[collection][current].nameHash))
end

function cleanPlayer()
	ClearPedDecorations(PlayerPedId())

	for k,v in pairs(currentTattoos) do
		ApplyPedOverlay(PlayerPedId(), GetHashKey(v.collection), GetHashKey(Config.TattooList[v.collection][v.texture].nameHash))
	end
end





RegisterNetEvent("esx_tattooshop:getSkin")
AddEventHandler("esx_tattooshop:getSkin", function(target)
	TriggerEvent('skinchanger:getSkin', function(skin)
		skinBefore = skin
		TriggerServerEvent('esx_tattooshop:setSkin', skin, target, currentTattoos)
	end)
end)

RegisterNetEvent("esx_tattooshop:setSkin")
AddEventHandler("esx_tattooshop:setSkin", function(target)
	TriggerEvent('skinchanger:setSkin', function(skin)
		skinBefore = skin
		TriggerServerEvent('esx_tattooshop:setSkin', skin, target, currentTattoos)
	end)
end)

RegisterNetEvent('esx_tattooshop:buySuccess')
AddEventHandler('esx_tattooshop:buySuccess', function(tattoo)
ESX.ShowNotification('~r~Vous êtes entrain de tatouer !')
  RequestAnimDict('anim@amb@clubhouse@tutorial@bkr_tut_ig3@')
        
    while not HasAnimDictLoaded('anim@amb@clubhouse@tutorial@bkr_tut_ig3@') do
      Citizen.Wait(0)
    end
local ped = GetPlayerPed(-1)
	--ClearPedSecondaryTask(ped)
	FreezeEntityPosition(ped, true)
	local x,y,z = table.unpack(GetEntityCoords(ped))
	local prop_name = "v_ilev_ta_tatgun"
	Jointsupp = CreateObject(GetHashKey(prop_name), x, y, z,  true,  true, true)
	AttachEntityToEntity(Jointsupp, ped, GetPedBoneIndex(ped, 28422), -0.0, 0.03, 0, 0, -270.0, -20.0, true, true, false, true, 1, true)
	TaskPlayAnim(ped, "anim@amb@clubhouse@tutorial@bkr_tut_ig3@", "machinic_loop_mechandplayer", 8.00, -8.00, -1, (2 + 16 + 32), 0.00, 0, 0, 0)
Wait(15000)
ESX.ShowNotification("~g~Vous avez fini de tatouer, bravo!.")
	table.insert(currentTattoos, tattoo)
	DeleteObject(Jointsupp)
	DetachEntity(Jointsupp, 1, true)
	ClearPedTasksImmediately(ped)
	ClearPedSecondaryTask(ped)
	FreezeEntityPosition(ped, false)
end)


RegisterNetEvent("esx_tattooshop:change")
AddEventHandler("esx_tattooshop:change", function(collection, name)
	drawTattoo(name, collection)
end)


RegisterNetEvent("esx_tattooshop:resetSkin")
AddEventHandler("esx_tattooshop:resetSkin", function()
	cleanPlayer()
	ESX.TriggerServerCallback('esx_tattooshop:requestPlayerTattoos', function(tattooList)
		if tattooList then
			for k,v in pairs(tattooList) do
				ApplyPedOverlay(PlayerPedId(), GetHashKey(v.collection), GetHashKey(Config.TattooList[v.collection][v.texture].nameHash))
			end

			currentTattoos = tattooList
		end
	end)
end)


RegisterNetEvent("esx_tattooshop:setPedSkin")
AddEventHandler("esx_tattooshop:setPedSkin", function()
	setPedSkin()
	ESX.TriggerServerCallback('esx_tattooshop:requestPlayerTattoos', function(tattooList)
		if tattooList then
			for k,v in pairs(tattooList) do
				ApplyPedOverlay(PlayerPedId(), GetHashKey(v.collection), GetHashKey(Config.TattooList[v.collection][v.texture].nameHash))
			end

			currentTattoos = tattooList
		end
	end)
end)




RegisterNetEvent("esx_tattooshop:setSkin")
AddEventHandler("esx_tattooshop:setSkin", function(skin, target, playerCurrentTattoos)
	OpenShopMenu(target, skin, playerCurrentTattoos)
end)












function OpentattooActionsMenu()

	local elements = {
	  --{label = _U('work_wear'), value = 'cloakroom'},
	  --{label = _U('civ_wear'), value = 'cloakroom2'},
	  {label = "Déposer Stock", value = 'put_stock'}
	}
	
	if PlayerData.job ~= nil and PlayerData.job.grade_name == 'boss'  then 
	  table.insert(elements, {label = 'Prendre Stock', value = 'get_stock'})
	  table.insert(elements, {label = "Actions boss", value = 'boss_actions'})
	end
  
	ESX.UI.Menu.CloseAll()
  
	ESX.UI.Menu.Open(
	  'default', GetCurrentResourceName(), 'tattoo_actions',
	  {
		title    = "Tatoueur",
		elements = elements
	  },
	  function(data, menu)
  
		if data.current.value == 'put_stock' then
		  OpenPutStocksMenu()
		end
  
		if data.current.value == 'get_stock' then
		  OpenGetStocksMenu()
		end
		
		if data.current.value == 'boss_actions' then
		  TriggerEvent('esx_society:openBossMenu', 'tattoo', function(data, menu)
			menu.close()
		  end)
		end
  
	  end,
	  function(data, menu)
		menu.close()
	  end
	)
  end
  


  
function OpenGetStocksMenu()

	ESX.TriggerServerCallback('esx_tattooshop:getStockItems', function(items)
    
	  local elements = {}
  
	  for i=1, #items, 1 do
		table.insert(elements, {label = 'x' .. items[i].count .. ' ' .. items[i].label, value = items[i].name})
	  end
  
	  ESX.UI.Menu.Open(
		'default', GetCurrentResourceName(), 'stocks_menu',
		{
		  title    = "Tatoueur stock",
		  elements = elements
		},
		function(data, menu)
  
		  local itemName = data.current.value
  
		  ESX.UI.Menu.Open(
			'dialog', GetCurrentResourceName(), 'stocks_menu_get_item_count',
			{
			  title = "Quantité"
			},
			function(data2, menu2)
  
			  local count = tonumber(data2.value)
  
			  if count == nil then
				ESX.ShowNotification("Quantité invalide")
			  else
				menu2.close()
				menu.close()
				OpenGetStocksMenu()
  
				TriggerServerEvent('esx_tattooshop:getStockItem', itemName, count)
			  end
  
			end,
			function(data2, menu2)
			  menu2.close()
			end
		  )
  
		end,
		function(data, menu)
		  menu.close()
		end
	  )
  
	end)
  
  end
  
  function OpenPutStocksMenu()
  
  ESX.TriggerServerCallback('esx_tattooshop:getPlayerInventory', function(inventory)
  
	  local elements = {}
  
	  for i=1, #inventory.items, 1 do
  
		local item = inventory.items[i]
  
		if item.count > 0 then
		  table.insert(elements, {label = item.label .. ' x' .. item.count, type = 'item_standard', value = item.name})
		end
  
	  end
  
	  ESX.UI.Menu.Open(
		'default', GetCurrentResourceName(), 'stocks_menu',
		{
		  title    = "Inventaire",
		  elements = elements
		},
		function(data, menu)
  
		  local itemName = data.current.value
  
		  ESX.UI.Menu.Open(
			'dialog', GetCurrentResourceName(), 'stocks_menu_put_item_count',
			{
			  title = "Quantité"
			},
			function(data2, menu2)
  
			  local count = tonumber(data2.value)
  
			  if count == nil then
				ESX.ShowNotification("Quantité invalide")
			  else
				menu2.close()
				menu.close()
				OpenPutStocksMenu()
  
				TriggerServerEvent('esx_tattooshop:putStockItems', itemName, count)
			  end
  
			end,
			function(data2, menu2)
			  menu2.close()
			end
		  )
  
		end,
		function(data, menu)
		  menu.close()
		end
	  )
  
	end)
  
  end
  

function GetClosestPlayer()
	local player = -1
	local minDistance = 1000.0

	local myCoords = GetEntityCoords(PlayerPedId())
	for _, id in pairs(GetActivePlayers()) do
		if(id ~= PlayerId()) then
		local ped = GetPlayerPed(id)
		local coords = GetEntityCoords(ped)
		local distance = #(myCoords-coords)

		if(distance < minDistance) then
			minDistance = distance
			player = GetPlayerServerId(id)
		end
		end
	end

	return player, minDistance
end