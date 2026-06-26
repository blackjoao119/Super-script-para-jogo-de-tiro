--[[
    ╔════════════════════════════════════════════════════════════╗
    ║       PROJECT: WARCORE v1.2.0 (AXIOM UI FRAMEWORK)       ║
    ║       STUDIO: WARCORE LABS                                 ║
    ║------------------------------------------------------------║
    ║       LEAD DEVELOPER: ENZO CAVALCANTI                      ║
    ║       FRAMEWORK: AXIOM UI (ORIGINAL - COMPLETO)            ║
    ╚════════════════════════════════════════════════════════════╝
]]

--==========================
-- SERVICES
--==========================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Camera = workspace.CurrentCamera
local Player = Players.LocalPlayer
local Lighting = game:GetService("Lighting")

--==========================
-- THEME MANAGER
--==========================
local ThemeManager = {}
ThemeManager.CurrentTheme = "Midnight"
ThemeManager.Themes = {}

function ThemeManager:RegisterTheme(name, themeData)
    ThemeManager.Themes[name] = themeData
end

function ThemeManager:SetTheme(name)
    if ThemeManager.Themes[name] then
        ThemeManager.CurrentTheme = name
        if ThemeManager.OnThemeChanged then
            ThemeManager.OnThemeChanged(ThemeManager.Themes[name])
        end
    end
end

function ThemeManager:GetCurrentTheme()
    return ThemeManager.Themes[ThemeManager.CurrentTheme]
end

-- Tema padrão "Midnight"
ThemeManager:RegisterTheme("Midnight", {
    Background = Color3.fromRGB(10, 12, 20),
    Panel = Color3.fromRGB(15, 18, 28),
    Accent = Color3.fromRGB(0, 240, 255),
    Text = Color3.fromRGB(255, 255, 255),
    TextSecondary = Color3.fromRGB(150, 160, 180),
    Hover = Color3.fromRGB(25, 30, 45),
    Stroke = Color3.fromRGB(30, 36, 55),
    Scrollbar = Color3.fromRGB(0, 240, 255),
    ToggleOn = Color3.fromRGB(0, 240, 255),
    ToggleOff = Color3.fromRGB(40, 45, 65),
    SliderFill = Color3.fromRGB(0, 240, 255),
    Dropdown = Color3.fromRGB(15, 18, 28),
    Success = Color3.fromRGB(0, 200, 100),
    Error = Color3.fromRGB(255, 50, 50),
    Warning = Color3.fromRGB(255, 160, 0),
    Info = Color3.fromRGB(0, 180, 255)
})

--==========================
-- UTILITIES
--==========================
local Utilities = {}

function Utilities.Create(className, parent, properties)
    local instance = Instance.new(className)
    if parent then instance.Parent = parent end
    if properties then
        for prop, value in pairs(properties) do
            if prop ~= "Children" then
                instance[prop] = value
            end
        end
    end
    return instance
end

function Utilities.Animate(instance, tweenInfo, properties)
    local tween = TweenService:Create(instance, tweenInfo, properties)
    tween:Play()
    return tween
end

function Utilities.AddStroke(instance, color, thickness)
    return Utilities.Create("UIStroke", instance, {
        Color = color or ThemeManager:GetCurrentTheme().Stroke,
        Thickness = thickness or 1,
        Transparency = 0.4
    })
end

function Utilities.AddCorner(instance, radius)
    return Utilities.Create("UICorner", instance, {
        CornerRadius = radius or UDim.new(0, 6)
    })
end

--==========================
-- BASE COMPONENT
--==========================
local BaseComponent = {}
BaseComponent.__index = BaseComponent

function BaseComponent.new(parent)
    local self = setmetatable({}, BaseComponent)
    self.Instance = nil
    self.Parent = parent
    self.Connections = {}
    return self
end

function BaseComponent:Destroy()
    for _, conn in ipairs(self.Connections) do
        conn:Disconnect()
    end
    self.Connections = {}
    if self.Instance then
        self.Instance:Destroy()
    end
end

function BaseComponent:SetVisible(visible)
    if self.Instance then self.Instance.Visible = visible end
end

--==========================
-- COMPONENTS
--==========================

-- Section
local Section = setmetatable({}, {__index = BaseComponent})
Section.__index = Section
function Section.new(parent, title)
    local self = setmetatable(BaseComponent.new(parent), Section)
    local container = Utilities.Create("Frame", parent, {
        Size = UDim2.new(1, -10, 0, 22),
        BackgroundTransparency = 1,
        Name = "Section_" .. title
    })
    Utilities.Create("TextLabel", container, {
        Size = UDim2.new(1, 0, 0, 14),
        Position = UDim2.new(0, 5, 0, 0),
        Text = title,
        TextColor3 = ThemeManager:GetCurrentTheme().TextSecondary,
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 11
    })
    Utilities.Create("Frame", container, {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = ThemeManager:GetCurrentTheme().Stroke,
        BorderSizePixel = 0
    })
    self.Instance = container
    return self
end

-- Toggle
local Toggle = setmetatable({}, {__index = BaseComponent})
Toggle.__index = Toggle
function Toggle.new(parent, config)
    local self = setmetatable(BaseComponent.new(parent), Toggle)
    local theme = ThemeManager:GetCurrentTheme()
    self.State = config.DefaultValue or false
    self.Callback = config.Callback or function() end

    local container = Utilities.Create("TextButton", parent, {
        Size = UDim2.new(1, -10, 0, 38),
        BackgroundColor3 = theme.Panel,
        Text = "",
        AutoButtonColor = false,
        Name = "Toggle_" .. (config.Name or "Toggle")
    })
    Utilities.AddCorner(container)
    Utilities.AddStroke(container, theme.Stroke)

    Utilities.Create("TextLabel", container, {
        Size = UDim2.new(0.7, 0, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        Text = config.Name or "Toggle",
        TextColor3 = theme.Text,
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    local toggleFrame = Utilities.Create("Frame", container, {
        Size = UDim2.new(0, 36, 0, 20),
        Position = UDim2.new(1, -46, 0.5, -10),
        BackgroundColor3 = self.State and theme.ToggleOn or theme.ToggleOff,
        BorderSizePixel = 0
    })
    Utilities.AddCorner(toggleFrame, UDim.new(1, 0))

    local toggleDot = Utilities.Create("Frame", toggleFrame, {
        Size = UDim2.new(0, 16, 0, 16),
        Position = UDim2.new(0, self.State and 18 or 2, 0.5, -8),
        BackgroundColor3 = theme.Text,
        BorderSizePixel = 0
    })
    Utilities.AddCorner(toggleDot, UDim.new(1, 0))

    local function updateVisual(state)
        Utilities.Animate(toggleDot, TweenInfo.new(0.2), { Position = UDim2.new(0, state and 18 or 2, 0.5, -8) })
        Utilities.Animate(toggleFrame, TweenInfo.new(0.2), { BackgroundColor3 = state and theme.ToggleOn or theme.ToggleOff })
    end

    local clickConnection = container.MouseButton1Click:Connect(function()
        self.State = not self.State
        updateVisual(self.State)
        self.Callback(self.State)
    end)
    table.insert(self.Connections, clickConnection)

    local function addHover(btn)
        local hConn = btn.MouseEnter:Connect(function() Utilities.Animate(btn, TweenInfo.new(0.15), {BackgroundColor3 = theme.Hover}) end)
        local lConn = btn.MouseLeave:Connect(function() Utilities.Animate(btn, TweenInfo.new(0.15), {BackgroundColor3 = theme.Panel}) end)
        table.insert(self.Connections, hConn)
        table.insert(self.Connections, lConn)
    end
    addHover(container)

    self.Instance = container
    return self
end

-- Slider
local Slider = setmetatable({}, {__index = BaseComponent})
Slider.__index = Slider
function Slider.new(parent, config)
    local self = setmetatable(BaseComponent.new(parent), Slider)
    local theme = ThemeManager:GetCurrentTheme()
    local min, max = config.Range[1], config.Range[2]
    local increment = config.Increment or 1
    self.Callback = config.Callback or function() end
    self.Value = config.DefaultValue or min

    local container = Utilities.Create("Frame", parent, {
        Size = UDim2.new(1, -10, 0, 55),
        BackgroundColor3 = theme.Panel,
        Name = "Slider_" .. (config.Name or "Slider")
    })
    Utilities.AddCorner(container)
    Utilities.AddStroke(container, theme.Stroke)

    Utilities.Create("TextLabel", container, {
        Size = UDim2.new(0.7, 0, 0, 18),
        Position = UDim2.new(0, 10, 0, 6),
        Text = config.Name or "Slider",
        TextColor3 = theme.Text,
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    local valueLabel = Utilities.Create("TextLabel", container, {
        Size = UDim2.new(0, 50, 0, 18),
        Position = UDim2.new(1, -60, 0, 6),
        Text = tostring(self.Value),
        TextColor3 = theme.Accent,
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right
    })

    local sliderBg = Utilities.Create("TextButton", container, {
        Size = UDim2.new(1, -20, 0, 6),
        Position = UDim2.new(0, 10, 0, 34),
        BackgroundColor3 = theme.ToggleOff,
        Text = "",
        AutoButtonColor = false
    })
    Utilities.AddCorner(sliderBg, UDim.new(1, 0))

    local sliderFill = Utilities.Create("Frame", sliderBg, {
        Size = UDim2.new((self.Value - min) / (max - min), 0, 1, 0),
        BackgroundColor3 = theme.SliderFill,
        BorderSizePixel = 0
    })
    Utilities.AddCorner(sliderFill, UDim.new(1, 0))

    local sliderDot = Utilities.Create("Frame", sliderBg, {
        Size = UDim2.new(0, 14, 0, 14),
        Position = UDim2.new((self.Value - min) / (max - min), -7, 0.5, -7),
        BackgroundColor3 = theme.Text,
        BorderSizePixel = 0
    })
    Utilities.AddCorner(sliderDot, UDim.new(1, 0))

    local function updateValue(input)
        local mousePos = UserInputService:GetMouseLocation()
        local relPos = (mousePos - sliderBg.AbsolutePosition).X / sliderBg.AbsoluteSize.X
        local clampedValue = math.clamp(relPos, 0, 1) * (max - min) + min
        local steppedValue = math.round(clampedValue / increment) * increment
        steppedValue = math.clamp(steppedValue, min, max)

        self.Value = steppedValue
        valueLabel.Text = string.format("%.2f", steppedValue)
        sliderFill.Size = UDim2.new((steppedValue - min) / (max - min), 0, 1, 0)
        sliderDot.Position = UDim2.new((steppedValue - min) / (max - min), -7, 0.5, -7)
        self.Callback(steppedValue)
    end

    local dragging = false
    local inputBeganConn = sliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateValue(input)
        end
    end)
    table.insert(self.Connections, inputBeganConn)

    local inputChangedConn = UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateValue(input)
        end
    end)
    table.insert(self.Connections, inputChangedConn)

    local inputEndedConn = UserInputService.InputEnded:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            dragging = false
        end
    end)
    table.insert(self.Connections, inputEndedConn)

    self.Instance = container
    return self
end

-- Dropdown
local Dropdown = setmetatable({}, {__index = BaseComponent})
Dropdown.__index = Dropdown
function Dropdown.new(parent, config)
    local self = setmetatable(BaseComponent.new(parent), Dropdown)
    local theme = ThemeManager:GetCurrentTheme()
    self.Options = config.Options or {}
    self.Callback = config.Callback or function() end
    self.SelectedOption = config.DefaultValue or self.Options[1]
    self.IsOpen = false
    self.DropdownList = nil

    local container = Utilities.Create("TextButton", parent, {
        Size = UDim2.new(1, -10, 0, 36),
        BackgroundColor3 = theme.Panel,
        Text = "",
        AutoButtonColor = false,
        Name = "Dropdown_" .. (config.Name or "Dropdown")
    })
    Utilities.AddCorner(container)
    Utilities.AddStroke(container, theme.Stroke)

    Utilities.Create("TextLabel", container, {
        Size = UDim2.new(0.7, -10, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        Text = config.Name or "Dropdown",
        TextColor3 = theme.TextSecondary,
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    local selectedText = Utilities.Create("TextLabel", container, {
        Size = UDim2.new(0, 80, 1, 0),
        Position = UDim2.new(1, -110, 0, 0),
        Text = self.SelectedOption or "...",
        TextColor3 = theme.Text,
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextTruncate = Enum.TextTruncate.AtEnd
    })

    local arrow = Utilities.Create("TextLabel", container, {
        Size = UDim2.new(0, 20, 1, 0),
        Position = UDim2.new(1, -25, 0, 0),
        Text = "▼",
        TextColor3 = theme.Accent,
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 10
    })

    local function openDropdown()
        if self.IsOpen then return end
        self.IsOpen = true
        local list = Utilities.Create("ScrollingFrame", parent.Parent, {
            Size = UDim2.new(1, -10, 0, #self.Options * 30),
            Position = UDim2.new(0, 5, 0, container.Position.Y.Offset + 36),
            BackgroundColor3 = theme.Dropdown,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = theme.Scrollbar,
            CanvasSize = UDim2.new(0, 0, 0, #self.Options * 30),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ZIndex = 10,
            BorderSizePixel = 0
        })
        Utilities.AddCorner(list)
        Utilities.AddStroke(list, theme.Stroke)
        Utilities.Create("UIListLayout", list, { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 1) })

        for _, option in ipairs(self.Options) do
            local optionBtn = Utilities.Create("TextButton", list, {
                Size = UDim2.new(1, 0, 0, 30),
                Text = "",
                BackgroundColor3 = theme.Panel,
                AutoButtonColor = false,
                ZIndex = 10
            })
            Utilities.Create("TextLabel", optionBtn, {
                Size = UDim2.new(1, -10, 1, 0),
                Position = UDim2.new(0, 5, 0, 0),
                Text = option,
                TextColor3 = theme.Text,
                BackgroundTransparency = 1,
                Font = Enum.Font.Gotham,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 10
            })
            local optConn = optionBtn.MouseButton1Click:Connect(function()
                self.SelectedOption = option
                selectedText.Text = option
                self.Callback(option)
                self.IsOpen = false
                list:Destroy()
                arrow.Text = "▼"
            end)
            table.insert(self.Connections, optConn)
        end
        self.DropdownList = list
        arrow.Text = "▲"
    end

    local function closeDropdown()
        if not self.IsOpen then return end
        self.IsOpen = false
        if self.DropdownList then
            self.DropdownList:Destroy()
            self.DropdownList = nil
        end
        arrow.Text = "▼"
    end

    container.MouseButton1Click:Connect(function()
        if self.IsOpen then closeDropdown() else openDropdown() end
    end)

    self.Instance = container
    return self
end

-- Button
local Button = setmetatable({}, {__index = BaseComponent})
Button.__index = Button
function Button.new(parent, config)
    local self = setmetatable(BaseComponent.new(parent), Button)
    local theme = ThemeManager:GetCurrentTheme()
    self.Callback = config.Callback or function() end

    local container = Utilities.Create("TextButton", parent, {
        Size = UDim2.new(1, -10, 0, 36),
        BackgroundColor3 = theme.Panel,
        Text = "",
        AutoButtonColor = false,
        Name = "Button_" .. (config.Name or "Button")
    })
    Utilities.AddCorner(container)
    Utilities.AddStroke(container, theme.Stroke)

    Utilities.Create("TextLabel", container, {
        Size = UDim2.new(1, -10, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        Text = config.Name or "Button",
        TextColor3 = theme.Text,
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    local clickConn = container.MouseButton1Click:Connect(function()
        Utilities.Animate(container, TweenInfo.new(0.1), {BackgroundColor3 = theme.Accent})
        task.wait(0.1)
        Utilities.Animate(container, TweenInfo.new(0.1), {BackgroundColor3 = theme.Panel})
        self.Callback()
    end)
    table.insert(self.Connections, clickConn)

    local hConn = container.MouseEnter:Connect(function() Utilities.Animate(container, TweenInfo.new(0.15), {BackgroundColor3 = theme.Hover}) end)
    local lConn = container.MouseLeave:Connect(function() Utilities.Animate(container, TweenInfo.new(0.15), {BackgroundColor3 = theme.Panel}) end)
    table.insert(self.Connections, hConn)
    table.insert(self.Connections, lConn)

    self.Instance = container
    return self
end

-- Color Picker (Simples)
local ColorPicker = setmetatable({}, {__index = BaseComponent})
ColorPicker.__index = ColorPicker
function ColorPicker.new(parent, config)
    local self = setmetatable(BaseComponent.new(parent), ColorPicker)
    local theme = ThemeManager:GetCurrentTheme()
    self.SelectedColor = config.DefaultColor or Color3.fromRGB(255, 0, 0)
    self.Callback = config.Callback or function() end

    local container = Utilities.Create("Frame", parent, {
        Size = UDim2.new(1, -10, 0, 36),
        BackgroundColor3 = theme.Panel,
        Name = "ColorPicker_" .. (config.Name or "Color")
    })
    Utilities.AddCorner(container)
    Utilities.AddStroke(container, theme.Stroke)

    Utilities.Create("TextLabel", container, {
        Size = UDim2.new(0.7, 0, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        Text = config.Name or "Color",
        TextColor3 = theme.Text,
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    local colorDisplay = Utilities.Create("Frame", container, {
        Size = UDim2.new(0, 24, 0, 24),
        Position = UDim2.new(1, -34, 0.5, -12),
        BackgroundColor3 = self.SelectedColor,
        BorderSizePixel = 0
    })
    Utilities.AddCorner(colorDisplay, UDim.new(1, 0))
    Utilities.AddStroke(colorDisplay, theme.Text)

    local pickerFrame
    local function openPicker()
        if pickerFrame then pickerFrame:Destroy() end
        pickerFrame = Utilities.Create("Frame", parent.Parent, {
            Size = UDim2.new(1, -10, 0, 40),
            Position = UDim2.new(0, 5, 0, container.Position.Y.Offset + 40),
            BackgroundColor3 = theme.Panel,
            ZIndex = 10,
            BorderSizePixel = 0
        })
        Utilities.AddCorner(pickerFrame)
        Utilities.AddStroke(pickerFrame, theme.Stroke)

        -- Sliders para R, G, B
        local rSlider = Slider.new(pickerFrame, {
            Name = "R", Range = {0, 255}, Increment = 1,
            DefaultValue = math.round(self.SelectedColor.R * 255),
            Callback = function(v)
                self.SelectedColor = Color3.fromRGB(v, self.SelectedColor.G * 255, self.SelectedColor.B * 255)
                colorDisplay.BackgroundColor3 = self.SelectedColor
                self.Callback(self.SelectedColor)
            end
        })
        rSlider.Instance.Size = UDim2.new(1, -20, 0, 12)
        rSlider.Instance.Position = UDim2.new(0, 10, 0, 2)

        local gSlider = Slider.new(pickerFrame, {
            Name = "G", Range = {0, 255}, Increment = 1,
            DefaultValue = math.round(self.SelectedColor.G * 255),
            Callback = function(v)
                self.SelectedColor = Color3.fromRGB(self.SelectedColor.R * 255, v, self.SelectedColor.B * 255)
                colorDisplay.BackgroundColor3 = self.SelectedColor
                self.Callback(self.SelectedColor)
            end
        })
        gSlider.Instance.Size = UDim2.new(1, -20, 0, 12)
        gSlider.Instance.Position = UDim2.new(0, 10, 0, 14)

        local bSlider = Slider.new(pickerFrame, {
            Name = "B", Range = {0, 255}, Increment = 1,
            DefaultValue = math.round(self.SelectedColor.B * 255),
            Callback = function(v)
                self.SelectedColor = Color3.fromRGB(self.SelectedColor.R * 255, self.SelectedColor.G * 255, v)
                colorDisplay.BackgroundColor3 = self.SelectedColor
                self.Callback(self.SelectedColor)
            end
        })
        bSlider.Instance.Size = UDim2.new(1, -20, 0, 12)
        bSlider.Instance.Position = UDim2.new(0, 10, 0, 26)
    end

    colorDisplay.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            openPicker()
        end
    end)

    self.Instance = container
    return self
end

--==========================
-- TAB CLASS
--==========================
local Tab = {}
Tab.__index = Tab
function Tab.new(window, name)
    local self = setmetatable({}, Tab)
    self.Window = window
    self.Name = name
    self.Components = {}
    self.Container = Utilities.Create("ScrollingFrame", window.ContentArea, {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = ThemeManager:GetCurrentTheme().Scrollbar,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Visible = false,
        BorderSizePixel = 0
    })
    Utilities.Create("UIListLayout", self.Container, { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) })
    Utilities.Create("UIPadding", self.Container, { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 20) })
    return self
end

function Tab:CreateButton(config) local comp = Button.new(self.Container, config) table.insert(self.Components, comp) return comp end
function Tab:CreateToggle(config) local comp = Toggle.new(self.Container, config) table.insert(self.Components, comp) return comp end
function Tab:CreateSlider(config) local comp = Slider.new(self.Container, config) table.insert(self.Components, comp) return comp end
function Tab:CreateDropdown(config) local comp = Dropdown.new(self.Container, config) table.insert(self.Components, comp) return comp end
function Tab:CreateSection(config) local comp = Section.new(self.Container, config.Name or config.Title) table.insert(self.Components, comp) return comp end
function Tab:CreateColorPicker(config) local comp = ColorPicker.new(self.Container, config) table.insert(self.Components, comp) return comp end

function Tab:SetVisible(visible)
    if self.Container then self.Container.Visible = visible end
end

--==========================
-- WINDOW CLASS
--==========================
local Window = {}
Window.__index = Window
function Window.new(config)
    local self = setmetatable({}, Window)
    local theme = ThemeManager:GetCurrentTheme()
    self.Tabs = {}
    self.TabButtons = {}

    self.ScreenGui = Utilities.Create("ScreenGui", CoreGui, { Name = config.Name or "Axiom UI", ResetOnSpawn = false })
    self.MainFrame = Utilities.Create("Frame", self.ScreenGui, {
        Size = UDim2.new(0, 580, 0, 420),
        Position = UDim2.new(0.5, -290, 0.5, -210),
        BackgroundColor3 = theme.Background,
        BorderSizePixel = 0,
        Active = true,
        ClipsDescendants = true
    })
    Utilities.AddCorner(self.MainFrame, UDim.new(0, 8))
    Utilities.AddStroke(self.MainFrame, theme.Stroke, 2)

    -- Shadow
    Utilities.Create("Frame", self.MainFrame, {
        Size = UDim2.new(1, 4, 1, 4),
        Position = UDim2.new(0, -2, 0, -2),
        BackgroundColor3 = Color3.fromRGB(0,0,0),
        BackgroundTransparency = 0.8,
        ZIndex = -1,
        BorderSizePixel = 0
    })

    -- Title Bar
    local titleBar = Utilities.Create("Frame", self.MainFrame, {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = theme.Panel,
        BorderSizePixel = 0
    })
    Utilities.AddCorner(titleBar, UDim.new(0, 8))
    Utilities.Create("Frame", titleBar, {
        Size = UDim2.new(1, 0, 0, 8),
        Position = UDim2.new(0, 0, 1, -8),
        BackgroundColor3 = theme.Panel,
        BorderSizePixel = 0
    })

    Utilities.Create("TextLabel", titleBar, {
        Size = UDim2.new(0.8, 0, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        Text = config.Name or "Axiom UI",
        TextColor3 = theme.Text,
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    -- Close Button
    local closeBtn = Utilities.Create("TextButton", titleBar, {
        Size = UDim2.new(0, 28, 0, 28),
        Position = UDim2.new(1, -34, 0, 4),
        Text = "✕",
        TextColor3 = theme.TextSecondary,
        BackgroundColor3 = theme.Panel,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        AutoButtonColor = false
    })
    Utilities.AddCorner(closeBtn, UDim.new(0, 4))
    closeBtn.MouseButton1Click:Connect(function()
        self.ScreenGui:Destroy()
    end)

    -- Tab Area
    local tabArea = Utilities.Create("Frame", self.MainFrame, {
        Size = UDim2.new(0, 120, 1, -36),
        Position = UDim2.new(0, 0, 0, 36),
        BackgroundColor3 = theme.Panel,
        BorderSizePixel = 0
    })
    Utilities.AddStroke(tabArea, theme.Stroke, 1)
    Utilities.Create("UIListLayout", tabArea, { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2) })
    Utilities.Create("UIPadding", tabArea, { PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5) })

    -- Content Area
    self.ContentArea = Utilities.Create("Frame", self.MainFrame, {
        Size = UDim2.new(1, -120, 1, -36),
        Position = UDim2.new(0, 120, 0, 36),
        BackgroundColor3 = theme.Background,
        BorderSizePixel = 0
    })

    -- Dragging
    local dragging, dragStart, startPos
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = self.MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            self.MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)

    -- Window Methods
    function self:CreateTab(name)
        local tab = Tab.new(self, name)
        local theme = ThemeManager:GetCurrentTheme()

        local tabButton = Utilities.Create("TextButton", tabArea, {
            Size = UDim2.new(1, -2, 0, 34),
            Text = "",
            BackgroundColor3 = theme.Panel,
            AutoButtonColor = false,
            Name = "TabBtn_" .. name
        })
        Utilities.AddCorner(tabButton, UDim.new(0, 4))
        local tabLabel = Utilities.Create("TextLabel", tabButton, {
            Size = UDim2.new(1, -10, 1, 0),
            Position = UDim2.new(0, 10, 0, 0),
            Text = name,
            TextColor3 = theme.TextSecondary,
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left
        })

        tabButton.MouseButton1Click:Connect(function()
            for _, t in pairs(self.Tabs) do t:SetVisible(false) end
            tab:SetVisible(true)
            for _, btn in pairs(self.TabButtons) do
                Utilities.Animate(btn, TweenInfo.new(0.2), {BackgroundColor3 = theme.Panel})
                if btn:FindFirstChildOfClass("TextLabel") then
                    btn:FindFirstChildOfClass("TextLabel").TextColor3 = theme.TextSecondary
                end
            end
            Utilities.Animate(tabButton, TweenInfo.new(0.2), {BackgroundColor3 = theme.Hover})
            tabLabel.TextColor3 = theme.Accent
        end)

        table.insert(self.Tabs, tab)
        table.insert(self.TabButtons, tabButton)

        if #self.Tabs == 1 then
            tab:SetVisible(true)
            Utilities.Animate(tabButton, TweenInfo.new(0.2), {BackgroundColor3 = theme.Hover})
            tabLabel.TextColor3 = theme.Accent
        end
        return tab
    end

    return self
end

--==========================
-- LEGACY LOGIC (Extraída do WARCORE original)
--==========================
local SystemConfig = {
    MiraAtiva = false,
    FovRadius = 500,
    Smoothness = 0.35,
    TeamCheck = true,
    HighlightEnabled = false,
    HlDepthMode = "AlwaysOnTop",
    HlFillTransparency = 0.5,
    HlEnemyColor = Color3.fromRGB(255, 0, 0),
    DotEnabled = false,
    MicroHpEnabled = false,
    MicroDistEnabled = false,
    MicroTextSize = 8,
    MicroWidth = 35,
    FullBright = false,
    NoShadows = false,
    ClarezaMod = false,
    ShowFPS = false,
    ShowPlayers = false
}

local NoClipAtivo = false
local NoClipConnection = nil

local OriginalSettings = {
    Ambient = Lighting.Ambient,
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    GlobalShadows = Lighting.GlobalShadows,
    Exposure = Lighting.ExposureCompensation
}

function getTarget()
    local closest, shortest = nil, SystemConfig.FovRadius
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player and p.Character then
            local head = p.Character:FindFirstChild("Head")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if head and hum and hum.Health > 0 then
                local isTeam = (p.Team == Player.Team and Player.Team ~= nil)
                if not (isTeam and SystemConfig.TeamCheck) then
                    local pos, vis = Camera:WorldToViewportPoint(head.Position)
                    if vis and pos.Z > 0 then
                        local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                        if dist < shortest then
                            shortest = dist
                            closest = head
                        end
                    end
                end
            end
        end
    end
    return closest
end

function IsBehindWall(targetPart)
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {Player.Character, targetPart.Parent}
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    local result = workspace:Raycast(Camera.CFrame.Position, (targetPart.Position - Camera.CFrame.Position), rayParams)
    return result ~= nil
end

function CreateMicroDisplay(char)
    local root = char:WaitForChild("HumanoidRootPart", 5)
    if not root then return nil end
    local billboard = root:FindFirstChild("Aguia_MicroHUD")
    if not billboard then
        billboard = Instance.new("BillboardGui", root)
        billboard.Name = "Aguia_MicroHUD"
        billboard.AlwaysOnTop = true
        billboard.ExtentsOffset = Vector3.new(0, -3.7, 0)
        local bgBar = Instance.new("Frame", billboard)
        bgBar.Name = "BackgroundBar"
        bgBar.Size = UDim2.new(1, 0, 0, 2)
        bgBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        bgBar.BorderSizePixel = 0
        local mainBar = Instance.new("Frame", bgBar)
        mainBar.Name = "MainBar"
        mainBar.Size = UDim2.new(1, 0, 1, 0)
        mainBar.BorderSizePixel = 0
        local label = Instance.new("TextLabel", billboard)
        label.Name = "DistLabel"
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.GothamBold
        label.TextStrokeTransparency = 0.4
    end
    billboard.Size = UDim2.new(0, SystemConfig.MicroWidth, 0, SystemConfig.MicroTextSize + 4)
    billboard.DistLabel.Size = UDim2.new(1, 0, 0, SystemConfig.MicroTextSize)
    billboard.DistLabel.TextSize = SystemConfig.MicroTextSize
    billboard.DistLabel.Position = UDim2.new(0, 0, 0, 3)
    return billboard
end

--==========================
-- CORE LOOP
--==========================
RunService.RenderStepped:Connect(function(dt)
    -- Aimbot
    if SystemConfig.MiraAtiva then
        local target = getTarget()
        if target then
            local goal = CFrame.new(Camera.CFrame.Position, target.Position)
            Camera.CFrame = Camera.CFrame:Lerp(goal, SystemConfig.Smoothness * math.clamp(60 * dt, 0, 1))
        end
    end

    -- Lighting
    if SystemConfig.FullBright then
        Lighting.Ambient = Color3.fromRGB(178, 178, 178)
        Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
        Lighting.ClockTime = 14
    end
    if SystemConfig.ClarezaMod then
        Lighting.Brightness = 3
        Lighting.ExposureCompensation = 0.5
    else
        if not SystemConfig.FullBright then
            Lighting.Brightness = OriginalSettings.Brightness
            Lighting.ExposureCompensation = OriginalSettings.Exposure
        end
    end

    -- Visuals (RX, Dot, Micro)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player and p.Character then
            local char = p.Character
            local head = char:FindFirstChild("Head")
            if head then
                local isTeam = (p.Team == Player.Team and Player.Team ~= nil)
                local statusColor = isTeam and Color3.fromRGB(0, 255, 0) or SystemConfig.HlEnemyColor
                local hl = char:FindFirstChild("System_HL") or Instance.new("Highlight", char)
                hl.Name = "System_HL"
                hl.Enabled = SystemConfig.HighlightEnabled
                hl.FillColor = statusColor
                hl.OutlineColor = statusColor
                hl.FillTransparency = SystemConfig.HlFillTransparency
                hl.OutlineTransparency = 0
                hl.DepthMode = Enum.HighlightDepthMode[SystemConfig.HlDepthMode]

                local behind = IsBehindWall(head)
                local dotColor = isTeam and Color3.fromRGB(0, 255, 0) or (behind and Color3.fromRGB(255, 140, 0) or Color3.fromRGB(255, 0, 0))
                local dot = head:FindFirstChild("System_Dot")
                if not dot then
                    local bill = Instance.new("BillboardGui", head)
                    bill.Name = "System_Dot"
                    bill.Size = UDim2.new(0, 10, 0, 10)
                    bill.AlwaysOnTop = true
                    bill.ExtentsOffset = Vector3.new(0, 1.5, 0)
                    local f = Instance.new("Frame", bill)
                    f.Size = UDim2.new(1,0,1,0)
                    Instance.new("UICorner", f).CornerRadius = UDim.new(1,0)
                    dot = bill
                end
                dot.Enabled = SystemConfig.DotEnabled
                dot.Frame.BackgroundColor3 = dotColor
            end

            local hum = char:FindFirstChildOfClass("Humanoid")
            local root = char:FindFirstChild("HumanoidRootPart")
            if hum and root then
                local hud = root:FindFirstChild("Aguia_MicroHUD")
                if (SystemConfig.MicroHpEnabled or SystemConfig.MicroDistEnabled) and hum.Health > 0 then
                    local currentHud = CreateMicroDisplay(char)
                    if currentHud then
                        local isTeam = (p.Team == Player.Team and Player.Team ~= nil)
                        local teamColor = isTeam and Color3.fromRGB(0, 255, 120) or Color3.fromRGB(255, 50, 50)
                        if SystemConfig.MicroHpEnabled then
                            local healthRatio = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                            currentHud.BackgroundBar.MainBar.Size = UDim2.new(healthRatio, 0, 1, 0)
                            currentHud.BackgroundBar.MainBar.BackgroundColor3 = teamColor
                            currentHud.BackgroundBar.Visible = true
                        else
                            currentHud.BackgroundBar.Visible = false
                        end
                        if SystemConfig.MicroDistEnabled then
                            local distance = math.floor(Player:DistanceFromCharacter(root.Position))
                            currentHud.DistLabel.Text = string.format("%dm", distance)
                            currentHud.DistLabel.TextColor3 = teamColor
                            currentHud.DistLabel.Visible = true
                        else
                            currentHud.DistLabel.Visible = false
                        end
                        currentHud.Enabled = true
                    end
                else
                    if hud then hud.Enabled = false end
                end
            end
        end
    end
end)

-- NoClip Character Add
Player.CharacterAdded:Connect(function()
    task.wait(0.6)
    if NoClipAtivo then
        if NoClipConnection then NoClipConnection:Disconnect() end
        NoClipConnection = RunService.Stepped:Connect(function()
            local char = Player.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end)
    end
end)

--==========================
-- INITIALIZATION (Criação da UI)
--==========================
local MainWindow = Window.new({ Name = "👑 WARCORE v1.2.0" })

local CombatTab = MainWindow:CreateTab("Combate")
local VisualTab = MainWindow:CreateTab("Visual")
local RxTab = MainWindow:CreateTab("Opc RX")
local LightTab = MainWindow:CreateTab("Iluminacao")
local MovimentTab = MainWindow:CreateTab("Movimento")
local StatusTab = MainWindow:CreateTab("Monitor")

-- Aba Combate
CombatTab:CreateToggle({ Name = "Mira Assistida", DefaultValue = false, Callback = function(v) SystemConfig.MiraAtiva = v end })
CombatTab:CreateSlider({ Name = "Suavidade", Range = {0.1, 1}, Increment = 0.05, DefaultValue = 0.35, Callback = function(v) SystemConfig.Smoothness = v end })

-- Aba Visual
VisualTab:CreateSection({ Name = "Rastreamento" })
VisualTab:CreateToggle({ Name = "Scanner Raio-X", DefaultValue = false, Callback = function(v) SystemConfig.HighlightEnabled = v end })
VisualTab:CreateToggle({ Name = "Ponto na Cabeca", DefaultValue = false, Callback = function(v) SystemConfig.DotEnabled = v end })
VisualTab:CreateToggle({ Name = "Micro Vida", DefaultValue = false, Callback = function(v) SystemConfig.MicroHpEnabled = v end })
VisualTab:CreateToggle({ Name = "Micro Distancia", DefaultValue = false, Callback = function(v) SystemConfig.MicroDistEnabled = v end })
VisualTab:CreateSection({ Name = "Escala" })
VisualTab:CreateSlider({ Name = "Tamanho Texto", Range = {6, 24}, Increment = 1, DefaultValue = 8, Callback = function(v) SystemConfig.MicroTextSize = v end })
VisualTab:CreateSlider({ Name = "Largura Barra", Range = {20, 100}, Increment = 5, DefaultValue = 35, Callback = function(v) SystemConfig.MicroWidth = v end })

-- Aba Opções RX
RxTab:CreateSection({ Name = "Avancado RX" })
RxTab:CreateDropdown({
    Name = "Visibilidade", Options = {"Sempre Visivel", "Ocultar Atras"}, DefaultValue = "Sempre Visivel",
    Callback = function(opt) SystemConfig.HlDepthMode = (opt == "Sempre Visivel") and "AlwaysOnTop" or "Occluded" end
})
RxTab:CreateSlider({ Name = "Transparencia", Range = {0, 1}, Increment = 0.05, DefaultValue = 0.5, Callback = function(v) SystemConfig.HlFillTransparency = v end })
RxTab:CreateColorPicker({ Name = "Cor Inimigos", DefaultColor = Color3.fromRGB(255, 0, 0), Callback = function(c) SystemConfig.HlEnemyColor = c end })

-- Aba Iluminação
LightTab:CreateToggle({
    Name = "Full Bright", DefaultValue = false, Callback = function(v)
        SystemConfig.FullBright = v
        if not v then
            Lighting.Ambient = OriginalSettings.Ambient
            Lighting.Brightness = OriginalSettings.Brightness
            Lighting.ClockTime = OriginalSettings.ClockTime
            Lighting.FogEnd = OriginalSettings.FogEnd
            Lighting.OutdoorAmbient = OriginalSettings.OutdoorAmbient
        end
    end
})
LightTab:CreateToggle({ Name = "Clareza Tecnica", DefaultValue = false, Callback = function(v) SystemConfig.ClarezaMod = v end })
LightTab:CreateToggle({ Name = "Remover Sombras", DefaultValue = false, Callback = function(v) SystemConfig.NoShadows = v; Lighting.GlobalShadows = not v end })

-- Aba Movimento
MovimentTab:CreateToggle({
    Name = "No Clip", DefaultValue = false, Callback = function(v)
        NoClipAtivo = v
        if NoClipAtivo then
            if NoClipConnection then NoClipConnection:Disconnect() end
            NoClipConnection = RunService.Stepped:Connect(function()
                local char = Player.Character
                if char then for _, part in ipairs(char:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = false end end end
            end)
        else
            if NoClipConnection then NoClipConnection:Disconnect(); NoClipConnection = nil end
        end
    end
})
MovimentTab:CreateSection({ Name = "Util para entrar em predios." })

-- Aba Monitor
StatusTab:CreateToggle({ Name = "Mostrar FPS", DefaultValue = false, Callback = function(v) SystemConfig.ShowFPS = v end })
StatusTab:CreateToggle({ Name = "Contar Players", DefaultValue = false, Callback = function(v) SystemConfig.ShowPlayers = v end })

-- Notificação de carregamento
local notifFrame = Utilities.Create("Frame", MainWindow.ScreenGui, {
    Size = UDim2.new(0, 260, 0, 0),
    Position = UDim2.new(1, -270, 1, -10),
    BackgroundColor3 = ThemeManager:GetCurrentTheme().Panel,
    AnchorPoint = Vector2.new(0, 1),
    ClipsDescendants = true,
    ZIndex = 20
})
Utilities.AddCorner(notifFrame)
Utilities.AddStroke(notifFrame, ThemeManager:GetCurrentTheme().Accent)
Utilities.Create("TextLabel", notifFrame, {
    Size = UDim2.new(1, -10, 0, 40),
    Position = UDim2.new(0, 5, 0, 5),
    Text = "👑 WARCORE v1.2.0 carregado!",
    TextColor3 = ThemeManager:GetCurrentTheme().Text,
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    ZIndex = 20
})
Utilities.Animate(notifFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {Size = UDim2.new(0, 260, 0, 50)})
task.wait(4)
Utilities.Animate(notifFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {Size = UDim2.new(0, 260, 0, 0)})
task.wait(0.5)
notifFrame:Destroy()