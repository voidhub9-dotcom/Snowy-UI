# Snowy UI

Roblox UI library by Snowy Studios. Navy and cyan, a sidebar with folding categories, two-column collapsible sections, and animations for opening the menu, switching tabs and showing notifications.

## Load

```lua
local Snowy = loadstring(game:HttpGet("https://raw.githubusercontent.com/voidhub9-dotcom/Snowy-UI/Main/Source.lua"))()
```

A full working menu is in [`Example.lua`](Example.lua).

## Window

```lua
local Window = Snowy:CreateWindow({
    Title = "Snowy Hub",                     -- shown if no Logo
    Logo = "rbxassetid://123802801726537",   -- header wordmark and mobile button
    Version = "v2.0",
    Credit = "Made by Snowy Studios",
    Badge = "Premium Users",                 -- false hides it
    HideName = true,                         -- masks the name in the user card
    GameName = nil,                          -- defaults to the place name
    GameIcon = nil,                          -- defaults to the game's icon
    ToggleKey = Enum.KeyCode.RightShift,
    ConfigFolder = "SnowyHub",
    MobileButton = false,                    -- always on for touch devices
})
```

| Method | What it does |
|---|---|
| `Window:Tab(opts)` | Top-level sidebar item. `opts.Name`, `opts.Description`, `opts.Icon` (optional asset id) |
| `Window:Category(opts)` | Sidebar group that folds open. `opts.Name`, `opts.Icon`, `opts.Open` |
| `Category:Tab(opts)` | Sub-item inside a category, same options as `Window:Tab` |
| `Window:SelectTab(tab)` | Switches tab with the fade and slide animation |
| `Window:Toggle(state?)` | Shows or hides the menu with the open/close animation |
| `Window:Notify(opts)` | See Notifications |
| `Window:SaveConfig(name)` / `Window:LoadConfig(name)` | JSON in `ConfigFolder`. Needs `writefile`, `readfile`, `isfile` |
| `Window:ListConfigs()` | Names of saved configs |
| `Window:SetToggleKey(keyCode)` | Changes the menu key and the footer label |
| `Window:Destroy()` | Disconnects everything and removes the UI |

## Sections

```lua
local Section = Tab:Section({ Name = "Aimbot", Side = "Left", Icon = nil })
```

`Side` is `"Left"` or `"Right"`. If you leave it out, sections alternate. Click the header to fold a section.

## Elements

Every element with a `Flag` writes its value to `Snowy.Flags[flag]` and is saved in configs. Each returns an object with `:Set(value)` and `:Get()`.

```lua
Section:Toggle({ Name, Description, Default = false, Flag, Callback = function(state) end })

Section:Slider({ Name, Description, Min = 0, Max = 100, Default = 50, Increment = 1, Suffix = " px", Flag, Callback = function(value) end })

Section:Dropdown({ Name, Description, Options = { "A", "B" }, Default = "A", Multi = false, Icon = nil, Color = nil, Flag, Callback = function(value) end })
-- Multi = true: Default is a list, Callback gets a list. :SetOptions(list) replaces the options.

Section:Keybind({ Name, Description, Default = Enum.KeyCode.LeftAlt, Mode = "Hold" or "Toggle", Flag, Callback = function(active) end, ChangedCallback = function(key) end })
-- Click the chip, then press a key. Escape or Backspace clears it. :IsActive() returns the current state.

Section:Button({ Name, Description, ButtonText = "Run", Callback = function() end })

Section:Textbox({ Name, Description, Default = "", Placeholder = "Type...", OnlyEnter = false, Flag, Callback = function(text) end })

Section:Label(text, description)   -- returns an object with :Set(text)
```

## Notifications

```lua
Window:Notify({ Title = "Config saved", Content = "Written to SnowyHub/default.json", Type = "success", Duration = 5 })
```

`Type` is `"success"`, `"warning"`, `"error"` or `"info"`. Each one slides in from the right with an icon, the title, the step text and a bar.

Without `Progress`, the bar counts down and the corner shows the seconds left. With `Progress` (0 to 1, or 0 to 100) it shows a percentage, and you update it while the work runs:

```lua
local job = Window:Notify({ Title = "Server hop", Content = "Finding a server", Type = "info", Progress = 0 })
job:Update({ Progress = 0.6, Content = "Teleporting" })
job:Update({ Progress = 1, Content = "Done", Type = "success" })   -- closes itself 1.5 s after 100%
job:Dismiss()
```

`Snowy:Notify(opts)` works without a window.

## Other behaviour

- The search box filters rows in the current tab by name.
- The footer counts how many toggles are on.
- Drag the window by its header. On touch devices a logo button toggles the menu and can be dragged.
- The window scales down to fit small screens.
- Text uses Montserrat, which is built into Roblox.
- Icons are Lucide (ISC licence), loaded from the sprite sheets published in the `@rbxts/lucide` package. Pass a name such as `Icon = "swords"`; `Snowy.Icons` lists the 36 that are included. Any `rbxassetid://` also works.
