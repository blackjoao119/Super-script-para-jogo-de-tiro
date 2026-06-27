--[[
	SISTEMA DE INTERFACE GRÁFICA MODULAR - ROBLOX
	OTIMIZADO PARA MOBILE (toque, telas pequenas, desempenho)
	COM MÓDULO DE VOO FUNCIONAL INTEGRADO
	Autor: Sistema Automatizado
	Data: 2025
--]]

-- ===========================
-- SEÇÃO 1: SERVIÇOS
-- ===========================
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ===========================
-- SEÇÃO 2: TEMA (MOBILE OTIMIZADO)
-- ===========================
local Theme = {
	Background = Color3.fromRGB(20, 20, 20),			-- Preto quase puro
	Panel = Color3.fromRGB(28, 28, 30),					-- Painel principal
	TopBar = Color3.fromRGB(22, 22, 25),					-- Barra superior
	Accent = Color3.fromRGB(0, 180, 255),				-- Azul neon
	AccentDark = Color3.fromRGB(0, 140, 200),
	Text = Color3.fromRGB(235, 235, 240),
	TextMuted = Color3.fromRGB(160, 160, 170),
	Button = Color3.fromRGB(40, 40, 45),
	ButtonHover = Color3.fromRGB(50, 50, 55),
	ToggleOff = Color3.fromRGB(55, 55, 60),
	ToggleOn = Color3.fromRGB(0, 180, 255),
	SectionLine = Color3.fromRGB(0, 180, 255),
	ScrollBar = Color3.fromRGB(45, 45, 50),
	Border = Color3.fromRGB(50, 50, 55),

	Font = Enum.Font.Gotham,
	FontBold = Enum.Font.GothamBold,

	CornerRadius = UDim.new(0, 10),
	FloatingButtonCorner = UDim.new(1, 0),				-- Botão flutuante redondo

	FloatingButtonSize = 60,
	ButtonHeight = 50,
	ToggleWidth = 62,
	ToggleHeight = 32,
	TabButtonHeight = 44,
	TopBarHeight = 34,
	SectionTitleSize = 16,
	LabelTextSize = 15,
	ButtonTextSize = 16,

	OpenDuration = 0.2,
	CloseDuration = 0.15,
	HoverFadeIn = 0.08,
	HoverFadeOut = 0.1,
}

-- ===========================
-- SEÇÃO 3: UTILIDADES
-- ===========================
local Utilities = {}

function Utilities:Create(className, properties)
	local obj = Instance.new(className)
	for prop, value in pairs(properties) do
		obj[prop] = value
	end
	return obj
end

function Utilities:ApplyCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = radius or Theme.CornerRadius
	corner.Parent = parent
	return corner
end

function Utilities:ApplyPadding(parent, padding)
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, padding.Left or 0)
	pad.PaddingRight = UDim.new(0, padding.Right or 0)
	pad.PaddingTop = UDim.new(0, padding.Top or 0)
	pad.PaddingBottom = UDim.new(0, padding.Bottom or 0)
	pad.Parent = parent
	return pad
end

function Utilities:CreateFrame(parent, size, position, color, transparency)
	local frame = self:Create("Frame", {
		Size = size,
		Position = position or UDim2.new(0,0,0,0),
		BackgroundColor3 = color or Theme.Panel,
		BorderSizePixel = 0,
		BackgroundTransparency = transparency or 0,
		Parent = parent,
	})
	self:ApplyCorner(frame)
	return frame
end

function Utilities:CreateLabel(parent, text, size, position, color, font, textSize, textAlign)
	local label = self:Create("TextLabel", {
		Text = text,
		Size = size,
		Position = position or UDim2.new(0,0,0,0),
		BackgroundTransparency = 1,
		TextColor3 = color or Theme.Text,
		Font = font or Theme.Font,
		TextSize = textSize or Theme.LabelTextSize,
		TextXAlignment = textAlign or Enum.TextXAlignment.Left,
		Parent = parent,
	})
	return label
end

function Utilities:CreateButton(parent, text, size, position, color)
	local button = self:Create("TextButton", {
		Text = text,
		Size = size,
		Position = position or UDim2.new(0,0,0,0),
		BackgroundColor3 = color or Theme.Button,
		TextColor3 = Theme.Text,
		Font = Theme.Font,
		TextSize = Theme.ButtonTextSize,
		AutoButtonColor = false,
		BorderSizePixel = 0,
		Parent = parent,
	})
	self:ApplyCorner(button)
	return button
end

function Utilities:Tween(obj, tweenInfo, properties)
	local tween = TweenService:Create(obj, tweenInfo, properties)
	tween:Play()
	return tween
end

-- ===========================
-- SEÇÃO 4: SISTEMA DE ARRASTAR
-- ===========================
local DragSystem = {}
DragSystem.__index = DragSystem

function DragSystem.new(guiObject, constraintArea)
	local self = setmetatable({}, DragSystem)
	self.Object = guiObject
	self.Constraint = constraintArea
	self.IsDragging = false
	self.DragStart = nil
	self.StartPos = nil

	guiObject.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or 
		   input.UserInputType == Enum.UserInputType.Touch then
			self.IsDragging = true
			self.DragStart = input.Position
			self.StartPos = guiObject.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					self.IsDragging = false
				end
			end)
		end
	end)

	guiObject.InputChanged:Connect(function(input)
		if self.IsDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or
		   input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - self.DragStart
			local newPos = UDim2.new(
				self.StartPos.X.Scale, self.StartPos.X.Offset + delta.X,
				self.StartPos.Y.Scale, self.StartPos.Y.Offset + delta.Y
			)
			if self.Constraint then
				local absSize = self.Constraint.AbsoluteSize
				local objSize = guiObject.AbsoluteSize
				local minX = 0
				local minY = 0
				local maxX = math.max(0, absSize.X - objSize.X)
				local maxY = math.max(0, absSize.Y - objSize.Y)
				newPos = UDim2.new(
					0, math.clamp(newPos.X.Offset, minX, maxX),
					0, math.clamp(newPos.Y.Offset, minY, maxY)
				)
			end
			guiObject.Position = newPos
		end
	end)

	return self
end

-- ===========================
-- SEÇÃO 5: CONSTRUÇÃO DA INTERFACE
-- ===========================
local UI = {}

UI.ScreenGui = Utilities:Create("ScreenGui", {
	Name = "ModularUI_Mobile",
	Parent = PlayerGui,
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	IgnoreGuiInset = true,
})

local FloatingButton = Utilities:Create("TextButton", {
	Size = UDim2.new(0, Theme.FloatingButtonSize, 0, Theme.FloatingButtonSize),
	Position = UDim2.new(0, 16, 0, 180),
	BackgroundColor3 = Theme.Accent,
	Text = "☰",
	TextColor3 = Theme.Text,
	Font = Theme.FontBold,
	TextSize = 24,
	AutoButtonColor = false,
	BorderSizePixel = 0,
	Parent = UI.ScreenGui,
})
Utilities:ApplyCorner(FloatingButton, Theme.FloatingButtonCorner)
Utilities:ApplyPadding(FloatingButton, {Left=4, Right=4, Top=4, Bottom=4})

DragSystem.new(FloatingButton, UI.ScreenGui)

local MainPanel = Utilities:Create("Frame", {
	Name = "MainPanel",
	Size = UDim2.new(0, 0, 0, 0),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundColor3 = Theme.Panel,
	ClipsDescendants = true,
	Parent = UI.ScreenGui,
	Visible = false,
})
local targetPanelSize = UDim2.new(0.92, 0, 0.88, 0)

local TopBar = Utilities:CreateFrame(MainPanel, UDim2.new(1, 0, 0, Theme.TopBarHeight), 
	UDim2.new(0,0,0,0), Theme.TopBar)
TopBar.Name = "TopBar"

Utilities:CreateLabel(TopBar, "PAINEL MODULAR", UDim2.new(0.7,0,1,0), 
	UDim2.new(0,12,0,0), Theme.Text, Theme.FontBold, 16, Enum.TextXAlignment.Left)

local CloseButton = Utilities:CreateButton(TopBar, "✕", 
	UDim2.new(0, 32, 0, 32), UDim2.new(1,-36,0,1), Theme.Button)
CloseButton.TextSize = 18
CloseButton.TextColor3 = Theme.Text

DragSystem.new(TopBar, UI.ScreenGui)

local TabButtonsFrame = Utilities:CreateFrame(MainPanel, UDim2.new(1,0,0, Theme.TabButtonHeight+8),
	UDim2.new(0,0,0, Theme.TopBarHeight), Theme.Background)
Utilities:ApplyPadding(TabButtonsFrame, {Left=6, Right=6, Top=4, Bottom=4})

local TabButtonsLayout = Instance.new("UIListLayout")
TabButtonsLayout.FillDirection = Enum.FillDirection.Horizontal
TabButtonsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
TabButtonsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
TabButtonsLayout.Padding = UDim.new(0, 6)
TabButtonsLayout.Parent = TabButtonsFrame

local TabContentFrame = Utilities:CreateFrame(MainPanel, 
	UDim2.new(1,0,1,-Theme.TopBarHeight-Theme.TabButtonHeight-8),
	UDim2.new(0,0,0, Theme.TopBarHeight+Theme.TabButtonHeight+8), Theme.Background)

-- ===========================
-- SEÇÃO 6: SISTEMA DE ABAS
-- ===========================
local Tabs = {}
local ActiveTab = nil
local ActiveTabScrollingFrame = nil

function UI:CriarAba(nome)
	if Tabs[nome] then return end

	local tabButton = Utilities:CreateButton(TabButtonsFrame, nome, 
		UDim2.new(0, 90, 0, Theme.TabButtonHeight), nil, Theme.Button)
	tabButton.TextSize = 14
	tabButton.Font = Theme.FontBold

	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, 0, 1, 0)
	scroll.Position = UDim2.new(0,0,0,0)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 5
	scroll.ScrollBarImageColor3 = Theme.ScrollBar
	scroll.CanvasSize = UDim2.new(0,0,0,0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.Parent = TabContentFrame

	local listFrame = Instance.new("Frame")
	listFrame.Size = UDim2.new(1, 0, 1, 0)
	listFrame.BackgroundTransparency = 1
	listFrame.Parent = scroll

	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 10)
	listLayout.Parent = listFrame

	Utilities:ApplyPadding(listFrame, {Left=12, Right=12, Top=10, Bottom=10})

	local tabData = {
		Button = tabButton,
		ScrollFrame = scroll,
		ListFrame = listFrame,
		Layout = listLayout,
		Name = nome,
	}
	Tabs[nome] = tabData

	tabButton.MouseButton1Click:Connect(function()
		UI:SwitchTab(nome)
	end)

	if not ActiveTab then
		UI:SwitchTab(nome)
	end

	if nome == "Configuracoes" then
		tabButton.LayoutOrder = 999
	else
		tabButton.LayoutOrder = #Tabs
	end

	return tabData
end

function UI:SwitchTab(nome)
	local tabData = Tabs[nome]
	if not tabData then return end

	for _, data in pairs(Tabs) do
		data.ScrollFrame.Visible = false
		data.Button.BackgroundColor3 = Theme.Button
	end

	tabData.ScrollFrame.Visible = true
	tabData.Button.BackgroundColor3 = Theme.AccentDark

	ActiveTab = tabData.ScrollFrame
	ActiveTabScrollingFrame = tabData.ListFrame
end

-- ===========================
-- SEÇÃO 7: COMPONENTES
-- ===========================

function UI:CriarBotao(texto, callback)
	if not ActiveTabScrollingFrame then return end
	local btn = Utilities:CreateButton(ActiveTabScrollingFrame, texto, 
		UDim2.new(1, 0, 0, Theme.ButtonHeight), nil, Theme.Button)
	btn.MouseEnter:Connect(function()
		Utilities:Tween(btn, TweenInfo.new(Theme.HoverFadeIn), {BackgroundColor3 = Theme.ButtonHover})
	end)
	btn.MouseLeave:Connect(function()
		Utilities:Tween(btn, TweenInfo.new(Theme.HoverFadeOut), {BackgroundColor3 = Theme.Button})
	end)
	if callback then
		btn.MouseButton1Click:Connect(callback)
	end
	return btn
end

function UI:CriarToggle(texto, callback)
	if not ActiveTabScrollingFrame then return end
	local container = Utilities:CreateFrame(ActiveTabScrollingFrame, 
		UDim2.new(1, 0, 0, 40), nil, Theme.Panel)
	container.BackgroundTransparency = 1

	local label = Utilities:CreateLabel(container, texto, UDim2.new(0, 150, 1, 0), 
		nil, Theme.Text, Theme.Font, 15, Enum.TextXAlignment.Left)

	local toggleFrame = Utilities:CreateFrame(container, 
		UDim2.new(0, Theme.ToggleWidth, 0, Theme.ToggleHeight), 
		UDim2.new(1, -Theme.ToggleWidth-12, 0.5, -Theme.ToggleHeight/2), 
		Theme.ToggleOff)
	Utilities:ApplyCorner(toggleFrame, UDim.new(0, 16))

	local slider = Utilities:CreateFrame(toggleFrame, 
		UDim2.new(0, Theme.ToggleHeight-8, 0, Theme.ToggleHeight-8), 
		UDim2.new(0, 4, 0.5, -(Theme.ToggleHeight-8)/2), Theme.Text)
	Utilities:ApplyCorner(slider, UDim.new(0, (Theme.ToggleHeight-8)/2))

	local toggled = false
	local function updateVisual()
		if toggled then
			toggleFrame.BackgroundColor3 = Theme.ToggleOn
			Utilities:Tween(slider, TweenInfo.new(0.12), {
				Position = UDim2.new(1, -(Theme.ToggleHeight-4), 0.5, -(Theme.ToggleHeight-8)/2)
			})
		else
			toggleFrame.BackgroundColor3 = Theme.ToggleOff
			Utilities:Tween(slider, TweenInfo.new(0.12), {
				Position = UDim2.new(0, 4, 0.5, -(Theme.ToggleHeight-8)/2)
			})
		end
	end

	local clickButton = Instance.new("TextButton")
	clickButton.Size = UDim2.new(1,0,1,0)
	clickButton.BackgroundTransparency = 1
	clickButton.Text = ""
	clickButton.Parent = toggleFrame

	clickButton.MouseButton1Click:Connect(function()
		toggled = not toggled
		updateVisual()
		if callback then callback(toggled) end
	end)
	clickButton.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			toggled = not toggled
			updateVisual()
			if callback then callback(toggled) end
		end
	end)

	return {
		Container = container,
		Toggle = toggleFrame,
		GetState = function() return toggled end,
		SetState = function(state) toggled = state updateVisual() end,
	}
end

function UI:CriarLabel(texto)
	if not ActiveTabScrollingFrame then return end
	return Utilities:CreateLabel(ActiveTabScrollingFrame, texto, 
		UDim2.new(1, 0, 0, 22), nil, Theme.TextMuted, Theme.Font, 14)
end

function UI:CriarSecao(titulo)
	if not ActiveTabScrollingFrame then return end
	local container = Utilities:CreateFrame(ActiveTabScrollingFrame, 
		UDim2.new(1, 0, 0, 34), nil, Theme.Panel)
	container.BackgroundTransparency = 1
	local line = Utilities:CreateFrame(container, UDim2.new(0, 4, 1, -6), 
		UDim2.new(0,0,0,3), Theme.SectionLine)
	local titleLabel = Utilities:CreateLabel(container, titulo, 
		UDim2.new(1, -12, 1, 0), UDim2.new(0,12,0,0), Theme.Text, Theme.FontBold, Theme.SectionTitleSize)
	return container
end

-- ===========================
-- SEÇÃO 8: INICIALIZAÇÃO E ANIMAÇÕES
-- ===========================
local panelOpen = false

local function AbrirPainel()
	if panelOpen then return end
	MainPanel.Visible = true
	panelOpen = true
	Utilities:Tween(MainPanel, TweenInfo.new(Theme.OpenDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = targetPanelSize
	})
end

local function FecharPainel()
	if not panelOpen then return end
	Utilities:Tween(MainPanel, TweenInfo.new(Theme.CloseDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Size = UDim2.new(0,0,0,0)
	}).Completed:Connect(function()
		MainPanel.Visible = false
		panelOpen = false
	end)
end

FloatingButton.MouseButton1Click:Connect(function()
	if panelOpen then FecharPainel() else AbrirPainel() end
end)
FloatingButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch then
		if panelOpen then FecharPainel() else AbrirPainel() end
	end
end)

CloseButton.MouseButton1Click:Connect(FecharPainel)
CloseButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch then
		FecharPainel()
	end
end)

-- ===========================
-- SEÇÃO 9: MÓDULO DE VOO INTEGRADO
-- ===========================
-- Remove qualquer placeholder antigo de voo (não existia, mas garantimos)
-- Em seguida, cria a aba "✈️ Voo" e insere o script de voo funcional fornecido pelo usuário

UI:CriarAba("✈️ Voo")
UI:SwitchTab("✈️ Voo")

-- Variáveis do voo (isoladas)
local flyCam = workspace.CurrentCamera
local flyPlayer = LocalPlayer
local flyChar = flyPlayer.Character or flyPlayer.CharacterAdded:Wait()
local flying = false
local infinite = false
local speed = 50
local bv = nil
local loopConnection = nil

-- Funções auxiliares do voo
local function getChar()
    return flyPlayer.Character
end

local function startFly()
    local c = getChar()
    if not c then return end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local hum = c:FindFirstChild("Humanoid")
    if hum then
        hum.PlatformStand = false
        hum.AutoRotate = true
    end

    if bv then bv:Destroy() end
    bv = Instance.new("BodyVelocity")
    bv.Name = "FlyVelocity"
    bv.MaxForce = Vector3.new(400000, 400000, 400000)
    bv.Parent = hrp
    flying = true
end

local function stopFly()
    flying = false
    if bv then
        bv:Destroy()
        bv = nil
    end
    local hrp = getChar() and getChar():FindFirstChild("HumanoidRootPart")
    if hrp then hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0) end
end

-- Loop de voo (RenderStepped) – igual ao script fornecido
loopConnection = RunService.RenderStepped:Connect(function()
    if not flying or not bv then return end
    
    local c = getChar()
    if not c then return end
    
    local hrp = c:FindFirstChild("HumanoidRootPart")
    local hum = c:FindFirstChild("Humanoid")
    if not hrp or not hum then return end

    local moveDir = hum.MoveDirection
    local targetVel = Vector3.new(0, 0, 0)

    if infinite then
        targetVel = flyCam.CFrame.LookVector * speed
    else
        if moveDir.Magnitude > 0 then
            local flatLook = Vector3.new(flyCam.CFrame.LookVector.X, 0, flyCam.CFrame.LookVector.Z)
            if flatLook.Magnitude > 0 then flatLook = flatLook.Unit end
            
            local flatCamCFrame = CFrame.lookAt(Vector3.zero, flatLook)
            local rawInput = flatCamCFrame:VectorToObjectSpace(moveDir)
            
            targetVel = flyCam.CFrame:VectorToWorldSpace(rawInput) * speed
        else
            targetVel = Vector3.new(0, 0, 0)
        end
    end

    bv.Velocity = targetVel
end)

-- Criar controles na aba "✈️ Voo"
UI:CriarSecao("Controles de Voo")

local toggleFlyButton
toggleFlyButton = UI:CriarBotao("🚀 Iniciar Voo", function()
    if not flying then
        startFly()
        toggleFlyButton.Text = "🛑 Parar Voo"
    else
        stopFly()
        toggleFlyButton.Text = "🚀 Iniciar Voo"
    end
end)

-- Toggle para modo infinito
UI:CriarToggle("♾️ Infinito", function(state)
    infinite = state
end)

-- Campo de velocidade (usamos um Frame com TextBox, adaptado ao sistema)
local speedContainer = Utilities:CreateFrame(ActiveTabScrollingFrame, 
    UDim2.new(1, 0, 0, Theme.ButtonHeight), nil, Theme.Panel)
speedContainer.BackgroundTransparency = 1

local speedLabel = Utilities:CreateLabel(speedContainer, "Velocidade", 
    UDim2.new(0, 120, 1, 0), nil, Theme.Text, Theme.Font, 16)

local speedBox = Instance.new("TextBox")
speedBox.Size = UDim2.new(1, -130, 1, 0)
speedBox.Position = UDim2.new(0, 130, 0, 0)
speedBox.Text = "50"
speedBox.BackgroundColor3 = Theme.Button
speedBox.TextColor3 = Theme.Text
speedBox.Font = Theme.Font
speedBox.TextSize = 16
speedBox.ClearTextOnFocus = false
speedBox.Parent = speedContainer
Utilities:ApplyCorner(speedBox)
Utilities:ApplyPadding(speedBox, {Left=8, Right=8})

speedBox.FocusLost:Connect(function()
    local num = tonumber(speedBox.Text)
    if num then
        speed = math.clamp(num, 1, 500)
        speedBox.Text = tostring(speed)
    else
        speedBox.Text = tostring(speed)
    end
end)

-- Botão de parada total (reset)
UI:CriarBotao("⏹️ Parar Totalmente", function()
    stopFly()
    if toggleFlyButton then
        toggleFlyButton.Text = "🚀 Iniciar Voo"
    end
    local c = getChar()
    if c and c:FindFirstChild("HumanoidRootPart") then
        c.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
    end
end)

-- Garantir que o voo reinicie ao respawnar
flyPlayer.CharacterAdded:Connect(function(newChar)
    task.wait(0.5)
    if flying then
        startFly()
    end
end)

-- ===========================
-- SEÇÃO 10: OUTRAS ABAS PADRÃO
-- ===========================
UI:CriarAba("🏠 Principal")
UI:CriarAba("📦 Modulos")
UI:CriarAba("👤 Player")
UI:CriarAba("🔧 Ferramentas")
UI:CriarAba("⚙️ Configuracoes")

-- Exemplos (podem ser removidos)
UI:SwitchTab("🏠 Principal")
UI:CriarSecao("Bem-vindo")
UI:CriarLabel("Sistema pronto. A aba ✈️ Voo já está funcional.")
UI:CriarBotao("Exemplo", function() print("Funciona!") end)

UI:SwitchTab("👤 Player")
UI:CriarToggle("Noclip", function(state) print("Noclip:", state) end)

print("Sistema UI Mobile com Voo integrado carregado.")