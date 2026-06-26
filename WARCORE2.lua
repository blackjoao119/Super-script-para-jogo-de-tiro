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

--// ABA: MOVIMENTO
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
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
            end)
        else
            if NoClipConnection then
                NoClipConnection:Disconnect()
                NoClipConnection = nil
            end
        end
    end
})

MovimentTab:CreateParagraph({
    Title = "ℹ️ Informações Globais / Guide", 
    Content = "🇧🇷 Esta função é útil em mapas que possuem prédios ou casas para você entrar.\n🇺🇸 This function is useful in maps that have buildings or houses for you to enter."
})

--// =============================================
--// 🔄 ABA TELEPORTE – APENAS TOGGLE PARA MENU FLUTUANTE
--// =============================================

-- Criação do menu flutuante (design profissional dark theme)
local tpScreenGui = Instance.new("ScreenGui", CoreGui)
tpScreenGui.Name = "WarcoreTPMenu"

local tpFrame = Instance.new("Frame", tpScreenGui)
tpFrame.Size = UDim2.new(0, 300, 0, 450)
tpFrame.Position = UDim2.new(0.5, -150, 0.5, -225)
tpFrame.BackgroundColor3 = Color3.fromRGB(11, 13, 23)  -- mesmo fundo da janela Rayfield
tpFrame.BorderSizePixel = 0
tpFrame.Visible = false
tpFrame.ClipsDescendants = true

local frameCorner = Instance.new("UICorner", tpFrame)
frameCorner.CornerRadius = UDim.new(0, 12)

local frameStroke = Instance.new("UIStroke", tpFrame)
frameStroke.Thickness = 1.5
frameStroke.Color = Color3.fromRGB(35, 42, 65)
frameStroke.Transparency = 0.3

-- Título
local titleLabel = Instance.new("TextLabel", tpFrame)
titleLabel.Size = UDim2.new(1, 0, 0, 30)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "📍 Teleporte Rápido"
titleLabel.TextColor3 = Color3.fromRGB(0, 240, 255)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 16
titleLabel.Position = UDim2.new(0, 0, 0, 5)

-- Posição atual
local posLabel = Instance.new("TextLabel", tpFrame)
posLabel.Size = UDim2.new(1, -10, 0, 40)
posLabel.Position = UDim2.new(0, 5, 0, 40)
posLabel.BackgroundColor3 = Color3.fromRGB(15, 18, 28)
posLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
posLabel.Font = Enum.Font.Gotham
posLabel.TextSize = 13
posLabel.Text = "Posição: --, --, --"
local posCorner = Instance.new("UICorner", posLabel)
posCorner.CornerRadius = UDim.new(0, 8)

-- Campo de nome
local inputName = Instance.new("TextBox", tpFrame)
inputName.Size = UDim2.new(0.9, 0, 0, 40)
inputName.Position = UDim2.new(0.05, 0, 0, 90)
inputName.PlaceholderText = "Nome do Local"
inputName.PlaceholderColor3 = Color3.fromRGB(130, 140, 160)
inputName.BackgroundColor3 = Color3.fromRGB(15, 18, 28)
inputName.TextColor3 = Color3.fromRGB(255, 255, 255)
inputName.Font = Enum.Font.Gotham
inputName.TextSize = 14
inputName.ClearTextOnFocus = false
local inputCorner = Instance.new("UICorner", inputName)
inputCorner.CornerRadius = UDim.new(0, 8)

-- Botão Salvar
local saveBtn = Instance.new("TextButton", tpFrame)
saveBtn.Size = UDim2.new(0.9, 0, 0, 40)
saveBtn.Position = UDim2.new(0.05, 0, 0, 140)
saveBtn.Text = "💾 Adicionar à Lista"
saveBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
saveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
saveBtn.Font = Enum.Font.GothamBold
saveBtn.TextSize = 14
local saveCorner = Instance.new("UICorner", saveBtn)
saveCorner.CornerRadius = UDim.new(0, 8)
local saveStroke = Instance.new("UIStroke", saveBtn)
saveStroke.Thickness = 1
saveStroke.Color = Color3.fromRGB(255, 255, 255)
saveStroke.Transparency = 0.7

-- Container de scroll
local container = Instance.new("ScrollingFrame", tpFrame)
container.Size = UDim2.new(0.9, 0, 0, 250)
container.Position = UDim2.new(0.05, 0, 0, 190)
container.BackgroundColor3 = Color3.fromRGB(15, 18, 28)
container.BorderSizePixel = 0
container.ScrollBarThickness = 4
container.ScrollBarImageColor3 = Color3.fromRGB(0, 240, 255)
local contCorner = Instance.new("UICorner", container)
contCorner.CornerRadius = UDim.new(0, 8)
local layout = Instance.new("UIListLayout", container)
layout.Padding = UDim.new(0, 5)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.SortOrder = Enum.SortOrder.LayoutOrder

-- Animação de abertura/fechamento
local function toggleMenu(visible)
    if visible then
        tpFrame.Visible = true
        tpFrame.Size = UDim2.new(0, 0, 0, 450)  -- começa colapsado
        local tween = TweenService:Create(tpFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 300, 0, 450)})
        tween:Play()
    else
        local tween = TweenService:Create(tpFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 450)})
        tween:Play()
        tween.Completed:Connect(function()
            tpFrame.Visible = false
        end)
    end
end

-- Lógica de salvamento (temporário)
local savedLocations = {}  -- {name, cframe}

local function refreshContainer()
    -- Limpa o container
    for _, child in ipairs(container:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("Frame") then
            child:Destroy()
        end
    end

    for i, loc in ipairs(savedLocations) do
        local btn = Instance.new("TextButton", container)
        btn.Size = UDim2.new(1, -10, 0, 40)
        btn.Text = loc.name
        btn.BackgroundColor3 = Color3.fromRGB(30, 35, 50)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 13
        btn.LayoutOrder = i
        local btnCorner = Instance.new("UICorner", btn)
        btnCorner.CornerRadius = UDim.new(0, 6)

        btn.MouseButton1Click:Connect(function()
            local char = Player.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.CFrame = loc.cframe
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
        Rayfield:Notify({Title = "Erro", Content = "Digite um nome para o local.", Duration = 2, Image = 4483362458})
        return
    end
    local char = Player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local cframe = char.HumanoidRootPart.CFrame
    table.insert(savedLocations, {name = inputName.Text, cframe = cframe})
    inputName.Text = ""
    refreshContainer()
    Rayfield:Notify({Title = "Salvo", Content = inputName.Text .. " adicionado.", Duration = 2, Image = 4483362458})
end)

-- Atualização em tempo real da posição
RunService.RenderStepped:Connect(function()
    if tpFrame.Visible and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
        local p = Player.Character.HumanoidRootPart.Position
        posLabel.Text = string.format("Pos: %.1f, %.1f, %.1f", p.X, p.Y, p.Z)
    end
end)

-- Toggle na aba Teleporte da Rayfield
TeleportTab:CreateToggle({
    Name = "Ativar Menu Flutuante de Teleporte",
    CurrentValue = false,
    Callback = function(value)
        toggleMenu(value)
    end
})

--// ABA: MONITOR
StatusTab:CreateToggle({ Name = "Monitorar Taxa de FPS", CurrentValue = false, Callback = function(v) getgenv().SystemConfig.ShowFPS = v fpsF.Visible = v end })
StatusTab:CreateToggle({ Name = "Contador Ativo de Players", CurrentValue = false, Callback = function(v) getgenv().SystemConfig.ShowPlayers = v countF.Visible = v end })

--// [LOOP CORE]
RunService.RenderStepped:Connect(function(dt)
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
                    if hud then
                        hud.Enabled = false
                    end
                end
            end
            
        end
    end
end)

Player.CharacterAdded:Connect(function()
    task.wait(0.6)
    if NoClipAtivo then
        if NoClipConnection then NoClipConnection:Disconnect() end
        NoClipConnection = RunService.Stepped:Connect(function()
            local char = Player.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    end
    -- A lista de locais salvos permanece mesmo após renascer
end)

Rayfield:Notify({
    Title = "👑 WARCORE v1.2.0",
    Content = "Menu flutuante de teleporte integrado!",
    Duration = 5,
    Image = 4483362458
})