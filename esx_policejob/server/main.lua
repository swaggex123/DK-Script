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

local function isPolice(xPlayer)
  return xPlayer and xPlayer.job and xPlayer.job.name == Config.JobName
end

CreateThread(function()
  local esx = getESX()
  while not esx do
    Wait(250)
    esx = getESX()
  end

  TriggerEvent('esx_society:registerSociety',
    Config.JobName,
    Config.JobName,
    'society_' .. Config.JobName,
    'society_' .. Config.JobName,
    'society_' .. Config.JobName,
    { type = 'public' }
  )

  -- Callbacks (register once ESX is ready)
  esx.RegisterServerCallback('esx_policejob:getOtherPlayerData', function(src, cb, target)
    local xPlayer = esx.GetPlayerFromId(src)
    if not isPolice(xPlayer) then
      cb({})
      return
    end

    local xTarget = esx.GetPlayerFromId(target)
    if not xTarget then
      cb({})
      return
    end

    cb({
      name = xTarget.getName and xTarget.getName() or nil,
      job = xTarget.job,
      inventory = xTarget.getInventory and xTarget.getInventory() or xTarget.inventory,
      accounts = xTarget.getAccounts and xTarget.getAccounts() or xTarget.accounts,
      weapons = xTarget.getLoadout and xTarget.getLoadout() or {},
    })
  end)

  esx.RegisterServerCallback('esx_policejob:getStockItems', function(src, cb)
    local xPlayer = esx.GetPlayerFromId(src)
    if not isPolice(xPlayer) then cb({}) return end

    TriggerEvent('esx_addoninventory:getSharedInventory', 'society_' .. Config.JobName, function(inventory)
      cb(inventory.items)
    end)
  end)

  esx.RegisterServerCallback('esx_policejob:getPlayerInventory', function(src, cb)
    local xPlayer = esx.GetPlayerFromId(src)
    cb({ items = xPlayer.getInventory() })
  end)

  esx.RegisterServerCallback('esx_policejob:getArmoryWeapons', function(src, cb)
    local xPlayer = esx.GetPlayerFromId(src)
    if not isPolice(xPlayer) then cb({}) return end

    getArmoryWeapons(function(_, weapons)
      cb(weapons)
    end)
  end)
end)

-- Interaction relays
RegisterNetEvent('esx_policejob:requestHandcuff', function(target)
  local src = source
  local xPlayer = getESX().GetPlayerFromId(src)
  if not isPolice(xPlayer) then return end
  TriggerClientEvent('esx_policejob:handcuff', target)
end)

RegisterNetEvent('esx_policejob:requestDrag', function(target)
  local src = source
  local xPlayer = getESX().GetPlayerFromId(src)
  if not isPolice(xPlayer) then return end
  TriggerClientEvent('esx_policejob:drag', target, src)
end)

RegisterNetEvent('esx_policejob:requestPutInVehicle', function(target)
  local src = source
  local xPlayer = getESX().GetPlayerFromId(src)
  if not isPolice(xPlayer) then return end
  TriggerClientEvent('esx_policejob:putInVehicle', target)
end)

RegisterNetEvent('esx_policejob:requestOutVehicle', function(target)
  local src = source
  local xPlayer = getESX().GetPlayerFromId(src)
  if not isPolice(xPlayer) then return end
  TriggerClientEvent('esx_policejob:outVehicle', target)
end)

-- Search target data
-- (callbacks are registered in init thread)

-- Confiscate
RegisterNetEvent('esx_policejob:confiscatePlayerItem', function(target, itemType, itemName, amount)
  local src = source
  local xPlayer = getESX().GetPlayerFromId(src)
  if not isPolice(xPlayer) then return end

  local xTarget = getESX().GetPlayerFromId(target)
  if not xTarget then return end

  if itemType == 'item_standard' then
    local targetItem = xTarget.getInventoryItem(itemName)
    if not targetItem or targetItem.count < amount then return end

    xTarget.removeInventoryItem(itemName, amount)
    xPlayer.addInventoryItem(itemName, amount)
  elseif itemType == 'item_account' then
    local targetAccount = xTarget.getAccount(itemName)
    if not targetAccount or targetAccount.money < amount then return end

    xTarget.removeAccountMoney(itemName, amount)
    xPlayer.addAccountMoney(itemName, amount)
  elseif itemType == 'item_weapon' then
    xTarget.removeWeapon(itemName)
    xPlayer.addWeapon(itemName, amount or 0)
  end
end)

-- Society stock items (addoninventory)
-- (callbacks are registered in init thread)

RegisterNetEvent('esx_policejob:getStockItem', function(itemName, count)
  local src = source
  local xPlayer = getESX().GetPlayerFromId(src)
  if not isPolice(xPlayer) then return end

  TriggerEvent('esx_addoninventory:getSharedInventory', 'society_' .. Config.JobName, function(inventory)
    local item = inventory.getItem(itemName)
    if count <= 0 or item.count < count then
      xPlayer.showNotification(_U('armory_not_enough'))
      return
    end

    inventory.removeItem(itemName, count)
    xPlayer.addInventoryItem(itemName, count)
  end)
end)

-- (callbacks are registered in init thread)

RegisterNetEvent('esx_policejob:putStockItems', function(itemName, count)
  local src = source
  local xPlayer = getESX().GetPlayerFromId(src)
  if not isPolice(xPlayer) then return end

  local item = xPlayer.getInventoryItem(itemName)
  if count <= 0 or item.count < count then return end

  TriggerEvent('esx_addoninventory:getSharedInventory', 'society_' .. Config.JobName, function(inventory)
    xPlayer.removeInventoryItem(itemName, count)
    inventory.addItem(itemName, count)
  end)
end)

-- Armory weapons (datastore)
local function getArmoryWeapons(cb)
  TriggerEvent('esx_datastore:getSharedDataStore', 'society_' .. Config.JobName, function(store)
    local weapons = store.get('weapons') or {}
    cb(store, weapons)
  end)
end

-- (callbacks are registered in init thread)

RegisterNetEvent('esx_policejob:addArmoryWeapon', function(weaponName)
  local src = source
  local xPlayer = getESX().GetPlayerFromId(src)
  if not isPolice(xPlayer) then return end

  if not xPlayer.hasWeapon(weaponName) then return end

  xPlayer.removeWeapon(weaponName)

  getArmoryWeapons(function(store, weapons)
    local found = false
    for i = 1, #weapons do
      if weapons[i].name == weaponName then
        weapons[i].count = (weapons[i].count or 0) + 1
        found = true
        break
      end
    end
    if not found then
      weapons[#weapons + 1] = { name = weaponName, count = 1 }
    end
    store.set('weapons', weapons)
  end)
end)

RegisterNetEvent('esx_policejob:removeArmoryWeapon', function(weaponName)
  local src = source
  local xPlayer = getESX().GetPlayerFromId(src)
  if not isPolice(xPlayer) then return end

  getArmoryWeapons(function(store, weapons)
    for i = 1, #weapons do
      if weapons[i].name == weaponName and (weapons[i].count or 0) > 0 then
        weapons[i].count = weapons[i].count - 1
        store.set('weapons', weapons)
        xPlayer.addWeapon(weaponName, 250)
        return
      end
    end
    xPlayer.showNotification(_U('armory_not_enough'))
  end)
end)

