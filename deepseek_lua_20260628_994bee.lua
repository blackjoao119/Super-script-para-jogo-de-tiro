-- =============================================
-- 🔥 SISTEMA DE TELEPORTE – MÓDULO DE TESTE
-- =============================================
-- Certifique-se de que estas variáveis já existam no escopo:
--   Player, TweenService, CoreGui, RunService, Rayfield, TeleportTab
-- E que a função 'hover' esteja definida (está incluída abaixo).

local tpGui = Instance.new("ScreenGui", CoreGui)
tpGui.Name = "WarcoreTeleporte"
tpGui.Enabled = true
tpGui.ResetOnSpawn = false
tpGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local isTeleportOpen = false

-- Função hover (necessária para os botões)
local function hover(btn, baseColor, hoverColor, textHover)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = hoverColor, BackgroundTransparency = 0.1}):Play()
        if textHover then TweenService:Create(btn, TweenInfo.new(0.2), {TextColor3 = textHover}):Play() end
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = baseColor, BackgroundTransparency = 0.3}):Play()
        if textHover then TweenService:Create(btn, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(220,230,240)}):Play() end
    end)
end

-- ========================
-- 1. JANELA PRINCIPAL
-- ========================
local tpFrame = Instance.new("Frame", tpGui)
tpFrame.Size = UDim2.new(0, 360, 0, 540)
tpFrame.Position = UDim2.new(0.5, -180, 0.5, -270)
tpFrame.BackgroundColor3 = Color3.fromRGB(30, 33, 45)
tpFrame.BackgroundTransparency = 0.05
tpFrame.BorderSizePixel = 0
tpFrame.ClipsDescendants = true
tpFrame.Visible = false
tpFrame.ZIndex = 10

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
border.Color = Color3.fromRGB(60, 70, 90)
border.Transparency = 0.2

-- Barra de título
local titleBar = Instance.new("Frame", tpFrame)
titleBar.Size = UDim2.new(1, 0, 0, 42)
titleBar.BackgroundColor3 = Color3.fromRGB(35, 38, 50)
titleBar.BorderSizePixel = 0
local titleCorner = Instance.new("UICorner", titleBar)
titleCorner.CornerRadius = UDim.new(0, 18)
local titleFix = Instance.new("Frame", titleBar)
titleFix.Size = UDim2.new(1, 0, 0, 20)
titleFix.Position = UDim2.new(0, 0, 0, 22)
titleFix.BackgroundColor3 = Color3.fromRGB(35, 38, 50)
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
titleLabel.TextColor3 = Color3.fromRGB(240, 245, 255)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 18
titleLabel.BackgroundTransparency = 1

local minimizeBtn = Instance.new("TextButton", titleBar)
minimizeBtn.Size = UDim2.new(0, 32, 0, 32)
minimizeBtn.Position = UDim2.new(1, -68, 0, 5)
minimizeBtn.Text = "─"
minimizeBtn.TextColor3 = Color3.fromRGB(220, 230, 240)
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextSize = 20
minimizeBtn.BackgroundColor3 = Color3.fromRGB(50, 55, 65)
minimizeBtn.BackgroundTransparency = 0.3
minimizeBtn.AutoButtonColor = false
Instance.new("UICorner", minimizeBtn).CornerRadius = UDim.new(0, 10)

local closeBtn = Instance.new("TextButton", titleBar)
closeBtn.Size = UDim2.new(0, 32, 0, 32)
closeBtn.Position = UDim2.new(1, -32, 0, 5)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 220, 220)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 20
closeBtn.BackgroundColor3 = Color3.fromRGB(190, 60, 60)
closeBtn.BackgroundTransparency = 0.2
closeBtn.AutoButtonColor = false
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 10)

hover(minimizeBtn, Color3.fromRGB(50,55,65), Color3.fromRGB(70,75,85), Color3.fromRGB(255,255,255))
hover(closeBtn, Color3.fromRGB(190,60,60), Color3.fromRGB(230,80,80), Color3.fromRGB(255,255,255))

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

-- Conteúdo interno
local posPanel = Instance.new("Frame", tpFrame)
posPanel.Size = UDim2.new(1, -24, 0, 46)
posPanel.Position = UDim2.new(0, 12, 0, 52)
posPanel.BackgroundColor3 = Color3.fromRGB(40, 43, 55)
posPanel.BorderSizePixel = 0
Instance.new("UICorner", posPanel).CornerRadius = UDim.new(0, 10)
local posStroke = Instance.new("UIStroke", posPanel)
posStroke.Thickness = 1
posStroke.Color = Color3.fromRGB(0, 240, 255)
posStroke.Transparency = 0.7

local posLabel = Instance.new("TextLabel", posPanel)
posLabel.Size = UDim2.new(1, -10, 1, 0)
posLabel.Position = UDim2.new(0, 5, 0, 0)
posLabel.BackgroundTransparency = 1
posLabel.Text = "📍 Posição: --, --, --"
posLabel.TextColor3 = Color3.fromRGB(240, 245, 255)
posLabel.Font = Enum.Font.GothamMedium
posLabel.TextSize = 15

local inputName = Instance.new("TextBox", tpFrame)
inputName.Size = UDim2.new(1, -24, 0, 48)
inputName.Position = UDim2.new(0, 12, 0, 110)
inputName.PlaceholderText = "Nome do Local"
inputName.PlaceholderColor3 = Color3.fromRGB(180, 190, 210)
inputName.BackgroundColor3 = Color3.fromRGB(40, 43, 55)
inputName.TextColor3 = Color3.fromRGB(255, 255, 255)
inputName.Font = Enum.Font.Gotham
inputName.TextSize = 16
inputName.ClearTextOnFocus = false
Instance.new("UICorner", inputName).CornerRadius = UDim.new(0, 10)
local inputStroke = Instance.new("UIStroke", inputName)
inputStroke.Thickness = 1
inputStroke.Color = Color3.fromRGB(80, 90, 110)
inputStroke.Transparency = 0.3

local saveBtn = Instance.new("TextButton", tpFrame)
saveBtn.Size = UDim2.new(1, -24, 0, 48)
saveBtn.Position = UDim2.new(0, 12, 0, 170)
saveBtn.Text = "💾 Salvar Local"
saveBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 255)
saveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
saveBtn.Font = Enum.Font.GothamBold
saveBtn.TextSize = 17
saveBtn.AutoButtonColor = false
Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0, 10)
local saveStroke = Instance.new("UIStroke", saveBtn)
saveStroke.Thickness = 1
saveStroke.Color = Color3.fromRGB(255, 255, 255)
saveStroke.Transparency = 0.4
hover(saveBtn, Color3.fromRGB(0,140,255), Color3.fromRGB(0,170,255), Color3.fromRGB(255,255,255))

local container = Instance.new("ScrollingFrame", tpFrame)
container.Size = UDim2.new(1, -24, 0, 250)
container.Position = UDim2.new(0, 12, 0, 230)
container.BackgroundColor3 = Color3.fromRGB(40, 43, 55)
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
clearBtn.Text = "🗑 Limpar Tudo (meus locais)"
clearBtn.BackgroundColor3 = Color3.fromRGB(170, 50, 50)
clearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
clearBtn.Font = Enum.Font.GothamBold
clearBtn.TextSize = 15
clearBtn.AutoButtonColor = false
Instance.new("UICorner", clearBtn).CornerRadius = UDim.new(0, 10)
local clearStroke = Instance.new("UIStroke", clearBtn)
clearStroke.Thickness = 1
clearStroke.Color = Color3.fromRGB(255, 255, 255)
clearStroke.Transparency = 0.4
hover(clearBtn, Color3.fromRGB(170,50,50), Color3.fromRGB(210,70,70), Color3.fromRGB(255,255,255))

-- Locais fixos (imutáveis)
local FixedLocations = {
    {name = "👑 Bandeira de Captura", x = -463.30, y = 261.15, z = -1013.22},
    {name = "👑 Local do Barril", x = 1706.69, y = 120.95, z = 3773.69}
}

-- Locais salvos pelo usuário
local savedLocations = {}

-- Função de atualização da lista (corrigida)
local function refreshContainer()
    for _, child in ipairs(container:GetChildren()) do
        if not child:IsA("UIListLayout") then
            child:Destroy()
        end
    end

    -- 1. Locais Fixos (dourados)
    for i, loc in ipairs(FixedLocations) do
        local btn = Instance.new("TextButton", container)
        btn.Name = "Fixed_" .. loc.name
        btn.Size = UDim2.new(1, -10, 0, 44)
        btn.Text = loc.name .. "\n" .. string.format("%.1f, %.1f, %.1f", loc.x, loc.y, loc.z)
        btn.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
        btn.TextColor3 = Color3.fromRGB(30, 30, 30)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 14
        btn.LayoutOrder = i
        btn.AutoButtonColor = false
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

        hover(btn, Color3.fromRGB(255, 200, 0), Color3.fromRGB(255, 220, 50))

        btn.MouseButton1Click:Connect(function()
            local root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if root then
                root.CFrame = CFrame.new(loc.x, loc.y, loc.z)
                -- Rayfield:Notify pode ser omitido no teste isolado
            end
        end)
    end

    -- 2. Locais do Usuário (com botão X)
    for i, loc in ipairs(savedLocations) do
        local itemFrame = Instance.new("Frame", container)
        itemFrame.Name = "User_" .. loc.name
        itemFrame.Size = UDim2.new(1, -10, 0, 44)
        itemFrame.BackgroundTransparency = 1
        itemFrame.LayoutOrder = 100 + i

        local itemLayout = Instance.new("UIListLayout", itemFrame)
        itemLayout.FillDirection = Enum.FillDirection.Horizontal
        itemLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
        itemLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        itemLayout.Padding = UDim.new(0, 4)

        local btn = Instance.new("TextButton", itemFrame)
        btn.Size = UDim2.new(1, -30, 1, 0)
        btn.Text = loc.name .. "\n" .. string.format("%.1f, %.1f, %.1f", loc.x, loc.y, loc.z)
        btn.BackgroundColor3 = Color3.fromRGB(50, 55, 70)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 14
        btn.AutoButtonColor = false
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

        hover(btn, Color3.fromRGB(50,55,70), Color3.fromRGB(70,75,90))

        btn.MouseButton1Click:Connect(function()
            local root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if root then
                root.CFrame = CFrame.new(loc.x, loc.y, loc.z)
            end
        end)

        local delBtn = Instance.new("TextButton", itemFrame)
        delBtn.Size = UDim2.new(0, 24, 0, 24)
        delBtn.Text = "✕"
        delBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        delBtn.Font = Enum.Font.GothamBold
        delBtn.TextSize = 14
        delBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
        delBtn.AutoButtonColor = false
        Instance.new("UICorner", delBtn).CornerRadius = UDim.new(0, 6)

        hover(delBtn, Color3.fromRGB(200,60,60), Color3.fromRGB(240,80,80), Color3.fromRGB(255,255,255))

        local index = i
        delBtn.MouseButton1Click:Connect(function()
            table.remove(savedLocations, index)
            refreshContainer()
        end)
    end

    container.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
end

saveBtn.MouseButton1Click:Connect(function()
    if inputName.Text == "" then return end
    local char = Player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local pos = char.HumanoidRootPart.Position
    local x, y, z = math.floor(pos.X * 100) / 100, math.floor(pos.Y * 100) / 100, math.floor(pos.Z * 100) / 100
    table.insert(savedLocations, {name = inputName.Text, x = x, y = y, z = z})
    inputName.Text = ""
    refreshContainer()
end)

clearBtn.MouseButton1Click:Connect(function()
    savedLocations = {}
    refreshContainer()
end)

-- Funções de animação
function toggleMenu(show)
    if show then
        tpFrame.Visible = true
        tpFrame.Size = UDim2.new(0, 0, 0, 540)
        tpFrame.BackgroundTransparency = 1
        TweenService:Create(tpFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 360, 0, 540),
            BackgroundTransparency = 0.05
        }):Play()
    else
        local tween = TweenService:Create(tpFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 540),
            BackgroundTransparency = 1
        })
        tween:Play()
        tween.Completed:Connect(function()
            tpFrame.Visible = false
        end)
    end
end

local function animateBtn(btn, visible)
    if visible then
        btn.Visible = true
        btn.Size = UDim2.new(0, 0, 0, 0)
        btn.BackgroundTransparency = 1
        TweenService:Create(btn, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 58, 0, 58),
            BackgroundTransparency = 0.1,
            TextSize = 30
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

-- Botão flutuante
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
        local curSize = TpFloatingBtn.Size.X.Offset
        TweenService:Create(TpFloatingBtn, TweenInfo.new(0.1), {Size = UDim2.new(0, curSize + 6, 0, curSize + 6)}):Play()
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
        isTeleportOpen = not isTeleportOpen
        toggleMenu(isTeleportOpen)
    end
    hasMoved = false
end)

minimizeBtn.MouseButton1Click:Connect(function()
    isTeleportOpen = false
    toggleMenu(false)
end)

closeBtn.MouseButton1Click:Connect(function()
    isTeleportOpen = false
    toggleMenu(false)
end)

-- Toggle principal (precisa de TeleportTab já criada)
local teleportToggle = TeleportTab:CreateToggle({
    Name = "Ativar Sistema de Teleporte",
    CurrentValue = false,
    Callback = function(value)
        if value then
            animateBtn(TpFloatingBtn, true)
        else
            animateBtn(TpFloatingBtn, false)
            if isTeleportOpen then
                isTeleportOpen = false
                toggleMenu(false)
            end
        end
    end
})

-- Atualiza coordenadas em tempo real
RunService.RenderStepped:Connect(function()
    if tpFrame.Visible and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
        local p = Player.Character.HumanoidRootPart.Position
        posLabel.Text = string.format("📍 Posição: %.1f, %.1f, %.1f", p.X, p.Y, p.Z)
    end
end)

-- Exibe os locais fixos ao iniciar
refreshContainer()