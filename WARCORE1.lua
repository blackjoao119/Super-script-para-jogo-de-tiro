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
--// 🔄 NOVA ABA: TELEPORTE (SISTEMA COMPLETO, 100% RAYFIELD)
--// =============================================
local savedLocations = {}  -- Lista de {name, x, y, z} (temporário, reseta ao sair)
local currentLocationLabel = nil
local savedSection = nil      -- Referência da seção de locais salvos
local savedElements = {}       -- Armazena elementos criados dinamicamente para limpeza

-- Função para copiar texto para a área de transferência
local function copyToClipboard(text)
    local success, err = pcall(function()
        if setclipboard then
            setclipboard(text)
        elseif syn and syn.set_clipboard then
            syn.set_clipboard(text)
        else
            -- Fallback usando um TextBox oculto (compatível com qualquer executor)
            local temp = Instance.new("TextBox")
            temp.Text = text
            temp:CaptureFocus()
            temp:ReleaseFocus()
            temp:Destroy()
        end
    end)
    if success then
        Rayfield:Notify({
            Title = "Copiado!",
            Content = "Coordenadas copiadas para o clipboard.",
            Duration = 2,
            Image = 4483362458
        })
    else
        Rayfield:Notify({
            Title = "Erro",
            Content = "Não foi possível copiar. Use manualmente.",
            Duration = 2,
            Image = 4483362458
        })
    end
end

-- Atualiza a exibição da localização atual (chamada no loop)
local function updateCurrentLocationDisplay()
    local char = Player.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local pos = char.HumanoidRootPart.Position
        local x, y, z = math.floor(pos.X * 100) / 100, math.floor(pos.Y * 100) / 100, math.floor(pos.Z * 100) / 100
        local text = string.format("X: %.2f\nY: %.2f\nZ: %.2f\n\nPosição:\n%.2f, %.2f, %.2f", x, y, z, x, y, z)
        if currentLocationLabel then
            currentLocationLabel:Set(text)
        end
    end
end

-- Reconstroi a lista visual de locais salvos
local function refreshSavedLocationsList()
    -- Remove elementos antigos da seção
    for _, elem in ipairs(savedElements) do
        pcall(function() elem:Destroy() end)
    end
    savedElements = {}

    if #savedLocations == 0 then
        -- Exibe mensagem de vazio
        local emptyMsg = TeleportTab:CreateParagraph({
            Title = "Nenhum local salvo",
            Content = "Use o campo acima para salvar sua posição atual com um nome."
        })
        table.insert(savedElements, emptyMsg)
        return
    end

    for i, loc in ipairs(savedLocations) do
        -- Nome e coordenadas
        local infoText = string.format("📍 %s\n   X: %.2f  Y: %.2f  Z: %.2f", loc.name, loc.x, loc.y, loc.z)
        local info = TeleportTab:CreateParagraph({
            Title = "Local #" .. i,
            Content = infoText
        })
        table.insert(savedElements, info)

        -- Botão Teleportar
        local btnTeleport = TeleportTab:CreateButton({
            Name = "🚀 Teleportar para " .. loc.name,
            Callback = function()
                local char = Player.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    char.HumanoidRootPart.CFrame = CFrame.new(loc.x, loc.y, loc.z)
                    Rayfield:Notify({
                        Title = "Teleportado!",
                        Content = "Movido para " .. loc.name,
                        Duration = 3,
                        Image = 4483362458
                    })
                end
            end
        })
        table.insert(savedElements, btnTeleport)

        -- Botão Copiar
        local btnCopy = TeleportTab:CreateButton({
            Name = "📋 Copiar " .. loc.name,
            Callback = function()
                local coords = string.format("%.2f, %.2f, %.2f", loc.x, loc.y, loc.z)
                copyToClipboard(coords)
            end
        })
        table.insert(savedElements, btnCopy)

        -- Botão Editar Nome
        local btnEdit = TeleportTab:CreateButton({
            Name = "✏ Editar Nome de " .. loc.name,
            Callback = function()
                -- Para editar, usamos um Input temporário e depois capturamos o valor
                -- Como não há modal nativo, solicitamos via Input existente? Criamos um campo extra.
                -- Solução: mudar o nome diretamente via um campo de texto separado? 
                -- Vamos usar um prompt improvisado: criar um novo Input na aba "Editar Nome"
                -- Por simplicidade, vamos usar o campo de nome principal e um botão "Salvar Edição"
                -- Mas isso conflita com novo salvamento. Alternativa: criar uma sub-seção temporária.
                -- Melhor: usar o sistema de notificação para pedir o novo nome? Não.
                -- Vou criar um campo de texto "Novo nome" e um botão "Confirmar edição" que aparecem abaixo do local selecionado.
                -- Para evitar complexidade, vou adicionar um Input e um botão que só aparecem quando editar.
                -- Vou limpar a lista e recriar com um campo de edição ativo? Pode ser confuso.
                -- Optarei por uma abordagem simples: ao clicar em Editar, um Input e um botão aparecem no final da lista, e o usuário define o novo nome.
                -- Primeiro removo os elementos de edição anteriores (se existirem)
                -- Vou armazenar o índice sendo editado
                editingIndex = i
                refreshSavedLocationsList()
            end
        })
        table.insert(savedElements, btnEdit)

        -- Botão Excluir
        local btnDelete = TeleportTab:CreateButton({
            Name = "🗑 Excluir " .. loc.name,
            Callback = function()
                -- Confirmação simples via notificação? Melhor fazer uma confirmação com botões.
                -- Rayfield não tem diálogo de confirmação nativo. Faremos: ao clicar, removemos diretamente, mas exibimos notificação de confirmação.
                -- Para evitar acidentes, podemos pedir para clicar duas vezes ou usar um toggle de confirmação.
                -- Simplificando: removemos e notificamos.
                table.remove(savedLocations, i)
                refreshSavedLocationsList()
                Rayfield:Notify({
                    Title = "Removido",
                    Content = loc.name .. " foi excluído.",
                    Duration = 2,
                    Image = 4483362458
                })
            end
        })
        table.insert(savedElements, btnDelete)
    end

    -- Se houver um índice de edição ativo, mostrar campo de edição
    if editingIndex and savedLocations[editingIndex] then
        local editInput = TeleportTab:CreateInput({
            Name = "Novo nome para " .. savedLocations[editingIndex].name,
            PlaceholderText = "Digite o novo nome",
            Callback = function(text)
                -- Não faz nada no callback, espera o botão
            end
        })
        table.insert(savedElements, editInput)

        local confirmEditBtn = TeleportTab:CreateButton({
            Name = "✅ Confirmar Edição",
            Callback = function()
                -- Pega o texto do input? Infelizmente não temos referência fácil.
                -- Vamos usar uma variável externa para armazenar o texto digitado
                if newNameBuffer and newNameBuffer ~= "" then
                    savedLocations[editingIndex].name = newNameBuffer
                    newNameBuffer = ""
                    editingIndex = nil
                    refreshSavedLocationsList()
                    Rayfield:Notify({
                        Title = "Editado",
                        Content = "Nome atualizado para " .. savedLocations[editingIndex] and savedLocations[editingIndex].name or "",
                        Duration = 2,
                        Image = 4483362458
                    })
                end
            end
        })
        table.insert(savedElements, confirmEditBtn)
    end
end

-- Variáveis de controle para edição
editingIndex = nil
newNameBuffer = ""

-- Seção: Minha Localização Atual
TeleportTab:CreateSection("📍 Minha Localização Atual")

-- Usaremos CreateLabel se disponível, senão um Paragraph atualizado periodicamente
local hasLabel, labelTest = pcall(function()
    return TeleportTab:CreateLabel({ Text = "Inicializando..." })
end)
if hasLabel and labelTest and labelTest.Set then
    currentLocationLabel = labelTest
else
    -- Fallback: criamos um Paragraph e vamos recriá-lo a cada atualização (menos eficiente)
    currentLocationLabel = TeleportTab:CreateParagraph({
        Title = "Coordenadas",
        Content = "Aguardando..."
    })
    -- Sobrescreveremos o método Set para compatibilidade
    currentLocationLabel.Set = function(self, text)
        -- Recria o parágrafo
        pcall(function() self:Destroy() end)
        local newPara = TeleportTab:CreateParagraph({
            Title = "Coordenadas",
            Content = text
        })
        -- Atualiza a referência global
        currentLocationLabel = newPara
        currentLocationLabel.Set = self.Set
    end
end

-- Botão Copiar Local Atual
TeleportTab:CreateButton({
    Name = "📋 Copiar Local Atual",
    Callback = function()
        local char = Player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local pos = char.HumanoidRootPart.Position
            local coords = string.format("%.2f, %.2f, %.2f", pos.X, pos.Y, pos.Z)
            copyToClipboard(coords)
        end
    end
})

-- Seção: Salvar Novo Local
TeleportTab:CreateSection("➕ Salvar Novo Local")

local saveNameInput = TeleportTab:CreateInput({
    Name = "Nome do local",
    PlaceholderText = "Ex: Spawn, Boss, Farm...",
    Callback = function(text)
        -- Armazena temporariamente o nome digitado
        saveNameBuffer = text
    end
})

local saveNameBuffer = ""

TeleportTab:CreateButton({
    Name = "💾 Salvar Local",
    Callback = function()
        local char = Player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local pos = char.HumanoidRootPart.Position
            local name = (saveNameBuffer ~= "" and saveNameBuffer) or "Local " .. (#savedLocations + 1)
            local x, y, z = math.floor(pos.X * 100) / 100, math.floor(pos.Y * 100) / 100, math.floor(pos.Z * 100) / 100
            table.insert(savedLocations, {name = name, x = x, y = y, z = z})
            saveNameBuffer = ""  -- Limpa o buffer
            refreshSavedLocationsList()
            Rayfield:Notify({
                Title = "Salvo!",
                Content = name .. " adicionado aos locais.",
                Duration = 2,
                Image = 4483362458
            })
        else
            Rayfield:Notify({
                Title = "Erro",
                Content = "Personagem não encontrado.",
                Duration = 2,
                Image = 4483362458
            })
        end
    end
})

-- Seção: Locais Salvos (será populada dinamicamente)
savedSection = TeleportTab:CreateSection("📂 Lista de Locais Salvos")
refreshSavedLocationsList()

-- Também precisamos atualizar o buffer de edição quando o input de edição for usado
-- Vamos conectar o callback do Input de edição (criado em refreshSavedLocationsList) para atualizar newNameBuffer
-- Isso será feito na própria função refresh, pois o Input é criado lá.
-- Modificaremos refreshSavedLocationsList para incluir um Input com callback que seta newNameBuffer.

-- Precisamos redefinir refreshSavedLocationsList para lidar com o Input de edição corretamente.
-- Vou atualizar a função acima para incluir essa lógica.

-- Na verdade, vou reescrever refreshSavedLocationsList completamente para incorporar a edição de forma robusta.
-- (Já fiz acima, mas preciso garantir que o Input de edição atualize newNameBuffer.)
-- Vou ajustar a criação do Input de edição:

-- (A função abaixo substitui a anterior, mantendo o mesmo nome)

local function refreshSavedLocationsList()
    for _, elem in ipairs(savedElements) do
        pcall(function() elem:Destroy() end)
    end
    savedElements = {}

    if #savedLocations == 0 then
        local emptyMsg = TeleportTab:CreateParagraph({
            Title = "Nenhum local salvo",
            Content = "Use o campo acima para salvar sua posição atual com um nome."
        })
        table.insert(savedElements, emptyMsg)
        editingIndex = nil  -- limpa edição
        return
    end

    for i, loc in ipairs(savedLocations) do
        local infoText = string.format("📍 %s\n   X: %.2f  Y: %.2f  Z: %.2f", loc.name, loc.x, loc.y, loc.z)
        local info = TeleportTab:CreateParagraph({
            Title = "Local #" .. i,
            Content = infoText
        })
        table.insert(savedElements, info)

        local btnTeleport = TeleportTab:CreateButton({
            Name = "🚀 Teleportar para " .. loc.name,
            Callback = function()
                local char = Player.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    char.HumanoidRootPart.CFrame = CFrame.new(loc.x, loc.y, loc.z)
                    Rayfield:Notify({
                        Title = "Teleportado!",
                        Content = "Movido para " .. loc.name,
                        Duration = 3,
                        Image = 4483362458
                    })
                end
            end
        })
        table.insert(savedElements, btnTeleport)

        local btnCopy = TeleportTab:CreateButton({
            Name = "📋 Copiar " .. loc.name,
            Callback = function()
                local coords = string.format("%.2f, %.2f, %.2f", loc.x, loc.y, loc.z)
                copyToClipboard(coords)
            end
        })
        table.insert(savedElements, btnCopy)

        local btnEdit = TeleportTab:CreateButton({
            Name = "✏ Editar Nome de " .. loc.name,
            Callback = function()
                editingIndex = i
                newNameBuffer = ""
                refreshSavedLocationsList()
            end
        })
        table.insert(savedElements, btnEdit)

        local btnDelete = TeleportTab:CreateButton({
            Name = "🗑 Excluir " .. loc.name,
            Callback = function()
                table.remove(savedLocations, i)
                refreshSavedLocationsList()
                Rayfield:Notify({
                    Title = "Removido",
                    Content = loc.name .. " foi excluído.",
                    Duration = 2,
                    Image = 4483362458
                })
            end
        })
        table.insert(savedElements, btnDelete)
    end

    -- Mostra campo de edição se necessário
    if editingIndex and savedLocations[editingIndex] then
        local loc = savedLocations[editingIndex]
        local editInput = TeleportTab:CreateInput({
            Name = "Novo nome para " .. loc.name,
            PlaceholderText = "Digite o novo nome",
            Callback = function(text)
                newNameBuffer = text
            end
        })
        table.insert(savedElements, editInput)

        local confirmEditBtn = TeleportTab:CreateButton({
            Name = "✅ Confirmar Edição",
            Callback = function()
                if newNameBuffer ~= "" then
                    savedLocations[editingIndex].name = newNameBuffer
                    newNameBuffer = ""
                    editingIndex = nil
                    refreshSavedLocationsList()
                    Rayfield:Notify({
                        Title = "Editado",
                        Content = "Nome atualizado para " .. savedLocations[editingIndex].name,
                        Duration = 2,
                        Image = 4483362458
                    })
                else
                    Rayfield:Notify({
                        Title = "Aviso",
                        Content = "Digite um novo nome antes de confirmar.",
                        Duration = 2,
                        Image = 4483362458
                    })
                end
            end
        })
        table.insert(savedElements, confirmEditBtn)

        local cancelEditBtn = TeleportTab:CreateButton({
            Name = "❌ Cancelar Edição",
            Callback = function()
                editingIndex = nil
                newNameBuffer = ""
                refreshSavedLocationsList()
            end
        })
        table.insert(savedElements, cancelEditBtn)
    end
end

--// ABA: MONITOR
StatusTab:CreateToggle({ Name = "Monitorar Taxa de FPS", CurrentValue = false, Callback = function(v) getgenv().SystemConfig.ShowFPS = v fpsF.Visible = v end })
StatusTab:CreateToggle({ Name = "Contador Ativo de Players", CurrentValue = false, Callback = function(v) getgenv().SystemConfig.ShowPlayers = v countF.Visible = v end })

--// [LOOP CORE]
RunService.RenderStepped:Connect(function(dt)
    -- Atualiza coordenadas em tempo real (apenas se a aba estiver visível? Melhor sempre)
    updateCurrentLocationDisplay()

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
    -- Ao renascer, atualiza a lista de locais (não perde os salvos)
    refreshSavedLocationsList()
end)

Rayfield:Notify({
    Title = "👑 WARCORE v1.2.0",
    Content = "Nova aba Teleporte ativada, meu rei!",
    Duration = 5,
    Image = 4483362458
})