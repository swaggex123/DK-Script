Config = {}

Config.Locale = 'hu'

-- General
Config.JobName = 'police'
Config.OpenMenuKey = 167 -- F6
Config.DrawDistance = 25.0

-- Controls / distances
Config.InteractionDistance = 2.0
Config.HandcuffDistance = 2.0
Config.SearchDistance = 2.0
Config.DragDistance = 2.0

-- Marker settings
Config.Marker = {
  type = 1,
  size = vec3(1.2, 1.2, 0.8),
  color = { r = 50, g = 120, b = 255, a = 180 },
}

-- Locations (default Mission Row-ish)
Config.Zones = {
  Cloakroom = {
    coords = vec3(452.6, -992.8, 30.6),
    label = 'cloakroom',
  },
  Armory = {
    coords = vec3(451.7, -980.1, 30.6),
    label = 'armory',
  },
  Boss = {
    coords = vec3(448.4, -973.2, 30.6),
    label = 'boss_actions',
    bossGrade = 4, -- boss+ can access
  },
  Garage = {
    coords = vec3(454.6, -1017.4, 28.4),
    spawn = {
      coords = vec3(438.9, -1018.3, 28.7),
      heading = 90.0,
    },
    label = 'garage',
  },
}

Config.PoliceVehicles = {
  { label = 'Police Cruiser', model = 'police' },
  { label = 'Police Buffalo', model = 'police2' },
  { label = 'Police Interceptor', model = 'police3' },
}

Config.ArmoryItems = {
  { label = 'Pistol Ammo', name = 'ammo-9', type = 'item', count = 25 },
  { label = 'Radio', name = 'radio', type = 'item', count = 1 },
}

Config.ArmoryWeapons = {
  { label = 'Pistol', name = 'weapon_pistol', type = 'weapon', ammo = 42 },
  { label = 'Stun Gun', name = 'weapon_stungun', type = 'weapon', ammo = 0 },
  { label = 'Nightstick', name = 'weapon_nightstick', type = 'weapon', ammo = 0 },
  { label = 'Flashlight', name = 'weapon_flashlight', type = 'weapon', ammo = 0 },
}

