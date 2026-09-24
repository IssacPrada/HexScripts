--[[
    UILibrary
    A custom Roblox UI library with tabs, sections, buttons, toggles, sliders,
    textboxes, keybinds, dropdowns (+refresh), a settings tab, tween animations,
    UI sounds, and a live gradient/theme customizer.

    Usage (loadstring):
        local Library = loadstring(game:HttpGet("<raw url>"))()
        local Window = Library:CreateWindow({
            Title = "My Hub",
            SubTitle = "v1.0",
        })
        local Tab = Window:CreateTab("Main")
        local Section = Tab:CreateSection("General")
        Section:AddButton({Text = "Click Me", Callback = function() end})

    All elements return an object with :Set(...) / :Get() where relevant,
    so you can update them programmatically later.
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local Library = {}
Library.__index = Library

-- ============================== THEME ==============================

Library.Theme = {
    Background      = Color3.fromRGB(24, 24, 28),
    Secondary       = Color3.fromRGB(32, 32, 38),
    Tertiary        = Color3.fromRGB(40, 40, 48),
    Stroke          = Color3.fromRGB(55, 55, 64),
    Text            = Color3.fromRGB(235, 235, 240),
    SubText         = Color3.fromRGB(160, 160, 170),
    Accent1         = Color3.fromRGB(138, 92, 246),   -- gradient color 1
    Accent2         = Color3.fromRGB(56, 189, 248),   -- gradient color 2
    Success         = Color3.fromRGB(80, 220, 130),
    Error           = Color3.fromRGB(235, 80, 90),
    Font            = Enum.Font.GothamMedium,
    BoldFont        = Enum.Font.GothamBold,
}

Library.Sounds = {
    Click   = "rbxassetid://6895079853",
    Hover   = "rbxassetid://6895079091",
    Toggle  = "rbxassetid://6895079771",
    Notify  = "rbxassetid://6895079537",
}

Library.Flags = {} -- stores values of every element by Flag name, for saving/loading configs

-- ============================== UTILITIES ==============================

local function Create(class, props, children)
    local inst = Instance.new(class)
    for prop, value in pairs(props or {}) do
        inst[prop] = value
    end
    for _, child in ipairs(children or {}) do
        child.Parent = inst
    end
    return inst
end

local function Tween(inst, info, props)
    local tween = TweenService:Create(inst, info, props)
    tween:Play()
    return tween
end

local QUICK = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local SMOOTH = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local function PlaySound(id, volume)
    local ok, sound = pcall(function()
        return Create("Sound", {
            SoundId = id,
            Volume = volume or 0.4,
            Parent = CoreGui,
        })
    end)
    if ok and sound then
        sound:Play()
        game:GetService("Debris"):AddItem(sound, 2)
    end
end

local function Corner(radius)
    return Create("UICorner", {CornerRadius = UDim.new(0, radius or 8)})
end

local function Stroke(color, thickness, transparency)
    return Create("UIStroke", {
        Color = color or Library.Theme.Stroke,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
    })
end

local function Padding(t, b, l, r)
    return Create("UIPadding", {
        PaddingTop = UDim.new(0, t or 0),
        PaddingBottom = UDim.new(0, b or 0),
        PaddingLeft = UDim.new(0, l or 0),
        PaddingRight = UDim.new(0, r or 0),
    })
end

local function ApplyGradient(inst, color1, color2, rotation)
    local grad = inst:FindFirstChildOfClass("UIGradient")
    if not grad then
        grad = Create("UIGradient", {})
        grad.Parent = inst
    end
    grad.Color = ColorSequence.new(color1, color2)
    grad.Rotation = rotation or 0
    return grad
end

local function MakeDraggable(dragHandle, target)
    local dragging, dragStart, startPos = false, nil, nil
    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = target.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

local function AddHoverSound(button)
    button.MouseEnter:Connect(function()
        PlaySound(Library.Sounds.Hover, 0.15)
    end)
end

-- ============================== ROOT GUI ==============================

local function GetGuiParent()
    local ok, result = pcall(function()
        return game:GetService("CoreGui")
    end)
    if ok then
        local success = pcall(function()
            local test = Instance.new("ScreenGui")
            test.Parent = result
            test:Destroy()
        end)
        if success then return result end
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end

-- ============================== WINDOW ==============================

function Library:CreateWindow(config)
    config = config or {}
    local Theme = Library.Theme

    local ScreenGui = Create("ScreenGui", {
        Name = "UILibrary_" .. tostring(math.random(1, 999999)),
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = GetGuiParent(),
    })

    local Main = Create("Frame", {
        Name = "Main",
        Size = UDim2.fromOffset(560, 380),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = ScreenGui,
    }, {Corner(12)})

    local OuterStroke = Stroke(Theme.Accent1, 1.2, 0.35)
    OuterStroke.Parent = Main
    ApplyGradient(OuterStroke, Theme.Accent1, Theme.Accent2, 45)

    -- animate the border gradient slowly
    task.spawn(function()
        local grad = OuterStroke:FindFirstChildOfClass("UIGradient")
        while Main.Parent do
            Tween(grad, TweenInfo.new(3, Enum.EasingStyle.Linear), {Rotation = grad.Rotation + 360})
            task.wait(3)
        end
    end)

    -- Topbar
    local TopBar = Create("Frame", {
        Name = "TopBar",
        Size = UDim2.new(1, 0, 0, 48),
        BackgroundColor3 = Theme.Secondary,
        BorderSizePixel = 0,
        Parent = Main,
    }, {Corner(12)})

    Create("Frame", { -- cover bottom corners of topbar so it looks square-bottomed
        Size = UDim2.new(1, 0, 0, 12),
        Position = UDim2.new(0, 0, 1, -12),
        BackgroundColor3 = Theme.Secondary,
        BorderSizePixel = 0,
        Parent = TopBar,
    })

    local Icon = Create("Frame", {
        Size = UDim2.fromOffset(28, 28),
        Position = UDim2.fromOffset(12, 10),
        BackgroundColor3 = Theme.Accent1,
        Parent = TopBar,
    }, {Corner(8)})
    ApplyGradient(Icon, Theme.Accent1, Theme.Accent2, 90)

    Create("TextLabel", {
        Text = config.Title or "UI Library",
        Font = Theme.BoldFont,
        TextSize = 15,
        TextColor3 = Theme.Text,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(50, 6),
        Size = UDim2.fromOffset(300, 18),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = TopBar,
    })

    Create("TextLabel", {
        Text = config.SubTitle or "",
        Font = Theme.Font,
        TextSize = 12,
        TextColor3 = Theme.SubText,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(50, 24),
        Size = UDim2.fromOffset(300, 16),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = TopBar,
    })

    local CloseBtn = Create("TextButton", {
        Text = "X",
        Font = Theme.BoldFont,
        TextSize = 14,
        TextColor3 = Theme.SubText,
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(32, 32),
        Position = UDim2.new(1, -40, 0, 8),
        Parent = TopBar,
    })
    CloseBtn.MouseButton1Click:Connect(function()
        PlaySound(Library.Sounds.Click)
        Tween(Main, QUICK, {Size = UDim2.fromOffset(560, 0)})
        task.wait(0.18)
        ScreenGui.Enabled = false
    end)

    MakeDraggable(TopBar, Main)

    -- Tab bar (left)
    local TabBar = Create("Frame", {
        Name = "TabBar",
        Size = UDim2.new(0, 140, 1, -48),
        Position = UDim2.new(0, 0, 0, 48),
        BackgroundColor3 = Theme.Secondary,
        BorderSizePixel = 0,
        Parent = Main,
    })

    local TabList = Create("UIListLayout", {
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    TabList.Parent = TabBar
    Padding(10, 10, 8, 8).Parent = TabBar

    -- Content area (right)
    local ContentArea = Create("Frame", {
        Name = "ContentArea",
        Size = UDim2.new(1, -140, 1, -48),
        Position = UDim2.new(0, 140, 0, 48),
        BackgroundTransparency = 1,
        Parent = Main,
    })

    -- Toggle UI visibility keybind
    local uiVisible = true
    local toggleKey = config.ToggleKey or Enum.KeyCode.RightControl
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == toggleKey then
            uiVisible = not uiVisible
            ScreenGui.Enabled = uiVisible
        end
    end)

    local Window = setmetatable({
        ScreenGui = ScreenGui,
        Main = Main,
        TabBar = TabBar,
        ContentArea = ContentArea,
        Tabs = {},
        _firstTab = true,
    }, {__index = Library})

    -- entrance animation
    Main.Size = UDim2.fromOffset(560, 0)
    Tween(Main, SMOOTH, {Size = UDim2.fromOffset(560, 380)})

    return Window
end

-- ============================== TABS ==============================

function Library:CreateTab(name, icon)
    local Theme = Library.Theme

    local TabButton = Create("TextButton", {
        Text = "",
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = Theme.Tertiary,
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Parent = self.TabBar,
    }, {Corner(8)})

    Create("TextLabel", {
        Text = name,
        Font = Theme.Font,
        TextSize = 13,
        TextColor3 = Theme.SubText,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -16, 1, 0),
        Position = UDim2.fromOffset(12, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        Name = "Label",
        Parent = TabButton,
    })

    local Page = Create("ScrollingFrame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Accent1,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
        Parent = self.ContentArea,
    })
    Padding(14, 14, 14, 14).Parent = Page
    local PageLayout = Create("UIListLayout", {
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    PageLayout.Parent = Page

    local Tab = setmetatable({
        Button = TabButton,
        Page = Page,
    }, {__index = Library})

    local function selectTab()
        for _, t in pairs(self.Tabs) do
            t.Page.Visible = false
            Tween(t.Button, QUICK, {BackgroundTransparency = 1})
            t.Button.Label.TextColor3 = Theme.SubText
        end
        Page.Visible = true
        Tween(TabButton, QUICK, {BackgroundTransparency = 0})
        TabButton.Label.TextColor3 = Theme.Text
    end

    TabButton.MouseButton1Click:Connect(function()
        PlaySound(Library.Sounds.Click)
        selectTab()
    end)
    AddHoverSound(TabButton)

    table.insert(self.Tabs, Tab)
    if self._firstTab then
        self._firstTab = false
        selectTab()
    end

    return Tab
end

-- ============================== SECTIONS ==============================

function Library:CreateSection(title)
    local Theme = Library.Theme

    local SectionFrame = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.Secondary,
        Parent = self.Page,
    }, {Corner(10)})
    Stroke(Theme.Stroke, 1, 0.5).Parent = SectionFrame

    Create("TextLabel", {
        Text = title,
        Font = Theme.BoldFont,
        TextSize = 13,
        TextColor3 = Theme.Text,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 0, 26),
        Position = UDim2.fromOffset(12, 8),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = SectionFrame,
    })

    local Holder = Create("Frame", {
        Size = UDim2.new(1, -20, 0, 0),
        Position = UDim2.fromOffset(10, 36),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = SectionFrame,
    })
    local HolderLayout = Create("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    HolderLayout.Parent = Holder
    Padding(0, 10, 0, 0).Parent = Holder

    local Section = setmetatable({Holder = Holder}, {__index = Library})
    return Section
end

-- ============================== ELEMENTS ==============================

-- ---- Button ----
function Library:AddButton(opts)
    opts = opts or {}
    local Theme = Library.Theme

    local Btn = Create("TextButton", {
        Text = "",
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = Theme.Tertiary,
        AutoButtonColor = false,
        Parent = self.Holder,
    }, {Corner(8)})
    Stroke(Theme.Stroke, 1, 0.6).Parent = Btn

    Create("TextLabel", {
        Text = opts.Text or "Button",
        Font = Theme.Font,
        TextSize = 13,
        TextColor3 = Theme.Text,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.fromOffset(12, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Btn,
    })

    Btn.MouseButton1Click:Connect(function()
        PlaySound(Library.Sounds.Click)
        Tween(Btn, TweenInfo.new(0.08), {BackgroundColor3 = Theme.Accent1})
        task.wait(0.08)
        Tween(Btn, QUICK, {BackgroundColor3 = Theme.Tertiary})
        if opts.Callback then
            local ok, err = pcall(opts.Callback)
            if not ok then warn("[UILibrary] Button callback error: " .. tostring(err)) end
        end
    end)
    AddHoverSound(Btn)

    return Btn
end

-- ---- Toggle ----
function Library:AddToggle(opts)
    opts = opts or {}
    local Theme = Library.Theme
    local state = opts.Default or false

    local Row = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundTransparency = 1,
        Parent = self.Holder,
    })

    Create("TextLabel", {
        Text = opts.Text or "Toggle",
        Font = Theme.Font,
        TextSize = 13,
        TextColor3 = Theme.Text,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -50, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Row,
    })

    local Switch = Create("Frame", {
        Size = UDim2.fromOffset(40, 22),
        Position = UDim2.new(1, -40, 0.5, -11),
        BackgroundColor3 = state and Theme.Accent1 or Theme.Tertiary,
        Parent = Row,
    }, {Corner(11)})
    Stroke(Theme.Stroke, 1, 0.5).Parent = Switch

    local Knob = Create("Frame", {
        Size = UDim2.fromOffset(16, 16),
        Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
        BackgroundColor3 = Theme.Text,
        Parent = Switch,
    }, {Corner(8)})

    local ClickArea = Create("TextButton", {Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = Row})

    local Toggle = {}
    function Toggle:Set(value)
        state = value
        Tween(Switch, QUICK, {BackgroundColor3 = state and Theme.Accent1 or Theme.Tertiary})
        Tween(Knob, QUICK, {Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)})
        if opts.Flag then Library.Flags[opts.Flag] = state end
        if opts.Callback then pcall(opts.Callback, state) end
    end
    function Toggle:Get() return state end

    ClickArea.MouseButton1Click:Connect(function()
        PlaySound(Library.Sounds.Toggle)
        Toggle:Set(not state)
    end)
    AddHoverSound(ClickArea)

    if opts.Flag then Library.Flags[opts.Flag] = state end
    if state and opts.Callback then pcall(opts.Callback, state) end

    return Toggle
end

-- ---- Slider ----
function Library:AddSlider(opts)
    opts = opts or {}
    local Theme = Library.Theme
    local min, max = opts.Min or 0, opts.Max or 100
    local value = math.clamp(opts.Default or min, min, max)
    local decimals = opts.Decimals or 0

    local Row = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundTransparency = 1,
        Parent = self.Holder,
    })

    Create("TextLabel", {
        Text = opts.Text or "Slider",
        Font = Theme.Font,
        TextSize = 13,
        TextColor3 = Theme.Text,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -50, 0, 18),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Row,
    })

    local ValueLabel = Create("TextLabel", {
        Text = tostring(value),
        Font = Theme.Font,
        TextSize = 12,
        TextColor3 = Theme.SubText,
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(50, 18),
        Position = UDim2.new(1, -50, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = Row,
    })

    local Track = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 8),
        Position = UDim2.fromOffset(0, 26),
        BackgroundColor3 = Theme.Tertiary,
        Parent = Row,
    }, {Corner(4)})

    local Fill = Create("Frame", {
        Size = UDim2.fromScale((value - min) / (max - min), 1),
        BackgroundColor3 = Theme.Accent1,
        Parent = Track,
    }, {Corner(4)})
    ApplyGradient(Fill, Theme.Accent1, Theme.Accent2, 0)

    local Grabber = Create("TextButton", {Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = Track})

    local Slider = {}
    local dragging = false

    local function updateFromX(xPos)
        local rel = math.clamp((xPos - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
        local raw = min + (max - min) * rel
        local mult = 10 ^ decimals
        raw = math.floor(raw * mult + 0.5) / mult
        value = raw
        Fill.Size = UDim2.fromScale(rel, 1)
        ValueLabel.Text = tostring(value)
        if opts.Flag then Library.Flags[opts.Flag] = value end
        if opts.Callback then pcall(opts.Callback, value) end
    end

    Grabber.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateFromX(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateFromX(input.Position.X)
        end
    end)

    function Slider:Set(v)
        v = math.clamp(v, min, max)
        local rel = (v - min) / (max - min)
        value = v
        Tween(Fill, QUICK, {Size = UDim2.fromScale(rel, 1)})
        ValueLabel.Text = tostring(v)
        if opts.Flag then Library.Flags[opts.Flag] = v end
        if opts.Callback then pcall(opts.Callback, v) end
    end
    function Slider:Get() return value end

    if opts.Flag then Library.Flags[opts.Flag] = value end

    return Slider
end

-- ---- Textbox ----
function Library:AddTextbox(opts)
    opts = opts or {}
    local Theme = Library.Theme

    local Row = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundTransparency = 1,
        Parent = self.Holder,
    })

    Create("TextLabel", {
        Text = opts.Text or "Textbox",
        Font = Theme.Font,
        TextSize = 13,
        TextColor3 = Theme.Text,
        BackgroundTransparency = 1,
        Size = UDim2.new(0.45, 0, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Row,
    })

    local Box = Create("TextBox", {
        Text = opts.Default or "",
        PlaceholderText = opts.Placeholder or "...",
        Font = Theme.Font,
        TextSize = 13,
        TextColor3 = Theme.Text,
        PlaceholderColor3 = Theme.SubText,
        BackgroundColor3 = Theme.Tertiary,
        ClearTextOnFocus = false,
        Size = UDim2.new(0.55, 0, 1, 0),
        Position = UDim2.new(0.45, 0, 0, 0),
        Parent = Row,
    }, {Corner(6), Padding(0, 0, 8, 8)})
    Stroke(Theme.Stroke, 1, 0.5).Parent = Box

    local Textbox = {}
    function Textbox:Set(text)
        Box.Text = text
        if opts.Flag then Library.Flags[opts.Flag] = text end
    end
    function Textbox:Get() return Box.Text end

    Box.FocusLost:Connect(function(enterPressed)
        if opts.Flag then Library.Flags[opts.Flag] = Box.Text end
        if opts.Callback then pcall(opts.Callback, Box.Text, enterPressed) end
    end)

    if opts.Flag then Library.Flags[opts.Flag] = Box.Text end

    return Textbox
end

-- ---- Keybind ----
function Library:AddKeybind(opts)
    opts = opts or {}
    local Theme = Library.Theme
    local bound = opts.Default or Enum.KeyCode.Unknown
    local listening = false

    local Row = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundTransparency = 1,
        Parent = self.Holder,
    })

    Create("TextLabel", {
        Text = opts.Text or "Keybind",
        Font = Theme.Font,
        TextSize = 13,
        TextColor3 = Theme.Text,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -90, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Row,
    })

    local KeyBtn = Create("TextButton", {
        Text = bound == Enum.KeyCode.Unknown and "None" or bound.Name,
        Font = Theme.Font,
        TextSize = 12,
        TextColor3 = Theme.Text,
        BackgroundColor3 = Theme.Tertiary,
        AutoButtonColor = false,
        Size = UDim2.fromOffset(80, 26),
        Position = UDim2.new(1, -80, 0.5, -13),
        Parent = Row,
    }, {Corner(6)})
    Stroke(Theme.Stroke, 1, 0.5).Parent = KeyBtn

    local Keybind = {}
    function Keybind:Set(keyCode)
        bound = keyCode
        KeyBtn.Text = keyCode == Enum.KeyCode.Unknown and "None" or keyCode.Name
        if opts.Flag then Library.Flags[opts.Flag] = bound end
    end
    function Keybind:Get() return bound end

    KeyBtn.MouseButton1Click:Connect(function()
        PlaySound(Library.Sounds.Click)
        listening = true
        KeyBtn.Text = "..."
        Tween(KeyBtn, QUICK, {BackgroundColor3 = Theme.Accent1})
    end)

    UserInputService.InputBegan:Connect(function(input, gpe)
        if listening and input.UserInputType == Enum.UserInputType.Keyboard then
            listening = false
            bound = input.KeyCode
            KeyBtn.Text = bound.Name
            Tween(KeyBtn, QUICK, {BackgroundColor3 = Theme.Tertiary})
            if opts.Flag then Library.Flags[opts.Flag] = bound end
            if opts.Callback then pcall(opts.Callback, bound) end
        elseif not gpe and not listening and opts.OnPress and input.KeyCode == bound then
            pcall(opts.OnPress)
        end
    end)

    if opts.Flag then Library.Flags[opts.Flag] = bound end

    return Keybind
end

-- ---- Dropdown (with refresh support) ----
function Library:AddDropdown(opts)
    opts = opts or {}
    local Theme = Library.Theme
    local options = opts.Options or {}
    local multi = opts.Multi or false
    local selected = opts.Default or (multi and {} or nil)
    local open = false

    local Row = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundTransparency = 1,
        ClipsDescendants = false,
        Parent = self.Holder,
    })

    Create("TextLabel", {
        Text = opts.Text or "Dropdown",
        Font = Theme.Font,
        TextSize = 13,
        TextColor3 = Theme.Text,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 18),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Row,
    })

    local Head = Create("TextButton", {
        Text = "",
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.fromOffset(0, 20),
        BackgroundColor3 = Theme.Tertiary,
        AutoButtonColor = false,
        Parent = Row,
    }, {Corner(6)})
    Stroke(Theme.Stroke, 1, 0.5).Parent = Head

    local function selectedText()
        if multi then
            local list = {}
            for _, v in pairs(selected) do table.insert(list, v) end
            return #list == 0 and "None selected" or table.concat(list, ", ")
        end
        return selected or "Select..."
    end

    local HeadLabel = Create("TextLabel", {
        Text = selectedText(),
        Font = Theme.Font,
        TextSize = 12,
        TextColor3 = Theme.SubText,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -30, 1, 0),
        Position = UDim2.fromOffset(10, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = Head,
    })

    local Arrow = Create("TextLabel", {
        Text = "v",
        Font = Theme.BoldFont,
        TextSize = 12,
        TextColor3 = Theme.SubText,
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(20, 30),
        Position = UDim2.new(1, -24, 0, 0),
        Parent = Head,
    })

    local ListFrame = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.fromOffset(0, 52),
        BackgroundColor3 = Theme.Tertiary,
        ClipsDescendants = true,
        Visible = false,
        ZIndex = 5,
        Parent = Row,
    }, {Corner(6)})
    Stroke(Theme.Stroke, 1, 0.5).Parent = ListFrame

    local ListLayout = Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder})
    ListLayout.Parent = ListFrame
    Padding(4, 4, 4, 4).Parent = ListFrame

    local Dropdown = {}

    local function rebuildOptions()
        for _, c in ipairs(ListFrame:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        for i, optText in ipairs(options) do
            local OptBtn = Create("TextButton", {
                Text = "",
                Size = UDim2.new(1, 0, 0, 26),
                BackgroundColor3 = Theme.Secondary,
                BackgroundTransparency = 1,
                AutoButtonColor = false,
                LayoutOrder = i,
                ZIndex = 6,
                Parent = ListFrame,
            }, {Corner(5)})
            Create("TextLabel", {
                Text = optText,
                Font = Theme.Font,
                TextSize = 12,
                TextColor3 = Theme.Text,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -16, 1, 0),
                Position = UDim2.fromOffset(8, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 6,
                Parent = OptBtn,
            })
            OptBtn.MouseEnter:Connect(function()
                Tween(OptBtn, QUICK, {BackgroundTransparency = 0})
            end)
            OptBtn.MouseLeave:Connect(function()
                Tween(OptBtn, QUICK, {BackgroundTransparency = 1})
            end)
            OptBtn.MouseButton1Click:Connect(function()
                PlaySound(Library.Sounds.Click)
                if multi then
                    if selected[optText] then
                        selected[optText] = nil
                    else
                        selected[optText] = optText
                    end
                else
                    selected = optText
                end
                HeadLabel.Text = selectedText()
                if opts.Flag then Library.Flags[opts.Flag] = selected end
                if opts.Callback then pcall(opts.Callback, selected) end
                if not multi then
                    Dropdown:Close()
                end
            end)
        end
    end
    rebuildOptions()

    function Dropdown:Refresh(newOptions)
        options = newOptions or options
        rebuildOptions()
    end

    function Dropdown:Open()
        open = true
        ListFrame.Visible = true
        local target = math.min(#options, 6) * 26 + 8
        Tween(ListFrame, QUICK, {Size = UDim2.new(1, 0, 0, target)})
        Tween(Arrow, QUICK, {Rotation = 180})
    end

    function Dropdown:Close()
        open = false
        Tween(ListFrame, QUICK, {Size = UDim2.new(1, 0, 0, 0)})
        Tween(Arrow, QUICK, {Rotation = 0})
        task.delay(0.2, function()
            if not open then ListFrame.Visible = false end
        end)
    end

    function Dropdown:Get() return selected end
    function Dropdown:Set(value)
        selected = value
        HeadLabel.Text = selectedText()
        if opts.Flag then Library.Flags[opts.Flag] = selected end
    end

    Head.MouseButton1Click:Connect(function()
        PlaySound(Library.Sounds.Click)
        if open then Dropdown:Close() else Dropdown:Open() end
    end)
    AddHoverSound(Head)

    if opts.Flag then Library.Flags[opts.Flag] = selected end

    return Dropdown
end

-- ============================== SETTINGS TAB (theme / gradient customizer) ==============================

function Library:CreateSettingsTab(window)
    local Theme = Library.Theme
    local Tab = window:CreateTab("Settings")
    local Section = Tab:CreateSection("Theme")

    Section:AddSlider({
        Text = "Accent Hue Shift",
        Min = 0, Max = 360, Default = 0,
        Callback = function(v)
            local h1 = (v / 360)
            local h2 = ((v + 40) % 360) / 360
            Theme.Accent1 = Color3.fromHSV(h1, 0.65, 0.95)
            Theme.Accent2 = Color3.fromHSV(h2, 0.65, 0.95)
            -- live-update every gradient/accent stroke in the window
            for _, desc in ipairs(window.Main:GetDescendants()) do
                if desc:IsA("UIGradient") then
                    desc.Color = ColorSequence.new(Theme.Accent1, Theme.Accent2)
                end
            end
        end,
    })

    Section:AddToggle({
        Text = "Reduce Motion (disable tween animations)",
        Default = false,
        Callback = function(state)
            Library._reduceMotion = state
        end,
    })

    local KeySection = Tab:CreateSection("Keybinds")
    KeySection:AddKeybind({
        Text = "Toggle UI Visibility",
        Default = Enum.KeyCode.RightControl,
        Callback = function(key)
            -- consumer library can read this Flag to rebind toggle key
        end,
    })

    return Tab
end

-- ============================== INTRO / SPLASH ANIMATION ==============================
--[[
    Library:PlayIntro({
        Image = "rbxassetid://0",   -- upload your logo as a Decal in Roblox and put the asset id here
        Text = "Hex Scripts",
        OnComplete = function() ... end, -- called when the intro finishes (e.g. show key system / window)
    })

    Sequence: screen blurs in -> logo pops in centered -> logo swishes to the left ->
    "Hex Scripts" text fades in beside it -> the text's gradient slowly shifts to red ->
    everything fades out.
]]
function Library:PlayIntro(config)
    config = config or {}
    local Theme = Library.Theme
    local logoImage = config.Image or "rbxassetid://0"
    local titleText = config.Text or "Hex Scripts"
    local onComplete = config.OnComplete

    local Lighting = game:GetService("Lighting")

    local ScreenGui = Create("ScreenGui", {
        Name = "Intro",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 1000,
        Parent = GetGuiParent(),
    })

    local Blur = Create("BlurEffect", {Size = 0, Parent = Lighting})

    local Backdrop = Create("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 1,
        Parent = ScreenGui,
    })

    local Logo = Create("ImageLabel", {
        Image = logoImage,
        Size = UDim2.fromOffset(0, 0),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        ScaleType = Enum.ScaleType.Fit,
        Parent = Backdrop,
    })

    local TitleLabel = Create("TextLabel", {
        Text = titleText,
        Font = Theme.BoldFont,
        TextSize = 34,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 1,
        TextTransparency = 1,
        Size = UDim2.fromOffset(420, 50),
        Position = UDim2.fromScale(0.58, 0.5),
        AnchorPoint = Vector2.new(0, 0.5),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Backdrop,
    })
    local TitleGradient = Create("UIGradient", {
        Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255)),
    })
    TitleGradient.Parent = TitleLabel

    task.spawn(function()
        -- fade the blur + dim backdrop in
        Tween(Blur, TweenInfo.new(0.6), {Size = 20})
        Tween(Backdrop, TweenInfo.new(0.6), {BackgroundTransparency = 0.15})
        task.wait(0.25)

        -- logo pops in with a slight overshoot
        Tween(Logo, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(160, 160),
        })
        task.wait(0.9)

        -- logo swishes over to the left and shrinks a bit
        Tween(Logo, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {
            Position = UDim2.fromScale(0.42, 0.5),
            Size = UDim2.fromOffset(90, 90),
        })
        task.wait(0.2)

        -- title text fades/slides in next to the logo
        Tween(TitleLabel, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            TextTransparency = 0,
        })

        -- gradient on the title slowly shifts from white to the theme's red accent
        Tween(TitleGradient, TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            Color = ColorSequence.new(Theme.Accent2, Theme.Accent1),
        })
        task.wait(1.9)

        -- fade everything out
        Tween(Backdrop, TweenInfo.new(0.5), {BackgroundTransparency = 1})
        Tween(Logo, TweenInfo.new(0.5), {ImageTransparency = 1})
        Tween(TitleLabel, TweenInfo.new(0.5), {TextTransparency = 1})
        Tween(Blur, TweenInfo.new(0.5), {Size = 0})
        task.wait(0.55)

        Blur:Destroy()
        ScreenGui:Destroy()
        if onComplete then
            local ok, err = pcall(onComplete)
            if not ok then warn("[UILibrary] Intro OnComplete error: " .. tostring(err)) end
        end
    end)

    return ScreenGui
end

-- ============================== KEY SYSTEM ==============================
--[[
    Library:CreateKeySystem({
        Title = "Hex Scripts",
        Subtitle = "Enter your key to continue",
        GetKeyLink = "https://linkvertise.com/your-link", -- optional, copies to clipboard when clicked
        CheckKey = function(key)
            -- return true/false. Replace this with your own check, e.g. an HTTP
            -- request to your own key API, or a table of valid keys.
            local validKeys = {"HEX-DEMO-KEY"}
            for _, k in ipairs(validKeys) do
                if key == k then return true end
            end
            return false
        end,
        OnSuccess = function() ... end, -- called once a valid key is submitted
    })
]]
function Library:CreateKeySystem(config)
    config = config or {}
    local Theme = Library.Theme
    local title = config.Title or "Key System"
    local subtitle = config.Subtitle or "Enter your key to continue"
    local checkCallback = config.CheckKey
    local getKeyUrl = config.GetKeyLink
    local onSuccess = config.OnSuccess

    local ScreenGui = Create("ScreenGui", {
        Name = "KeySystem",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999,
        Parent = GetGuiParent(),
    })

    local Backdrop = Create("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.4,
        Parent = ScreenGui,
    })

    local hasGetKey = getKeyUrl ~= nil
    local Box = Create("Frame", {
        Size = UDim2.fromOffset(360, 0),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.Background,
        ClipsDescendants = true,
        Parent = Backdrop,
    }, {Corner(12)})
    local BoxStroke = Stroke(Theme.Accent1, 1.2, 0.3)
    BoxStroke.Parent = Box
    ApplyGradient(BoxStroke, Theme.Accent1, Theme.Accent2, 45)

    Create("TextLabel", {
        Text = title, Font = Theme.BoldFont, TextSize = 18, TextColor3 = Theme.Text,
        BackgroundTransparency = 1, Size = UDim2.new(1, -30, 0, 24),
        Position = UDim2.fromOffset(15, 16), TextXAlignment = Enum.TextXAlignment.Left, Parent = Box,
    })
    Create("TextLabel", {
        Text = subtitle, Font = Theme.Font, TextSize = 13, TextColor3 = Theme.SubText,
        BackgroundTransparency = 1, Size = UDim2.new(1, -30, 0, 18),
        Position = UDim2.fromOffset(15, 42), TextXAlignment = Enum.TextXAlignment.Left, Parent = Box,
    })

    local KeyBox = Create("TextBox", {
        Text = "",
        PlaceholderText = "Enter key here...",
        Font = Theme.Font, TextSize = 13, TextColor3 = Theme.Text,
        PlaceholderColor3 = Theme.SubText,
        BackgroundColor3 = Theme.Tertiary,
        ClearTextOnFocus = false,
        Size = UDim2.new(1, -30, 0, 36),
        Position = UDim2.fromOffset(15, 76),
        Parent = Box,
    }, {Corner(8), Padding(0, 0, 10, 10)})
    Stroke(Theme.Stroke, 1, 0.5).Parent = KeyBox

    local StatusLabel = Create("TextLabel", {
        Text = "", Font = Theme.Font, TextSize = 12, TextColor3 = Theme.Error,
        BackgroundTransparency = 1, Size = UDim2.new(1, -30, 0, 16),
        Position = UDim2.fromOffset(15, 116), TextXAlignment = Enum.TextXAlignment.Left, Parent = Box,
    })

    local SubmitBtn = Create("TextButton", {
        Text = "", Size = UDim2.new(1, -30, 0, 36), Position = UDim2.fromOffset(15, 140),
        BackgroundColor3 = Theme.Accent1, AutoButtonColor = false, Parent = Box,
    }, {Corner(8)})
    ApplyGradient(SubmitBtn, Theme.Accent1, Theme.Accent2, 90)
    Create("TextLabel", {
        Text = "Submit", Font = Theme.BoldFont, TextSize = 14, TextColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = SubmitBtn,
    })

    local boxHeight = hasGetKey and 210 or 182
    if hasGetKey then
        local GetKeyLabel = Create("TextButton", {
            Text = "Get Key", Font = Theme.Font, TextSize = 12, TextColor3 = Theme.SubText,
            BackgroundTransparency = 1, Size = UDim2.new(1, -30, 0, 18),
            Position = UDim2.fromOffset(15, 182), Parent = Box,
        })
        GetKeyLabel.MouseButton1Click:Connect(function()
            if setclipboard then pcall(setclipboard, getKeyUrl) end
            StatusLabel.TextColor3 = Theme.Success
            StatusLabel.Text = "Link copied to clipboard!"
        end)
    end

    -- entrance
    Tween(Box, SMOOTH, {Size = UDim2.fromOffset(360, boxHeight)})

    local function attempt()
        local key = KeyBox.Text
        PlaySound(Library.Sounds.Click)
        if key == "" then
            StatusLabel.TextColor3 = Theme.Error
            StatusLabel.Text = "Please enter a key."
            return
        end
        local valid = true
        if checkCallback then
            local ok, result = pcall(checkCallback, key)
            valid = ok and result
        end
        if valid then
            StatusLabel.TextColor3 = Theme.Success
            StatusLabel.Text = "Key accepted!"
            PlaySound(Library.Sounds.Notify)
            task.wait(0.4)
            Tween(Backdrop, QUICK, {BackgroundTransparency = 1})
            Tween(Box, QUICK, {Size = UDim2.fromOffset(360, 0)})
            task.wait(0.2)
            ScreenGui:Destroy()
            if onSuccess then pcall(onSuccess) end
        else
            StatusLabel.TextColor3 = Theme.Error
            StatusLabel.Text = "Invalid key. Try again."
            Tween(Box, TweenInfo.new(0.06, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, 3, true), {
                Position = Box.Position + UDim2.fromOffset(8, 0),
            })
        end
    end

    SubmitBtn.MouseButton1Click:Connect(attempt)
    KeyBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then attempt() end
    end)
    AddHoverSound(SubmitBtn)

    return ScreenGui
end

return Library
