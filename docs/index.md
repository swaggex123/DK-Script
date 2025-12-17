## DK-Script Documentation

This repository currently ships Three FiveM resources as `.rar` archives:

- `cl_notify.rar`
- `Dk-frakciobuy.rar`
- `esx_legacy_vehicleshop.rar`

These docs describe the **public surfaces** you can call from other resources:

- **Events** (`RegisterNetEvent`)
- **Commands** (`RegisterCommand`)
- **ESX server callbacks** (`ESX.RegisterServerCallback`)
- **NUI callbacks** (`RegisterNUICallback`) and **NUI messages** (`SendNUIMessage` / `window.postMessage`)
- **Configuration** tables

### Resources

- [`cl_notify`](resources/cl_notify.md)
- [`Dk-frakciobuy`](resources/Dk-frakciobuy.md)
- [`esx_legacy_vehicleshop`](resources/esx_legacy_vehicleshop.md)

### How to use these docs

- **If you run the `.rar` directly**: extract each archive into your server’s `resources/` folder and ensure it in `server.cfg`.
- **If you modify code**: treat event/callback names below as the contract; changing names will break integrations.
