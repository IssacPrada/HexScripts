# `Example.lua` — Walkthrough

This file shows the recommended load order and demonstrates every element
type. Structure:

```
1. loadstring the library
2. define buildMainWindow()   -- builds Home / Main / Settings tabs
3. define startKeySystem()    -- shows the key screen, calls buildMainWindow() on success
4. Library:PlayIntro({ OnComplete = startKeySystem })
```

The intro plays first, then the key system, then the main window — matching
a typical script-hub flow.

## Step-by-step

**1. Load the library**
```lua
local Library = loadstring(game:HttpGet("<raw url>"))()
```

**2. `buildMainWindow()`** — creates the window, the Home tab (profile/server/
Discord/friends), a Main tab with one example of every element (button,
toggle, slider, textbox, keybind, dropdown with `:Refresh()`, multi-select
dropdown), and the built-in Settings tab.

**3. `startKeySystem()`** — calls `Library:CreateKeySystem`. Its `CheckKey`
callback checks the entered key against a hardcoded demo string
(`"HEX-DEMO-KEY"`) — **replace this with a real check** before shipping (see
the README's Notes section). `OnSuccess` is set to `buildMainWindow`, so the
window only appears after a valid key.

**4. `Library:PlayIntro(...)`** — runs first, with `OnComplete` wired to
`startKeySystem`.

## Things to customize before using this

- `Logo` in `CreateWindow` and `Image` in `PlayIntro` — set to your uploaded
  logo's `rbxassetid://`.
- `DiscordInvite` in `CreateHomeTab` — your real invite, or remove the field
  to hide the card.
- `GetKeyLink` and `CheckKey` in `CreateKeySystem` — your real key link and
  verification logic.
- The `loadstring(game:HttpGet(...))` URL at the top — point it at your
  hosted raw `UILibrary.lua` once it's on GitHub.
