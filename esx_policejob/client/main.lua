local ESX = ESX

local function getESX()
  if ESX then return ESX end
  if exports and exports['es_extended'] and exports['es_extended'].getSharedObject then
    ESX = exports['es_extended']:getSharedObject()
    return ESX
  end
  return nil
end

local function _U(key)
  local locale = Locales and (Locales[Config.Locale] or Locales['en']) or nil
  if not locale then return key end
  return locale[key] or key
end

local PlayerData = {}
local isHandcuffed = false
local isDragged = false
local draggerId = 0

local function isPolice()
  return PlayerData.job and PlayerData.job.name == Config.JobName
end

local function notify(msg)
  local esx = getESX()
  if esx and esx.ShowNotification then
    esx.ShowNotification(msg)
  else
    SetNotificationTextEntry('STRING')
    AddTextComponentString(msg)
    DrawNotification(false, false)
  end
end

local function getClosestPlayer(maxDistance)
  local esx = getESX()
  if esx and esx.Game and esx.Game.GetClosestPlayer then
    return esx.Game.GetClosestPlayer()
  end

  local plyPed = PlayerPedId()
  local plyCoords = GetEntityCoords(plyPed)
  local closestPlayer, closestDistance = -1, (maxDistance or 3.0)

  for _, player in ipairs(GetActivePlayers()) do
    local ped = GetPlayerPed(player)
    if ped ~= plyPed then
      local dist = #(GetEntityCoords(ped) - plyCoords)
      if dist < closestDistance then
        closestDistance = dist
        closestPlayer = player
      end
    end
  end

  return closestPlayer, closestDistance
end

local function openPoliceActionsMenu()
  if not isPolice() then
    notify(_U('not_police'))
    return
  end

  if IsPedInAnyVehicle(PlayerPedId(), false) then
    notify(_U('action_in_vehicle'))
    return
  end

  local elements = {
    { label = _U('handcuff'), value = 'handcuff' },
    { label = _U('drag'), value = 'drag' },
    { label = _U('put_in_vehicle'), value = 'put_in_vehicle' },
    { label = _U('out_the_vehicle'), value = 'out_vehicle' },
    { label = _U('search'), value = 'search' },
    { label = _U('bill'), value = 'bill' },
  }

  getESX().UI.Menu.Open('default', GetCurrentResourceName(), 'police_actions', {
    title = _U('police_actions'),
    align = 'top-left',
    elements = elements
  }, function(data, menu)
    local action = data.current.value
    local closestPlayer, closestDistance = getClosestPlayer(Config.InteractionDistance)
    if closestPlayer == -1 or closestDistance > Config.InteractionDistance then
      notify(_U('no_players_nearby'))
      return
    end

    local targetServerId = GetPlayerServerId(closestPlayer)

    if action == 'handcuff' then
      TriggerServerEvent('esx_policejob:requestHandcuff', targetServerId)
    elseif action == 'drag' then
      TriggerServerEvent('esx_policejob:requestDrag', targetServerId)
    elseif action == 'put_in_vehicle' then
      TriggerServerEvent('esx_policejob:requestPutInVehicle', targetServerId)
    elseif action == 'out_vehicle' then
      TriggerServerEvent('esx_policejob:requestOutVehicle', targetServerId)
    elseif action == 'search' then
      TriggerEvent('esx_policejob:openSearchMenu', targetServerId)
    elseif action == 'bill' then
      getESX().UI.Menu.Open('dialog', GetCurrentResourceName(), 'billing', {
        title = _U('bill_amount')
      }, function(billData, billMenu)
        local amount = tonumber(billData.value)
        if not amount or amount <= 0 then
          notify(_U('invalid_amount'))
          return
        end
        billMenu.close()
        TriggerServerEvent('esx_billing:sendBill', targetServerId, 'society_' .. Config.JobName, Config.JobName, amount)
      end, function(_, billMenu)
        billMenu.close()
      end)
    end
  end, function(_, menu)
    menu.close()
  end)
end

local function openZoneMenu(zoneKey)
  if zoneKey == 'Armory' then
    TriggerEvent('esx_policejob:openArmoryMenu')
  elseif zoneKey == 'Garage' then
    TriggerEvent('esx_policejob:openGarageMenu')
  elseif zoneKey == 'Boss' then
    local bossGrade = Config.Zones.Boss.bossGrade or 4
    if (PlayerData.job and PlayerData.job.grade or 0) < bossGrade then
      notify(_U('not_police'))
      return
    end
    TriggerEvent('esx_society:openBossMenu', Config.JobName, function(_, menu)
      if menu then menu.close() end
    end, { wash = false })
  elseif zoneKey == 'Cloakroom' then
    notify(_U('cloakroom'))
  end
end

RegisterNetEvent('esx:playerLoaded', function(xPlayer)
  PlayerData = xPlayer
end)

RegisterNetEvent('esx:setJob', function(job)
  PlayerData.job = job
end)

CreateThread(function()
  local esx = getESX()
  while not esx do
    Wait(250)
    esx = getESX()
  end

  PlayerData = esx.GetPlayerData()
end)

-- Keybind
CreateThread(function()
  while true do
    Wait(0)
    if isPolice() and IsControlJustReleased(0, Config.OpenMenuKey) then
      openPoliceActionsMenu()
    end
  end
end)

-- Markers
CreateThread(function()
  while true do
    local sleep = 1000
    if isPolice() then
      local ped = PlayerPedId()
      local coords = GetEntityCoords(ped)

      for k, zone in pairs(Config.Zones) do
        local dist = #(coords - zone.coords)
        if dist < Config.DrawDistance then
          sleep = 0
          DrawMarker(
            Config.Marker.type,
            zone.coords.x, zone.coords.y, zone.coords.z - 1.0,
            0.0, 0.0, 0.0,
            0.0, 0.0, 0.0,
            Config.Marker.size.x, Config.Marker.size.y, Config.Marker.size.z,
            Config.Marker.color.r, Config.Marker.color.g, Config.Marker.color.b, Config.Marker.color.a,
            false, true, 2, false, nil, nil, false
          )

          if dist < Config.InteractionDistance then
            sleep = 0
            ESX.ShowHelpNotification(_U('open_menu'))
            if IsControlJustReleased(0, 38) then -- E
              openZoneMenu(k)
            end
          end
        end
      end
    end
    Wait(sleep)
  end
end)

-- Handcuff / drag / vehicle interaction (target side)
RegisterNetEvent('esx_policejob:handcuff', function()
  local ped = PlayerPedId()
  isHandcuffed = not isHandcuffed

  if isHandcuffed then
    RequestAnimDict('mp_arresting')
    while not HasAnimDictLoaded('mp_arresting') do Wait(10) end
    TaskPlayAnim(ped, 'mp_arresting', 'idle', 8.0, -8.0, -1, 49, 0, false, false, false)
    SetEnableHandcuffs(ped, true)
    DisablePlayerFiring(PlayerId(), true)
    SetCurrentPedWeapon(ped, GetHashKey('WEAPON_UNARMED'), true)
  else
    ClearPedTasks(ped)
    SetEnableHandcuffs(ped, false)
    DisablePlayerFiring(PlayerId(), false)
    isDragged = false
    draggerId = 0
  end
end)

RegisterNetEvent('esx_policejob:drag', function(copServerId)
  if not isHandcuffed then return end
  isDragged = not isDragged
  draggerId = copServerId
end)

CreateThread(function()
  while true do
    Wait(0)
    if isHandcuffed then
      DisableControlAction(0, 24, true) -- attack
      DisableControlAction(0, 257, true) -- attack2
      DisableControlAction(0, 25, true) -- aim
      DisableControlAction(0, 263, true) -- melee
      DisableControlAction(0, 37, true) -- weapon wheel
      DisableControlAction(0, 44, true) -- cover
      DisableControlAction(0, 140, true)
      DisableControlAction(0, 141, true)
      DisableControlAction(0, 142, true)
      DisableControlAction(0, 143, true)

      if isDragged and draggerId ~= 0 then
        local targetPed = GetPlayerPed(GetPlayerFromServerId(draggerId))
        if DoesEntityExist(targetPed) then
          AttachEntityToEntity(PlayerPedId(), targetPed, 11816, 0.54, 0.54, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
        else
          isDragged = false
          DetachEntity(PlayerPedId(), true, false)
        end
      else
        DetachEntity(PlayerPedId(), true, false)
      end
    else
      Wait(500)
    end
  end
end)

RegisterNetEvent('esx_policejob:putInVehicle', function()
  if not isHandcuffed then return end
  local ped = PlayerPedId()
  local coords = GetEntityCoords(ped)
  local vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 71)
  if vehicle ~= 0 then
    for i = 0, GetVehicleMaxNumberOfPassengers(vehicle) do
      if IsVehicleSeatFree(vehicle, i) then
        TaskWarpPedIntoVehicle(ped, vehicle, i)
        return
      end
    end
  end
end)

RegisterNetEvent('esx_policejob:outVehicle', function()
  local ped = PlayerPedId()
  if IsPedSittingInAnyVehicle(ped) then
    TaskLeaveVehicle(ped, GetVehiclePedIsIn(ped, false), 16)
  end
end)

-- Armory menu
RegisterNetEvent('esx_policejob:openArmoryMenu', function()
  if not isPolice() then return end

  local elements = {
    { label = _U('armory_take_item'), value = 'take_item' },
    { label = _U('armory_deposit_item'), value = 'deposit_item' },
    { label = _U('armory_take_weapon'), value = 'take_weapon' },
    { label = _U('armory_deposit_weapon'), value = 'deposit_weapon' },
  }

  ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'armory', {
    title = _U('armory'),
    align = 'top-left',
    elements = elements
  }, function(data, menu)
    if data.current.value == 'take_item' then
      ESX.TriggerServerCallback('esx_policejob:getStockItems', function(items)
        local itemElements = {}
        for _, item in ipairs(items) do
          itemElements[#itemElements + 1] = { label = ('%s x%s'):format(item.label, item.count), value = item.name, count = item.count }
        end
        ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'armory_take_item', {
          title = _U('armory_take_item'),
          align = 'top-left',
          elements = itemElements
        }, function(itemData, itemMenu)
          ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'armory_take_item_count', {
            title = itemData.current.label
          }, function(countData, countMenu)
            local count = tonumber(countData.value)
            if not count or count <= 0 then
              notify(_U('invalid_amount'))
              return
            end
            countMenu.close()
            itemMenu.close()
            TriggerServerEvent('esx_policejob:getStockItem', itemData.current.value, count)
          end, function(_, countMenu)
            countMenu.close()
          end)
        end, function(_, itemMenu)
          itemMenu.close()
        end)
      end)
    elseif data.current.value == 'deposit_item' then
      ESX.TriggerServerCallback('esx_policejob:getPlayerInventory', function(inventory)
        local itemElements = {}
        for _, item in ipairs(inventory.items) do
          if item.count and item.count > 0 then
            itemElements[#itemElements + 1] = { label = ('%s x%s'):format(item.label, item.count), value = item.name, count = item.count }
          end
        end
        ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'armory_deposit_item', {
          title = _U('armory_deposit_item'),
          align = 'top-left',
          elements = itemElements
        }, function(itemData, itemMenu)
          ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'armory_deposit_item_count', {
            title = itemData.current.label
          }, function(countData, countMenu)
            local count = tonumber(countData.value)
            if not count or count <= 0 then
              notify(_U('invalid_amount'))
              return
            end
            countMenu.close()
            itemMenu.close()
            TriggerServerEvent('esx_policejob:putStockItems', itemData.current.value, count)
          end, function(_, countMenu)
            countMenu.close()
          end)
        end, function(_, itemMenu)
          itemMenu.close()
        end)
      end)
    elseif data.current.value == 'take_weapon' then
      ESX.TriggerServerCallback('esx_policejob:getArmoryWeapons', function(weapons)
        local weaponElements = {}
        for _, w in ipairs(weapons) do
          weaponElements[#weaponElements + 1] = { label = ('%s x%s'):format(ESX.GetWeaponLabel(w.name), w.count), value = w.name }
        end
        ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'armory_take_weapon', {
          title = _U('armory_take_weapon'),
          align = 'top-left',
          elements = weaponElements
        }, function(wData, wMenu)
          wMenu.close()
          TriggerServerEvent('esx_policejob:removeArmoryWeapon', wData.current.value)
        end, function(_, wMenu)
          wMenu.close()
        end)
      end)
    elseif data.current.value == 'deposit_weapon' then
      local weaponElements = {}
      local plyPed = PlayerPedId()
      for _, w in ipairs(ESX.GetWeaponList()) do
        if HasPedGotWeapon(plyPed, joaat(w.name), false) and w.name ~= 'WEAPON_UNARMED' then
          weaponElements[#weaponElements + 1] = { label = w.label, value = w.name }
        end
      end
      ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'armory_deposit_weapon', {
        title = _U('armory_deposit_weapon'),
        align = 'top-left',
        elements = weaponElements
      }, function(wData, wMenu)
        wMenu.close()
        TriggerServerEvent('esx_policejob:addArmoryWeapon', wData.current.value)
      end, function(_, wMenu)
        wMenu.close()
      end)
    end
  end, function(_, menu)
    menu.close()
  end)
end)

-- Garage menu
RegisterNetEvent('esx_policejob:openGarageMenu', function()
  if not isPolice() then return end

  local elements = {}
  for _, v in ipairs(Config.PoliceVehicles) do
    elements[#elements + 1] = { label = v.label, value = v.model }
  end
  elements[#elements + 1] = { label = _U('garage_store'), value = 'store' }

  ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'garage', {
    title = _U('garage'),
    align = 'top-left',
    elements = elements
  }, function(data, menu)
    if data.current.value == 'store' then
      local ped = PlayerPedId()
      local coords = GetEntityCoords(ped)
      local vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 71)
      if vehicle == 0 then
        notify(_U('no_vehicle_nearby'))
        return
      end
      ESX.Game.DeleteVehicle(vehicle)
      notify(_U('vehicle_stored'))
      return
    end

    local model = data.current.value
    local spawn = Config.Zones.Garage.spawn

    ESX.Game.SpawnVehicle(model, spawn.coords, spawn.heading, function(vehicle)
      SetVehicleDirtLevel(vehicle, 0.0)
      SetVehicleFuelLevel(vehicle, 100.0)
      SetVehicleNumberPlateText(vehicle, 'POLICE')
      TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
    end)
  end, function(_, menu)
    menu.close()
  end)
end)

-- Search / confiscate menu
RegisterNetEvent('esx_policejob:openSearchMenu', function(targetServerId)
  if not isPolice() then return end

  ESX.TriggerServerCallback('esx_policejob:getOtherPlayerData', function(data)
    local elements = {}

    if data.accounts then
      for _, acc in ipairs(data.accounts) do
        if acc.name ~= 'bank' and acc.money and acc.money > 0 then
          elements[#elements + 1] = {
            label = ('%s: $%s'):format(acc.label or acc.name, acc.money),
            type = 'item_account',
            value = acc.name,
            amount = acc.money
          }
        end
      end
    end

    if data.weapons then
      for _, w in ipairs(data.weapons) do
        elements[#elements + 1] = {
          label = ('%s [%s]'):format(ESX.GetWeaponLabel(w.name), w.ammo or 0),
          type = 'item_weapon',
          value = w.name,
          amount = w.ammo or 0
        }
      end
    end

    if data.inventory then
      for _, item in ipairs(data.inventory) do
        if item.count and item.count > 0 then
          elements[#elements + 1] = {
            label = ('%s x%s'):format(item.label, item.count),
            type = 'item_standard',
            value = item.name,
            amount = item.count
          }
        end
      end
    end

    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'search', {
      title = _U('search'),
      align = 'top-left',
      elements = elements
    }, function(itemData, menu)
      local selected = itemData.current
      ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'confiscate_count', {
        title = _U('confiscate') .. ' (' .. selected.label .. ')'
      }, function(countData, countMenu)
        local amount = tonumber(countData.value) or 0
        if selected.type ~= 'item_standard' then
          amount = selected.amount
        end
        if selected.type == 'item_standard' and (not amount or amount <= 0) then
          notify(_U('invalid_amount'))
          return
        end
        countMenu.close()
        TriggerServerEvent('esx_policejob:confiscatePlayerItem', targetServerId, selected.type, selected.value, amount)
      end, function(_, countMenu)
        countMenu.close()
      end)
    end, function(_, menu)
      menu.close()
    end)
  end, targetServerId)
end)

