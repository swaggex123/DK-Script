## `cl_notify`

Client-side NUI notification resource.

### Install

- **Resource name**: `cl_notify`
- **Add to server**: extract `cl_notify.rar` into `resources/[local]/cl_notify/`
- **Ensure** in `server.cfg`:

```cfg
ensure cl_notify
```

### Public API

#### Client event: `notify`

Shows a notification in the top-left, plays a sound depending on type, and auto-hides.

- **Event name**: `notify`
- **Side**: client
- **Parameters**:
  - **message** (`string`): text to display
  - **type** (`string`): one of `success | error | info | warning`

**Example (client):**

```lua
-- Anywhere on the client
TriggerEvent('notify', 'Saved successfully!', 'success')
TriggerEvent('notify', 'Something went wrong', 'error')
TriggerEvent('notify', 'Heads up…', 'info')
TriggerEvent('notify', 'Be careful!', 'warning')
```

**Example (server → client):**

```lua
-- Server code
RegisterCommand('hello', function(source)
  TriggerClientEvent('notify', source, 'Hello from server!', 'info')
end)
```

#### Command: `/tesztnotify`

Quick manual test command.

- **Command**: `tesztnotify`
- **Usage**:

```text
/tesztnotify [type] [message...]
```

- **Examples**:

```text
/tesztnotify success Purchase complete
/tesztnotify error Something failed
```

### NUI contract (for UI devs)

#### Incoming NUI message

The Lua side sends:

- **action**: `"notify"`
- **message**: string
- **type**: `success|error|info|warning`

The UI listens via `window.addEventListener('message', ...)` and expects icon images at:

- `html/img/success.png`
- `html/img/error.png`
- `html/img/info.png`
- `html/img/warning.png`

### Notes

- This resource does **not** export a function; integrations should call the `notify` **client event**.
