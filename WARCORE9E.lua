--[[
    ╔════════════════════════════════════════════════════════════╗
    ║       PROJECT: WARCORE v1.2.0 (ADVANCED RX OVERHAUL)       ║
    ║       STUDIO: WARCORE LABS                                 ║
    ║------------------------------------------------------------║
    ║       LEAD DEVELOPER: ENZO CAVALCANTI                      ║
    ║       MOD: ABA EXCLUSIVA DE CUSTOMIZAÇÃO PARA RAIO-X       ║
    ╚════════════════════════════════════════════════════════════╝
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local Player = Players.LocalPlayer
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

--// [CONFIGURAÇÃO GLOBAL - WARCORE]
getgenv().SystemConfig = {
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
    ShowPlayers = false,
    -- Movimento
    FlyEnabled = false,
    FlySpeed = 50,
    FlyInfinite = false,
    SpeedEnabled = false,
    SpeedValue = 50,
    JumpEnabled = false,
    JumpPower = 100,
    InfiniteJump = false
}

local NoClipAtivo = false
local NoClipConnection = nil

-- Variáveis de controle do Fly
local flyVelocity = nil
local flyConnection = nil

-- Valores originais do personagem
local OriginalWalkSpeed = 16
local OriginalJumpPower = 50

local OriginalSettings = {
    Ambient = Lighting.Ambient,
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    GlobalShadows = Lighting.GlobalShadows,
    Exposure = Lighting.ExposureCompensation
}

--// [SISTEMA DE INTERFACE: TAGS E BOTÃO ELITE NEON]
local ScreenGui = Instance.new("ScreenGui", CoreGui)
local TagContainer = Instance.new("Frame", ScreenGui)
TagContainer.Size = UDim2.new(0, 60, 0, 50)
TagContainer.Position = UDim2.new(0, 5, 0, 45)
TagContainer.BackgroundTransparency = 1
local UIList = Instance.new("UIListLayout", TagContainer)
UIList.Padding = UDim.new(0, 3)

local function CreateTag(color)
    local f = Instance.new("Frame", TagContainer)
    f.Size = UDim2.new(0, 75, 0, 18)
    f.BackgroundColor3 = Color3.fromRGB(15, 18, 28)
    f.BackgroundTransparency = 0.2
    f.Visible = false
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 5)
    
    local stroke = Instance.new("UIStroke", f)
    stroke.Thickness = 1
    stroke.Color = color
    stroke.Transparency = 0.4
    
    local l = Instance.new("TextLabel", f)
    l.Size = UDim2.new(1, 0, 1, 0)
    l.BackgroundTransparency = 1
    l.TextColor3 = Color3.fromRGB(255, 255, 255)
    l.TextSize = 10
    l.Font = Enum.Font.GothamBold
    return f, l
end

local fpsF, fpsL = CreateTag(Color3.fromRGB(0, 240, 255))
local countF, countL = CreateTag(Color3.fromRGB(255, 0, 120))

-- Botão Flutuante Elite
local FloatingBtn = Instance.new("TextButton", ScreenGui)
FloatingBtn.Visible = false
FloatingBtn.Size = UDim2.new(0, 70, 0, 38)
FloatingBtn.Position = UDim2.new(0.1, 0, 0.5, 0)
FloatingBtn.BackgroundColor3 = Color3.fromRGB(11, 14, 24)
FloatingBtn.Text = "⚡ OFF"
FloatingBtn.TextColor3 = Color3.fromRGB(130, 140, 160)
FloatingBtn.Font = Enum.Font.GothamBold
FloatingBtn.TextSize = 13
FloatingBtn.Draggable = true
FloatingBtn.Active = true

local BtnCorner = Instance.new("UICorner", FloatingBtn)
BtnCorner.CornerRadius = UDim.new(0, 10)

local Stroke = Instance.new("UIStroke", FloatingBtn)
Stroke.Thickness = 2
Stroke.Color = Color3.fromRGB(35, 42, 65)

local function UpdateBtnVisual(active)
    if active then
        TweenService:Create(FloatingBtn, TweenInfo.new(0.25), {BackgroundColor3 = Color3.fromRGB(16, 28, 48)}):Play()
        TweenService:Create(Stroke, TweenInfo.new(0.25), {Color = Color3.fromRGB(0, 240, 255)}):Play()
        FloatingBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        FloatingBtn.Text = "⚡ ON"
    else
        TweenService:Create(FloatingBtn, TweenInfo.new(0.25), {BackgroundColor3 = Color3.fromRGB(11, 14, 24)}):Play()
        TweenService:Create(Stroke, TweenInfo.new(0.25), {Color = Color3.fromRGB(35, 42, 65)}):Play()
        FloatingBtn.TextColor3 = Color3.fromRGB(130, 140, 160)
        FloatingBtn.Text = "⚡ OFF"
    end
end

FloatingBtn.MouseButton1Click:Connect(function()
    getgenv().SystemConfig.MiraAtiva = not getgenv().SystemConfig.MiraAtiva
    UpdateBtnVisual(getgenv().SystemConfig.MiraAtiva)
end)

--// [FUNÇÃO: BUSCA DE ALVO]
local function getTarget()
    local closest, shortest = nil, getgenv().SystemConfig.FovRadius
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player and p.Character then
            local head = p.Character:FindFirstChild("Head")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            
            if head and hum and hum.Health > 0 then
                local isTeam = (p.Team == Player.Team and Player.Team ~= nil)
                if not (isTeam and getgenv().SystemConfig.TeamCheck) then
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

--// [FUNÇÃO: WALL CHECK]
local function IsBehindWall(targetPart)
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {Player.Character, targetPart.Parent}
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    local result = workspace:Raycast(Camera.CFrame.Position, (targetPart.Position - Camera.CFrame.Position), rayParams)
    return result ~= nil
end

--// [FUNÇÃO INTEGRADA DO MICRO-HUD]
local function CreateMicroDisplay(char)
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

    billboard.Size = UDim2.new(0, getgenv().SystemConfig.MicroWidth, 0, getgenv().SystemConfig.MicroTextSize + 4)
    billboard.DistLabel.Size = UDim2.new(1, 0, 0, getgenv().SystemConfig.MicroTextSize)
    billboard.DistLabel.TextSize = getgenv().SystemConfig.MicroTextSize
    billboard.DistLabel.Position = UDim2.new(0, 0, 0, 3)

    return billboard
end

--// [INTERFACE RAYFIELD]
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "👑 WARCORE v1.2.0",
   LoadingTitle = "WARCORE está iniciando meu rei...",
   LoadingSubtitle = "WARCORE LABS PROTOCOL",
   ConfigurationSaving = { Enabled = false },
   Theme = "Custom"
})

Window.BackgroundColor = Color3.fromRGB(11, 13, 23)

local CombatTab = Window:CreateTab("🔫 Combate", 10734950020)
local VisualTab = Window:CreateTab("👁️ Visual", 10734951477)
local RxTab = Window:CreateTab("🛸 Opções RX", 10734951477)
local LightTab = Window:CreateTab("💡 Iluminação", 10734951477)
local MovimentTab = Window:CreateTab("🧱 Movimento", 4483362458)
local TeleportTab = Window:CreateTab("📍 Teleporte", 10734951477)
local StatusTab = Window:CreateTab("📊 Monitor", 4483362458)

--// ABA: COMBATE
CombatTab:CreateToggle({ 
    Name = "Ativar Mira Assistida", 
    CurrentValue = false, 
    Callback = function(v) 
        getgenv().SystemConfig.MiraAtiva = v 
        FloatingBtn.Visible = v 
        UpdateBtnVisual(v)
    end 
})
CombatTab:CreateSlider({ Name = "Suavidade de Resposta", Range = {0.1, 1}, Increment = 0.05, CurrentValue = 0.35, Callback = function(v) getgenv().SystemConfig.Smoothness = v end })

--// ABA: VISUAL
VisualTab:CreateSection("Elementos de Rastreamento")
VisualTab:CreateToggle({ Name = "Ativar Scanner Raio-X (RX)", CurrentValue = false, Callback = function(v) getgenv().SystemConfig.HighlightEnabled = v end })
VisualTab:CreateToggle({ Name = "Fixar Ponto na Cabeça", CurrentValue = false, Callback = function(v) getgenv().SystemConfig.DotEnabled = v end })
VisualTab:CreateToggle({ Name = "Micro-HUD: Exibir Vida nos Pés", CurrentValue = false, Callback = function(v) getgenv().SystemConfig.MicroHpEnabled = v end }) 
VisualTab:CreateToggle({ Name = "Micro-HUD: Exibir Distância", CurrentValue = false, Callback = function(v) getgenv().SystemConfig.MicroDistEnabled = v end }) 

VisualTab:CreateSection("Ajuste de Escala (Tamanho)")
VisualTab:CreateSlider({ Name = "Tamanho do Texto (Distância)", Range = {6, 24}, Increment = 1, CurrentValue = 8, Callback = function(v) getgenv().SystemConfig.MicroTextSize = v end })
VisualTab:CreateSlider({ Name = "Largura da Barra de Vida", Range = {20, 100}, Increment = 5, CurrentValue = 35, Callback = function(v) getgenv().SystemConfig.MicroWidth = v end })

--// [ABA]: OPÇÕES RX
RxTab:CreateSection("Configurações Avançadas do Raio-X")
RxTab:CreateDropdown({
   Name = "Modo de Visibilidade (Parede)",
   Options = {"Ver através (AlwaysOnTop)", "Ocultar atrás (Occluded)"},
   CurrentOption = "Ver através (AlwaysOnTop)",
   MultipleOptions = false,
   Callback = function(Option)
       if Option == "Ver através (AlwaysOnTop)" then
           getgenv().SystemConfig.HlDepthMode = "AlwaysOnTop"
       else
           getgenv().SystemConfig.HlDepthMode = "Occluded"
       end
   end,
})

RxTab:CreateSlider({
    Name = "Transparência do Brilho (Fill)",
    Range = {0, 1},
    Increment = 0.05,
    CurrentValue = 0.5,
    Callback = function(v)
        getgenv().SystemConfig.HlFillTransparency = v
    end
})

RxTab:CreateColorPicker({
    Name = "Cor do Contorno (Inimigos)",
    Color = Color3.fromRGB(255, 0, 0),
    Callback = function(Value)
        getgenv().SystemConfig.HlEnemyColor = Value
    end
})

--// ABA: ILUMINAÇÃO
LightTab:CreateToggle({ 
    Name = "Filtro FullBright Ambiência", 
    CurrentValue = false, 
    Callback = function(v) 
        getgenv().SystemConfig.FullBright = v 
        if not v then
            Lighting.Ambient = OriginalSettings.Ambient
            Lighting.Brightness = OriginalSettings.Brightness
            Lighting.ClockTime = OriginalSettings.ClockTime
            Lighting.FogEnd = OriginalSettings.FogEnd
            Lighting.OutdoorAmbient = OriginalSettings.OutdoorAmbient
        end
    end 
})
LightTab:CreateToggle({ Name = "Clareza Técnico Aprimorada", CurrentValue = false, Callback = function(v) getgenv().SystemConfig.ClarezaMod = v end })
LightTab:CreateToggle({ Name = "Otimizar: Remover Sombras", CurrentValue = false, Callback = function(v) Lighting.GlobalShadows = not v end })

--// =============================================
--// ABA: MOVIMENTO (Fly, Speed, Pulo)
--// =============================================

-- Seção Fly
MovimentTab:CreateSection("🕊️ Fly")

local function stopFly()
    if flyConnection then flyConnection:Disconnect(); flyConnection = nil end
    if flyVelocity then flyVelocity:Destroy(); flyVelocity = nil end
    getgenv().SystemConfig.FlyEnabled = false
end

local function startFly()
    local char = Player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.PlatformStand = false
        hum.AutoRotate = true
    end

    if flyVelocity then flyVelocity:Destroy() end
    flyVelocity = Instance.new("BodyVelocity")
    flyVelocity.Name = "FlyVelocity"
    flyVelocity.MaxForce = Vector3.new(400000, 400000, 400000)
    flyVelocity.Parent = hrp
    getgenv().SystemConfig.FlyEnabled = true

    if flyConnection then flyConnection:Disconnect() end
    flyConnection = RunService.RenderStepped:Connect(function()
        if not getgenv().SystemConfig.FlyEnabled then stopFly(); return end
        local char = Player.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then return end
        if not flyVelocity then return end

        local speed = getgenv().SystemConfig.FlySpeed
        local targetVel = Vector3.zero

        if getgenv().SystemConfig.FlyInfinite then
            targetVel = Camera.CFrame.LookVector * speed
        else
            local moveDir = hum.MoveDirection
            if moveDir.Magnitude > 0 then
                local flatLook = Vector3.new(Camera.CFrame.LookVector.X, 0, Camera.CFrame.LookVector.Z)
                if flatLook.Magnitude > 0 then flatLook = flatLook.Unit end
                local flatCamCFrame = CFrame.lookAt(Vector3.zero, flatLook)
                local rawInput = flatCamCFrame:VectorToObjectSpace(moveDir)
                targetVel = Camera.CFrame:VectorToWorldSpace(rawInput) * speed
            else
                targetVel = Vector3.zero
            end
        end
        flyVelocity.Velocity = targetVel
    end)
end

MovimentTab:CreateToggle({ Name = "Ativar Fly", CurrentValue = false, Callback = function(v) if v then startFly() else stopFly() end end })
MovimentTab:CreateToggle({ Name = "Modo Infinito (câmera)", CurrentValue = false, Callback = function(v) getgenv().SystemConfig.FlyInfinite = v end })
MovimentTab:CreateSlider({ Name = "Velocidade do Fly", Range = {1,500}, Increment = 1, CurrentValue = 50, Callback = function(v) getgenv().SystemConfig.FlySpeed = v end })

-- Seção No-Clip
MovimentTab:CreateSection("🧱 No-Clip")
MovimentTab:CreateToggle({
    Name = "Ativar Matriz No-Clip",
    CurrentValue = false,
    Callback = function(v)
        NoClipAtivo = v
        if NoClipAtivo then
            NoClipConnection = RunService.Stepped:Connect(function()
                local char = Player.Character
                if char then
                    for _, part in ipairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then part.CanCollide = false end
                    end
                end
            end)
        else
            if NoClipConnection then NoClipConnection:Disconnect(); NoClipConnection = nil end
        end
    end
})

-- Seção Speed Hack
MovimentTab:CreateSection("⚡ Velocidade de Caminhada")
MovimentTab:CreateToggle({
    Name = "Ativar Speed Hack",
    CurrentValue = false,
    Callback = function(v)
        getgenv().SystemConfig.SpeedEnabled = v
        local char = Player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = v and getgenv().SystemConfig.SpeedValue or OriginalWalkSpeed
        end
    end
})
MovimentTab:CreateSlider({
    Name = "Velocidade", Range = {16,200}, Increment = 1, CurrentValue = 50,
    Callback = function(v)
        getgenv().SystemConfig.SpeedValue = v
        if getgenv().SystemConfig.SpeedEnabled then
            local char = Player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = v end
        end
    end
})

-- Seção Super Pulo
MovimentTab:CreateSection("🦘 Super Pulo")
MovimentTab:CreateToggle({
    Name = "Ativar Super Pulo",
    CurrentValue = false,
    Callback = function(v)
        getgenv().SystemConfig.JumpEnabled = v
        local char = Player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.JumpPower = v and getgenv().SystemConfig.JumpPower or OriginalJumpPower
        end
    end
})
MovimentTab:CreateSlider({
    Name = "Altura do Pulo", Range = {50,300}, Increment = 5, CurrentValue = 100,
    Callback = function(v)
        getgenv().SystemConfig.JumpPower = v
        if getgenv().SystemConfig.JumpEnabled then
            local char = Player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then hum.JumpPower = v end
        end
    end
})

-- Seção Pulo Infinito
MovimentTab:CreateSection("🔄 Pulo Infinito")
MovimentTab:CreateToggle({
    Name = "Pulo Infinito (pular no ar)", CurrentValue = false,
    Callback = function(v) getgenv().SystemConfig.InfiniteJump = v end
})

--// =============================================
--// 🔥 SISTEMA DE TELEPORTE – REDESENHO TOTAL
--// =============================================

local tpGui = Instance.new("ScreenGui", CoreGui)
tpGui.Name = "WarcoreTeleporte"
tpGui.Enabled = true
tpGui.ResetOnSpawn = false

-- ========================
-- BOTÃO FLUTUANTE MODERNO
-- ========================
local TpFloatingBtn = Instance.new("TextButton", tpGui)
TpFloatingBtn.Size = UDim2.new(0, 58, 0, 58)
TpFloatingBtn.Position = UDim2.new(0.8, 0, 0.7, 0)
TpFloatingBtn.BackgroundColor3 = Color3.fromRGB(11, 13, 23)
TpFloatingBtn.BackgroundTransparency = 0.1
TpFloatingBtn.Text = "📍"
TpFloatingBtn.TextColor3 = Color3.fromRGB(0, 240, 255)
TpFloatingBtn.Font = Enum.Font.GothamBold
TpFloatingBtn.TextSize = 30
TpFloatingBtn.AutoButtonColor = false
TpFloatingBtn.Visible = false
TpFloatingBtn.Active = true
TpFloatingBtn.ZIndex = 10

Instance.new("UICorner", TpFloatingBtn).CornerRadius = UDim.new(0, 22)

local floatShadow = Instance.new("UIStroke", TpFloatingBtn)
floatShadow.Thickness = 3
floatShadow.Color = Color3.fromRGB(0, 0, 0)
floatShadow.Transparency = 0.5
local floatStroke = Instance.new("UIStroke", TpFloatingBtn)
floatStroke.Thickness = 1.5
floatStroke.Color = Color3.fromRGB(0, 240, 255)
floatStroke.Transparency = 0.6

local isDragging = false
local dragStartPos = nil
local btnStartPos = nil
local hasMoved = false

TpFloatingBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = true
        hasMoved = false
        dragStartPos = input.Position
        btnStartPos = TpFloatingBtn.Position
        TweenService:Create(TpFloatingBtn, TweenInfo.new(0.1), {Size = UDim2.new(0, 64, 0, 64)}):Play()
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                isDragging = false
                TweenService:Create(TpFloatingBtn, TweenInfo.new(0.1), {Size = UDim2.new(0, 58, 0, 58)}):Play()
            end
        end)
    end
end)

TpFloatingBtn.InputChanged:Connect(function(input)
    if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStartPos
        if delta.Magnitude > 5 then hasMoved = true end
        TpFloatingBtn.Position = UDim2.new(
            btnStartPos.X.Scale, btnStartPos.X.Offset + delta.X,
            btnStartPos.Y.Scale, btnStartPos.Y.Offset + delta.Y
        )
    end
end)

TpFloatingBtn.InputEnded:Connect(function(input)
    if not hasMoved and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        toggleMenu(true)
    end
    hasMoved = false
end)

-- ========================
-- JANELA PRINCIPAL (DESIGN PREMIUM)
-- ========================
local tpFrame = Instance.new("Frame", tpGui)
tpFrame.Size = UDim2.new(0, 360, 0, 540)
tpFrame.Position = UDim2.new(0.5, -180, 0.5, -270)
tpFrame.BackgroundColor3 = Color3.fromRGB(18, 20, 30)
tpFrame.BorderSizePixel = 0
tpFrame.ClipsDescendants = true
tpFrame.Visible = false
tpFrame.ZIndex = 5

local frameCorner = Instance.new("UICorner", tpFrame)
frameCorner.CornerRadius = UDim.new(0, 18)

local shadow1 = Instance.new("UIStroke", tpFrame)
shadow1.Thickness = 6
shadow1.Color = Color3.fromRGB(0, 0, 0)
shadow1.Transparency = 0.7
shadow1.Name = "Shadow1"

local shadow2 = Instance.new("UIStroke", tpFrame)
shadow2.Thickness = 2
shadow2.Color = Color3.fromRGB(0, 0, 0)
shadow2.Transparency = 0.5
shadow2.Name = "Shadow2"

local border = Instance.new("UIStroke", tpFrame)
border.Thickness = 1
border.Color = Color3.fromRGB(40, 50, 70)
border.Transparency = 0.3

-- ========================
-- BARRA DE TÍTULO ELEGANTE
-- ========================
local titleBar = Instance.new("Frame", tpFrame)
titleBar.Size = UDim2.new(1, 0, 0, 42)
titleBar.BackgroundColor3 = Color3.fromRGB(22, 25, 38)
titleBar.BorderSizePixel = 0
local titleCorner = Instance.new("UICorner", titleBar)
titleCorner.CornerRadius = UDim.new(0, 18)
local titleFix = Instance.new("Frame", titleBar)
titleFix.Size = UDim2.new(1, 0, 0, 20)
titleFix.Position = UDim2.new(0, 0, 0, 22)
titleFix.BackgroundColor3 = Color3.fromRGB(22, 25, 38)
titleFix.BorderSizePixel = 0

local icon = Instance.new("ImageLabel", titleBar)
icon.Size = UDim2.new(0, 26, 0, 26)
icon.Position = UDim2.new(0, 10, 0, 8)
icon.BackgroundTransparency = 1
icon.Image = "rbxassetid://10734951477"
icon.ImageColor3 = Color3.fromRGB(0, 240, 255)
icon.ScaleType = Enum.ScaleType.Fit

local titleLabel = Instance.new("TextLabel", titleBar)
titleLabel.Size = UDim2.new(1, -110, 1, 0)
titleLabel.Position = UDim2.new(0, 42, 0, 0)
titleLabel.Text = "Teleporte Rápido"
titleLabel.TextColor3 = Color3.fromRGB(230, 235, 245)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 18
titleLabel.BackgroundTransparency = 1

local minimizeBtn = Instance.new("TextButton", titleBar)
minimizeBtn.Size = UDim2.new(0, 32, 0, 32)
minimizeBtn.Position = UDim2.new(1, -68, 0, 5)
minimizeBtn.Text = "─"
minimizeBtn.TextColor3 = Color3.fromRGB(200, 210, 220)
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextSize = 20
minimizeBtn.BackgroundColor3 = Color3.fromRGB(40, 45, 55)
minimizeBtn.BackgroundTransparency = 0.3
minimizeBtn.AutoButtonColor = false
Instance.new("UICorner", minimizeBtn).CornerRadius = UDim.new(0, 10)

local closeBtn = Instance.new("TextButton", titleBar)
closeBtn.Size = UDim2.new(0, 32, 0, 32)
closeBtn.Position = UDim2.new(1, -32, 0, 5)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 200, 200)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 20
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
closeBtn.BackgroundTransparency = 0.3
closeBtn.AutoButtonColor = false
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 10)

local function hover(btn, baseColor, hoverColor, textHover)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = hoverColor, BackgroundTransparency = 0.1}):Play()
        if textHover then TweenService:Create(btn, TweenInfo.new(0.2), {TextColor3 = textHover}):Play() end
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = baseColor, BackgroundTransparency = 0.3}):Play()
        if textHover then TweenService:Create(btn, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(200,210,220)}):Play() end
    end)
end
hover(minimizeBtn, Color3.fromRGB(40,45,55), Color3.fromRGB(60,65,75), Color3.fromRGB(255,255,255))
hover(closeBtn, Color3.fromRGB(180,50,50), Color3.fromRGB(220,70,70), Color3.fromRGB(255,255,255))

local winDragging = false
local winStart, winFrameStart
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        winDragging = true
        winStart = input.Position
        winFrameStart = tpFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then winDragging = false end
        end)
    end
end)
titleBar.InputChanged:Connect(function(input)
    if winDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - winStart
        tpFrame.Position = UDim2.new(winFrameStart.X.Scale, winFrameStart.X.Offset + delta.X, winFrameStart.Y.Scale, winFrameStart.Y.Offset + delta.Y)
    end
end)

-- ========================
-- CONTEÚDO INTERNO REFINADO
-- ========================

local posPanel = Instance.new("Frame", tpFrame)
posPanel.Size = UDim2.new(1, -24, 0, 46)
posPanel.Position = UDim2.new(0, 12, 0, 52)
posPanel.BackgroundColor3 = Color3.fromRGB(25, 28, 38)
posPanel.BorderSizePixel = 0
Instance.new("UICorner", posPanel).CornerRadius = UDim.new(0, 10)
local posStroke = Instance.new("UIStroke", posPanel)
posStroke.Thickness = 1
posStroke.Color = Color3.fromRGB(0, 240, 255)
posStroke.Transparency = 0.8

local posLabel = Instance.new("TextLabel", posPanel)
posLabel.Size = UDim2.new(1, -10, 1, 0)
posLabel.Position = UDim2.new(0, 5, 0, 0)
posLabel.BackgroundTransparency = 1
posLabel.Text = "📍 Posição: --, --, --"
posLabel.TextColor3 = Color3.fromRGB(200, 220, 240)
posLabel.Font = Enum.Font.GothamMedium
posLabel.TextSize = 15

local inputName = Instance.new("TextBox", tpFrame)
inputName.Size = UDim2.new(1, -24, 0, 48)
inputName.Position = UDim2.new(0, 12, 0, 110)
inputName.PlaceholderText = "Nome do Local"
inputName.PlaceholderColor3 = Color3.fromRGB(140, 150, 165)
inputName.BackgroundColor3 = Color3.fromRGB(25, 28, 38)
inputName.TextColor3 = Color3.fromRGB(255, 255, 255)
inputName.Font = Enum.Font.Gotham
inputName.TextSize = 16
inputName.ClearTextOnFocus = false
Instance.new("UICorner", inputName).CornerRadius = UDim.new(0, 10)
local inputStroke = Instance.new("UIStroke", inputName)
inputStroke.Thickness = 1
inputStroke.Color = Color3.fromRGB(60, 70, 85)
inputStroke.Transparency = 0.5

local saveBtn = Instance.new("TextButton", tpFrame)
saveBtn.Size = UDim2.new(1, -24, 0, 48)
saveBtn.Position = UDim2.new(0, 12, 0, 170)
saveBtn.Text = "💾 Salvar Local"
saveBtn.BackgroundColor3 = Color3.fromRGB(0, 130, 240)
saveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
saveBtn.Font = Enum.Font.GothamBold
saveBtn.TextSize = 17
saveBtn.AutoButtonColor = false
Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0, 10)
local saveStroke = Instance.new("UIStroke", saveBtn)
saveStroke.Thickness = 1
saveStroke.Color = Color3.fromRGB(255, 255, 255)
saveStroke.Transparency = 0.5
hover(saveBtn, Color3.fromRGB(0,130,240), Color3.fromRGB(0,160,255), Color3.fromRGB(255,255,255))

local container = Instance.new("ScrollingFrame", tpFrame)
container.Size = UDim2.new(1, -24, 0, 250)
container.Position = UDim2.new(0, 12, 0, 230)
container.BackgroundColor3 = Color3.fromRGB(25, 28, 38)
container.BorderSizePixel = 0
container.ScrollBarThickness = 5
container.ScrollBarImageColor3 = Color3.fromRGB(0, 240, 255)
Instance.new("UICorner", container).CornerRadius = UDim.new(0, 10)

local layout = Instance.new("UIListLayout", container)
layout.Padding = UDim.new(0, 8)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.SortOrder = Enum.SortOrder.LayoutOrder

local clearBtn = Instance.new("TextButton", tpFrame)
clearBtn.Size = UDim2.new(1, -24, 0, 46)
clearBtn.Position = UDim2.new(0, 12, 0, 492)
clearBtn.Text = "🗑 Limpar Tudo"
clearBtn.BackgroundColor3 = Color3.fromRGB(160, 45, 45)
clearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
clearBtn.Font = Enum.Font.GothamBold
clearBtn.TextSize = 17
clearBtn.AutoButtonColor = false
Instance.new("UICorner", clearBtn).CornerRadius = UDim.new(0, 10)
local clearStroke = Instance.new("UIStroke", clearBtn)
clearStroke.Thickness = 1
clearStroke.Color = Color3.fromRGB(255, 255, 255)
clearStroke.Transparency = 0.5
hover(clearBtn, Color3.fromRGB(160,45,45), Color3.fromRGB(200,65,65), Color3.fromRGB(255,255,255))

-- Dados dos locais salvos
local savedLocations = {}

local function refreshContainer()
    for _, child in ipairs(container:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    for i, loc in ipairs(savedLocations) do
        local btn = Instance.new("TextButton", container)
        btn.Size = UDim2.new(1, -10, 0, 44)
        btn.Text = loc.name .. "\n" .. string.format("%.1f, %.1f, %.1f", loc.x, loc.y, loc.z)
        btn.BackgroundColor3 = Color3.fromRGB(30, 35, 50)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 14
        btn.LayoutOrder = i
        btn.AutoButtonColor = false
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        hover(btn, Color3.fromRGB(30,35,50), Color3.fromRGB(50,55,70))
        btn.MouseButton1Click:Connect(function()
            local char = Player.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.CFrame = CFrame.new(loc.x, loc.y, loc.z)
                Rayfield:Notify({
                    Title = "Teleportado",
                    Content = "Movido para " .. loc.name,
                    Duration = 2,
                    Image = 4483362458
                })
            end
        end)
    end
    container.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
end

saveBtn.MouseButton1Click:Connect(function()
    if inputName.Text == "" then
        Rayfield:Notify({Title = "Aviso", Content = "Digite um nome para o local.", Duration = 2, Image = 4483362458})
        return
    end
    local char = Player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local pos = char.HumanoidRootPart.Position
    local x, y, z = math.floor(pos.X * 100) / 100, math.floor(pos.Y * 100) / 100, math.floor(pos.Z * 100) / 100
    table.insert(savedLocations, {name = inputName.Text, x = x, y = y, z = z})
    inputName.Text = ""
    refreshContainer()
    Rayfield:Notify({Title = "Salvo", Content = inputName.Text .. " adicionado.", Duration = 2, Image = 4483362458})
end)

clearBtn.MouseButton1Click:Connect(function()
    if #savedLocations == 0 then return end
    savedLocations = {}
    refreshContainer()
    Rayfield:Notify({Title = "Limpo", Content = "Todos os locais foram removidos.", Duration = 2, Image = 4483362458})
end)

-- Função para animar botão flutuante
local function animateBtn(btn, visible)
    if visible then
        btn.Visible = true
        btn.Size = UDim2.new(0, 0, 0, 0)
        btn.BackgroundTransparency = 1
        TweenService:Create(btn, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 58, 0, 58),
            BackgroundTransparency = 0.1
        }):Play()
    else
        local tween = TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1
        })
        tween:Play()
        tween.Completed:Connect(function() btn.Visible = false end)
    end
end

-- Função toggleMenu
function toggleMenu(show)
    if show then
        tpFrame.Visible = true
        tpFrame.Size = UDim2.new(0, 0, 0, 540)
        tpFrame.BackgroundTransparency = 1
        TweenService:Create(tpFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 360, 0, 540),
            BackgroundTransparency = 0.0
        }):Play()
        animateBtn(TpFloatingBtn, false)
    else
        local tween = TweenService:Create(tpFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 540),
            BackgroundTransparency = 1
        })
        tween:Play()
        tween.Completed:Connect(function()
            tpFrame.Visible = false
            if teleportToggle.CurrentValue then
                animateBtn(TpFloatingBtn, true)
            end
        end)
    end
end

minimizeBtn.MouseButton1Click:Connect(function()
    toggleMenu(false)
end)

closeBtn.MouseButton1Click:Connect(function()
    toggleMenu(false)
    teleportToggle:Set(false)
end)

local teleportToggle = TeleportTab:CreateToggle({
    Name = "Ativar Sistema de Teleporte",
    CurrentValue = false,
    Callback = function(value)
        if value then
            if not tpFrame.Visible then
                animateBtn(TpFloatingBtn, true)
            end
        else
            if tpFrame.Visible then
                tpFrame.Visible = false
            end
            animateBtn(TpFloatingBtn, false)
        end
    end
})

-- Atualiza posição em tempo real
RunService.RenderStepped:Connect(function()
    if tpFrame.Visible and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
        local p = Player.Character.HumanoidRootPart.Position
        posLabel.Text = string.format("📍 Posição: %.1f, %.1f, %.1f", p.X, p.Y, p.Z)
    end
end)

--// ABA: MONITOR
StatusTab:CreateToggle({ Name = "Monitorar Taxa de FPS", CurrentValue = false, Callback = function(v) getgenv().SystemConfig.ShowFPS = v fpsF.Visible = v end })
StatusTab:CreateToggle({ Name = "Contador Ativo de Players", CurrentValue = false, Callback = function(v) getgenv().SystemConfig.ShowPlayers = v countF.Visible = v end })

--// [LOOP MASTER]
RunService.RenderStepped:Connect(function(dt)
    if getgenv().SystemConfig.InfiniteJump then
        local char = Player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum:GetState() == Enum.HumanoidStateType.Freefall and UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end

    if getgenv().SystemConfig.ShowFPS then fpsL.Text = " ⚡ FPS: " .. math.floor(1/dt) end
    if getgenv().SystemConfig.ShowPlayers then countL.Text = " 👥 Players: " .. #Players:GetPlayers() end

    if getgenv().SystemConfig.MiraAtiva then
        local target = getTarget()
        if target then
            local goal = CFrame.new(Camera.CFrame.Position, target.Position)
            Camera.CFrame = Camera.CFrame:Lerp(goal, getgenv().SystemConfig.Smoothness * math.clamp(60 * dt, 0, 1))
        end
    end

    if getgenv().SystemConfig.FullBright then
        Lighting.Ambient = Color3.fromRGB(178, 178, 178)
        Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
        Lighting.ClockTime = 14
    end
    if getgenv().SystemConfig.ClarezaMod then
        Lighting.Brightness = 3
        Lighting.ExposureCompensation = 0.5
    else
        if not getgenv().SystemConfig.FullBright then
            Lighting.Brightness = OriginalSettings.Brightness
            Lighting.ExposureCompensation = OriginalSettings.Exposure
        end
    end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player and p.Character then
            local char = p.Character
            local head = char:FindFirstChild("Head")
            if head then
                local isTeam = (p.Team == Player.Team and Player.Team ~= nil)
                local statusColor = isTeam and Color3.fromRGB(0, 255, 0) or getgenv().SystemConfig.HlEnemyColor
                local hl = char:FindFirstChild("System_HL") or Instance.new("Highlight", char)
                hl.Name = "System_HL"
                hl.Enabled = getgenv().SystemConfig.HighlightEnabled
                hl.FillColor = statusColor
                hl.OutlineColor = statusColor
                hl.FillTransparency = getgenv().SystemConfig.HlFillTransparency
                hl.OutlineTransparency = 0
                hl.DepthMode = Enum.HighlightDepthMode[getgenv().SystemConfig.HlDepthMode]
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
                dot.Enabled = getgenv().SystemConfig.DotEnabled
                dot.Frame.BackgroundColor3 = dotColor
            end
            local hum = char:FindFirstChildOfClass("Humanoid")
            local root = char:FindFirstChild("HumanoidRootPart")
            if hum and root then
                local hud = root:FindFirstChild("Aguia_MicroHUD")
                if (getgenv().SystemConfig.MicroHpEnabled or getgenv().SystemConfig.MicroDistEnabled) and hum.Health > 0 then
                    local currentHud = CreateMicroDisplay(char)
                    if currentHud then
                        local isTeam = (p.Team == Player.Team and Player.Team ~= nil)
                        local teamColor = isTeam and Color3.fromRGB(0, 255, 120) or Color3.fromRGB(255, 50, 50)
                        if getgenv().SystemConfig.MicroHpEnabled then
                            local healthRatio = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                            currentHud.BackgroundBar.MainBar.Size = UDim2.new(healthRatio, 0, 1, 0)
                            currentHud.BackgroundBar.MainBar.BackgroundColor3 = teamColor
                            currentHud.BackgroundBar.Visible = true
                        else
                            currentHud.BackgroundBar.Visible = false
                        end
                        if getgenv().SystemConfig.MicroDistEnabled then
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

-- Forçar Speed e Jump no Heartbeat
RunService.Heartbeat:Connect(function()
    local char = Player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if getgenv().SystemConfig.SpeedEnabled then
        if hum.WalkSpeed ~= getgenv().SystemConfig.SpeedValue then
            hum.WalkSpeed = getgenv().SystemConfig.SpeedValue
        end
    else
        if hum.WalkSpeed ~= OriginalWalkSpeed then hum.WalkSpeed = OriginalWalkSpeed end
    end
    if getgenv().SystemConfig.JumpEnabled then
        if hum.JumpPower ~= getgenv().SystemConfig.JumpPower then
            hum.JumpPower = getgenv().SystemConfig.JumpPower
        end
    else
        if hum.JumpPower ~= OriginalJumpPower then hum.JumpPower = OriginalJumpPower end
    end
end)

--// [EVENTO: CHARACTER ADDED]
Player.CharacterAdded:Connect(function(char)
    task.wait(0.6)
    local hum = char:WaitForChild("Humanoid", 5)
    if hum then
        OriginalWalkSpeed = hum.WalkSpeed
        OriginalJumpPower = hum.JumpPower
    end
    if NoClipAtivo then
        if NoClipConnection then NoClipConnection:Disconnect() end
        NoClipConnection = RunService.Stepped:Connect(function()
            local chr = Player.Character
            if chr then
                for _, part in ipairs(chr:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end)
    end
    if getgenv().SystemConfig.FlyEnabled then startFly() end
end)

Rayfield:Notify({
    Title = "👑 WARCORE v1.2.0",
    Content = "Sistema de teleporte premium integrado!",
    Duration = 5,
    Image = 4483362458
})