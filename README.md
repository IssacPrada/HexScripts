# Hex Scripts UI Library

A custom Roblox UI library featuring an icon-rail sidebar, a live "Home" tab
(profile, server info, executor status, Discord, friends), tabs, sections,
buttons, toggles, sliders, textboxes, keybinds, dropdowns with refresh, a
theme/settings tab, an animated intro splash, a key system, tweened
animations, and UI sounds throughout.

## Files in this repo

| File | Description |
|---|---|
| [`UILibrary.lua`](./UILibrary.lua) | The library itself. Load it with `loadstring`. See [UILibrary.md](./UILibrary.md) for the full API reference. |
| [`Example.lua`](./Example.lua) | A complete working example wiring up the intro, key system, Home tab, Main tab, and Settings tab. See [Example.md](./Example.md). |

## Quick Start

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/IssacPrada/HexScripts/main/UILibrary.lua"))()

local Window = Library:CreateWindow({
    Title = "Hex Scripts",
    SubTitle = "v1.0.0",
    Logo = "rbxassetid://0", -- your uploaded logo decal id
})

Library:CreateHomeTab(Window, {
    HubName = "Hex Scripts",
    DiscordInvite = ".gg/yourinvite",
})

local Tab = Window:CreateTab("Main")
local Section = Tab:CreateSection("General")

Section:AddButton({
    Text = "Click Me",
    Callback = function()
        print("Clicked!")
    end,
})

Library:CreateSettingsTab(Window)
```

## Documentation

- **[UILibrary.md](./UILibrary.md)** — full API reference: every function, its
  parameters, return values, and a usage snippet.
- **[Example.md](./Example.md)** — walkthrough of the example script and the
  recommended load order (Intro → Key System → Window).

These docs are plain Markdown at the repo root, so they can be published
as-is with GitBook (GitBook can sync directly from a GitHub repo/branch).
Next step there: connect this repo in GitBook and set up the sidebar/nav
to point at UILibrary.md and Example.md.

## Notes & Limitations

- **Logo/icons**: this library never bakes images in for you — upload your
  logo/icons to Roblox as Decals and pass the resulting `rbxassetid://...`
  into `Logo`, `PlayIntro`'s `Image`, and `CreateTab`'s icon argument.
- **Key system**: the built-in `CreateKeySystem` is a UI shell only. The
  `CheckKey` callback in the example checks against a hardcoded string —
  that is a placeholder, not real security. Wire it up to your own backend
  or a key-check service for a real key system.
- **Home tab data**: player thumbnail, ping, server region, and friends data
  all use official Roblox APIs and are wrapped in `pcall`. If an executor or
  game blocks one of them, the corresponding stat falls back to `"N/A"`
  instead of erroring.
