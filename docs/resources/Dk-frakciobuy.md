## `Dk-frakciobuy`

Faction/job “purchase NPC” resource with menus and leader-only markers.

### Install

- **Resource name**: `Dk-frakciobuy`
- Extract `Dk-frakciobuy.rar` into `resources/[local]/Dk-frakciobuy/`
- **Dependencies**:
  - `ox_lib` (required; contexts, zones, text UI)
  - `es_extended` (required; jobs/money)
  - `esx_society` (required if you use the boss menu marker)

Ensure order in `server.cfg`:

```cfg
ensure ox_lib
ensure es_extended
ensure esx_society
ensure Dk-frakciobuy
```

### Configuration

All configuration is in `config.lua`.

#### `Config.Factions`

Array of factions available for purchase.

Each faction object supports:

- **name** (`string`): display name
- **job** (`string`): ESX job name to set
- **price** (`number`): cash price to buy
- **type** (`"legal" | "illegal"`)
- **vehicles** (`array`): list of spawnable vehicles for faction leader
  - `{ label = string, model = string }`
- **blip** (`table`): map blip config
  - `coords` (`vector3`), `sprite` (`number`), `color` (`number`), `name` (`string`)
- **boss** (`vector3`): boss menu marker position
- **garage** (`vector3`): spawn menu marker position
- **parkLocation** (`vector3`): vehicle parking marker position

#### `Config.NPC`

- **model** (`string`): ped model
- **coords** (`vector4`): spawn position + heading

### Public API (events)

This resource is event-driven. If you integrate from another resource, use these.

#### Client event: `jobshop:openFactionMenu`

Opens the main “Legal/Illegal/Return” menu.

- **Side**: client
- **Parameters**: none

**Example:**

```lua
TriggerEvent('jobshop:openFactionMenu')
```

#### Client event: `jobshop:openFactionType`

Opens the purchase list for a given faction type.

- **Side**: client
- **Parameters**:
  - **type**: `"legal"` or `"illegal"`

**Example:**

```lua
TriggerEvent('jobshop:openFactionType', 'legal')
```

#### Server event: `jobshop:buyFaction`

Attempts to purchase a faction.

- **Side**: server
- **Parameters**:
  - **factionIndex** (`number`): 1-based index into `Config.Factions`

**Example (client → server):**

```lua
TriggerServerEvent('jobshop:buyFaction', 1)
```

#### Server event: `jobshop:returnFaction`

Returns (sells back) the current faction and refunds the price to bank.

- **Side**: server
- **Parameters**:
  - **factionIndex** (`number`): 1-based index into `Config.Factions`

**Example:**

```lua
TriggerServerEvent('jobshop:returnFaction', 1)
```

#### Server event: `jobshop:checkFactionStatus`

Checks whether the player is currently in a configured faction job and enables leader features.

- **Side**: server
- **Parameters**: none

This is normally triggered when `esx:playerLoaded` fires on the client.

#### Client event: `jobshop:addBlip`

Adds a blip for the faction.

- **Side**: client
- **Parameters**:
  - **blipData** (`table`): `{ coords, sprite, color, name }`
  - **faction** (`table`): faction object (used for fallback name)
  - **route** (`boolean`): if true, sets GPS route to the blip

#### Client event: `jobshop:setLeader`

Enables leader-only features (boss menu marker, vehicle spawn menu, parking marker).

- **Side**: client
- **Parameters**:
  - **isLeader** (`boolean`)
  - **faction** (`table`): faction object containing `job`, `boss`, `garage`, `parkLocation`, `vehicles`

**Example (server → client):**

```lua
TriggerClientEvent('jobshop:setLeader', source, true, {
  job = 'mechanic',
  boss = vector3(0,0,0),
  garage = vector3(0,0,0),
  parkLocation = vector3(0,0,0),
  vehicles = { { label = 'Rumpo', model = 'rumpo' } },
  index = 4,
})
```

### Leader gameplay hooks

When leader is enabled, the client uses:

- **Boss menu**: `TriggerEvent('esx_society:openBossMenu', faction.job, ...)`
- **Vehicle spawn**: opens a menu from `faction.vehicles`, spawns selected vehicle, then fires:
  - `TriggerServerEvent('jobshop:storeVehicle', { model = model, plate = plate })`
- **Vehicle park**:
  - `TriggerServerEvent('jobshop:removeVehicle', plate)`

### Global client functions (callable, but not a stable API)

The client file defines some **global** functions (not `local`), which makes them technically callable from other client code at runtime. They are intended as internal helpers; prefer the events above.

#### `openVehicleMenu(vehicles)`

- **Side**: client
- **Parameters**:
  - **vehicles** (`array`): `{ { label = string, model = string }, ... }`
- **Behavior**: shows a context menu and spawns the selected vehicle, then fires `jobshop:storeVehicle`.

#### `parkVehicle()`

- **Side**: client
- **Behavior**: deletes the current vehicle and fires `jobshop:removeVehicle` with the plate.

### Persistence / ownership notes

- Faction ownership (`ownedFactions`) is stored **in server memory** only.
  - **Server restart resets ownership**, making all factions purchasable again.

### Database notes

A sample `sql.txt` is included for adding jobs/grades, but you must ensure:

- The configured job names in `Config.Factions[*].job` exist in `jobs`.
- You create matching entries in `job_grades`.
- The script sets job grade to `4` for leader. If your grades only go `0-3`, add a grade `4` or change the script.
