-- Snowy UI example: the Rivals menu from the preview.
-- Callbacks only print / notify. Hook your own feature code into them.

local Snowy = loadstring(game:HttpGet("https://raw.githubusercontent.com/voidhub9-dotcom/Snowy-UI/Main/Source.lua"))()

local Window = Snowy:CreateWindow({
    Title = "Snowy Hub",
    Logo = "rbxassetid://123802801726537",
    Version = "v2.0",
    Credit = "Made by Snowy Studios",
    Badge = "Premium Users",      -- false to hide the badge
    HideName = true,              -- masks the display name in the user card
    ToggleKey = Enum.KeyCode.RightShift,
    ConfigFolder = "SnowyHub",
})

-- Home ---------------------------------------------------------------------
local Home = Window:Tab({ Name = "Home", Description = "Welcome back" })
local Info = Home:Section({ Name = "Session", Side = "Left" })
Info:Label("Snowy Hub loaded", "Press RightShift to hide or show the menu")
Info:Button({
    Name = "Copy Job ID",
    Description = "Copies this server's Job ID",
    ButtonText = "Copy",
    Callback = function()
        if setclipboard then
            setclipboard(game.JobId)
            Window:Notify({ Title = "Copied", Content = "Job ID is on your clipboard", Type = "success", Duration = 3 })
        else
            Window:Notify({ Title = "Not supported", Content = "Your executor has no setclipboard", Type = "error" })
        end
    end,
})

-- Combat (category with sub tabs) -------------------------------------------
local Combat = Window:Category({ Name = "Combat", Open = true })

local Aimbot = Combat:Tab({ Name = "Aimbot Settings", Description = "Lock-on, smoothing and targeting for every fight" })

local AimSec = Aimbot:Section({ Name = "Aimbot", Side = "Left" })
AimSec:Keybind({
    Name = "Aim Key",
    Description = "Hold this key to lock onto a target",
    Default = Enum.KeyCode.LeftAlt,
    Mode = "Hold",
    Flag = "AimKey",
    Callback = function(held)
        print("aim key held:", held)
    end,
})
AimSec:Dropdown({
    Name = "Aim Part",
    Description = "Which body part the aim snaps to",
    Options = { "Head", "UpperTorso", "HumanoidRootPart" },
    Default = "Head",
    Flag = "AimPart",
    Callback = function(part)
        print("aim part:", part)
    end,
})
AimSec:Toggle({
    Name = "Always Active",
    Description = "Locks on without holding the aim key",
    Default = true,
    Flag = "AlwaysActive",
    Callback = function(v) print("always active:", v) end,
})
AimSec:Toggle({
    Name = "Team Check",
    Description = "Skips players that are on your team",
    Default = false,
    Flag = "TeamCheck",
    Callback = function(v) print("team check:", v) end,
})

local Smooth = Aimbot:Section({ Name = "Smoothing", Side = "Right" })
Smooth:Dropdown({
    Name = "Response Curve",
    Description = "Snaps straight on, easier to control",
    Options = { "Instant", "Smooth", "Linear" },
    Default = "Instant",
    Color = Color3.fromRGB(242, 193, 78),
    Flag = "Curve",
    Callback = function(v) print("curve:", v) end,
})
Smooth:Slider({
    Name = "Smoothness",
    Description = "How slowly the aim moves to the target",
    Min = 0, Max = 50, Default = 20, Increment = 1,
    Flag = "Smoothness",
    Callback = function(v) print("smoothness:", v) end,
})
Smooth:Toggle({
    Name = "Show FOV",
    Description = "Draws the lock-on circle around your crosshair",
    Flag = "ShowFOV",
    Callback = function(v) print("show fov:", v) end,
})
Smooth:Slider({
    Name = "FOV Radius",
    Description = "Size of the lock-on circle",
    Min = 20, Max = 400, Default = 120, Increment = 5, Suffix = " px",
    Flag = "FOVRadius",
    Callback = function(v) print("fov radius:", v) end,
})
Smooth:Toggle({
    Name = "Sticky Target",
    Description = "Keeps the lock until the target dies",
    Flag = "Sticky",
    Callback = function(v) print("sticky:", v) end,
})

local Silent = Combat:Tab({ Name = "Silent Aim", Description = "Redirect shots without moving the camera" })
local SilentSec = Silent:Section({ Name = "Silent Aim" })
SilentSec:Toggle({ Name = "Enable Silent Aim", Description = "Turns silent aim on", Flag = "SilentAim" })
SilentSec:Slider({ Name = "Hit Chance", Description = "Chance each shot is redirected", Min = 0, Max = 100, Default = 100, Suffix = "%", Flag = "HitChance" })

local Trigger = Combat:Tab({ Name = "Triggerbot", Description = "Fires when your crosshair is on a target" })
local TrigSec = Trigger:Section({ Name = "Triggerbot" })
TrigSec:Toggle({ Name = "Enable Triggerbot", Description = "Shoots automatically when on target", Flag = "Triggerbot" })
TrigSec:Slider({ Name = "Delay", Description = "Wait before shooting", Min = 0, Max = 500, Default = 40, Increment = 10, Suffix = " ms", Flag = "TrigDelay" })

-- Visuals ----------------------------------------------------------------------
local Visuals = Window:Category({ Name = "Visuals" })
local ESP = Visuals:Tab({ Name = "ESP", Description = "See players through walls" })
local EspSec = ESP:Section({ Name = "ESP", Side = "Left" })
EspSec:Toggle({ Name = "Enable ESP", Description = "Master switch for all ESP", Flag = "ESP" })
EspSec:Dropdown({
    Name = "Show",
    Description = "What to draw on each player",
    Options = { "Box", "Name", "Distance", "Health", "Tracer" },
    Multi = true,
    Default = { "Box", "Name" },
    Flag = "ESPParts",
    Callback = function(list) print("esp parts:", table.concat(list, ", ")) end,
})
local EspFilter = ESP:Section({ Name = "Filters", Side = "Right" })
EspFilter:Toggle({ Name = "Exclude Friends", Description = "Hides your Roblox friends", Default = true, Flag = "ESPFriends" })
EspFilter:Slider({ Name = "Max Distance", Description = "Players further away are hidden", Min = 50, Max = 2000, Default = 1000, Increment = 50, Suffix = " m", Flag = "ESPDist" })

-- Configuration -----------------------------------------------------------
local Settings = Window:Category({ Name = "Configuration" })
local Cfg = Settings:Tab({ Name = "Configs", Description = "Save and load your settings" })
local CfgSec = Cfg:Section({ Name = "Config" })
local nameBox = CfgSec:Textbox({ Name = "Config Name", Description = "File name to save or load", Default = "default", Placeholder = "default" })
CfgSec:Button({
    Name = "Save Config",
    Description = "Writes every flag to a JSON file",
    ButtonText = "Save",
    Callback = function()
        local ok, err = Window:SaveConfig(nameBox:Get())
        Window:Notify({
            Title = ok and "Config saved" or "Save failed",
            Content = ok and ("Written to SnowyHub/" .. nameBox:Get() .. ".json") or tostring(err),
            Type = ok and "success" or "error",
        })
    end,
})
CfgSec:Button({
    Name = "Load Config",
    Description = "Applies a saved config",
    ButtonText = "Load",
    Callback = function()
        local ok, err = Window:LoadConfig(nameBox:Get())
        Window:Notify({
            Title = ok and "Config loaded" or "Load failed",
            Content = ok and nameBox:Get() or tostring(err),
            Type = ok and "success" or "error",
        })
    end,
})
local UiSec = Cfg:Section({ Name = "Interface", Side = "Right" })
UiSec:Keybind({
    Name = "Menu Key",
    Description = "Opens and closes this menu",
    Default = Enum.KeyCode.RightShift,
    Mode = "Toggle",
    ChangedCallback = function(key)
        if key then Window:SetToggleKey(key) end
    end,
})
UiSec:Button({
    Name = "Unload",
    Description = "Removes the menu completely",
    ButtonText = "Unload",
    Callback = function() Window:Destroy() end,
})

Window:Notify({ Title = "Snowy Hub loaded", Content = "Press RightShift to toggle the menu", Type = "success", Duration = 5 })
