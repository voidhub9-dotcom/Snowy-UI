--[[
    Snowy UI
    Roblox UI library by Snowy Studios.

    local Snowy = loadstring(game:HttpGet("https://raw.githubusercontent.com/voidhub9-dotcom/Snowy-UI/Main/Source.lua"))()
    See Readme.md for the full API.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local Library = {
    Version = "1.0.0",
    Flags = {},
    Options = {},
    Windows = {},
}

local Theme = {
    Background   = Color3.fromRGB(20, 34, 48),
    Card         = Color3.fromRGB(24, 40, 56),
    CardHeader   = Color3.fromRGB(26, 43, 60),
    Field        = Color3.fromRGB(19, 33, 49),
    Line         = Color3.fromRGB(34, 52, 71),
    Line2        = Color3.fromRGB(42, 62, 83),
    Text         = Color3.fromRGB(233, 240, 247),
    SubText      = Color3.fromRGB(196, 207, 218),
    Muted        = Color3.fromRGB(139, 157, 176),
    Accent       = Color3.fromRGB(92, 201, 226),
    Track        = Color3.fromRGB(42, 58, 75),
    ToggleOff    = Color3.fromRGB(51, 70, 90),
    KnobOff      = Color3.fromRGB(200, 210, 220),
    Selected     = Color3.fromRGB(29, 48, 67),
    SelectedLine = Color3.fromRGB(44, 69, 96),
    Yellow       = Color3.fromRGB(242, 193, 78),
    BadgeBg      = Color3.fromRGB(90, 74, 22),
    BadgeLine    = Color3.fromRGB(125, 102, 32),
    Success      = Color3.fromRGB(70, 217, 154),
    Warning      = Color3.fromRGB(255, 181, 71),
    Error        = Color3.fromRGB(255, 95, 109),
    Info         = Color3.fromRGB(92, 201, 226),
}
Library.Theme = Theme

local FONT_FAMILY = "rbxasset://fonts/families/Montserrat.json"
local MONO_FAMILY = "rbxasset://fonts/families/RobotoMono.json"

local function F(weight)
    return Font.new(FONT_FAMILY, weight or Enum.FontWeight.Medium, Enum.FontStyle.Normal)
end
local W_MED = Enum.FontWeight.Medium
local W_SEMI = Enum.FontWeight.SemiBold
local W_BOLD = Enum.FontWeight.Bold
local W_XBOLD = Enum.FontWeight.ExtraBold

local WINDOW_W, WINDOW_H = 916, 640
local HEADER_H, FOOTER_H, SIDEBAR_W = 80, 36, 222

---------------------------------------------------------------------------
-- helpers
---------------------------------------------------------------------------

local function New(class, props, children)
    local obj = Instance.new(class)
    if props then
        for k, v in pairs(props) do
            if k ~= "Parent" then
                obj[k] = v
            end
        end
    end
    if children then
        for _, child in ipairs(children) do
            child.Parent = obj
        end
    end
    if props and props.Parent then
        obj.Parent = props.Parent
    end
    return obj
end

local function Corner(radius)
    return New("UICorner", { CornerRadius = UDim.new(0, radius) })
end

local function Stroke(color, thickness, transparency)
    return New("UIStroke", {
        Color = color,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
end

local function Padding(top, bottom, left, right)
    return New("UIPadding", {
        PaddingTop = UDim.new(0, top or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
        PaddingLeft = UDim.new(0, left or 0),
        PaddingRight = UDim.new(0, right or 0),
    })
end

local function List(direction, spacing, hAlign, vAlign)
    return New("UIListLayout", {
        FillDirection = direction or Enum.FillDirection.Vertical,
        Padding = UDim.new(0, spacing or 0),
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = hAlign or Enum.HorizontalAlignment.Left,
        VerticalAlignment = vAlign or Enum.VerticalAlignment.Top,
    })
end

local function Label(props)
    local base = {
        BackgroundTransparency = 1,
        FontFace = F(W_MED),
        TextColor3 = Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Text = "",
    }
    for k, v in pairs(props) do
        base[k] = v
    end
    return New("TextLabel", base)
end

local function Tween(obj, time, props, style, direction)
    local tween = TweenService:Create(
        obj,
        TweenInfo.new(time, style or Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out),
        props
    )
    tween:Play()
    return tween
end

local function Clamp(v, a, b)
    if v < a then return a end
    if v > b then return b end
    return v
end

local function Round(v, step)
    if not step or step <= 0 then
        return v
    end
    return math.floor(v / step + 0.5) * step
end

local function Decimals(step)
    if not step or step >= 1 then
        return 0
    end
    local s = tostring(step)
    local dot = string.find(s, "%.")
    if not dot then
        return 0
    end
    return #s - dot
end

local function FormatNumber(v, step)
    local d = Decimals(step)
    if d == 0 then
        return tostring(math.floor(v + 0.5))
    end
    return string.format("%." .. d .. "f", v)
end

local function KeyName(key)
    if key == nil then
        return "None"
    end
    if typeof(key) == "EnumItem" then
        return key.Name
    end
    return tostring(key)
end

local function PrettyKey(key)
    local name = KeyName(key)
    local map = {
        LeftAlt = "LeftAlt", RightAlt = "RightAlt",
        LeftShift = "LeftShift", RightShift = "RIGHT SHIFT",
        LeftControl = "LeftCtrl", RightControl = "RIGHT CTRL",
        MouseButton1 = "MB1", MouseButton2 = "MB2", MouseButton3 = "MB3",
    }
    return map[name] or name
end

-- two-bar chevron, rotation 0 points down, -90 points right
local function Chevron(parent, size, color)
    local holder = New("Frame", {
        Name = "Chevron",
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(size, size),
        Parent = parent,
    })
    local len = math.floor(size * 0.48 + 0.5)
    New("Frame", {
        BackgroundColor3 = color,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.36, 0, 0.5, 0),
        Size = UDim2.fromOffset(len, 2),
        Rotation = 45,
        Parent = holder,
    }, { Corner(1) })
    New("Frame", {
        BackgroundColor3 = color,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.64, 0, 0.5, 0),
        Size = UDim2.fromOffset(len, 2),
        Rotation = -45,
        Parent = holder,
    }, { Corner(1) })
    return holder
end

local function Cross(parent, size, color, thickness)
    local holder = New("Frame", {
        Name = "Cross",
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(size, size),
        Parent = parent,
    })
    for _, rot in ipairs({ 45, -45 }) do
        New("Frame", {
            BackgroundColor3 = color,
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(math.floor(size * 1.2), thickness or 2),
            Rotation = rot,
            Parent = holder,
        }, { Corner(1) })
    end
    return holder
end

local function Check(parent, size, color)
    local holder = New("Frame", {
        Name = "Check",
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(size, size),
        Parent = parent,
    })
    New("Frame", {
        BackgroundColor3 = color,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.33, 0, 0.62, 0),
        Size = UDim2.fromOffset(math.floor(size * 0.45), 2),
        Rotation = 45,
        Parent = holder,
    }, { Corner(1) })
    New("Frame", {
        BackgroundColor3 = color,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.6, 0, 0.48, 0),
        Size = UDim2.fromOffset(math.floor(size * 0.8), 2),
        Rotation = -50,
        Parent = holder,
    }, { Corner(1) })
    return holder
end

local function Icon(parent, image, size, color)
    return New("ImageLabel", {
        Name = "Icon",
        BackgroundTransparency = 1,
        Image = image,
        ImageColor3 = color or Theme.SubText,
        Size = UDim2.fromOffset(size, size),
        ScaleType = Enum.ScaleType.Fit,
        Parent = parent,
    })
end

local function GuiParent()
    local ok, hui = pcall(function()
        return gethui()
    end)
    if ok and typeof(hui) == "Instance" then
        return hui
    end
    local okCore, core = pcall(function()
        return game:GetService("CoreGui")
    end)
    if okCore and core then
        return core
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local function SafeParent(gui)
    local target = GuiParent()
    local ok = pcall(function()
        gui.Parent = target
    end)
    if not ok or gui.Parent == nil then
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
end

local function Draggable(handle, target, onDrag)
    local dragging, startPos, startInput = false, nil, nil
    local conns = {}
    table.insert(conns, handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            startInput = input.Position
            startPos = target.Position
            local endConn
            endConn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    endConn:Disconnect()
                end
            end)
        end
    end))
    table.insert(conns, UserInputService.InputChanged:Connect(function(input)
        if not dragging then
            return
        end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - startInput
            target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            if onDrag then
                onDrag()
            end
        end
    end))
    return conns
end

---------------------------------------------------------------------------
-- window
---------------------------------------------------------------------------

function Library:CreateWindow(opts)
    opts = opts or {}
    local Window = {
        Tabs = {},
        Categories = {},
        Elements = {},
        Connections = {},
        Visible = true,
        ToggleKey = opts.ToggleKey or Enum.KeyCode.RightShift,
        ConfigFolder = opts.ConfigFolder or "SnowyUI",
        ActiveTab = nil,
    }
    table.insert(Library.Windows, Window)

    local function Connect(signal, fn)
        local c = signal:Connect(fn)
        table.insert(Window.Connections, c)
        return c
    end

    local Gui = New("ScreenGui", {
        Name = "SnowyUI_" .. HttpService:GenerateGUID(false):sub(1, 8),
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999,
    })
    pcall(function()
        if syn and syn.protect_gui then
            syn.protect_gui(Gui)
        end
    end)
    SafeParent(Gui)
    Window.Gui = Gui

    local Main = New("Frame", {
        Name = "Main",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(WINDOW_W, WINDOW_H),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        Parent = Gui,
    }, { Corner(14), Stroke(Theme.Line2, 1) })
    Window.Main = Main

    local Scale = New("UIScale", { Scale = 1, Parent = Main })
    local function TargetScale()
        local cam = workspace.CurrentCamera
        local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)
        return math.min(1, (vp.X - 24) / WINDOW_W, (vp.Y - 24) / WINDOW_H)
    end
    Scale.Scale = TargetScale()
    if workspace.CurrentCamera then
        Connect(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"), function()
            if Window.Visible then
                Scale.Scale = TargetScale()
            end
        end)
    end

    -- header -------------------------------------------------------------
    local Header = New("Frame", {
        Name = "Header",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, HEADER_H),
        Parent = Main,
    })
    New("Frame", {
        BackgroundColor3 = Theme.Line,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -1),
        Size = UDim2.new(1, 0, 0, 1),
        Parent = Header,
    })

    local brandX = 22
    if opts.Logo then
        New("ImageLabel", {
            Name = "Logo",
            BackgroundTransparency = 1,
            Image = opts.Logo,
            ScaleType = Enum.ScaleType.Fit,
            Position = UDim2.fromOffset(brandX, 10),
            Size = UDim2.fromOffset(92, 44),
            Parent = Header,
        })
    else
        Label({
            Text = string.upper(opts.Title or "Snowy Hub"),
            FontFace = F(W_XBOLD),
            TextSize = 20,
            Position = UDim2.fromOffset(brandX, 14),
            Size = UDim2.fromOffset(170, 30),
            Parent = Header,
        })
    end
    local versionText = opts.Version or "v1.0"
    if opts.Credit then
        versionText = versionText .. "  ·  " .. opts.Credit
    end
    Label({
        Text = versionText,
        TextSize = 10,
        FontFace = F(W_SEMI),
        TextColor3 = Theme.Muted,
        Position = UDim2.fromOffset(brandX + 2, 56),
        Size = UDim2.fromOffset(180, 14),
        Parent = Header,
    })
    New("Frame", {
        BackgroundColor3 = Theme.Line2,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(212, 23),
        Size = UDim2.fromOffset(1, 34),
        Parent = Header,
    })

    -- game chip
    local gameName = opts.GameName
    if not gameName then
        local ok, info = pcall(function()
            return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
        end)
        gameName = (ok and info and info.Name) or "Roblox"
    end
    local GameChip = New("Frame", {
        Name = "GameChip",
        BackgroundColor3 = Theme.Field,
        Position = UDim2.fromOffset(228, 22),
        Size = UDim2.fromOffset(0, 36),
        AutomaticSize = Enum.AutomaticSize.X,
        Parent = Header,
    }, { Corner(10), Stroke(Theme.Line2), Padding(0, 0, 6, 12), List(Enum.FillDirection.Horizontal, 8, nil, Enum.VerticalAlignment.Center) })
    New("ImageLabel", {
        BackgroundColor3 = Theme.Card,
        Image = opts.GameIcon or ("rbxthumb://type=GameIcon&id=" .. tostring(game.GameId) .. "&w=150&h=150"),
        Size = UDim2.fromOffset(24, 24),
        Parent = GameChip,
    }, { Corner(6) })
    Label({
        Text = gameName,
        FontFace = F(W_SEMI),
        TextSize = 13.5,
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.fromOffset(0, 36),
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = GameChip,
    }, nil)
    New("UISizeConstraint", { MaxSize = Vector2.new(260, 36), Parent = GameChip })

    local function HeaderButton(xOffset)
        local b = New("TextButton", {
            AutoButtonColor = false,
            Text = "",
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, xOffset, 0.5, 0),
            Size = UDim2.fromOffset(36, 36),
            BackgroundColor3 = Theme.Field,
            Parent = Header,
        }, { Corner(10), Stroke(Theme.Line2) })
        Connect(b.MouseEnter, function() Tween(b, 0.15, { BackgroundColor3 = Theme.Selected }) end)
        Connect(b.MouseLeave, function() Tween(b, 0.15, { BackgroundColor3 = Theme.Field }) end)
        return b
    end

    local CloseBtn = HeaderButton(-14)
    local x = Cross(CloseBtn, 11, Theme.SubText, 2)
    x.AnchorPoint = Vector2.new(0.5, 0.5)
    x.Position = UDim2.fromScale(0.5, 0.5)

    local MinBtn = HeaderButton(-58)
    New("Frame", {
        BackgroundColor3 = Theme.SubText,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(12, 2),
        Parent = MinBtn,
    }, { Corner(1) })

    local SearchBox = New("Frame", {
        Name = "Search",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -102, 0.5, 0),
        Size = UDim2.fromOffset(200, 36),
        BackgroundColor3 = Theme.Field,
        Parent = Header,
    }, { Corner(10), Stroke(Theme.Line2) })
    local lens = New("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(13, 11),
        Size = UDim2.fromOffset(11, 11),
        Parent = SearchBox,
    }, { Corner(6), Stroke(Theme.SubText, 2) })
    New("Frame", {
        BackgroundColor3 = Theme.SubText,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromOffset(13, 13),
        Size = UDim2.fromOffset(6, 2),
        Rotation = 45,
        Parent = lens,
    }, { Corner(1) })
    local SearchInput = New("TextBox", {
        BackgroundTransparency = 1,
        ClearTextOnFocus = false,
        PlaceholderText = "Search...",
        PlaceholderColor3 = Theme.Muted,
        Text = "",
        TextColor3 = Theme.Text,
        FontFace = F(W_MED),
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(36, 0),
        Size = UDim2.new(1, -44, 1, 0),
        Parent = SearchBox,
    })

    -- sidebar ------------------------------------------------------------
    local Sidebar = New("Frame", {
        Name = "Sidebar",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, HEADER_H),
        Size = UDim2.new(0, SIDEBAR_W, 1, -(HEADER_H + FOOTER_H)),
        Parent = Main,
    })
    New("Frame", {
        BackgroundColor3 = Theme.Line,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -1, 0, 0),
        Size = UDim2.new(0, 1, 1, 0),
        Parent = Sidebar,
    })
    local Nav = New("ScrollingFrame", {
        Name = "Nav",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(12, 14),
        Size = UDim2.new(1, -20, 1, -100),
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Line2,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Parent = Sidebar,
    }, { List(Enum.FillDirection.Vertical, 2), Padding(0, 6, 0, 6) })

    -- user card
    local UserCard = New("Frame", {
        Name = "User",
        BackgroundColor3 = Theme.Card,
        Position = UDim2.new(0, 12, 1, -72),
        Size = UDim2.new(1, -24, 0, 58),
        Parent = Sidebar,
    }, { Corner(12), Stroke(Theme.Line2) })
    New("ImageLabel", {
        BackgroundColor3 = Theme.Field,
        Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(LocalPlayer.UserId) .. "&w=150&h=150",
        Position = UDim2.fromOffset(10, 12),
        Size = UDim2.fromOffset(34, 34),
        Parent = UserCard,
    }, { Corner(9) })
    local displayName = LocalPlayer.DisplayName
    if opts.HideName ~= false then
        displayName = string.sub(displayName, 1, 1) .. string.rep("*", math.min(14, math.max(6, #displayName - 1)))
    end
    Label({
        Text = displayName,
        FontFace = F(W_BOLD),
        TextSize = 13,
        Position = UDim2.fromOffset(54, 9),
        Size = UDim2.new(1, -60, 0, 18),
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = UserCard,
    })
    if opts.Badge ~= false then
        local badge = New("Frame", {
            BackgroundColor3 = Theme.BadgeBg,
            Position = UDim2.fromOffset(54, 30),
            Size = UDim2.fromOffset(0, 18),
            AutomaticSize = Enum.AutomaticSize.X,
            Parent = UserCard,
        }, { Corner(5), Stroke(Theme.BadgeLine), Padding(0, 0, 7, 7) })
        Label({
            Text = opts.Badge or "Premium Users",
            FontFace = F(W_BOLD),
            TextSize = 10.5,
            TextColor3 = Theme.Yellow,
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.fromOffset(0, 18),
            Parent = badge,
        })
    end

    -- body -----------------------------------------------------------------
    local Body = New("CanvasGroup", {
        Name = "Body",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(SIDEBAR_W, HEADER_H),
        Size = UDim2.new(1, -SIDEBAR_W, 1, -(HEADER_H + FOOTER_H)),
        Parent = Main,
    })
    local TitleRow = New("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(14, 16),
        Size = UDim2.new(1, -36, 0, 28),
        Parent = Body,
    }, { List(Enum.FillDirection.Horizontal, 12, nil, Enum.VerticalAlignment.Bottom) })
    local PageTitle = Label({
        Text = "",
        FontFace = F(W_BOLD),
        TextSize = 19.5,
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.fromOffset(0, 28),
        Parent = TitleRow,
    })
    local PageDesc = Label({
        Text = "",
        FontFace = F(W_MED),
        TextSize = 11.5,
        TextColor3 = Theme.Muted,
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.fromOffset(0, 22),
        Parent = TitleRow,
    })
    local Pages = New("Frame", {
        Name = "Pages",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(12, 58),
        Size = UDim2.new(1, -24, 1, -58),
        Parent = Body,
    })

    -- footer ---------------------------------------------------------------
    local Footer = New("Frame", {
        Name = "Footer",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 1, -FOOTER_H),
        Size = UDim2.new(1, 0, 0, FOOTER_H),
        Parent = Main,
    })
    New("Frame", {
        BackgroundColor3 = Theme.Line,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 1),
        Parent = Footer,
    })
    local ring = New("Frame", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 18, 0.5, 0),
        Size = UDim2.fromOffset(14, 14),
        Parent = Footer,
    }, { Corner(7), Stroke(Theme.Accent, 2) })
    New("Frame", {
        BackgroundColor3 = Theme.Accent,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(4, 4),
        Parent = ring,
    }, { Corner(2) })
    local ActiveCount = Label({
        Text = "0",
        FontFace = F(W_BOLD),
        TextSize = 13,
        Position = UDim2.fromOffset(40, 0),
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        Parent = Footer,
    })
    local ActiveText = Label({
        Text = "active",
        FontFace = F(W_SEMI),
        TextSize = 13,
        TextColor3 = Theme.SubText,
        Position = UDim2.fromOffset(60, 0),
        Size = UDim2.new(0, 60, 1, 0),
        Parent = Footer,
    })
    local KeyChip = New("Frame", {
        BackgroundColor3 = Color3.fromRGB(15, 27, 40),
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.fromOffset(0, 24),
        AutomaticSize = Enum.AutomaticSize.X,
        Parent = Footer,
    }, { Corner(6), Stroke(Color3.fromRGB(58, 79, 102)), Padding(0, 0, 10, 10) })
    local KeyChipText = Label({
        Text = string.upper(PrettyKey(Window.ToggleKey)),
        FontFace = Font.new(MONO_FAMILY, W_BOLD),
        TextSize = 11,
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.fromOffset(0, 24),
        Parent = KeyChip,
    })

    -- overlays -------------------------------------------------------------
    local Overlay = New("Frame", {
        Name = "Overlay",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Visible = false,
        Parent = Gui,
    })
    local OverlayCatcher = New("TextButton", {
        Text = "",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Parent = Overlay,
    })
    local NotifyHolder = New("Frame", {
        Name = "Notifications",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -20, 1, -20),
        Size = UDim2.new(0, 320, 1, -40),
        Parent = Gui,
    }, { List(Enum.FillDirection.Vertical, 10, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Bottom) })

    local FadeCover = New("Frame", {
        Name = "Fade",
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = 0,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 50,
        Parent = Main,
    }, { Corner(14) })

    ---------------------------------------------------------------------------
    -- active counter
    ---------------------------------------------------------------------------
    function Window:UpdateActive()
        local n = 0
        for _, el in ipairs(Window.Elements) do
            if el.Type == "Toggle" and el.Value == true then
                n = n + 1
            end
        end
        ActiveCount.Text = tostring(n)
        ActiveText.Position = UDim2.fromOffset(40 + ActiveCount.TextBounds.X + 6, 0)
    end

    ---------------------------------------------------------------------------
    -- open / close animation
    ---------------------------------------------------------------------------
    local MobileButton

    local function Show()
        Window.Visible = true
        Main.Visible = true
        local target = TargetScale()
        Scale.Scale = target * 0.94
        FadeCover.BackgroundTransparency = 0
        FadeCover.Visible = true
        Tween(Scale, 0.45, { Scale = target }, Enum.EasingStyle.Back)
        local t = Tween(FadeCover, 0.35, { BackgroundTransparency = 1 })
        t.Completed:Connect(function()
            if Window.Visible then
                FadeCover.Visible = false
            end
        end)
    end

    local function Hide()
        Window.Visible = false
        Overlay.Visible = false
        FadeCover.Visible = true
        local target = TargetScale()
        Tween(FadeCover, 0.2, { BackgroundTransparency = 0 })
        local t = Tween(Scale, 0.22, { Scale = target * 0.94 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        t.Completed:Connect(function()
            if not Window.Visible then
                Main.Visible = false
            end
        end)
    end

    function Window:Toggle(state)
        if state == nil then
            state = not Window.Visible
        end
        if state then
            Show()
        else
            Hide()
        end
    end

    Connect(CloseBtn.MouseButton1Click, function()
        Window:Toggle(false)
        if MobileButton == nil then
            Window:Notify({
                Title = "Hidden",
                Content = "Press " .. PrettyKey(Window.ToggleKey) .. " to open the menu again",
                Type = "info",
                Duration = 4,
            })
        end
    end)
    Connect(MinBtn.MouseButton1Click, function()
        Window:Toggle(false)
    end)

    Connect(UserInputService.InputBegan, function(input, gpe)
        if gpe then
            return
        end
        if input.KeyCode == Window.ToggleKey then
            Window:Toggle()
        end
    end)

    for _, c in ipairs(Draggable(Header, Main)) do
        table.insert(Window.Connections, c)
    end

    if UserInputService.TouchEnabled or opts.MobileButton then
        MobileButton = New("ImageButton", {
            Name = "MobileToggle",
            AutoButtonColor = false,
            BackgroundColor3 = Theme.Background,
            Image = opts.Logo or "",
            ScaleType = Enum.ScaleType.Fit,
            Position = UDim2.new(0, 16, 0.5, -26),
            Size = UDim2.fromOffset(58, 52),
            Parent = Gui,
        }, { Corner(14), Stroke(Theme.Line2), Padding(6, 6, 6, 6) })
        local moved = false
        local conns = Draggable(MobileButton, MobileButton, function() moved = true end)
        for _, c in ipairs(conns) do
            table.insert(Window.Connections, c)
        end
        Connect(MobileButton.MouseButton1Down, function() moved = false end)
        Connect(MobileButton.MouseButton1Click, function()
            if not moved then
                Window:Toggle()
            end
        end)
    end

    ---------------------------------------------------------------------------
    -- navigation / tabs
    ---------------------------------------------------------------------------
    local navOrder = 0
    local function NextOrder()
        navOrder = navOrder + 1
        return navOrder
    end

    local function StyleNav(tab, active)
        local btn = tab.Button
        if tab.Nested then
            Tween(btn, 0.2, { BackgroundTransparency = active and 0 or 1 })
            Tween(tab.Stroke, 0.2, { Transparency = active and 0 or 1 })
            Tween(tab.Text, 0.2, { TextColor3 = active and Theme.Text or Color3.fromRGB(169, 183, 197) })
            tab.Text.FontFace = F(active and W_BOLD or W_SEMI)
        else
            Tween(btn, 0.2, { BackgroundTransparency = active and 0 or 1 })
            Tween(tab.Stroke, 0.2, { Transparency = active and 0 or 1 })
            Tween(tab.Text, 0.2, { TextColor3 = active and Theme.Text or Theme.SubText })
            tab.Text.FontFace = F(active and W_BOLD or W_SEMI)
        end
        if tab.IconImage then
            Tween(tab.IconImage, 0.2, { ImageColor3 = active and (tab.Nested and Theme.Text or Theme.Accent) or Theme.SubText })
        end
    end

    local switching = false
    function Window:SelectTab(tab)
        if Window.ActiveTab == tab or switching then
            return
        end
        local previous = Window.ActiveTab
        Window.ActiveTab = tab
        Overlay.Visible = false
        if previous then
            StyleNav(previous, false)
        end
        StyleNav(tab, true)
        if tab.Category and not tab.Category.Open then
            tab.Category:SetOpen(true)
        end
        if SearchInput.Text ~= "" then
            SearchInput.Text = ""
        end

        if previous == nil then
            tab.Page.Visible = true
            PageTitle.Text = tab.Name
            PageDesc.Text = tab.Description or ""
            return
        end

        switching = true
        local out = Tween(Body, 0.12, { GroupTransparency = 1 }, Enum.EasingStyle.Quad)
        out.Completed:Connect(function()
            previous.Page.Visible = false
            tab.Page.Visible = true
            tab.Page.CanvasPosition = Vector2.new(0, 0)
            PageTitle.Text = tab.Name
            PageDesc.Text = tab.Description or ""
            Pages.Position = UDim2.fromOffset(12, 68)
            Tween(Pages, 0.35, { Position = UDim2.fromOffset(12, 58) })
            Tween(Body, 0.28, { GroupTransparency = 0 })
            switching = false
        end)
    end

    local function BuildTab(tabOpts, category)
        tabOpts = tabOpts or {}
        local Tab = {
            Name = tabOpts.Name or "Tab",
            Description = tabOpts.Description,
            Nested = category ~= nil,
            Category = category,
            Sections = {},
            Rows = {},
        }

        local parent = category and category.SubList or Nav
        local btn = New("TextButton", {
            Name = Tab.Name,
            AutoButtonColor = false,
            Text = "",
            BackgroundColor3 = Theme.Selected,
            BackgroundTransparency = 1,
            Size = category and UDim2.new(1, 0, 0, 34) or UDim2.new(1, 0, 0, 43),
            LayoutOrder = NextOrder(),
            Parent = parent,
        }, { Corner(10) })
        local stroke = Stroke(Theme.SelectedLine)
        stroke.Transparency = 1
        stroke.Parent = btn
        local textX = 12
        if tabOpts.Icon then
            local img = Icon(btn, tabOpts.Icon, category and 15 or 18, Theme.SubText)
            img.AnchorPoint = Vector2.new(0, 0.5)
            img.Position = UDim2.new(0, 12, 0.5, 0)
            Tab.IconImage = img
            textX = category and 36 or 43
        end
        Tab.Text = Label({
            Text = Tab.Name,
            FontFace = F(W_SEMI),
            TextSize = category and 12.5 or 14.5,
            TextColor3 = category and Color3.fromRGB(169, 183, 197) or Theme.SubText,
            Position = UDim2.fromOffset(textX, 0),
            Size = UDim2.new(1, -textX - 8, 1, 0),
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = btn,
        })
        Tab.Button = btn
        Tab.Stroke = stroke

        Connect(btn.MouseEnter, function()
            if Window.ActiveTab ~= Tab then
                Tween(Tab.Text, 0.15, { TextColor3 = Theme.Text })
            end
        end)
        Connect(btn.MouseLeave, function()
            if Window.ActiveTab ~= Tab then
                Tween(Tab.Text, 0.15, { TextColor3 = category and Color3.fromRGB(169, 183, 197) or Theme.SubText })
            end
        end)
        Connect(btn.MouseButton1Click, function()
            Window:SelectTab(Tab)
        end)

        local page = New("ScrollingFrame", {
            Name = Tab.Name,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.fromScale(1, 1),
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Theme.Line2,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            Visible = false,
            Parent = Pages,
        }, { Padding(0, 16, 0, 8) })
        local LeftCol = New("Frame", {
            Name = "Left",
            BackgroundTransparency = 1,
            Size = UDim2.new(0.5, -7, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Parent = page,
        }, { List(Enum.FillDirection.Vertical, 14) })
        local RightCol = New("Frame", {
            Name = "Right",
            BackgroundTransparency = 1,
            Position = UDim2.new(0.5, 7, 0, 0),
            Size = UDim2.new(0.5, -7, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Parent = page,
        }, { List(Enum.FillDirection.Vertical, 14) })
        Tab.Page = page
        Tab.Left = LeftCol
        Tab.Right = RightCol

        local sectionCount = 0

        function Tab:Section(secOpts)
            secOpts = secOpts or {}
            sectionCount = sectionCount + 1
            local side = secOpts.Side
            if side == nil then
                side = (sectionCount % 2 == 1) and "Left" or "Right"
            end
            local column = (string.lower(side) == "right") and RightCol or LeftCol

            local Section = { Name = secOpts.Name or "Section", Rows = {}, Open = true }
            local card = New("Frame", {
                Name = Section.Name,
                BackgroundColor3 = Theme.Card,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                LayoutOrder = sectionCount,
                Parent = column,
            }, { Corner(14), Stroke(Theme.Line), List(Enum.FillDirection.Vertical, 0) })

            local head = New("TextButton", {
                Name = "Header",
                AutoButtonColor = false,
                Text = "",
                BackgroundColor3 = Theme.CardHeader,
                Size = UDim2.new(1, 0, 0, 48),
                LayoutOrder = 1,
                Parent = card,
            }, { Corner(14) })
            local cover = New("Frame", {
                BackgroundColor3 = Theme.CardHeader,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 0, 1, -14),
                Size = UDim2.new(1, 0, 0, 14),
                Parent = head,
            })
            New("Frame", {
                BackgroundColor3 = Theme.Line,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 0, 1, -1),
                Size = UDim2.new(1, 0, 0, 1),
                Parent = head,
            })
            local titleX = 20
            if secOpts.Icon then
                local img = Icon(head, secOpts.Icon, 19, Theme.Accent)
                img.AnchorPoint = Vector2.new(0, 0.5)
                img.Position = UDim2.new(0, 20, 0.5, 0)
                titleX = 50
            end
            Label({
                Text = Section.Name,
                FontFace = F(W_BOLD),
                TextSize = 15,
                Position = UDim2.fromOffset(titleX, 0),
                Size = UDim2.new(1, -titleX - 40, 1, 0),
                Parent = head,
            })
            local chev = Chevron(head, 14, Theme.SubText)
            chev.AnchorPoint = Vector2.new(1, 0.5)
            chev.Position = UDim2.new(1, -18, 0.5, 0)

            local body = New("Frame", {
                Name = "Body",
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                LayoutOrder = 2,
                Parent = card,
            }, { List(Enum.FillDirection.Vertical, 0), Padding(2, 6, 0, 0) })
            Section.Card = card
            Section.Body = body

            local function SetOpen(open)
                Section.Open = open
                body.Visible = open
                cover.Visible = open
                Tween(chev, 0.25, { Rotation = open and 0 or -90 })
            end
            Section.SetOpen = function(_, open) SetOpen(open) end
            Connect(head.MouseButton1Click, function()
                SetOpen(not Section.Open)
            end)

            local rowOrder = 0

            local function MakeRow(name, desc, tall)
                rowOrder = rowOrder + 1
                local row = New("Frame", {
                    Name = name,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    LayoutOrder = rowOrder,
                    Parent = body,
                }, { Padding(13, 11, 22, 16) })
                local textHolder = New("Frame", {
                    Name = "Text",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, tall and -70 or -140, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Parent = row,
                }, { List(Enum.FillDirection.Vertical, 4) })
                local title = Label({
                    Text = name,
                    FontFace = F(W_SEMI),
                    TextSize = 14,
                    TextColor3 = Color3.fromRGB(240, 245, 250),
                    Size = UDim2.new(1, 0, 0, 18),
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    LayoutOrder = 1,
                    Parent = textHolder,
                })
                if desc and desc ~= "" then
                    Label({
                        Text = desc,
                        FontFace = F(W_MED),
                        TextSize = 11.5,
                        TextColor3 = Theme.Muted,
                        TextWrapped = true,
                        Size = UDim2.new(1, 0, 0, 0),
                        AutomaticSize = Enum.AutomaticSize.Y,
                        LineHeight = 1.1,
                        LayoutOrder = 2,
                        Parent = textHolder,
                    })
                end
                local entry = { Name = string.lower(name), Frame = row, Section = Section }
                table.insert(Section.Rows, entry)
                table.insert(Tab.Rows, entry)
                return row, title, textHolder
            end

            local function Register(el, flag)
                el.Window = Window
                table.insert(Window.Elements, el)
                if flag then
                    el.Flag = flag
                    Library.Options[flag] = el
                    Library.Flags[flag] = el.Value
                end
            end

            local function Fire(el, ...)
                if el.Callback then
                    local args = { ... }
                    task.spawn(function()
                        local ok, err = pcall(el.Callback, table.unpack(args))
                        if not ok then
                            warn("[Snowy UI] " .. tostring(el.Name) .. " callback error: " .. tostring(err))
                        end
                    end)
                end
            end

            local function ControlAnchor(row, inst)
                inst.AnchorPoint = Vector2.new(1, 0.5)
                inst.Position = UDim2.new(1, 0, 0.5, 0)
                inst.Parent = row
            end

            ---------------------------------------------------------------
            -- Toggle
            ---------------------------------------------------------------
            function Section:Toggle(o)
                o = o or {}
                local el = { Type = "Toggle", Name = o.Name or "Toggle", Value = o.Default == true, Callback = o.Callback }
                local row = MakeRow(el.Name, o.Description)
                local sw = New("TextButton", {
                    AutoButtonColor = false,
                    Text = "",
                    Size = UDim2.fromOffset(40, 24),
                    BackgroundColor3 = el.Value and Theme.Accent or Theme.ToggleOff,
                }, { Corner(12) })
                ControlAnchor(row, sw)
                local knob = New("Frame", {
                    BackgroundColor3 = el.Value and Color3.new(1, 1, 1) or Theme.KnobOff,
                    AnchorPoint = Vector2.new(0, 0.5),
                    Position = UDim2.new(0, el.Value and 20 or 4, 0.5, 0),
                    Size = UDim2.fromOffset(16, 16),
                    Parent = sw,
                }, { Corner(8) })

                function el:Set(v, silent)
                    v = v == true
                    el.Value = v
                    Tween(sw, 0.22, { BackgroundColor3 = v and Theme.Accent or Theme.ToggleOff })
                    Tween(knob, 0.25, { Position = UDim2.new(0, v and 20 or 4, 0.5, 0), BackgroundColor3 = v and Color3.new(1, 1, 1) or Theme.KnobOff })
                    if el.Flag then Library.Flags[el.Flag] = v end
                    Window:UpdateActive()
                    if not silent then Fire(el, v) end
                end
                function el:Get() return el.Value end

                Connect(sw.MouseButton1Click, function() el:Set(not el.Value) end)
                Register(el, o.Flag)
                Window:UpdateActive()
                if el.Value and o.FireOnStart then Fire(el, true) end
                return el
            end

            ---------------------------------------------------------------
            -- Slider
            ---------------------------------------------------------------
            function Section:Slider(o)
                o = o or {}
                local min, max = o.Min or 0, o.Max or 100
                local step = o.Increment or 1
                local suffix = o.Suffix or ""
                local el = { Type = "Slider", Name = o.Name or "Slider", Callback = o.Callback, Min = min, Max = max }
                el.Value = Clamp(Round(o.Default or min, step), min, max)

                local row, _, textHolder = MakeRow(el.Name, o.Description, true)
                textHolder.Size = UDim2.new(1, -70, 0, 0)

                local vbox = New("TextBox", {
                    ClearTextOnFocus = false,
                    BackgroundColor3 = Theme.Field,
                    AnchorPoint = Vector2.new(1, 0),
                    Position = UDim2.new(1, 0, 0, 0),
                    Size = UDim2.fromOffset(0, 28),
                    AutomaticSize = Enum.AutomaticSize.X,
                    FontFace = F(W_SEMI),
                    TextSize = 12.5,
                    TextColor3 = Theme.Text,
                    Text = "",
                    Parent = row,
                }, { Corner(8), Stroke(Theme.Line2), Padding(0, 0, 9, 9), New("UISizeConstraint", { MinSize = Vector2.new(44, 28) }) })

                local trackWrap = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 70, 0, 18),
                    LayoutOrder = 10,
                    Parent = textHolder,
                })
                local track = New("TextButton", {
                    AutoButtonColor = false,
                    Text = "",
                    BackgroundColor3 = Theme.Track,
                    AnchorPoint = Vector2.new(0, 1),
                    Position = UDim2.new(0, 0, 1, -2),
                    Size = UDim2.new(1, 0, 0, 4),
                    Parent = trackWrap,
                }, { Corner(2) })
                local hit = New("TextButton", {
                    Text = "",
                    BackgroundTransparency = 1,
                    AnchorPoint = Vector2.new(0, 0.5),
                    Position = UDim2.new(0, 0, 0.5, 0),
                    Size = UDim2.new(1, 0, 0, 22),
                    Parent = track,
                })
                local fill = New("Frame", {
                    BackgroundColor3 = Theme.Accent,
                    BorderSizePixel = 0,
                    Size = UDim2.fromScale(0, 1),
                    Parent = track,
                }, { Corner(2) })
                local thumb = New("Frame", {
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.fromScale(0, 0.5),
                    Size = UDim2.fromOffset(14, 14),
                    ZIndex = 2,
                    Parent = track,
                }, { Corner(7) })

                local function Render(animate)
                    local pct = (max == min) and 0 or (el.Value - min) / (max - min)
                    vbox.Text = FormatNumber(el.Value, step) .. suffix
                    if animate then
                        Tween(fill, 0.12, { Size = UDim2.fromScale(pct, 1) })
                        Tween(thumb, 0.12, { Position = UDim2.fromScale(pct, 0.5) })
                    else
                        fill.Size = UDim2.fromScale(pct, 1)
                        thumb.Position = UDim2.fromScale(pct, 0.5)
                    end
                end

                function el:Set(v, silent)
                    v = tonumber(v)
                    if not v then
                        Render(false)
                        return
                    end
                    v = Clamp(Round(v, step), min, max)
                    local changed = v ~= el.Value
                    el.Value = v
                    Render(true)
                    if el.Flag then Library.Flags[el.Flag] = v end
                    if changed and not silent then Fire(el, v) end
                end
                function el:Get() return el.Value end

                local dragging = false
                local function FromX(px)
                    local pct = Clamp((px - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
                    el:Set(min + (max - min) * pct)
                end
                local function Begin(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = true
                        FromX(input.Position.X)
                        Tween(thumb, 0.15, { Size = UDim2.fromOffset(17, 17) })
                    end
                end
                Connect(track.InputBegan, Begin)
                Connect(hit.InputBegan, Begin)
                Connect(UserInputService.InputChanged, function(input)
                    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        FromX(input.Position.X)
                    end
                end)
                Connect(UserInputService.InputEnded, function(input)
                    if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
                        dragging = false
                        Tween(thumb, 0.15, { Size = UDim2.fromOffset(14, 14) })
                    end
                end)
                Connect(vbox.FocusLost, function()
                    local n = tonumber((string.gsub(vbox.Text, "[^%d%.%-]", "")))
                    if n then el:Set(n) else Render(false) end
                end)

                Render(false)
                Register(el, o.Flag)
                return el
            end

            ---------------------------------------------------------------
            -- Dropdown
            ---------------------------------------------------------------
            function Section:Dropdown(o)
                o = o or {}
                local el = {
                    Type = "Dropdown",
                    Name = o.Name or "Dropdown",
                    Callback = o.Callback,
                    Options = o.Options or {},
                    Multi = o.Multi == true,
                }
                if el.Multi then
                    el.Value = {}
                    if type(o.Default) == "table" then
                        for _, v in ipairs(o.Default) do el.Value[v] = true end
                    end
                else
                    el.Value = o.Default
                    if el.Value == nil then el.Value = el.Options[1] end
                end

                local row = MakeRow(el.Name, o.Description)
                local holder = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.fromOffset(0, 30),
                    AutomaticSize = Enum.AutomaticSize.X,
                }, { List(Enum.FillDirection.Horizontal, 8, nil, Enum.VerticalAlignment.Center) })
                ControlAnchor(row, holder)
                local valueColor = o.Color or Color3.fromRGB(207, 227, 238)
                local chip = New("TextButton", {
                    AutoButtonColor = false,
                    Text = "",
                    BackgroundColor3 = Theme.Field,
                    Size = UDim2.fromOffset(0, 30),
                    AutomaticSize = Enum.AutomaticSize.X,
                    LayoutOrder = 1,
                    Parent = holder,
                }, { Corner(9), Stroke(Theme.Line2), Padding(0, 0, 10, 11), List(Enum.FillDirection.Horizontal, 7, nil, Enum.VerticalAlignment.Center) })
                if o.Icon then
                    Icon(chip, o.Icon, 15, o.Color or Theme.Accent)
                end
                local chipText = Label({
                    Text = "",
                    FontFace = F(W_SEMI),
                    TextSize = 12.5,
                    TextColor3 = valueColor,
                    Size = UDim2.fromOffset(0, 30),
                    AutomaticSize = Enum.AutomaticSize.X,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    Parent = chip,
                })
                New("UISizeConstraint", { MaxSize = Vector2.new(84, 30), Parent = chipText })
                local chev = Chevron(holder, 13, Theme.SubText)
                chev.LayoutOrder = 2

                local function Display()
                    if el.Multi then
                        local picked = {}
                        for _, opt in ipairs(el.Options) do
                            if el.Value[opt] then table.insert(picked, tostring(opt)) end
                        end
                        if #picked == 0 then return "None" end
                        if #picked == 1 then return picked[1] end
                        return picked[1] .. " +" .. tostring(#picked - 1)
                    end
                    return el.Value ~= nil and tostring(el.Value) or "None"
                end

                local function Output()
                    if el.Multi then
                        local list = {}
                        for _, opt in ipairs(el.Options) do
                            if el.Value[opt] then table.insert(list, opt) end
                        end
                        return list
                    end
                    return el.Value
                end

                local listFrame
                local function CloseList()
                    if listFrame then
                        local f = listFrame
                        listFrame = nil
                        Tween(chev, 0.2, { Rotation = 0 })
                        local t = Tween(f, 0.12, { Size = UDim2.fromOffset(f.Size.X.Offset, 0) })
                        t.Completed:Connect(function() f:Destroy() end)
                        Overlay.Visible = false
                    end
                end

                local function OpenList()
                    if listFrame then CloseList() return end
                    for _, child in ipairs(Overlay:GetChildren()) do
                        if child ~= OverlayCatcher then child:Destroy() end
                    end
                    Overlay.Visible = true
                    Tween(chev, 0.2, { Rotation = 180 })
                    local s = Scale.Scale
                    local width = math.max(170, chip.AbsoluteSize.X / s + 26)
                    local height = math.min(#el.Options * 32 + 10, 230)
                    local frame = New("Frame", {
                        BackgroundColor3 = Theme.Card,
                        ClipsDescendants = true,
                        Position = UDim2.fromOffset(chip.AbsolutePosition.X, chip.AbsolutePosition.Y + chip.AbsoluteSize.Y + 6 * s),
                        Size = UDim2.fromOffset(width, 0),
                        Parent = Overlay,
                    }, { Corner(10), Stroke(Theme.Line2), New("UIScale", { Scale = s }) })
                    local scroller = New("ScrollingFrame", {
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        Size = UDim2.fromScale(1, 1),
                        CanvasSize = UDim2.new(),
                        AutomaticCanvasSize = Enum.AutomaticSize.Y,
                        ScrollBarThickness = 3,
                        ScrollBarImageColor3 = Theme.Line2,
                        Parent = frame,
                    }, { List(Enum.FillDirection.Vertical, 2), Padding(5, 5, 5, 5) })
                    for i, opt in ipairs(el.Options) do
                        local selected
                        if el.Multi then selected = el.Value[opt] == true else selected = el.Value == opt end
                        local b = New("TextButton", {
                            AutoButtonColor = false,
                            Text = "",
                            BackgroundColor3 = Theme.Selected,
                            BackgroundTransparency = selected and 0 or 1,
                            Size = UDim2.new(1, 0, 0, 30),
                            LayoutOrder = i,
                            Parent = scroller,
                        }, { Corner(7) })
                        local t = Label({
                            Text = tostring(opt),
                            FontFace = F(selected and W_BOLD or W_SEMI),
                            TextSize = 12.5,
                            TextColor3 = selected and Theme.Accent or Theme.SubText,
                            Position = UDim2.fromOffset(10, 0),
                            Size = UDim2.new(1, -34, 1, 0),
                            TextTruncate = Enum.TextTruncate.AtEnd,
                            Parent = b,
                        })
                        if selected then
                            local c = Check(b, 12, Theme.Accent)
                            c.AnchorPoint = Vector2.new(1, 0.5)
                            c.Position = UDim2.new(1, -10, 0.5, 0)
                        end
                        Connect(b.MouseEnter, function() if t.TextColor3 ~= Theme.Accent then Tween(t, 0.12, { TextColor3 = Theme.Text }) end end)
                        Connect(b.MouseLeave, function() if t.TextColor3 ~= Theme.Accent then Tween(t, 0.12, { TextColor3 = Theme.SubText }) end end)
                        Connect(b.MouseButton1Click, function()
                            if el.Multi then
                                el.Value[opt] = not el.Value[opt]
                                el:Set(el.Value)
                                CloseList()
                                OpenList()
                            else
                                el:Set(opt)
                                CloseList()
                            end
                        end)
                    end
                    listFrame = frame
                    Tween(frame, 0.22, { Size = UDim2.fromOffset(width, height) })
                end

                function el:Set(v, silent)
                    if el.Multi then
                        local set = {}
                        if type(v) == "table" then
                            for k, val in pairs(v) do
                                if type(k) == "number" then set[val] = true elseif val then set[k] = true end
                            end
                        end
                        el.Value = set
                    else
                        el.Value = v
                    end
                    chipText.Text = Display()
                    if el.Flag then Library.Flags[el.Flag] = Output() end
                    if not silent then Fire(el, Output()) end
                end
                function el:Get() return Output() end
                function el:SetOptions(list)
                    el.Options = list or {}
                    if not el.Multi and el.Value ~= nil and not table.find(el.Options, el.Value) then
                        el.Value = el.Options[1]
                    end
                    chipText.Text = Display()
                end

                Connect(chip.MouseButton1Click, OpenList)
                Connect(OverlayCatcher.MouseButton1Click, CloseList)
                chipText.Text = Display()
                Register(el, o.Flag)
                if el.Flag then Library.Flags[el.Flag] = Output() end
                return el
            end

            ---------------------------------------------------------------
            -- Keybind
            ---------------------------------------------------------------
            function Section:Keybind(o)
                o = o or {}
                local el = {
                    Type = "Keybind",
                    Name = o.Name or "Keybind",
                    Callback = o.Callback,
                    Changed = o.ChangedCallback,
                    Value = o.Default,
                    Mode = o.Mode or "Toggle",
                    Active = false,
                }
                local row = MakeRow(el.Name, o.Description)
                local holder = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.fromOffset(0, 30),
                    AutomaticSize = Enum.AutomaticSize.X,
                }, { List(Enum.FillDirection.Horizontal, 8, nil, Enum.VerticalAlignment.Center) })
                ControlAnchor(row, holder)
                local chip = New("TextButton", {
                    AutoButtonColor = false,
                    Text = "",
                    BackgroundColor3 = Theme.Field,
                    Size = UDim2.fromOffset(0, 30),
                    AutomaticSize = Enum.AutomaticSize.X,
                    Parent = holder,
                }, { Corner(9), Stroke(Theme.Line2), Padding(0, 0, 10, 11), List(Enum.FillDirection.Horizontal, 7, nil, Enum.VerticalAlignment.Center) })
                Label({
                    Text = string.upper(el.Mode),
                    FontFace = F(W_BOLD),
                    TextSize = 9.5,
                    TextColor3 = Theme.Muted,
                    Size = UDim2.fromOffset(0, 30),
                    AutomaticSize = Enum.AutomaticSize.X,
                    LayoutOrder = 1,
                    Parent = chip,
                })
                local keyText = Label({
                    Text = PrettyKey(el.Value),
                    FontFace = F(W_BOLD),
                    TextSize = 12.5,
                    TextColor3 = Color3.fromRGB(207, 227, 238),
                    Size = UDim2.fromOffset(0, 30),
                    AutomaticSize = Enum.AutomaticSize.X,
                    LayoutOrder = 2,
                    Parent = chip,
                })

                local listening = false
                local function Matches(input)
                    if el.Value == nil then return false end
                    if el.Value.EnumType == Enum.KeyCode then
                        return input.KeyCode == el.Value
                    end
                    return input.UserInputType == el.Value
                end

                function el:Set(v, silent)
                    if type(v) == "string" then
                        if v == "None" or v == "" then
                            v = nil
                        else
                            local ok, key = pcall(function() return Enum.KeyCode[v] end)
                            if ok and key then
                                v = key
                            else
                                local ok2, uit = pcall(function() return Enum.UserInputType[v] end)
                                v = (ok2 and uit) or nil
                            end
                        end
                    end
                    el.Value = v
                    keyText.Text = PrettyKey(v)
                    if el.Flag then Library.Flags[el.Flag] = KeyName(v) end
                    if el.Changed and not silent then
                        task.spawn(pcall, el.Changed, v)
                    end
                end
                function el:Get() return el.Value end
                function el:IsActive() return el.Active end

                Connect(chip.MouseButton1Click, function()
                    if listening then return end
                    listening = true
                    keyText.Text = "..."
                    Tween(chip, 0.15, { BackgroundColor3 = Theme.Selected })
                end)
                Connect(UserInputService.InputBegan, function(input, gpe)
                    if listening then
                        local key
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then
                                key = "None"
                            else
                                key = input.KeyCode
                            end
                        elseif input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3 then
                            key = input.UserInputType
                        end
                        if key ~= nil then
                            listening = false
                            Tween(chip, 0.15, { BackgroundColor3 = Theme.Field })
                            el:Set(key)
                        end
                        return
                    end
                    if gpe and input.UserInputType == Enum.UserInputType.Keyboard then return end
                    if Matches(input) then
                        if el.Mode == "Hold" then
                            el.Active = true
                            Fire(el, true)
                        else
                            el.Active = not el.Active
                            Fire(el, el.Active)
                        end
                    end
                end)
                Connect(UserInputService.InputEnded, function(input)
                    if el.Mode == "Hold" and el.Active and Matches(input) then
                        el.Active = false
                        Fire(el, false)
                    end
                end)

                Register(el, o.Flag)
                if el.Flag then Library.Flags[el.Flag] = KeyName(el.Value) end
                return el
            end

            ---------------------------------------------------------------
            -- Button
            ---------------------------------------------------------------
            function Section:Button(o)
                o = o or {}
                local el = { Type = "Button", Name = o.Name or "Button", Callback = o.Callback }
                local row = MakeRow(el.Name, o.Description)
                local b = New("TextButton", {
                    AutoButtonColor = false,
                    BackgroundColor3 = Theme.Field,
                    Size = UDim2.fromOffset(0, 30),
                    AutomaticSize = Enum.AutomaticSize.X,
                    FontFace = F(W_BOLD),
                    TextSize = 12.5,
                    TextColor3 = Theme.Accent,
                    Text = o.ButtonText or "Run",
                }, { Corner(9), Stroke(Theme.Line2), Padding(0, 0, 14, 14) })
                ControlAnchor(row, b)
                Connect(b.MouseEnter, function() Tween(b, 0.15, { BackgroundColor3 = Theme.Selected }) end)
                Connect(b.MouseLeave, function() Tween(b, 0.15, { BackgroundColor3 = Theme.Field }) end)
                Connect(b.MouseButton1Click, function()
                    Tween(b, 0.08, { BackgroundColor3 = Theme.SelectedLine }).Completed:Connect(function()
                        Tween(b, 0.2, { BackgroundColor3 = Theme.Field })
                    end)
                    Fire(el)
                end)
                Register(el, nil)
                return el
            end

            ---------------------------------------------------------------
            -- Textbox
            ---------------------------------------------------------------
            function Section:Textbox(o)
                o = o or {}
                local el = { Type = "Textbox", Name = o.Name or "Textbox", Callback = o.Callback, Value = o.Default or "" }
                local row = MakeRow(el.Name, o.Description)
                local box = New("TextBox", {
                    ClearTextOnFocus = false,
                    BackgroundColor3 = Theme.Field,
                    Size = UDim2.fromOffset(120, 30),
                    FontFace = F(W_SEMI),
                    TextSize = 12.5,
                    TextColor3 = Theme.Text,
                    PlaceholderText = o.Placeholder or "Type...",
                    PlaceholderColor3 = Theme.Muted,
                    Text = el.Value,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                }, { Corner(9), Stroke(Theme.Line2), Padding(0, 0, 10, 10) })
                ControlAnchor(row, box)
                function el:Set(v, silent)
                    el.Value = tostring(v or "")
                    box.Text = el.Value
                    if el.Flag then Library.Flags[el.Flag] = el.Value end
                    if not silent then Fire(el, el.Value) end
                end
                function el:Get() return el.Value end
                Connect(box.FocusLost, function(enter)
                    if o.OnlyEnter and not enter then
                        box.Text = el.Value
                        return
                    end
                    el:Set(box.Text)
                end)
                Register(el, o.Flag)
                return el
            end

            ---------------------------------------------------------------
            -- Label / Paragraph
            ---------------------------------------------------------------
            function Section:Label(text, desc)
                local el = { Type = "Label", Name = tostring(text) }
                local _, title = MakeRow(el.Name, desc, true)
                function el:Set(newText)
                    el.Name = tostring(newText)
                    title.Text = el.Name
                end
                return el
            end

            table.insert(Tab.Sections, Section)
            return Section
        end

        if category then
            table.insert(category.Tabs, Tab)
        end
        table.insert(Window.Tabs, Tab)
        if Window.ActiveTab == nil then
            Window:SelectTab(Tab)
        end
        return Tab
    end

    function Window:Tab(tabOpts)
        return BuildTab(tabOpts, nil)
    end

    function Window:Category(catOpts)
        catOpts = catOpts or {}
        local Category = { Name = catOpts.Name or "Category", Tabs = {}, Open = false }
        local btn = New("TextButton", {
            Name = Category.Name,
            AutoButtonColor = false,
            Text = "",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 43),
            LayoutOrder = NextOrder(),
            Parent = Nav,
        }, { Corner(10) })
        local textX = 12
        local img
        if catOpts.Icon then
            img = Icon(btn, catOpts.Icon, 18, Theme.SubText)
            img.AnchorPoint = Vector2.new(0, 0.5)
            img.Position = UDim2.new(0, 12, 0.5, 0)
            textX = 43
        end
        local text = Label({
            Text = Category.Name,
            FontFace = F(W_SEMI),
            TextSize = 14.5,
            TextColor3 = Theme.SubText,
            Position = UDim2.fromOffset(textX, 0),
            Size = UDim2.new(1, -textX - 34, 1, 0),
            Parent = btn,
        })
        local chev = Chevron(btn, 14, Theme.SubText)
        chev.AnchorPoint = Vector2.new(1, 0.5)
        chev.Position = UDim2.new(1, -12, 0.5, 0)
        chev.Rotation = -90

        local subWrap = New("Frame", {
            Name = Category.Name .. "_Subs",
            BackgroundTransparency = 1,
            ClipsDescendants = true,
            Size = UDim2.new(1, 0, 0, 0),
            LayoutOrder = NextOrder(),
            Parent = Nav,
        })
        New("Frame", {
            BackgroundColor3 = Theme.Line2,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(24, 0),
            Size = UDim2.new(0, 1, 1, -4),
            Parent = subWrap,
        })
        local subList = New("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(32, 0),
            Size = UDim2.new(1, -32, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Parent = subWrap,
        }, { List(Enum.FillDirection.Vertical, 2) })
        Category.SubList = subList

        -- tabs created inside a category are ordered by their own list, not the nav order
        local function Height()
            return #Category.Tabs * 36 + 4
        end

        function Category:SetOpen(open)
            Category.Open = open
            Tween(chev, 0.25, { Rotation = open and 0 or -90 })
            Tween(subWrap, 0.3, { Size = UDim2.new(1, 0, 0, open and Height() or 0) })
            Tween(text, 0.2, { TextColor3 = open and Theme.Text or Theme.SubText })
            text.FontFace = F(open and W_BOLD or W_SEMI)
            if img then
                Tween(img, 0.2, { ImageColor3 = open and Theme.Accent or Theme.SubText })
            end
        end

        function Category:Tab(tabOpts)
            local t = BuildTab(tabOpts, Category)
            if Category.Open then
                subWrap.Size = UDim2.new(1, 0, 0, Height())
            end
            return t
        end

        Connect(btn.MouseButton1Click, function()
            Category:SetOpen(not Category.Open)
        end)

        table.insert(Window.Categories, Category)
        if catOpts.Open then
            Category:SetOpen(true)
        end
        return Category
    end

    ---------------------------------------------------------------------------
    -- search
    ---------------------------------------------------------------------------
    Connect(SearchInput:GetPropertyChangedSignal("Text"), function()
        local tab = Window.ActiveTab
        if not tab then return end
        local q = string.lower(SearchInput.Text)
        for _, section in ipairs(tab.Sections) do
            local any = false
            for _, entry in ipairs(section.Rows) do
                local show = q == "" or string.find(entry.Name, q, 1, true) ~= nil
                entry.Frame.Visible = show
                if show then any = true end
            end
            section.Card.Visible = any or q == ""
        end
    end)

    ---------------------------------------------------------------------------
    -- notifications
    ---------------------------------------------------------------------------
    function Window:Notify(n)
        return Library:Notify(n, NotifyHolder)
    end

    ---------------------------------------------------------------------------
    -- config
    ---------------------------------------------------------------------------
    local function CanFiles()
        return type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
    end

    function Window:SaveConfig(name)
        name = name or "default"
        if not CanFiles() then
            return false, "executor has no file functions"
        end
        local data = {}
        for flag, el in pairs(Library.Options) do
            if el.Window == Window then
                local v = Library.Flags[flag]
                if el.Type == "Keybind" then v = KeyName(el.Value) end
                data[flag] = v
            end
        end
        local ok, err = pcall(function()
            if type(isfolder) == "function" and not isfolder(Window.ConfigFolder) and type(makefolder) == "function" then
                makefolder(Window.ConfigFolder)
            end
            writefile(Window.ConfigFolder .. "/" .. name .. ".json", HttpService:JSONEncode(data))
        end)
        return ok, err
    end

    function Window:LoadConfig(name)
        name = name or "default"
        if not CanFiles() then
            return false, "executor has no file functions"
        end
        local path = Window.ConfigFolder .. "/" .. name .. ".json"
        if not isfile(path) then
            return false, "no config named " .. name
        end
        local ok, data = pcall(function()
            return HttpService:JSONDecode(readfile(path))
        end)
        if not ok or type(data) ~= "table" then
            return false, "config file is not valid JSON"
        end
        for flag, v in pairs(data) do
            local el = Library.Options[flag]
            if el and el.Set and el.Window == Window then
                pcall(el.Set, el, v)
            end
        end
        return true
    end

    function Window:ListConfigs()
        local out = {}
        if type(listfiles) ~= "function" or type(isfolder) ~= "function" or not isfolder(Window.ConfigFolder) then
            return out
        end
        for _, path in ipairs(listfiles(Window.ConfigFolder)) do
            local file = string.match(path, "([^/\\]+)%.json$")
            if file then table.insert(out, file) end
        end
        return out
    end

    function Window:SetToggleKey(key)
        Window.ToggleKey = key
        KeyChipText.Text = string.upper(PrettyKey(key))
    end

    function Window:Destroy()
        for _, c in ipairs(Window.Connections) do
            pcall(function() c:Disconnect() end)
        end
        Window.Connections = {}
        for flag, el in pairs(Library.Options) do
            if el.Window == Window then
                Library.Options[flag] = nil
                Library.Flags[flag] = nil
            end
        end
        Gui:Destroy()
    end

    Show()
    return Window
end

---------------------------------------------------------------------------
-- notifications (also usable without a window)
---------------------------------------------------------------------------

local SharedNotifyHolder
local function GetNotifyHolder()
    if SharedNotifyHolder and SharedNotifyHolder.Parent then
        return SharedNotifyHolder
    end
    local gui = New("ScreenGui", {
        Name = "SnowyUI_Notify",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 1000,
    })
    SafeParent(gui)
    SharedNotifyHolder = New("Frame", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -20, 1, -20),
        Size = UDim2.new(0, 320, 1, -40),
        Parent = gui,
    }, { List(Enum.FillDirection.Vertical, 10, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Bottom) })
    return SharedNotifyHolder
end

function Library:Notify(n, holder)
    n = n or {}
    holder = holder or GetNotifyHolder()
    local kind = string.lower(n.Type or "info")
    local color = Theme.Info
    if kind == "success" then color = Theme.Success
    elseif kind == "warning" or kind == "warn" then color = Theme.Warning
    elseif kind == "error" then color = Theme.Error end
    local duration = n.Duration or 5

    local slot = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = holder,
    })
    local card = New("Frame", {
        BackgroundColor3 = Theme.Card,
        Position = UDim2.fromOffset(360, 0),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ClipsDescendants = true,
        Parent = slot,
    }, { Corner(12), Stroke(Theme.Line2), Padding(12, 14, 12, 12) })
    New("UIGradient", {
        Color = ColorSequence.new(color:Lerp(Theme.Card, 0.78), Theme.Card),
        Transparency = NumberSequence.new(0),
        Offset = Vector2.new(-0.2, 0),
        Parent = card,
    })

    local tile = New("Frame", {
        BackgroundColor3 = color,
        BackgroundTransparency = 0.82,
        Size = UDim2.fromOffset(34, 34),
        Parent = card,
    }, { Corner(10), Stroke(color, 1, 0.55) })
    if kind == "success" then
        local c = Check(tile, 14, color)
        c.AnchorPoint = Vector2.new(0.5, 0.5)
        c.Position = UDim2.fromScale(0.5, 0.5)
    elseif kind == "error" then
        local c = Cross(tile, 10, color, 2)
        c.AnchorPoint = Vector2.new(0.5, 0.5)
        c.Position = UDim2.fromScale(0.5, 0.5)
    else
        Label({
            Text = (kind == "info") and "i" or "!",
            FontFace = F(W_XBOLD),
            TextSize = 16,
            TextColor3 = color,
            TextXAlignment = Enum.TextXAlignment.Center,
            Size = UDim2.fromScale(1, 1),
            Parent = tile,
        })
    end

    local textCol = New("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(46, 0),
        Size = UDim2.new(1, -70, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = card,
    }, { List(Enum.FillDirection.Vertical, 3) })
    Label({
        Text = n.Title or "Snowy UI",
        FontFace = F(W_BOLD),
        TextSize = 13.5,
        Size = UDim2.new(1, 0, 0, 18),
        TextTruncate = Enum.TextTruncate.AtEnd,
        LayoutOrder = 1,
        Parent = textCol,
    })
    if n.Content and n.Content ~= "" then
        Label({
            Text = n.Content,
            FontFace = F(W_MED),
            TextSize = 12,
            TextColor3 = Theme.Muted,
            TextWrapped = true,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 2,
            Parent = textCol,
        })
    end

    local close = New("TextButton", {
        Text = "",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.fromOffset(18, 18),
        Parent = card,
    })
    local cx = Cross(close, 8, Theme.Muted, 2)
    cx.AnchorPoint = Vector2.new(0.5, 0.5)
    cx.Position = UDim2.fromScale(0.5, 0.5)

    local bar = New("Frame", {
        BackgroundColor3 = color,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, -12, 1, 14),
        Size = UDim2.new(1, 24, 0, 2),
        Parent = card,
    })

    local closed = false
    local function Dismiss()
        if closed then return end
        closed = true
        local t = Tween(card, 0.3, { Position = UDim2.fromOffset(360, 0) }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        t.Completed:Connect(function()
            slot:Destroy()
        end)
    end
    close.MouseButton1Click:Connect(Dismiss)

    Tween(card, 0.45, { Position = UDim2.fromOffset(0, 0) })
    Tween(bar, duration, { Size = UDim2.new(0, 0, 0, 2) }, Enum.EasingStyle.Linear)
    task.delay(duration, Dismiss)

    return { Dismiss = Dismiss }
end

return Library
