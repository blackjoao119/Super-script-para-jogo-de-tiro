--[[
    WARCORE PREMIUM - Roblox Menu
    Design: Moderno, minimalista, futurista, AAA
    Compatível com PC e mobile (executores Delta e similares)
    
    Basta alterar a variável PREMIUM_LINK abaixo para modificar o link.
]]--

-- ========== SERVIÇOS ==========
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- ========== CONFIGURAÇÕES ==========
local PREMIUM_LINK = "COLE_SEU_LINK_AQUI"  -- 🔗 Altere aqui o link Premium

local CORES = {
    fundo = Color3.fromRGB(15, 15, 22),
    topo = Color3.fromRGB(25, 25, 35),
    texto = Color3.fromRGB(230, 230, 240),
    destaque = Color3.fromRGB(0, 180, 255),
    ouro = Color3.fromRGB(255, 200, 0),
    vidro = Color3.fromRGB(255, 255, 255),
    sucesso = Color3.fromRGB(0, 255, 100)
}

-- ========== ESTADO GLOBAL ==========
local isMenuOpen = false
local isMinimized = false
local dragEnabled = true
local dragging = false
local currentTab = "Visual"

local espEnabled = false
local fullBrightEnabled = false
local highlightConnections = {}
local originalLighting = {}

-- ========== GUI PRINCIPAL ==========
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "WarcoreMenu"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Botão de abrir/fechar o menu
local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(0, 48, 0, 48)
ToggleButton.Position = UDim2.new(1, -56, 0.5, -24)
ToggleButton.BackgroundColor3 = CORES.topo
ToggleButton.Text = "☰"
ToggleButton.TextColor3 = CORES.texto
ToggleButton.TextSize = 24
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.ZIndex = 10

local ToggleCorner = Instance.new("UICorner", ToggleButton)
ToggleCorner.CornerRadius = UDim.new(1, 0)

local ToggleStroke = Instance.new("UIStroke", ToggleButton)
ToggleStroke.Color = CORES.destaque
ToggleStroke.Thickness = 2
ToggleStroke.Transparency = 0.3

ToggleButton.Parent = ScreenGui

-- Container principal do menu (inicialmente invisível)
local MainContainer = Instance.new("Frame")
MainContainer.Size = UDim2.new(0.34, 0, 0.58, 0)
MainContainer.Position = UDim2.new(1, 0, 0.21, 0) -- começa fora da tela
MainContainer.BackgroundColor3 = CORES.fundo
MainContainer.BackgroundTransparency = 0.15
MainContainer.ClipsDescendants = true
MainContainer.Visible = false
MainContainer.ZIndex = 9

local MainCorner = Instance.new("UICorner", MainContainer)
MainCorner.CornerRadius = UDim.new(0, 12)

local MainStroke = Instance.new("UIStroke", MainContainer)
MainStroke.Color = CORES.destaque
MainStroke.Thickness = 1.5
MainStroke.Transparency = 0.5

-- Gradiente de fundo
local MainGradient = Instance.new("UIGradient", MainContainer)
MainGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(20,20,30)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(10,10,18))
})
MainGradient.Rotation = 45

MainContainer.Parent = ScreenGui

-- Layout vertical dentro do menu
local UILayout = Instance.new("UIListLayout", MainContainer)
UILayout.FillDirection = Enum.FillDirection.Vertical
UILayout.SortOrder = Enum.SortOrder.LayoutOrder
UILayout.Padding = UDim.new(0, 0)

-- ========== BARRA SUPERIOR ==========
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 44)
TopBar.BackgroundColor3 = CORES.topo
TopBar.BackgroundTransparency = 0.2
TopBar.LayoutOrder = 0
TopBar.ZIndex = 10

Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 12)
local TopBarStroke = Instance.new("UIStroke", TopBar)
TopBarStroke.Color = CORES.destaque
TopBarStroke.Thickness = 1
TopBarStroke.Transparency = 0.6

-- Título
local TitleLabel = Instance.new("TextLabel", TopBar)
TitleLabel.Text = "WARCORE"
TitleLabel.TextColor3 = CORES.texto
TitleLabel.TextSize = 20
TitleLabel.Font = Enum.Font.GothamBlack
TitleLabel.BackgroundTransparency = 1
TitleLabel.Size = UDim2.new(0.6, 0, 1, 0)
TitleLabel.Position = UDim2.new(0, 12, 0, 0)
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Botão de minimizar
local MinimizeButton = Instance.new("TextButton", TopBar)
MinimizeButton.Size = UDim2.new(0, 30, 0, 30)
MinimizeButton.Position = UDim2.new(1, -42, 0.5, -15)
MinimizeButton.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
MinimizeButton.Text = "─"
MinimizeButton.TextColor3 = CORES.texto
MinimizeButton.TextSize = 20
MinimizeButton.Font = Enum.Font.GothamBold
MinimizeButton.ZIndex = 11

local MinCorner = Instance.new("UICorner", MinimizeButton)
MinCorner.CornerRadius = UDim.new(0.5, 0)

local MinStroke = Instance.new("UIStroke", MinimizeButton)
MinStroke.Color = CORES.destaque
MinStroke.Thickness = 1
MinStroke.Transparency = 0.7

TopBar.Parent = MainContainer

-- ========== CONTAINER DO CONTEÚDO (abaixo da top bar) ==========
local ContentContainer = Instance.new("Frame")
ContentContainer.Name = "ContentContainer"
ContentContainer.Size = UDim2.new(1, 0, 1, -44)
ContentContainer.BackgroundTransparency = 1
ContentContainer.LayoutOrder = 1
ContentContainer.ClipsDescendants = true

-- Layout interno vertical
local ContentLayout = Instance.new("UIListLayout", ContentContainer)
ContentLayout.FillDirection = Enum.FillDirection.Vertical
ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
ContentLayout.Padding = UDim.new(0, 0)

ContentContainer.Parent = MainContainer

-- ========== BARRA DE ABAS ==========
local TabBar = Instance.new("Frame")
TabBar.Name = "TabBar"
TabBar.Size = UDim2.new(1, 0, 0, 38)
TabBar.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
TabBar.BackgroundTransparency = 0.3
TabBar.LayoutOrder = 0

Instance.new("UICorner", TabBar).CornerRadius = UDim.new(0, 8)
local TabBarStroke = Instance.new("UIStroke", TabBar)
TabBarStroke.Color = CORES.destaque
TabBarStroke.Thickness = 1
TabBarStroke.Transparency = 0.6

TabBar.Parent = ContentContainer

-- Frame para conteúdo das abas
local ContentFrame = Instance.new("Frame")
ContentFrame.Name = "ContentFrame"
ContentFrame.Size = UDim2.new(1, 0, 1, -38)
ContentFrame.BackgroundTransparency = 1
ContentFrame.LayoutOrder = 1
ContentFrame.ClipsDescendants = true
ContentFrame.Parent = ContentContainer

-- ========== CRIAÇÃO DAS ABAS ==========
local tabs = {}
local tabPages = {}

local function criarBotaoAba(nome, icone)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.33, -6, 0.8, 0)
    btn.Position = UDim2.new(0, 4, 0.1, 0) -- posição ajustada depois
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    btn.BackgroundTransparency = 0.5
    btn.Text = icone .. " " .. nome
    btn.TextColor3 = CORES.texto
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamSemibold
    btn.ZIndex = 11
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = CORES.destaque
    stroke.Thickness = 1
    stroke.Transparency = 0.7
    return btn
end

-- Função para efeito hover
local function adicionarHover(btn)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 0.3}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 0.5}):Play()
    end)
end

-- Criar botões das abas
local tabVisual = criarBotaoAba("Visual", "👁️")
tabVisual.LayoutOrder = 0
tabVisual.Parent = TabBar
adicionarHover(tabVisual)

local tabOpcoes = criarBotaoAba("Opções", "⚙️")
tabOpcoes.LayoutOrder = 1
tabOpcoes.Parent = TabBar
adicionarHover(tabOpcoes)

local tabPremium = criarBotaoAba("Premium", "⭐")
tabPremium.LayoutOrder = 2
tabPremium.Parent = TabBar
adicionarHover(tabPremium)

-- ========== PÁGINAS DE CONTEÚDO ==========
local function criarPagina(nome)
    local page = Instance.new("Frame")
    page.Name = nome
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.Parent = ContentFrame
    return page
end

local VisualPage = criarPagina("Visual")
local OptionsPage = criarPagina("Opcoes")
local PremiumPage = criarPagina("Premium")

tabPages["Visual"] = VisualPage
tabPages["Opcoes"] = OptionsPage
tabPages["Premium"] = PremiumPage

-- Ajuste de layout dos botões (grid)
local TabBarLayout = Instance.new("UIGridLayout", TabBar)
TabBarLayout.CellPadding = UDim2.new(0, 4)
TabBarLayout.CellSize = UDim2.new(0.33, -8, 1, 0)
TabBarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
TabBarLayout.VerticalAlignment = Enum.VerticalAlignment.Center
TabBarLayout.FillDirection = Enum.FillDirection.Horizontal

-- ========== PÁGINA VISUAL ==========
local function criarToggle(nome, default, parent)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -24, 0, 40)
    container.Position = UDim2.new(0, 12, 0, 0)
    container.BackgroundTransparency = 1
    container.Name = nome

    local label = Instance.new("TextLabel", container)
    label.Text = nome
    label.TextColor3 = CORES.texto
    label.TextSize = 14
    label.Font = Enum.Font.Gotham
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 0, 0, 0)
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.TextXAlignment = Enum.TextXAlignment.Left

    local toggleBtn = Instance.new("TextButton", container)
    toggleBtn.Size = UDim2.new(0, 48, 0, 26)
    toggleBtn.Position = UDim2.new(1, -52, 0.5, -13)
    toggleBtn.BackgroundColor3 = default and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(120, 120, 120)
    toggleBtn.Text = ""
    toggleBtn.AutoButtonColor = false
    toggleBtn.Name = "ToggleButton"

    local toggleCorner = Instance.new("UICorner", toggleBtn)
    toggleCorner.CornerRadius = UDim.new(1, 0)

    local indicator = Instance.new("Frame", toggleBtn)
    indicator.Size = UDim2.new(0, 22, 0, 22)
    indicator.Position = default and UDim2.new(1, -24, 0.5, -11) or UDim2.new(0, 2, 0.5, -11)
    indicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    indicator.Name = "Indicator"
    local indCorner = Instance.new("UICorner", indicator)
    indCorner.CornerRadius = UDim.new(1, 0)

    local estado = default
    local function atualizarVisual()
        if estado then
            toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
            TweenService:Create(indicator, TweenInfo.new(0.2), {Position = UDim2.new(1, -24, 0.5, -11)}):Play()
        else
            toggleBtn.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
            TweenService:Create(indicator, TweenInfo.new(0.2), {Position = UDim2.new(0, 2, 0.5, -11)}):Play()
        end
    end

    toggleBtn.MouseButton1Click:Connect(function()
        estado = not estado
        atualizarVisual()
        if nome == "ESP Básico" then
            espEnabled = estado
            if estado then
                ativarESP()
            else
                desativarESP()
            end
        elseif nome == "FullBright" then
            fullBrightEnabled = estado
            if estado then
                ativarFullBright()
            else
                desativarFullBright()
            end
        end
    end)

    container.Parent = parent
    return container
end

local VisualLayout = Instance.new("UIListLayout", VisualPage)
VisualLayout.Padding = UDim.new(0, 8)
VisualLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
VisualLayout.SortOrder = Enum.SortOrder.LayoutOrder

criarToggle("ESP Básico", false, VisualPage)
criarToggle("FullBright", false, VisualPage)

-- ========== PÁGINA OPÇÕES ==========
local OptionsLayout = Instance.new("UIListLayout", OptionsPage)
OptionsLayout.Padding = UDim.new(0, 8)
OptionsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
OptionsLayout.SortOrder = Enum.SortOrder.LayoutOrder

local fpsToggle = criarToggle("Mostrar FPS", false, OptionsPage)
local playerCountToggle = criarToggle("Mostrar Jogadores", false, OptionsPage)
local dragToggle = criarToggle("Menu Arrastável", true, OptionsPage)
dragToggle:FindFirstChild("ToggleButton").MouseButton1Click:Connect(function()
    dragEnabled = not dragEnabled
end)

-- Botão minimizar dentro das opções
local minimizarBtnOpcoes = Instance.new("TextButton", OptionsPage)
minimizarBtnOpcoes.Size = UDim2.new(0.8, 0, 0, 36)
minimizarBtnOpcoes.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
minimizarBtnOpcoes.Text = "Minimizar / Restaurar"
minimizarBtnOpcoes.TextColor3 = CORES.texto
minimizarBtnOpcoes.TextSize = 14
minimizarBtnOpcoes.Font = Enum.Font.Gotham
Instance.new("UICorner", minimizarBtnOpcoes).CornerRadius = UDim.new(0, 8)
local mmStroke = Instance.new("UIStroke", minimizarBtnOpcoes)
mmStroke.Color = CORES.destaque
mmStroke.Thickness = 1
mmStroke.Transparency = 0.8
adicionarHover(minimizarBtnOpcoes)
minimizarBtnOpcoes.MouseButton1Click:Connect(function()
    toggleMinimizar()
end)

-- ========== PÁGINA PREMIUM ==========
local premiumContainer = Instance.new("Frame", PremiumPage)
premiumContainer.Size = UDim2.new(0.9, 0, 0.9, 0)
premiumContainer.Position = UDim2.new(0.05, 0, 0.05, 0)
premiumContainer.BackgroundTransparency = 0.2
premiumContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
Instance.new("UICorner", premiumContainer).CornerRadius = UDim.new(0, 14)
local premGradient = Instance.new("UIGradient", premiumContainer)
premGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 50)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 20))
})
premGradient.Rotation = -30

local premStroke = Instance.new("UIStroke", premiumContainer)
premStroke.Color = CORES.ouro
premStroke.Thickness = 2
premStroke.Transparency = 0.3

-- Ícone Premium
local iconePremium = Instance.new("ImageLabel", premiumContainer)
iconePremium.Size = UDim2.new(0, 60, 0, 60)
iconePremium.Position = UDim2.new(0.5, -30, 0, 20)
iconePremium.BackgroundTransparency = 1
iconePremium.Image = "rbxassetid://6031094678" -- estrela dourada (asset público)
iconePremium.ImageColor3 = CORES.ouro

-- Textos bilíngues
local textos = {
    pt = {
        titulo = "🚀 WARCORE PREMIUM",
        desc = "Desbloqueie a versão completa e tenha acesso a todos os recursos exclusivos.",
        recursos = {
            "Aim Assist",
            "Fly",
            "Speed",
            "NoClip",
            "Super Jump",
            "Infinite Jump",
            "ESP Avançado",
            "Teleporte Ilimitado",
            "Todas as futuras atualizações"
        },
        final = "A versão Premium oferece muito mais desempenho, recursos exclusivos e melhorias constantes."
    },
    en = {
        titulo = "🚀 WARCORE PREMIUM",
        desc = "Unlock the full version and gain access to every exclusive feature.",
        recursos = {
            "Aim Assist",
            "Fly",
            "Speed",
            "NoClip",
            "Super Jump",
            "Infinite Jump",
            "Advanced ESP",
            "Unlimited Teleport",
            "All future updates"
        },
        final = "The Premium version includes exclusive features, better performance and lifetime updates."
    }
}

local colunaPt = Instance.new("Frame", premiumContainer)
colunaPt.Size = UDim2.new(0.45, 0, 1, -130)
colunaPt.Position = UDim2.new(0, 12, 0, 100)
colunaPt.BackgroundTransparency = 1
local colunaEn = Instance.new("Frame", premiumContainer)
colunaEn.Size = UDim2.new(0.45, 0, 1, -130)
colunaEn.Position = UDim2.new(0.5, 6, 0, 100)
colunaEn.BackgroundTransparency = 1

local function criarTextoPremium(parent, titulo, desc, recursos, final)
    local y = 0
    local function addText(text, size, font, color, transp)
        local label = Instance.new("TextLabel", parent)
        label.Size = UDim2.new(1, 0, 0, size)
        label.Position = UDim2.new(0, 0, 0, y)
        label.BackgroundTransparency = 1
        label.TextColor3 = color or CORES.ouro
        label.TextSize = size
        label.Font = font or Enum.Font.GothamBold
        label.Text = text
        label.TextWrapped = true
        y = y + size + 4
        return label
    end

    addText(titulo, 16, Enum.Font.GothamBlack, CORES.ouro)
    addText(desc, 12, Enum.Font.Gotham, CORES.texto)
    y = y + 4
    for _, rec in ipairs(recursos) do
        addText("✔ " .. rec, 13, Enum.Font.Gotham, Color3.fromRGB(180, 255, 180))
    end
    y = y + 4
    addText(final, 12, Enum.Font.Gotham, Color3.fromRGB(200, 200, 220))
end

criarTextoPremium(colunaPt, textos.pt.titulo, textos.pt.desc, textos.pt.recursos, textos.pt.final)
criarTextoPremium(colunaEn, textos.en.titulo, textos.en.desc, textos.en.recursos, textos.en.final)

-- Botão Premium
local botaoPremium = Instance.new("TextButton", premiumContainer)
botaoPremium.Size = UDim2.new(0.7, 0, 0, 48)
botaoPremium.Position = UDim2.new(0.5, 0, 0, 0) -- será centralizado depois
botaoPremium.AnchorPoint = Vector2.new(0.5, 0)
botaoPremium.Position = UDim2.new(0.5, 0, 1, -56)
botaoPremium.BackgroundColor3 = CORES.ouro
botaoPremium.Text = "⭐ GET PREMIUM ⭐"
botaoPremium.TextColor3 = Color3.fromRGB(0, 0, 0)
botaoPremium.TextSize = 18
botaoPremium.Font = Enum.Font.GothamBlack
botaoPremium.AutoButtonColor = false
Instance.new("UICorner", botaoPremium).CornerRadius = UDim.new(0, 12)
local premBtnGradient = Instance.new("UIGradient", botaoPremium)
premBtnGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 220, 50)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 160, 0))
})
local premBtnStroke = Instance.new("UIStroke", botaoPremium)
premBtnStroke.Color = Color3.fromRGB(255, 255, 200)
premBtnStroke.Thickness = 2
premBtnStroke.Transparency = 0.3

-- Notificação de cópia
local notificacao = Instance.new("TextLabel", PremiumPage)
notificacao.Size = UDim2.new(0.8, 0, 0, 30)
notificacao.Position = UDim2.new(0.1, 0, 0, 8)
notificacao.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
notificacao.BackgroundTransparency = 0.7
notificacao.TextColor3 = CORES.sucesso
notificacao.TextSize = 13
notificacao.Font = Enum.Font.GothamSemibold
notificacao.Text = ""
notificacao.TextTransparency = 1
Instance.new("UICorner", notificacao).CornerRadius = UDim.new(0, 8)

botaoPremium.MouseButton1Click:Connect(function()
    local copiado = pcall(function()
        if setclipboard then
            setclipboard(PREMIUM_LINK)
        else
            error("setclipboard não disponível")
        end
    end)
    if copiado then
        notificacao.Text = "✅ Link copiado! Cole no navegador para obter a versão completa."
    else
        notificacao.Text = "⚠️ Erro ao copiar. Link: " .. PREMIUM_LINK
    end
    -- Animação da notificação
    notificacao.TextTransparency = 1
    notificacao.Visible = true
    local fadeIn = TweenService:Create(notificacao, TweenInfo.new(0.3), {TextTransparency = 0})
    fadeIn:Play()
    fadeIn.Completed:Wait()
    wait(2.5)
    local fadeOut = TweenService:Create(notificacao, TweenInfo.new(0.5), {TextTransparency = 1})
    fadeOut:Play()
    fadeOut.Completed:Connect(function()
        notificacao.Visible = false
    end)
end)

-- ========== FUNÇÕES DE NAVEGAÇÃO ==========
local function trocarAba(novaAba)
    if currentTab == novaAba then return end
    local paginaAntiga = tabPages[currentTab]
    local paginaNova = tabPages[novaAba]
    if not paginaAntiga or not paginaNova then return end

    -- Animação de slide (nova aba entra da direita)
    paginaNova.Visible = true
    paginaNova.Position = UDim2.new(0.2, 0, 0, 0)
    TweenService:Create(paginaNova, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)}):Play()
    if paginaAntiga then
        TweenService:Create(paginaAntiga, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(-0.2, 0, 0, 0)}):Play()
        delay(0.2, function()
            paginaAntiga.Visible = false
            paginaAntiga.Position = UDim2.new(0, 0, 0, 0)
        end)
    end
    currentTab = novaAba
end

tabVisual.MouseButton1Click:Connect(function() trocarAba("Visual") end)
tabOpcoes.MouseButton1Click:Connect(function() trocarAba("Opcoes") end)
tabPremium.MouseButton1Click:Connect(function() trocarAba("Premium") end)

-- Iniciar na aba Visual
VisualPage.Visible = true
VisualPage.Position = UDim2.new(0, 0, 0, 0)

-- ========== MINIMIZAR / RESTAURAR ==========
local function toggleMinimizar()
    isMinimized = not isMinimized
    if isMinimized then
        -- Minimiza: contrai ContentContainer
        MinimizeButton.Text = "☐"
        TweenService:Create(ContentContainer, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Size = UDim2.new(1, 0, 0, 0)}):Play()
    else
        -- Restaura
        MinimizeButton.Text = "─"
        TweenService:Create(ContentContainer, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Size = UDim2.new(1, 0, 1, -44)}):Play()
    end
end

MinimizeButton.MouseButton1Click:Connect(toggleMinimizar)

-- ========== ARRASTAR MENU ==========
local dragInput, dragStart, startPos
local function updateDrag(input)
    local delta = input.Position - dragStart
    local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    MainContainer.Position = newPos
end

TopBar.InputBegan:Connect(function(input)
    if not dragEnabled then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainContainer.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        updateDrag(input)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- ========== ABRIR/FECHAR MENU (toggle) ==========
local menuOpenPos = UDim2.new(0.66, 0, 0.21, 0)
local menuClosedPos = UDim2.new(1, 0, 0.21, 0)

local function toggleMenu()
    isMenuOpen = not isMenuOpen
    if isMenuOpen then
        MainContainer.Visible = true
        TweenService:Create(MainContainer, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = menuOpenPos}):Play()
        ToggleButton.Text = "✕"
    else
        TweenService:Create(MainContainer, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = menuClosedPos}):Play()
        delay(0.35, function()
            if not isMenuOpen then
                MainContainer.Visible = false
            end
        end)
        ToggleButton.Text = "☰"
    end
end

ToggleButton.MouseButton1Click:Connect(toggleMenu)

-- ========== ESP (HIGHLIGHT) ==========
function ativarESP()
    local function adicionarHighlight(player)
        local char = player.Character or player.CharacterAdded:Wait()
        local highlight = Instance.new("Highlight")
        highlight.Name = "ESP_Highlight"
        highlight.FillColor = Color3.fromRGB(0, 255, 100)
        highlight.FillTransparency = 0.5
        highlight.OutlineColor = Color3.fromRGB(0, 200, 100)
        highlight.Parent = char
        table.insert(highlightConnections, player.CharacterAdded:Connect(function(newChar)
            highlight.Parent = newChar
        end))
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            adicionarHighlight(player)
        end
    end
    table.insert(highlightConnections, Players.PlayerAdded:Connect(function(player)
        if player ~= LocalPlayer then
            adicionarHighlight(player)
        end
    end))
end

function desativarESP()
    for _, conn in ipairs(highlightConnections) do
        conn:Disconnect()
    end
    highlightConnections = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local highlight = player.Character:FindFirstChild("ESP_Highlight")
            if highlight then highlight:Destroy() end
        end
    end
end

-- ========== FULLBRIGHT ==========
function ativarFullBright()
    local lighting = game:GetService("Lighting")
    originalLighting = {
        Brightness = lighting.Brightness,
        ClockTime = lighting.ClockTime,
        FogEnd = lighting.FogEnd,
        GlobalShadows = lighting.GlobalShadows,
        Ambient = lighting.Ambient,
        OutdoorAmbient = lighting.OutdoorAmbient,
        Outlines = lighting.Outlines
    }
    lighting.Brightness = 2
    lighting.ClockTime = 14
    lighting.FogEnd = 100000
    lighting.GlobalShadows = false
    lighting.Ambient = Color3.new(1, 1, 1)
    lighting.OutdoorAmbient = Color3.new(1, 1, 1)
    lighting.Outlines = false
end

function desativarFullBright()
    local lighting = game:GetService("Lighting")
    for prop, value in pairs(originalLighting) do
        lighting[prop] = value
    end
end

-- ========== FPS COUNTER ==========
local fpsLabel
RunService.Heartbeat:Connect(function(deltaTime)
    if fpsLabel and fpsLabel:FindFirstChild("FPS") then
        local fps = math.floor(1 / deltaTime)
        fpsLabel.Text = "FPS: " .. fps
    end
end)

-- Ativar/desativar via toggle
fpsToggle:FindFirstChild("ToggleButton").MouseButton1Click:Connect(function()
    local state = not fpsLabel
    if state then
        if not fpsLabel then
            fpsLabel = Instance.new("TextLabel", ScreenGui)
            fpsLabel.Size = UDim2.new(0, 120, 0, 30)
            fpsLabel.Position = UDim2.new(0, 8, 0, 8)
            fpsLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            fpsLabel.BackgroundTransparency = 0.6
            fpsLabel.TextColor3 = CORES.texto
            fpsLabel.Text = "FPS: --"
            fpsLabel.Font = Enum.Font.GothamBold
            fpsLabel.TextSize = 14
            Instance.new("UICorner", fpsLabel).CornerRadius = UDim.new(0, 6)
            fpsLabel.Name = "FPS"
        end
    else
        if fpsLabel then
            fpsLabel:Destroy()
            fpsLabel = nil
        end
    end
end)

-- ========== PLAYER COUNT ==========
local playerCountLabel
local function atualizarPlayerCount()
    if playerCountLabel then
        local count = #Players:GetPlayers()
        playerCountLabel.Text = "Jogadores: " .. count
    end
end

Players.PlayerAdded:Connect(atualizarPlayerCount)
Players.PlayerRemoving:Connect(atualizarPlayerCount)

playerCountToggle:FindFirstChild("ToggleButton").MouseButton1Click:Connect(function()
    local state = not playerCountLabel
    if state then
        if not playerCountLabel then
            playerCountLabel = Instance.new("TextLabel", ScreenGui)
            playerCountLabel.Size = UDim2.new(0, 140, 0, 30)
            playerCountLabel.Position = UDim2.new(0, 136, 0, 8)
            playerCountLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            playerCountLabel.BackgroundTransparency = 0.6
            playerCountLabel.TextColor3 = CORES.texto
            playerCountLabel.Font = Enum.Font.GothamBold
            playerCountLabel.TextSize = 14
            Instance.new("UICorner", playerCountLabel).CornerRadius = UDim.new(0, 6)
            playerCountLabel.Name = "PlayerCount"
            atualizarPlayerCount()
        end
    else
        if playerCountLabel then
            playerCountLabel:Destroy()
            playerCountLabel = nil
        end
    end
end)

-- ========== INICIALIZAÇÃO ==========
-- Abre o menu ao carregar
toggleMenu()
trocarAba("Visual")