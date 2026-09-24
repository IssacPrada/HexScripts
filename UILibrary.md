# `UILibrary.lua` — API Reference

Load the library once per script:

```lua
local Library = loadstring(game:HttpGet("<raw url to UILibrary.lua>"))()
```

Everything below is a method on the table returned by `loadstring`, or on the
objects that its methods return (`Window`, `Tab`, `Section`, and each element).

---

## `Library:CreateWindow(config)`

Creates the draggable main window. Returns a `Window` object.

| Field | Type | Default | Description |
|---|---|---|---|
| `Title` | string | `"UI Library"` | Bold title text in the top bar. |
| `SubTitle` | string | `""` | Smaller subtitle under the title. |
| `Logo` | string (`rbxassetid://`) | none | Optional square logo shown in the top-left icon badge. |
| `ToggleKey` | `Enum.KeyCode` | `Enum.KeyCode.RightControl` | Key that shows/hides the whole UI. |

```lua
local Window = Library:CreateWindow({
    Title = "Hex Scripts",
    SubTitle = "v1.0.0",
    Logo = "rbxassetid://123456789",
    ToggleKey = Enum.KeyCode.RightControl,
})
```

---

## `Window:CreateTab(name, icon)`

Adds an icon to the sidebar rail and a page to the content area. Returns a
`Tab` object. The first tab created is selected by default.

| Param | Type | Description |
|---|---|---|
| `name` | string | Tab name. Also used as the hover tooltip and, if no icon is given, the fallback letter badge. |
| `icon` | string (`rbxassetid://`), optional | Icon shown in the sidebar. Falls back to the first letter of `name` in a badge if omitted. |

```lua
local MainTab = Window:CreateTab("Main", "rbxassetid://123456789")
```

---

## `Tab:CreateSection(title)`

Adds a titled card to a tab's page for grouping elements. Returns a `Section`
object — call `Section:Add...` methods on it (below).

```lua
local Section = MainTab:CreateSection("General")
```

---

## Elements

Every `Add...` method is called on a `Section`. Most accept a `Flag` — when
set, the element's current value is mirrored into `Library.Flags[Flag]` on
every change, so you can read every setting from one table.

### `Section:AddButton(opts)`

| Field | Type | Description |
|---|---|---|
| `Text` | string | Button label. |
| `Callback` | function | Called on click. |

Returns the underlying `TextButton` instance.

### `Section:AddToggle(opts)`

| Field | Type | Description |
|---|---|---|
| `Text` | string | Label. |
| `Default` | boolean | Initial state. |
| `Flag` | string, optional | Key in `Library.Flags`. |
| `Callback` | function(state) | Called on change, and once immediately if `Default` is `true`. |

Returns a `Toggle` object: `Toggle:Set(bool)`, `Toggle:Get() -> bool`.

### `Section:AddSlider(opts)`

| Field | Type | Description |
|---|---|---|
| `Text` | string | Label. |
| `Min`, `Max` | number | Range. |
| `Default` | number | Initial value. |
| `Decimals` | number, optional | Decimal places to round to (default `0`). |
| `Flag` | string, optional | |
| `Callback` | function(value) | |

Returns a `Slider` object: `Slider:Set(number)`, `Slider:Get() -> number`.
Draggable by click-and-hold or single click on the track.

### `Section:AddTextbox(opts)`

| Field | Type | Description |
|---|---|---|
| `Text` | string | Label. |
| `Placeholder` | string | Placeholder text. |
| `Default` | string, optional | Initial text. |
| `Flag` | string, optional | |
| `Callback` | function(text, enterPressed) | Called on focus lost. |

Returns a `Textbox` object: `Textbox:Set(string)`, `Textbox:Get() -> string`.

### `Section:AddKeybind(opts)`

| Field | Type | Description |
|---|---|---|
| `Text` | string | Label. |
| `Default` | `Enum.KeyCode` | Initial bound key. |
| `Flag` | string, optional | |
| `Callback` | function(keyCode) | Called when the user rebinds the key. |
| `OnPress` | function | Called every time the bound key is pressed. |

Returns a `Keybind` object: `Keybind:Set(Enum.KeyCode)`, `Keybind:Get()`.
Click the key button, then press any key to rebind.

### `Section:AddDropdown(opts)`

| Field | Type | Description |
|---|---|---|
| `Text` | string | Label. |
| `Options` | array of strings | Options list. |
| `Multi` | boolean, optional | Enables multi-select (checkbox-style, selection persists open). |
| `Default` | string or table | Initial selection (string for single, table for multi). |
| `Flag` | string, optional | |
| `Callback` | function(selection) | Called on selection change. |

Returns a `Dropdown` object:
- `Dropdown:Get()`
- `Dropdown:Set(value)`
- `Dropdown:Refresh(newOptions)` — rebuilds the option list in place, e.g. for a live player list.
- `Dropdown:Open()` / `Dropdown:Close()`

```lua
local PlayerDropdown = Section:AddDropdown({
    Text = "Select Player",
    Options = {},
    Callback = function(selection) print(selection) end,
})

local function refresh()
    local names = {}
    for _, plr in ipairs(game.Players:GetPlayers()) do
        table.insert(names, plr.Name)
    end
    PlayerDropdown:Refresh(names)
end
refresh()
game.Players.PlayerAdded:Connect(refresh)
```

---

## `Library:CreateHomeTab(window, config)`

Builds a ready-made "Home" tab: player profile (avatar + greeting), a Server
card (player count, latency, region, session timer, copyable join script), an
executor/status card, an optional Discord card, and a Friends card (in
server / online / offline / all counts).

| Field | Type | Description |
|---|---|---|
| `HubName` | string, optional | Shown under the player's name. |
| `DiscordInvite` | string, optional | e.g. `".gg/yourinvite"`. Omit to hide the Discord card entirely. Clicking copies the full invite link to the clipboard. |
| `Icon` | string (`rbxassetid://`), optional | Icon for the Home tab in the sidebar. |

```lua
Library:CreateHomeTab(Window, {
    HubName = "Hex Scripts",
    DiscordInvite = ".gg/yourinvite",
})
```

**Data sources & fallbacks** (all wrapped in `pcall`, degrade to `"N/A"` /
`"Unknown"` if blocked):
- Avatar — `Players:GetUserThumbnailAsync`
- Latency — `Stats.Network.ServerStatsItem["Data Ping"]`
- Region — `LocalizationService:GetCountryRegionForPlayerAsync`
- Friends online / in-server — `Player:GetFriendsOnline`
- Total friend count — `https://friends.roblox.com/v1/users/<id>/friends/count` via `game:HttpGet`

---

## `Library:CreateSettingsTab(window)`

Adds a ready-made "Settings" tab with:
- an **Accent Hue Shift** slider that live-updates every gradient/accent
  color currently in the window,
- a **Reduce Motion** toggle (sets `Library._reduceMotion`; check this flag
  in your own animations if you add more),
- a **Toggle UI Visibility** keybind row.

```lua
Library:CreateSettingsTab(Window)
```

---

## `Library:PlayIntro(config)`

Plays a splash animation before your window appears: screen blurs in, your
logo pops in centered, swishes to the left, your title text fades in beside
it, and the title's gradient slowly shifts to the theme's red accent — then
everything fades out.

| Field | Type | Description |
|---|---|---|
| `Image` | string (`rbxassetid://`) | Your logo, uploaded as a Decal. |
| `Text` | string | Title text revealed next to the logo (e.g. `"Hex Scripts"`). |
| `OnComplete` | function | Called once the intro finishes — build your key system / window here. |

```lua
Library:PlayIntro({
    Image = "rbxassetid://123456789",
    Text = "Hex Scripts",
    OnComplete = function()
        -- show key system or build the window here
    end,
})
```

---

## `Library:CreateKeySystem(config)`

Shows a key-entry screen. This is a UI shell only — `CheckKey` is where you
plug in real verification.

| Field | Type | Description |
|---|---|---|
| `Title`, `Subtitle` | string | Header text. |
| `GetKeyLink` | string, optional | If set, shows a "Get Key" button that copies this link to the clipboard. |
| `CheckKey` | function(key) -> boolean | Your verification logic. |
| `OnSuccess` | function | Called once a valid key is submitted. |

```lua
Library:CreateKeySystem({
    Title = "Hex Scripts",
    Subtitle = "Enter your key to continue",
    CheckKey = function(key)
        -- replace with a real check against your own backend
        return key == "HEX-DEMO-KEY"
    end,
    OnSuccess = function()
        -- build the window here
    end,
})
```

---

## `Library.Flags`

A plain table. Every element created with a `Flag` mirrors its current value
here, e.g. `Library.Flags.WalkSpeed`. Useful for reading every setting at
once (e.g. to serialize a config), though this library does not include
file-based save/load — see the README's Notes section.

## `Library.Theme`

The color/font table used throughout. Editing values here before creating a
window changes the whole theme; `CreateSettingsTab`'s hue-shift slider edits
`Theme.Accent1` / `Theme.Accent2` at runtime and repaints every gradient.
