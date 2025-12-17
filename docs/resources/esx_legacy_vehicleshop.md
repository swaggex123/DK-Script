## `esx_legacy_vehicleshop`

ESX vehicle shop with NUI UI (browse, test drive, rent, buy).

### Install

- **Resource name**: `esx_legacy_vehicleshop`
- Extract `esx_legacy_vehicleshop.rar` into `resources/[local]/esx_legacy_vehicleshop/`
- **Dependencies**:
  - `es_extended` (required)
  - `mysql-async` (required by `@mysql-async/lib/MySQL.lua`)
  - `cl_notify` (recommended; this shop triggers the `notify` client event)
  - `esx_vehiclelock` (optional; used to give keys after purchase)

Ensure order in `server.cfg`:

```cfg
ensure es_extended
ensure mysql-async
ensure cl_notify
ensure esx_legacy_vehicleshop
```

### Public API

#### ESX server callback: `esx_legacy_vehicleshop:getVehicles`

Returns the list of vehicles the shop should display.

- **Side**: server callback
- **Signature**: `cb(vehicles)`
- **Vehicle shape** (as currently returned):

```lua
{
  name = 'Adder',
  model = 'adder',
  price = 1000000,
  image = 'html/images/adder.png',
  category = 'Benzin'
}
```

**Example (client):**

```lua
ESX.TriggerServerCallback('esx_legacy_vehicleshop:getVehicles', function(vehicles)
  print(('Got %d vehicles'):format(#vehicles))
end)
```

#### ESX server callback: `esx_legacy_vehicleshop:buyVehicle`

Charges the player and persists purchase to DB.

- **Side**: server callback
- **Parameters**:
  - **model** (`string`)
  - **price** (`number`)
  - **color** (`string|number`): UI currently sends a hex string like `"#ff0000"`
- **Returns**: `cb(true|false)`

**Example (client):**

```lua
ESX.TriggerServerCallback('esx_legacy_vehicleshop:buyVehicle', function(success)
  if success then
    TriggerEvent('notify', 'Purchased!', 'success')
  end
end, 'adder', 1000000, '#ffffff')
```

### Global client functions (callable, but not a stable API)

The client script defines these as **global** functions (not `local`), so they can be invoked by other client code at runtime. Prefer the NUI callbacks / server callbacks unless you’re intentionally integrating at a low level.

#### `OpenVehicleShop()`

- **Side**: client
- **Behavior**: focuses NUI and sends `action = 'openShop'` after fetching vehicles via `esx_legacy_vehicleshop:getVehicles`.

#### `CreateBlip()`

- **Side**: client
- **Behavior**: creates the “Autókereskedés” map blip at the configured shop coords.

### NUI contract

#### Incoming messages (Lua → UI)

- **Open**:
  - `action: 'openShop'`
  - `vehicles: <array>` (from `getVehicles` callback)

```lua
SendNUIMessage({ action = 'openShop', vehicles = vehicles })
```

- **Close** (not currently used from Lua, but UI supports it):
  - `action: 'closeShop'`

#### Outgoing callbacks (UI → Lua)

The UI POSTs to NUI endpoints:

- `POST https://${GetParentResourceName()}/testDrive`
  - body: `{ model: string }`
- `POST .../rentVehicle`
  - body: `{ model: string }`
- `POST .../buyVehicle`
  - body: `{ model: string, price: number, color: string }`
- `POST .../close`
  - body: `{}`

On the Lua side these are implemented via `RegisterNUICallback`:

- **`testDrive`**: spawns vehicle for 10 seconds, then deletes it.
- **`rentVehicle`**: spawns vehicle for 60 seconds, then deletes it.
- **`buyVehicle`**:
  - calls `esx_legacy_vehicleshop:buyVehicle`
  - on success: spawns vehicle, sets colors, triggers `esx_vehiclelock:givekey` with the plate
- **`close`**: clears NUI focus

### Database

A sample `sql.txt` is provided.

- Creates `owned_vehicles` with `owner`, `vehicle`, `fuel_level`, `health`, `stored`
- Adds `color` column

### Notes / integration gotchas

- The NUI `html/script.js` currently uses a **hardcoded vehicle list** and does not read the `vehicles` payload sent in `openShop`. If you want server-driven vehicles, update the UI to use `event.data.vehicles`.
- There is an extra server file `server/vehicleshop.lua` registering `vehicleshop:buyVehicle`; the client/NUI flow does not call it. Treat it as legacy unless you wire it up.
