--// =============================================
--// 🔥 SISTEMA DE TELEPORTE – BOTÃO SEMPRE VISÍVEL
--// =============================================

local tpGui = Instance.new("ScreenGui", CoreGui)
tpGui.Name = "WarcoreTeleporte"
tpGui.Enabled = true
tpGui.ResetOnSpawn = false
tpGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- ========================
-- BOTÃO FLUTUANTE (SEMPRE VISÍVEL, TAMANHO/COR VARIÁVEIS)
-- ========================
local TpFloatingBtn = Instance.new("TextButton", tpGui)
TpFloatingBtn.Size = UDim2.new(0, 30, 0, 30)           -- começa pequeno (OFF)
TpFloatingBtn.Position = UDim2.new(0.8, 0, 0.7, 0)
TpFloatingBtn.BackgroundColor3 = Color3.fromRGB(30, 33, 45)  -- cor da janela (OFF)
TpFloatingBtn.BackgroundTransparency = 0.4              -- mais opaco para ficar discreto
TpFloatingBtn.Text = "📍"
TpFloatingBtn.TextColor3 = Color3.fromRGB(0, 240, 255)
TpFloatingBtn.Font = Enum.Font.GothamBold
TpFloatingBtn.TextSize = 16                              -- texto pequeno
TpFloatingBtn.AutoButtonColor = false
TpFloatingBtn.Visible = true                             -- sempre visível
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

-- Variáveis de arraste
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
        -- Feedback tátil (aumenta um pouco)
        TweenService:Create(TpFloatingBtn, TweenInfo.new(0.1), {
            Size = UDim2.new(0, TpFloatingBtn.Size.X.Offset + 6, 0, TpFloatingBtn.Size.Y.Offset + 6)
        }):Play()
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                isDragging = false
                -- Restaura tamanho de acordo com o estado atual
                local targetSize = teleportToggle.CurrentValue and 58 or 30
                TweenService:Create(TpFloatingBtn, TweenInfo.new(0.1), {
                    Size = UDim2.new(0, targetSize, 0, targetSize)
                }):Play()
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

-- Novo comportamento: clicar alterna o Toggle (liga/desliga)
TpFloatingBtn.InputEnded:Connect(function(input)
    if not hasMoved and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        teleportToggle:Set(not teleportToggle.CurrentValue)  -- alterna o estado
    end
    hasMoved = false
end)

-- Função para animar o botão entre os estados ON/OFF
local function animateBtnState(state)
    -- state = true (ON) | false (OFF)
    if state then
        -- Ligado: grande, cor de destaque
        TweenService:Create(TpFloatingBtn, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 58, 0, 58),
            BackgroundColor3 = Color3.fromRGB(11, 13, 23),
            BackgroundTransparency = 0.1,
            TextSize = 30
        }):Play()
    else
        -- Desligado: pequeno, cor da janela, discreto
        TweenService:Create(TpFloatingBtn, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 30, 0, 30),
            BackgroundColor3 = Color3.fromRGB(30, 33, 45),
            BackgroundTransparency = 0.4,
            TextSize = 16
        }):Play()
    end
end

-- ========================
-- JANELA PRINCIPAL (CORES CORRIGIDAS) - MANTIDA IGUAL
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

-- ... (todo o conteúdo da janela permanece igual ao script anterior, 
-- desde a barra de título até o final da definição dos elementos)

-- Por brevidade, vou omitir a repetição e colocar "..." no lugar.
-- No script final, essa parte deve ser mantida exatamente como antes,
-- sem alterações. Copie a partir daqui:

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

-- Barra de título e conteúdo (mantidos como no último script funcional)
-- ...

-- Função toggleMenu também mantida, mas sem chamar animateBtn para sumir o botão.
-- Agora, ao abrir a janela, não escondemos o botão, apenas mantemos o estado visual.
-- Ajuste na função toggleMenu: remover as chamadas animateBtn.

function toggleMenu(show)
    if show then
        tpFrame.Visible = true
        tpFrame.Size = UDim2.new(0, 0, 0, 540)
        tpFrame.BackgroundTransparency = 1
        TweenService:Create(tpFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 360, 0, 540),
            BackgroundTransparency = 0.05
        }):Play()
        -- NÃO escondemos o botão mais
    else
        local tween = TweenService:Create(tpFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 540),
            BackgroundTransparency = 1
        })
        tween:Play()
        tween.Completed:Connect(function()
            tpFrame.Visible = false
            -- NÃO mostramos o botão, ele já está visível
        end)
    end
end

-- Callback do Toggle principal
local teleportToggle = TeleportTab:CreateToggle({
    Name = "Ativar Sistema de Teleporte",
    CurrentValue = false,
    Callback = function(value)
        -- Atualiza o visual do botão
        animateBtnState(value)
        -- Abre/fecha a janela de acordo
        if value then
            -- Ao ligar, se a janela não estiver aberta, abre
            if not tpFrame.Visible then
                toggleMenu(true)
            end
        else
            -- Ao desligar, fecha a janela se estiver aberta
            if tpFrame.Visible then
                toggleMenu(false)
            end
        end
    end
})

-- Inicializar estado visual (OFF)
animateBtnState(false)

-- ... continuação do script (monitor, loops, etc.)