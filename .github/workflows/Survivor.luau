local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Referências do jogador
local player = Players.LocalPlayer
local staminaBar = player.PlayerGui.MainUI.StatsFrame.Stamina.Fill
local staminaInfo = player.PlayerGui.MainUI.StatsFrame.Stamina.Info
local runButton = player.PlayerGui.MainUI:WaitForChild("RunButton")
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local camera = workspace.CurrentCamera

-- ============================================
-- CONFIGURAÇÕES
-- ============================================
local CONFIG = {
SprintSpeed = 20,        -- Velocidade ao correr
DrainRate = 10,          -- Taxa de gasto de stamina (% por segundo)
MaxStamina = 100,        -- Stamina máxima
RegenRate = 15,          -- Taxa de regeneração (% por segundo)
SpeedMultiplier = 1.4,   -- Multiplicador (não usado)
CooldownTime = 3,        -- Tempo de cooldown após esgotar
WaitTime = 1,            -- Tempo de espera (não usado)
NormalSpeed = 6,         -- Velocidade normal de caminhada
SprintFOV = 80,          -- FOV ao correr
NormalFOV = 70           -- FOV normal
}

-- Variáveis de controle
local staminaScale = staminaBar.Size.X.Scale
local maxStamina = CONFIG.MaxStamina
local minStamina = 0
local isSprinting = false
local isDraining = false
local isRegenerating = false
local isOnCooldown = false
local currentTween = nil

-- Mostrar botão apenas em dispositivos móveis
runButton.Visible = UserInputService.TouchEnabled

-- ============================================
-- FUNÇÃO: ATUALIZAR TEXTO DA STAMINA
-- ============================================
local function UpdateStaminaInfo()
    local currentStamina = math.floor(staminaScale * maxStamina)
    staminaInfo.Text = currentStamina .. "/" .. maxStamina
end

-- ============================================
-- FUNÇÃO: ATUALIZAR BARRA DE STAMINA
-- ============================================
local function UpdateStaminaBar(newScale)
    if currentTween then
        currentTween:Cancel()
    end
    
    local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Linear)
    currentTween = TweenService:Create(
    staminaBar, 
    tweenInfo, 
    {Size = UDim2.new(newScale, 0, staminaBar.Size.Y.Scale, 0)}
    )
    currentTween:Play()
    UpdateStaminaInfo()
end

-- ============================================
-- FUNÇÃO: ATUALIZAR CAMPO DE VISÃO (FOV)
-- ============================================
local function UpdateFOV(targetFOV)
    local fovInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local fovTween = TweenService:Create(camera, fovInfo, {FieldOfView = targetFOV})
    fovTween:Play()
end

-- ============================================
-- FUNÇÃO: DRENAR STAMINA (ao correr)
-- ============================================
local function DrainStamina()
    if isDraining then return end
    
    isDraining = true
    isRegenerating = false
    local lastTime = tick()
    
    while isSprinting and staminaScale > minStamina do
        -- Só drena se o jogador estiver se movendo
        if humanoid.MoveDirection.Magnitude > 0 then
            local deltaTime = tick() - lastTime
            staminaScale = math.max(minStamina, staminaScale - (CONFIG.DrainRate / 100) * deltaTime)
            UpdateStaminaBar(staminaScale)
        end
        lastTime = tick()
        task.wait(0.05)
    end
    
    isDraining = false
    
    -- Se a stamina acabou, ativar cooldown
    if staminaScale <= minStamina then
        isSprinting = false
        humanoid.WalkSpeed = CONFIG.NormalSpeed
        UpdateFOV(CONFIG.NormalFOV)
        isOnCooldown = true
        
        task.spawn(function()
            task.wait(CONFIG.CooldownTime)
            isOnCooldown = false
            RegenerateStamina()
        end)
    end
end

-- ============================================
-- FUNÇÃO: REGENERAR STAMINA
-- ============================================
local function RegenerateStamina()
    if isRegenerating then return end
    if isOnCooldown then return end
    
    isRegenerating = true
    isDraining = false
    
    local lastTime = tick()
    
    while not isSprinting and staminaScale < 1 and not isOnCooldown do
        local deltaTime = tick() - lastTime
        staminaScale = math.min(1, staminaScale + (CONFIG.RegenRate / 100) * deltaTime)
        UpdateStaminaBar(staminaScale)
        lastTime = tick()
        task.wait(0.05)
    end
    
    isRegenerating = false
end

-- ============================================
-- FUNÇÃO: ALTERNAR SPRINT
-- ============================================
local function ToggleSprint()
    if isOnCooldown then return end
    if character:GetAttribute("UsingAbility") then return end
    
    if isSprinting then
        -- Parar de correr
        isSprinting = false
        humanoid.WalkSpeed = CONFIG.NormalSpeed
        UpdateFOV(CONFIG.NormalFOV)
        task.spawn(RegenerateStamina)
    else
        -- Começar a correr (se tiver stamina)
        if staminaScale > 0.05 then
            isSprinting = true
            humanoid.WalkSpeed = CONFIG.SprintSpeed
            UpdateFOV(CONFIG.SprintFOV)
            DrainStamina()
        end
    end
end

-- ============================================
-- EVENTOS DE INPUT
-- ============================================

-- Teclado (Shift)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.LeftShift then
        ToggleSprint()
    end
end)

-- Botão móvel
runButton.MouseButton1Down:Connect(ToggleSprint)

-- Console (Xbox/PlayStation - Botão X)
ContextActionService:BindAction("ConsoleRun", function(_, state)
    if state == Enum.UserInputState.Begin then
        ToggleSprint()
    end
end, true, Enum.KeyCode.ButtonX)

-- ============================================
-- REGENERAÇÃO PASSIVA
-- ============================================
task.spawn(function()
    while task.wait(0.1) do
        if not isSprinting and not isOnCooldown and staminaScale < 1 then
            RegenerateStamina()
        end
    end
end)

-- ============================================
-- RESETAR AO RENASCER
-- ============================================
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    humanoid = character:WaitForChild("Humanoid")
    camera = workspace.CurrentCamera
    
    -- Resetar variáveis
    isSprinting = false
    isDraining = false
    isRegenerating = false
    isOnCooldown = false
    staminaScale = 1
    
    -- Resetar UI e stats
    UpdateStaminaBar(1)
    UpdateStaminaInfo()
    humanoid.WalkSpeed = CONFIG.NormalSpeed
    camera.FieldOfView = CONFIG.NormalFOV
end)
humanoid.WalkSpeed = CONFIG.NormalSpeed
-- ============================================
-- ATUALIZAR INFO INICIAL
-- ============================================
UpdateStaminaInfo()

